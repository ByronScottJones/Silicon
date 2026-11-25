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

@Suite struct MachOFileTests
{
    @Test( arguments: [
        ( UInt32( 7 ),          "i386" ),
        ( UInt32( 0x01000007 ), "x86_64" ),
        ( UInt32( 12 ),         "arm" ),
        ( UInt32( 0x0100000C ), "arm64" ),
        ( UInt32( 18 ),         "ppc" ),
        ( UInt32( 0x01000012 ), "<unknown>" ),
        ( UInt32( 0 ),          "<unknown>" ),
    ] )
    func cpuTypeMapsToArchitectureString( cpu: UInt32, expected: String )
    {
        #expect( MachOFile.cpuToArch( type: cpu ) == expected )
    }

    @Test( arguments: [
        ( UInt32( 0xCEFAEDFE ), MachOFixtures.i386 ),
        ( UInt32( 0xFEEDFACE ), MachOFixtures.ppc ),
        ( UInt32( 0xCFFAEDFE ), MachOFixtures.arm64 ),
        ( UInt32( 0xFEEDFACF ), MachOFixtures.x86_64 ),
    ] )
    func thinMachOExposesItsSingleArchitecture( magic: UInt32, cpu: UInt32 ) throws
    {
        let path = try MachOFixtures.write( MachOFixtures.thin( magic: magic, cpu: cpu ) )

        defer { MachOFixtures.remove( path ) }

        let file = try #require( MachOFile( path: path ) )

        #expect( file.architectures == [ MachOFile.cpuToArch( type: cpu ) ] )
    }

    @Test func fatBinaryListsEveryArchitectureInOrder() throws
    {
        let path = try MachOFixtures.write( MachOFixtures.fat( [ MachOFixtures.x86_64, MachOFixtures.arm64 ] ) )

        defer { MachOFixtures.remove( path ) }

        let file = try #require( MachOFile( path: path ) )

        #expect( file.architectures == [ "x86_64", "arm64" ] )
    }

    @Test func unknownCPUTypeIsReportedAsUnknown() throws
    {
        let path = try MachOFixtures.write( MachOFixtures.fat( [ MachOFixtures.ppc64 ] ) )

        defer { MachOFixtures.remove( path ) }

        let file = try #require( MachOFile( path: path ) )

        #expect( file.architectures == [ "<unknown>" ] )
    }

    @Test func emptyFileIsRejected() throws
    {
        let path = try MachOFixtures.write( Data() )

        defer { MachOFixtures.remove( path ) }

        #expect( MachOFile( path: path ) == nil )
    }

    @Test func plainTextIsRejected() throws
    {
        let path = try MachOFixtures.write( Data( "#!/bin/sh\necho hello\n".utf8 ) )

        defer { MachOFixtures.remove( path ) }

        #expect( MachOFile( path: path ) == nil )
    }

    @Test( arguments: [ 0, 2, 4, 6, 8, 12, 20, 27 ] )
    func truncatedFatHeaderIsRejected( keep: Int ) throws
    {
        let full = MachOFixtures.fat( [ MachOFixtures.x86_64, MachOFixtures.arm64 ] )
        let path = try MachOFixtures.write( full.prefix( keep ) )

        defer { MachOFixtures.remove( path ) }

        #expect( MachOFile( path: path ) == nil )
    }

    @Test func oversizedFatCountEndsInNoResult() throws
    {
        var bytes = [ UInt8 ]( [ 0xCA, 0xFE, 0xBA, 0xBE, 0xFF, 0xFF, 0xFF, 0xFF ] )

        bytes += [ UInt8 ]( repeating: 0, count: 40 )

        let path = try MachOFixtures.write( Data( bytes ) )

        defer { MachOFixtures.remove( path ) }

        #expect( MachOFile( path: path ) == nil )
    }

    @Test( arguments: [ UInt32( 0 ), 20, 52, 0xFFFF ] )
    func implausibleFatArchitectureCountIsRejected( count: UInt32 ) throws
    {
        let header = MachOFixtures.fat( [] ).prefix( 4 )
        let bytes  = [ UInt8( count >> 24 ), UInt8( ( count >> 16 ) & 0xFF ), UInt8( ( count >> 8 ) & 0xFF ), UInt8( count & 0xFF ) ]
        let path   = try MachOFixtures.write( header + Data( bytes ) + Data( repeating: 0, count: 400 ) )

        defer { MachOFixtures.remove( path ) }

        #expect( MachOFile( path: path ) == nil )
    }

    @Test func javaClassFileIsNotParsedAsFatBinary() throws
    {
        // 0xCAFEBABE, minor 0, major 52 (Java 8): read as a fat count of 52.
        let path = try MachOFixtures.write( Data( [ 0xCA, 0xFE, 0xBA, 0xBE, 0x00, 0x00, 0x00, 0x34 ] + [ UInt8 ]( repeating: 1, count: 400 ) ) )

        defer { MachOFixtures.remove( path ) }

        #expect( MachOFile( path: path ) == nil )
    }

    @Test func missingFileAndDirectoryAreRejected() throws
    {
        let path = try MachOFixtures.write( Data() )

        defer { MachOFixtures.remove( path ) }

        #expect( MachOFile( path: path + ".missing" ) == nil )
        #expect( MachOFile( path: ( path as NSString ).deletingLastPathComponent ) == nil )
    }
}
