/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright © 2020 DigiDNA - www.imazing.com
 * Enhancements Copyright © 2026 - Byron Scott Jones
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Foundation
import os

/// Downloads, caches, and queries Homebrew cask and formula metadata.
///
/// `@unchecked Sendable`: the three lookup tables are only read or written
/// while holding `lock`; every other stored property is an immutable `let`.
public final class HomebrewService: @unchecked Sendable
{
    public static let shared = HomebrewService()

    public struct Entry: Sendable
    {
        public let token:   String
        public let version: String
    }

    private static let log = Logger( subsystem: Bundle.main.bundleIdentifier ?? "com.DigiDNA.Silicon", category: "homebrew" )

    private let lock = NSLock()
    private var casksByBundleID: [ String: Entry ] = [:]
    private var casksByAppName:  [ String: Entry ] = [:]
    private var formulaByName:   [ String: Entry ] = [:]

    private let cacheDir:        URL
    private var caskCacheURL:    URL { self.cacheDir.appendingPathComponent( "cask.json" ) }
    private var formulaCacheURL: URL { self.cacheDir.appendingPathComponent( "formula.json" ) }

    private static let caskFeedURL:    URL = URL( string: "https://formulae.brew.sh/api/cask.json" )!
    private static let formulaFeedURL: URL = URL( string: "https://formulae.brew.sh/api/formula.json" )!
    private static let maxCacheAge: TimeInterval = 86400 // 24 hours

    private convenience init()
    {
        let home = FileManager.default.homeDirectoryForCurrentUser

        self.init( cacheDirectory: home.appendingPathComponent( ".Silicon/homebrew_cache" ) )
    }

    /// Creates a service that caches under `cacheDirectory`. Tests use this to stay out of the home folder.
    init( cacheDirectory: URL )
    {
        self.cacheDir = cacheDirectory
    }

    /// Load from cache if fresh; otherwise fetch from the network.
    ///
    /// - Throws: A file system or network error. Both feeds are fetched in
    ///   parallel and the first failure is rethrown.
    public func load() async throws
    {
        do
        {
            try FileManager.default.createDirectory( at: self.cacheDir, withIntermediateDirectories: true )

            async let caskData    = self.fetchOrLoad( remote: HomebrewService.caskFeedURL,    cache: self.caskCacheURL )
            async let formulaData = self.fetchOrLoad( remote: HomebrewService.formulaFeedURL, cache: self.formulaCacheURL )

            let casks    = try await caskData
            let formulae = try await formulaData

            self.parseCasks( data: casks )
            self.parseFormulae( data: formulae )
        }
        catch
        {
            HomebrewService.log.error( "Homebrew load failed: \( error.localizedDescription, privacy: .public )" )

            throw error
        }
    }

    /// Delete cached files and re-fetch.
    ///
    /// - Throws: Any error that `load()` throws.
    public func forceRefresh() async throws
    {
        try? FileManager.default.removeItem( at: self.caskCacheURL )
        try? FileManager.default.removeItem( at: self.formulaCacheURL )
        try await self.load()
    }

    /// Look up by bundle ID first (accurate), then by app display name (fuzzy fallback).
    public func lookup( bundleID: String?, appName: String ) -> Entry?
    {
        self.lock.lock()
        defer { self.lock.unlock() }

        if let bid = bundleID,
           let entry = self.casksByBundleID[ bid.lowercased() ] { return entry }

        let key = appName.lowercased()
        if let entry = self.casksByAppName[ key ] { return entry }
        if let entry = self.formulaByName[  key ] { return entry }
        return nil
    }

    // MARK: - Private

    private func isFresh( _ url: URL ) -> Bool
    {
        guard let attrs    = try? FileManager.default.attributesOfItem( atPath: url.path ),
              let modified = attrs[ .modificationDate ] as? Date
        else { return false }
        return Date().timeIntervalSince( modified ) < HomebrewService.maxCacheAge
    }

    private func fetchOrLoad( remote: URL, cache: URL ) async throws -> Data
    {
        if self.isFresh( cache ), let cached = try? Data( contentsOf: cache )
        {
            return cached
        }

        let ( data, response ) = try await URLSession.shared.data( from: remote )

        guard ( response as? HTTPURLResponse )?.statusCode == 200 else
        {
            let host = remote.host ?? "Homebrew"

            HomebrewService.log.error( "Unexpected response from \( host, privacy: .public )" )

            throw URLError( .badServerResponse )
        }

        try? data.write( to: cache )

        return data
    }

    private func parseCasks( data: Data )
    {
        guard let casks = try? JSONSerialization.jsonObject( with: data ) as? [ [ String: Any ] ]
        else
        {
            HomebrewService.log.error( "Cask JSON could not be parsed" )

            return
        }

        var byBundleID: [ String: Entry ] = [:]
        var byAppName:  [ String: Entry ] = [:]

        for cask in casks
        {
            guard let token   = cask[ "token"   ] as? String,
                  let version = cask[ "version" ] as? String
            else { continue }

            let entry = Entry( token: token, version: version )

            if let artifacts = cask[ "artifacts" ] as? [ [ String: Any ] ]
            {
                for artifact in artifacts
                {
                    // Bundle ID: extracted from the quit identifier used during uninstall
                    if let uninstalls = artifact[ "uninstall" ] as? [ [ String: Any ] ]
                    {
                        for u in uninstalls
                        {
                            if let q = u[ "quit" ] as? String
                            {
                                byBundleID[ q.lowercased() ] = entry
                            }
                            else if let qs = u[ "quit" ] as? [ String ]
                            {
                                qs.forEach { byBundleID[ $0.lowercased() ] = entry }
                            }
                        }
                    }

                    // App name: strip .app extension from the installed bundle name.
                    // Each element is either a plain String or a dict {"target": "Name.app"}
                    // when the cask renames the bundle on install.
                    if let apps = artifact[ "app" ] as? [ Any ]
                    {
                        for item in apps
                        {
                            let name: String?

                            if let s = item as? String
                            {
                                name = s
                            }
                            else if let d = item as? [ String: String ]
                            {
                                name = d[ "target" ]
                            }
                            else
                            {
                                name = nil
                            }

                            if let n = name
                            {
                                let key = ( ( n as NSString ).lastPathComponent as NSString ).deletingPathExtension.lowercased()
                                if byAppName[ key ] == nil { byAppName[ key ] = entry }
                            }
                        }
                    }
                }
            }

            // Fallback: match against the cask's human-readable name array
            if let names = cask[ "name" ] as? [ String ]
            {
                for name in names
                {
                    let key = name.lowercased()
                    if byAppName[ key ] == nil { byAppName[ key ] = entry }
                }
            }
        }

        self.lock.lock()
        defer { self.lock.unlock() }

        self.casksByBundleID = byBundleID
        self.casksByAppName  = byAppName
    }

    private func parseFormulae( data: Data )
    {
        guard let formulae = try? JSONSerialization.jsonObject( with: data ) as? [ [ String: Any ] ]
        else
        {
            HomebrewService.log.error( "Formula JSON could not be parsed" )

            return
        }

        var byName: [ String: Entry ] = [:]

        for formula in formulae
        {
            guard let name     = formula[ "name"     ] as? String,
                  let versions = formula[ "versions" ] as? [ String: Any ],
                  let stable   = versions[ "stable"  ] as? String
            else { continue }

            byName[ name.lowercased() ] = Entry( token: name, version: stable )
        }

        self.lock.lock()
        defer { self.lock.unlock() }

        self.formulaByName = byName
    }
}
