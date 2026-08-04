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

import Cocoa

@objc public class App: NSObject
{
    @objc public private( set ) var name:                String
    @objc public private( set ) var path:                String
    @objc public private( set ) var version:             String?
    @objc public private( set ) var icon:                NSImage?
    @objc public private( set ) var architectures:       [ String ]
    @objc public private( set ) var isAppleSiliconReady: Bool
    @objc public private( set ) var architecture:        String
    @objc public private( set ) var bundleID:            String?
    @objc public            dynamic var brewToken:        String?
    @objc public            dynamic var brewVersion:      String?
    
    public init?( path: String )
    {
        var isDir = ObjCBool( booleanLiteral: false )
        
        if FileManager.default.fileExists( atPath: path, isDirectory: &isDir ) == false || isDir.boolValue == false
        {
            return nil
        }
        
        guard let info = AppInfo( path: path ) else
        {
            return nil
        }
        
        if FileManager.default.fileExists( atPath: info.executable.path ) == false
        {
            return nil
        }
        
        guard let macho = MachOFile( path: info.executable.path ) else
        {
            return nil
        }
        
        let architectureInfo = App.describe( architectures: macho.architectures, isIOS: info.kind == .iOS )
        
        self.bundleID              = info.info[ "CFBundleIdentifier" ]        as? String
        self.version               = info.info[ "CFBundleShortVersionString" ] as? String
        self.name                  = FileManager.default.displayName( atPath: path )
        self.path                  = path
        self.icon                  = NSWorkspace.shared.icon( forFile: path )
        self.architectures         = macho.architectures
        self.isAppleSiliconReady   = architectureInfo.isAppleSiliconReady
        self.architecture          = architectureInfo.architecture
    }

    public init?( binaryPath path: String )
    {
        var isDir = ObjCBool( booleanLiteral: false )

        if FileManager.default.fileExists( atPath: path, isDirectory: &isDir ) == false || isDir.boolValue
        {
            return nil
        }

        guard let macho = MachOFile( path: path ) else
        {
            return nil
        }

        let architectureInfo = App.describe( architectures: macho.architectures, isIOS: false )

        self.bundleID              = nil
        self.version               = nil
        self.name                  = FileManager.default.displayName( atPath: path )
        self.path                  = path
        self.icon                  = nil
        self.architectures         = macho.architectures
        self.isAppleSiliconReady   = architectureInfo.isAppleSiliconReady
        self.architecture          = architectureInfo.architecture
    }

    private static func describe( architectures: [ String ], isIOS: Bool ) -> ( isAppleSiliconReady: Bool, architecture: String )
    {
        if architectures.count == 1
        {
            if architectures.contains( "arm64" )
            {
                return ( true, isIOS ? "Apple (iOS)" : "Apple" )
            }
            else if architectures.contains( "x86_64" )
            {
                return ( false, "Intel 64" )
            }
            else if architectures.contains( "i386" )
            {
                return ( false, "Intel 32" )
            }
            else if architectures.contains( "ppc" )
            {
                return ( false, "PowerPC" )
            }
            else
            {
                return ( false, "Unknown" )
            }
        }

        if architectures.contains( "arm64" )
        {
            return ( true, isIOS ? "Universal (iOS)" : "Universal" )
        }
        else if architectures.contains( "ppc" ) && architectures.contains( "i386" ) && architectures.contains( "x86_64" )
        {
            return ( false, "PowerPC/Intel 32/64" )
        }
        else if architectures.contains( "ppc" ) && architectures.contains( "x86_64" )
        {
            return ( false, "PowerPC/Intel 64" )
        }
        else if architectures.contains( "ppc" ) && architectures.contains( "i386" )
        {
            return ( false, "PowerPC/Intel 32" )
        }
        else if architectures.contains( "i386" ) && architectures.contains( "x86_64" )
        {
            return ( false, "Intel 32/64" )
        }

        return ( false, "Unknown" )
    }
    
    @IBAction public func showInFinder( _ sender: Any? )
    {
        NSWorkspace.shared.selectFile( self.path, inFileViewerRootedAtPath: "/" )
    }
}
