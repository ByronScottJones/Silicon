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

/// Fails when the literal tables in ENGINEERING.md drift from the code.
@Suite struct SpecificationTests
{
    private static func specification() throws -> String
    {
        let root = URL( fileURLWithPath: #filePath ).deletingLastPathComponent().deletingLastPathComponent()

        return try String( contentsOf: root.appendingPathComponent( "ENGINEERING.md" ), encoding: .utf8 )
    }

    @Test func cpuTypeTableMatchesParser() throws
    {
        let spec = try Self.specification()

        let rows = [
            ( "`7`",          UInt32( 7 ) ),
            ( "`0x01000007`", UInt32( 0x01000007 ) ),
            ( "`12`",         UInt32( 12 ) ),
            ( "`0x0100000C`", UInt32( 0x0100000C ) ),
            ( "`18`",         UInt32( 18 ) ),
        ]

        for ( cell, cpu ) in rows
        {
            let expected = MachOFile.cpuToArch( type: cpu )

            #expect( spec.contains( "| \( cell ) | `\( expected )` |" ), "Missing \( cell ) -> \( expected )" )
        }
    }

    @Test( arguments: [ "0xCAFEBABE", "0xCEFAEDFE", "0xFEEDFACE", "0xCFFAEDFE", "0xFEEDFACF" ] )
    func magicNumbersAreDocumented( magic: String ) throws
    {
        #expect( try Self.specification().contains( "`\( magic )`" ) )
    }

    @Test func everyLabelInTheCodeIsDocumented() throws
    {
        let spec = try Self.specification()

        for label in [ "Apple", "Intel 64", "Intel 32", "PowerPC", "Universal", "PowerPC/Intel 32/64", "PowerPC/Intel 64", "PowerPC/Intel 32", "Intel 32/64", "Unknown" ]
        {
            #expect( spec.contains( "`\( label )`" ), "Label \( label ) is not documented" )
        }
    }
}
