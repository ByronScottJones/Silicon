/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2020 DigiDNA - www.imazing.com
 * Enhancements Copyright @ 2026 - Byron Scott Jones
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
import Testing

/// Uses fresh cache files in a temporary directory so no test touches the network or the home folder.
@Suite struct HomebrewServiceTests
{
    private static let casks = """
    [
      { "token": "firefox", "version": "130.0", "name": [ "Mozilla Firefox" ],
        "artifacts": [ { "uninstall": [ { "quit": "org.mozilla.firefox" } ] }, { "app": [ "Firefox.app" ] } ] },
      { "token": "renamed", "version": "2.0", "name": [ "Renamed Tool" ],
        "artifacts": [ { "uninstall": [ { "quit": [ "com.example.one", "com.example.two" ] } ] },
                       { "app": [ { "target": "Applications/Shown.app" } ] } ] },
      { "token": "noversion", "name": [ "No Version" ] }
    ]
    """

    private static let formulae = """
    [
      { "name": "wget", "versions": { "stable": "1.24" } },
      { "name": "broken", "versions": { } }
    ]
    """

    private func makeService() throws -> ( HomebrewService, URL )
    {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent( UUID().uuidString )

        try FileManager.default.createDirectory( at: directory, withIntermediateDirectories: true )
        try Data( Self.casks.utf8 ).write( to: directory.appendingPathComponent( "cask.json" ) )
        try Data( Self.formulae.utf8 ).write( to: directory.appendingPathComponent( "formula.json" ) )

        return ( HomebrewService( cacheDirectory: directory ), directory )
    }

    @Test func bundleIDMatchesCaskFirst() async throws
    {
        let ( service, directory ) = try self.makeService()

        defer { try? FileManager.default.removeItem( at: directory ) }

        try await service.load()

        let entry = try #require( service.lookup( bundleID: "org.mozilla.firefox", appName: "Something Else" ) )

        #expect( entry.token == "firefox" )
        #expect( entry.version == "130.0" )
    }

    @Test func bundleIDLookupIsCaseInsensitiveAndAcceptsQuitArrays() async throws
    {
        let ( service, directory ) = try self.makeService()

        defer { try? FileManager.default.removeItem( at: directory ) }

        try await service.load()

        #expect( service.lookup( bundleID: "COM.EXAMPLE.TWO", appName: "x" )?.token == "renamed" )
    }

    @Test func appNameMatchesStringAndTargetArtifacts() async throws
    {
        let ( service, directory ) = try self.makeService()

        defer { try? FileManager.default.removeItem( at: directory ) }

        try await service.load()

        #expect( service.lookup( bundleID: nil, appName: "Firefox" )?.token == "firefox" )
        #expect( service.lookup( bundleID: nil, appName: "Shown" )?.token == "renamed" )
    }

    @Test func caskDisplayNameIsAFallback() async throws
    {
        let ( service, directory ) = try self.makeService()

        defer { try? FileManager.default.removeItem( at: directory ) }

        try await service.load()

        #expect( service.lookup( bundleID: nil, appName: "Mozilla Firefox" )?.token == "firefox" )
    }

    @Test func formulaIsUsedLastAndIncompleteEntriesAreSkipped() async throws
    {
        let ( service, directory ) = try self.makeService()

        defer { try? FileManager.default.removeItem( at: directory ) }

        try await service.load()

        #expect( service.lookup( bundleID: nil, appName: "wget" )?.version == "1.24" )
        #expect( service.lookup( bundleID: nil, appName: "broken" ) == nil )
        #expect( service.lookup( bundleID: nil, appName: "noversion" ) == nil )
    }

    @Test func unknownAppHasNoEntry() async throws
    {
        let ( service, directory ) = try self.makeService()

        defer { try? FileManager.default.removeItem( at: directory ) }

        try await service.load()

        #expect( service.lookup( bundleID: "nope", appName: "Nothing Here" ) == nil )
    }
}
