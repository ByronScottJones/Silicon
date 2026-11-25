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
import Testing

/// Covers the label rules in ENGINEERING.md section 5.2 through the public `App(binaryPath:)` initializer.
@Suite struct ClassificationTests
{
    private typealias F = MachOFixtures

    @Test( arguments: [
        ( [ F.arm64 ],                          "Apple",               true ),
        ( [ F.x86_64 ],                         "Intel 64",            false ),
        ( [ F.i386 ],                           "Intel 32",            false ),
        ( [ F.ppc ],                            "PowerPC",             false ),
        ( [ F.arm ],                            "Unknown",             false ),
        ( [ F.ppc64 ],                          "Unknown",             false ),
        ( [ F.x86_64, F.arm64 ],                "Universal",           true ),
        ( [ F.arm64, F.arm ],                   "Universal",           true ),
        ( [ F.ppc, F.i386, F.x86_64 ],          "PowerPC/Intel 32/64", false ),
        ( [ F.ppc, F.x86_64 ],                  "PowerPC/Intel 64",    false ),
        ( [ F.ppc, F.i386 ],                    "PowerPC/Intel 32",    false ),
        ( [ F.i386, F.x86_64 ],                 "Intel 32/64",         false ),
        ( [ F.arm, F.x86_64 ],                  "Unknown",             false ),
    ] )
    func labelFollowsSpecification( cpus: [ UInt32 ], label: String, ready: Bool ) throws
    {
        let path = try F.write( F.fat( cpus ) )

        defer { F.remove( path ) }

        let app = try #require( App( binaryPath: path ) )

        #expect( app.architecture == label )
        #expect( app.isAppleSiliconReady == ready )
    }

    @Test func rawArchitecturesKeepFileOrder() throws
    {
        let path = try F.write( F.fat( [ F.x86_64, F.arm64 ] ) )

        defer { F.remove( path ) }

        let app = try #require( App( binaryPath: path ) )

        #expect( app.architectures == [ "x86_64", "arm64" ] )
    }

    @Test func directBinaryResultHasNoBundleMetadata() throws
    {
        let path = try F.write( F.fat( [ F.arm64 ] ), name: "Plugin.bin" )

        defer { F.remove( path ) }

        let app = try #require( App( binaryPath: path ) )

        #expect( app.bundleID == nil )
        #expect( app.version == nil )
        #expect( app.icon == nil )
        #expect( app.path == path )
    }

    @Test func nonBinaryAndDirectoryAreRejected() throws
    {
        let path = try F.write( Data( "not a binary".utf8 ) )

        defer { F.remove( path ) }

        #expect( App( binaryPath: path ) == nil )
        #expect( App( binaryPath: ( path as NSString ).deletingLastPathComponent ) == nil )
    }

    @Test func missingBundleIsRejected()
    {
        #expect( App( path: "/nonexistent/Nothing.app" ) == nil )
    }
}
