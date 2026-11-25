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

/// Builds Mach-O byte layouts that match what `MachOFile` reads, and writes them to disposable files.
enum MachOFixtures
{
    static let i386:   UInt32 = 7
    static let x86_64: UInt32 = 0x01000007
    static let arm:    UInt32 = 12
    static let arm64:  UInt32 = 0x0100000C
    static let ppc:    UInt32 = 18
    static let ppc64:  UInt32 = 0x01000012

    private static func bigEndian( _ value: UInt32 ) -> [ UInt8 ]
    {
        [ UInt8( value >> 24 ), UInt8( ( value >> 16 ) & 0xFF ), UInt8( ( value >> 8 ) & 0xFF ), UInt8( value & 0xFF ) ]
    }

    private static func littleEndian( _ value: UInt32 ) -> [ UInt8 ]
    {
        bigEndian( value ).reversed()
    }

    /// A fat (universal) header with one 20-byte entry per CPU type.
    static func fat( _ cpus: [ UInt32 ] ) -> Data
    {
        var bytes = bigEndian( 0xCAFEBABE ) + bigEndian( UInt32( cpus.count ) )

        for cpu in cpus
        {
            bytes += bigEndian( cpu ) + [ UInt8 ]( repeating: 0, count: 16 )
        }

        return Data( bytes )
    }

    /// A thin Mach-O header. `magic` is the value the parser reads as a big-endian integer.
    static func thin( magic: UInt32, cpu: UInt32 ) -> Data
    {
        let littleEndianFile = magic == 0xCEFAEDFE || magic == 0xCFFAEDFE

        return Data( bigEndian( magic ) + ( littleEndianFile ? littleEndian( cpu ) : bigEndian( cpu ) ) )
    }

    /// Writes `data` to a new file under a fresh temporary directory and returns its path.
    static func write( _ data: Data, name: String = "binary" ) throws -> String
    {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent( UUID().uuidString )

        try FileManager.default.createDirectory( at: directory, withIntermediateDirectories: true )

        let url = directory.appendingPathComponent( name )

        try data.write( to: url )

        return url.path
    }

    static func remove( _ path: String )
    {
        try? FileManager.default.removeItem( atPath: ( path as NSString ).deletingLastPathComponent )
    }
}
