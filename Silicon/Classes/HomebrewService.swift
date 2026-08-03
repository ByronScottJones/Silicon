/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2020 DigiDNA - www.imazing.com
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

public final class HomebrewService
{
    public static let shared = HomebrewService()

    public struct Entry
    {
        public let token:   String
        public let version: String
    }

    private var casksByBundleID: [ String: Entry ] = [:]
    private var casksByAppName:  [ String: Entry ] = [:]
    private var formulaByName:   [ String: Entry ] = [:]

    private let cacheDir:        URL
    private var caskCacheURL:    URL { self.cacheDir.appendingPathComponent( "cask.json" ) }
    private var formulaCacheURL: URL { self.cacheDir.appendingPathComponent( "formula.json" ) }

    private static let caskFeedURL:    URL = URL( string: "https://formulae.brew.sh/api/cask.json" )!
    private static let formulaFeedURL: URL = URL( string: "https://formulae.brew.sh/api/formula.json" )!
    private static let maxCacheAge: TimeInterval = 86400 // 24 hours

    private init()
    {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.cacheDir = home.appendingPathComponent( ".Silicon/homebrew_cache" )
    }

    /// Load from cache if fresh; otherwise fetch from the network. Calls back on the main queue.
    public func load( completion: @escaping ( Error? ) -> Void )
    {
        DispatchQueue.global( qos: .userInitiated ).async
        {
            do
            {
                try FileManager.default.createDirectory( at: self.cacheDir, withIntermediateDirectories: true )
            }
            catch
            {
                DispatchQueue.main.async { completion( error ) }
                return
            }

            let group = DispatchGroup()
            var caskData:    Data?
            var formulaData: Data?
            var fetchError:  Error?

            group.enter()
            self.fetchOrLoad( remote: HomebrewService.caskFeedURL, cache: self.caskCacheURL )
            {
                result in
                switch result
                {
                    case .success( let data ): caskData   = data
                    case .failure( let err ):  fetchError = err
                }
                group.leave()
            }

            group.enter()
            self.fetchOrLoad( remote: HomebrewService.formulaFeedURL, cache: self.formulaCacheURL )
            {
                result in
                switch result
                {
                    case .success( let data ): formulaData = data
                    case .failure( let err ):  fetchError  = err
                }
                group.leave()
            }

            group.wait()

            if let error = fetchError
            {
                DispatchQueue.main.async { completion( error ) }
                return
            }

            if let data = caskData    { self.parseCasks(    data: data ) }
            if let data = formulaData { self.parseFormulae( data: data ) }

            DispatchQueue.main.async { completion( nil ) }
        }
    }

    /// Delete cached files and re-fetch. Calls back on the main queue.
    public func forceRefresh( completion: @escaping ( Error? ) -> Void )
    {
        try? FileManager.default.removeItem( at: self.caskCacheURL )
        try? FileManager.default.removeItem( at: self.formulaCacheURL )
        self.load( completion: completion )
    }

    /// Look up by bundle ID first (accurate), then by app display name (fuzzy fallback).
    public func lookup( bundleID: String?, appName: String ) -> Entry?
    {
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

    private func fetchOrLoad( remote: URL, cache: URL, completion: @escaping ( Result< Data, Error > ) -> Void )
    {
        if self.isFresh( cache ), let cached = try? Data( contentsOf: cache )
        {
            completion( .success( cached ) )
            return
        }

        URLSession.shared.dataTask( with: remote )
        {
            data, _, error in

            if let error = error { completion( .failure( error ) ); return }
            guard let data = data else
            {
                completion( .failure( URLError( .badServerResponse ) ) )
                return
            }

            try? data.write( to: cache )
            completion( .success( data ) )
        }
        .resume()
    }

    private func parseCasks( data: Data )
    {
        guard let casks = try? JSONSerialization.jsonObject( with: data ) as? [ [ String: Any ] ]
        else { return }

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

        self.casksByBundleID = byBundleID
        self.casksByAppName  = byAppName
    }

    private func parseFormulae( data: Data )
    {
        guard let formulae = try? JSONSerialization.jsonObject( with: data ) as? [ [ String: Any ] ]
        else { return }

        var byName: [ String: Entry ] = [:]

        for formula in formulae
        {
            guard let name     = formula[ "name"     ] as? String,
                  let versions = formula[ "versions" ] as? [ String: Any ],
                  let stable   = versions[ "stable"  ] as? String
            else { continue }

            byName[ name.lowercased() ] = Entry( token: name, version: stable )
        }

        self.formulaByName = byName
    }
}
