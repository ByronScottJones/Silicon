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

public class MainWindowController: NSWindowController
{
    @objc public private( set ) dynamic var started  = false
    @objc public private( set ) dynamic var loading  = false
    @objc private               dynamic var stop     = false
    @objc public private( set ) dynamic var appCount = UInt64( 0 )

    @objc public private( set ) dynamic var appsFolderOnly = UserDefaults.standard.value( forKey: "appsFolderOnly" ) == nil ? true : UserDefaults.standard.bool( forKey: "appsFolderOnly" )
    {
        didSet
        {
            UserDefaults.standard.set( self.appsFolderOnly, forKey: "appsFolderOnly" )
        }
    }

    @objc public private( set ) dynamic var recurseIntoApps = UserDefaults.standard.bool( forKey: "recurseIntoApps" )
    {
        didSet
        {
            UserDefaults.standard.set( self.recurseIntoApps, forKey: "recurseIntoApps" )
        }
    }

    @objc public private( set ) dynamic var excludeAppleApps = UserDefaults.standard.bool( forKey: "excludeAppleApps" )
    {
        didSet
        {
            UserDefaults.standard.set( self.excludeAppleApps, forKey: "excludeAppleApps" )
        }
    }

    @objc public private( set ) dynamic var showIntel32 = UserDefaults.standard.value( forKey: "showIntel32" ) == nil ? true : UserDefaults.standard.bool( forKey: "showIntel32" )
    {
        didSet
        {
            self.updateArchFilter()
            UserDefaults.standard.set( self.showIntel32, forKey: "showIntel32" )
        }
    }

    @objc public private( set ) dynamic var showIntel64 = UserDefaults.standard.value( forKey: "showIntel64" ) == nil ? true : UserDefaults.standard.bool( forKey: "showIntel64" )
    {
        didSet
        {
            self.updateArchFilter()
            UserDefaults.standard.set( self.showIntel64, forKey: "showIntel64" )
        }
    }

    @objc public private( set ) dynamic var showPowerPC = UserDefaults.standard.value( forKey: "showPowerPC" ) == nil ? true : UserDefaults.standard.bool( forKey: "showPowerPC" )
    {
        didSet
        {
            self.updateArchFilter()
            UserDefaults.standard.set( self.showPowerPC, forKey: "showPowerPC" )
        }
    }

    @objc public private( set ) dynamic var showAppleARM = UserDefaults.standard.value( forKey: "showAppleARM" ) == nil ? true : UserDefaults.standard.bool( forKey: "showAppleARM" )
    {
        didSet
        {
            self.updateArchFilter()
            UserDefaults.standard.set( self.showAppleARM, forKey: "showAppleARM" )
        }
    }

    @objc public private( set ) dynamic var showUniversal = UserDefaults.standard.value( forKey: "showUniversal" ) == nil ? true : UserDefaults.standard.bool( forKey: "showUniversal" )
    {
        didSet
        {
            self.updateArchFilter()
            UserDefaults.standard.set( self.showUniversal, forKey: "showUniversal" )
        }
    }

    @objc public private( set ) dynamic var showNonARM = UserDefaults.standard.value( forKey: "showNonARM" ) == nil ? true : UserDefaults.standard.bool( forKey: "showNonARM" )
    {
        didSet
        {
            self.updateArchFilter()
            UserDefaults.standard.set( self.showNonARM, forKey: "showNonARM" )
        }
    }

    @objc public private( set ) dynamic var sortOption = UserDefaults.standard.integer( forKey: "sortOption" )
    {
        didSet
        {
            self.updateSort()
            UserDefaults.standard.set( self.sortOption, forKey: "sortOption" )
        }
    }
    
    @IBOutlet public private( set ) dynamic var allApps:          NSArrayController!
    @IBOutlet public private( set ) dynamic var archFilteredApps: NSArrayController!
    @IBOutlet public private( set ) dynamic var arrayController:  NSArrayController!
    @IBOutlet public private( set ) dynamic var dropView:         DropView!
    
    public override var windowNibName: NSNib.Name?
    {
        "MainWindowController"
    }
    
    public override func windowDidLoad()
    {
        super.windowDidLoad()
        self.updateArchFilter()
        self.updateSort()
        
        self.window?.setContentBorderThickness( 0, for: .minY )
        
        self.dropView.onDrag = { _ in return true }
        self.dropView.onDrop =
        {
            urls in
            
            guard let window = self.window, let url = urls.first else
            {
                NSSound.beep()
                
                return false
            }
            
            guard let app = App( path: url.path ) else
            {
                let alert = NSAlert()
                
                alert.messageText     = "Not an Application"
                alert.informativeText = "The file you dropped was not detected as a macOS application."
                alert.alertStyle      = .critical
                
                alert.beginSheetModal( for: window, completionHandler: nil )
                
                return true
            }
            
            if app.architectures.contains( "arm64" )
            {
                let alert = NSAlert()
                
                alert.messageText     = "Apple Silicon Supported"
                alert.informativeText = "The application will run natively on Apple Silicon hardware."
                
                alert.beginSheetModal( for: window, completionHandler: nil )
                
                return true
            }
            
            let alert = NSAlert()
            
            alert.messageText     = "No Apple Silicon Support"
            alert.informativeText = "The application will be emulated on Apple Silicon hardware."
            alert.alertStyle      = .critical
            
            alert.beginSheetModal( for: window, completionHandler: nil )
            
            return true
        }
    }

    private func updateArchFilter()
    {
        var subpredicates: [ NSPredicate ] = []

        if self.showIntel32   { subpredicates.append( NSPredicate( format: "ANY architectures == %@", "i386" ) ) }
        if self.showIntel64   { subpredicates.append( NSPredicate( format: "ANY architectures == %@", "x86_64" ) ) }
        if self.showPowerPC   { subpredicates.append( NSPredicate( format: "ANY architectures == %@", "ppc" ) ) }
        if self.showAppleARM  { subpredicates.append( NSPredicate( format: "ANY architectures == %@", "arm64" ) ) }
        if self.showUniversal { subpredicates.append( NSPredicate( format: "architectures.@count > 1" ) ) }
        if self.showNonARM    { subpredicates.append( NSPredicate( format: "NOT ( ANY architectures BEGINSWITH %@ )", "arm" ) ) }

        if subpredicates.isEmpty || subpredicates.count == 6
        {
            self.archFilteredApps.filterPredicate = nil

            return
        }

        self.archFilteredApps.filterPredicate = NSCompoundPredicate( orPredicateWithSubpredicates: subpredicates )
    }

    private func updateSort()
    {
        let key: String
        let ascending: Bool

        switch self.sortOption
        {
            case 1:  key = "name";         ascending = false
            case 2:  key = "architecture"; ascending = true
            case 3:  key = "architecture"; ascending = false
            case 4:  key = "path";         ascending = true
            case 5:  key = "path";         ascending = false
            default: key = "name";         ascending = true
        }

        self.arrayController.sortDescriptors = [
            NSSortDescriptor( key: key, ascending: ascending, selector: #selector( NSString.localizedCaseInsensitiveCompare( _: ) ) )
        ]
    }
    
    public func stopLoading()
    {
        self.stop = true
    }
    
    @IBAction public func newDocument( _ sender: Any? )
    {
        let reset =
        {
            self.appCount     = 0
            self.showIntel32   = true
            self.showIntel64   = true
            self.showPowerPC   = true
            self.showAppleARM  = true
            self.showUniversal = true
            self.showNonARM    = true
            self.sortOption    = 0
            self.loading      = false
            self.stop         = false
            self.started      = false
        }
        
        if self.loading
        {
            self.stop = true
            
            DispatchQueue.global( qos: .userInitiated ).async
            {
                while self.loading
                {
                    Thread.sleep( forTimeInterval: 0.1 )
                }
                
                DispatchQueue.main.async
                {
                    reset()
                }
            }
        }
        else
        {
            reset()
        }
    }
    
    @IBAction public func reload( _ sender: Any? )
    {
        if self.loading
        {
            NSSound.beep()
            
            return
        }
        
        self.window?.setContentBorderThickness( 32, for: .minY )
        
        self.started  = true
        self.loading  = true
        self.appCount = 0
        
        self.allApps.remove( contentsOf: self.allApps.content as? [ Any ] ?? [] )
        
        DispatchQueue.global( qos: .userInitiated ).async
        {
            self.findApps()
            
            DispatchQueue.main.async
            {
                self.loading = false
            }
        }
    }
    
    @IBAction private func revealApp( _ sender: Any? )
    {
        guard let app = self.arrayController.selectedObjects.first as? App else
        {
            NSSound.beep()

            return
        }

        app.showInFinder( sender )
    }

    @IBAction public func exportCSV( _ sender: Any? )
    {
        let apps = self.arrayController.arrangedObjects as? [ App ] ?? []

        guard !apps.isEmpty else { NSSound.beep(); return }

        let panel = NSSavePanel()

        panel.allowedFileTypes     = [ "csv" ]
        panel.nameFieldStringValue = "Silicon Export"
        panel.canCreateDirectories = true

        guard let window = self.window else { return }

        panel.beginSheetModal( for: window )
        { response in
            guard response == .OK, let url = panel.url else { return }

            var lines = [ "Name,Architecture,Version,Bundle ID,Path" ]

            for app in apps
            {
                lines.append(
                    [
                        self.csvField( app.name ),
                        self.csvField( app.architecture ),
                        self.csvField( app.version ?? "" ),
                        self.csvField( app.bundleID ?? "" ),
                        self.csvField( app.path )
                    ].joined( separator: "," )
                )
            }

            do
            {
                try lines.joined( separator: "\n" ).write( to: url, atomically: true, encoding: .utf8 )
            }
            catch
            {
                let alert = NSAlert( error: error )
                alert.beginSheetModal( for: window, completionHandler: nil )
            }
        }
    }

    @IBAction public func exportHTML( _ sender: Any? )
    {
        let apps = self.arrayController.arrangedObjects as? [ App ] ?? []

        guard !apps.isEmpty else { NSSound.beep(); return }

        let panel = NSSavePanel()

        panel.allowedFileTypes     = [ "html" ]
        panel.nameFieldStringValue = "Silicon Export"
        panel.canCreateDirectories = true

        guard let window = self.window else { return }

        panel.beginSheetModal( for: window )
        { response in
            guard response == .OK, let url = panel.url else { return }

            let rows = apps.map
            { app -> String in
                let name     = self.htmlEscape( app.name )
                let arch     = self.htmlEscape( app.architecture )
                let version  = self.htmlEscape( app.version ?? "—" )
                let bundleID = self.htmlEscape( app.bundleID ?? "—" )
                let path     = self.htmlEscape( app.path )

                return "        <tr><td>\(name)</td><td>\(arch)</td><td>\(version)</td><td>\(bundleID)</td><td class=\"path\">\(path)</td></tr>"
            }.joined( separator: "\n" )

            let count  = apps.count
            let plural = count == 1 ? "" : "s"

            let html = """
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="utf-8">
                <title>Silicon Scan Results</title>
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; font-size: 13px; margin: 24px; }
                    h1 { font-size: 20px; margin: 0 0 4px; }
                    p.sub { color: #666; margin: 0 0 16px; font-size: 12px; }
                    table { border-collapse: collapse; width: 100%; }
                    th { background: #f0f0f0; text-align: left; padding: 6px 10px; border: 1px solid #ccc; white-space: nowrap; }
                    td { padding: 5px 10px; border: 1px solid #e0e0e0; vertical-align: top; }
                    tr:nth-child(even) td { background: #fafafa; }
                    .path { font-family: ui-monospace, monospace; font-size: 11px; color: #444; word-break: break-all; }
                </style>
            </head>
            <body>
                <h1>Silicon Scan Results</h1>
                <p class="sub">\(count) application\(plural)</p>
                <table>
                    <thead>
                        <tr><th>Name</th><th>Architecture</th><th>Version</th><th>Bundle ID</th><th>Path</th></tr>
                    </thead>
                    <tbody>
            \(rows)
                    </tbody>
                </table>
            </body>
            </html>
            """

            do
            {
                try html.write( to: url, atomically: true, encoding: .utf8 )
            }
            catch
            {
                let alert = NSAlert( error: error )
                alert.beginSheetModal( for: window, completionHandler: nil )
            }
        }
    }

    private func csvField( _ value: String ) -> String
    {
        "\"\( value.replacingOccurrences( of: "\"", with: "\"\"" ) )\""
    }

    private func htmlEscape( _ string: String ) -> String
    {
        string
            .replacingOccurrences( of: "&",  with: "&amp;" )
            .replacingOccurrences( of: "<",  with: "&lt;" )
            .replacingOccurrences( of: ">",  with: "&gt;" )
            .replacingOccurrences( of: "\"", with: "&quot;" )
    }
    
    private func findApps()
    {
        if self.appsFolderOnly
        {
            let paths = NSSearchPathForDirectoriesInDomains( .applicationDirectory, .allDomainsMask, true )
            
            for path in paths
            {
                self.findApps( in: path )
            }
        }
        else
        {
            self.findApps( in: "/" )
        }
    }
    
    private func findApps( in directory: String )
    {
        let blacklist = UserDefaults.standard.stringArray( forKey: "folderBlacklist" ) ?? []

        guard let enumerator = FileManager.default.enumerator( atPath: directory ) else
        {
            return
        }

        var e = enumerator.nextObject()

        while e != nil
        {
            if self.stop
            {
                return
            }

            autoreleasepool
            {
                guard var path = e as? String else
                {
                    e = enumerator.nextObject()

                    return
                }

                path = ( directory as NSString ).appendingPathComponent( path )

                if path.hasPrefix( "/Volumes" )
                {
                    e = enumerator.nextObject()

                    return
                }

                if blacklist.contains( where: { path.hasPrefix( $0 ) } )
                {
                    enumerator.skipDescendents()
                    e = enumerator.nextObject()

                    return
                }

                if path.hasSuffix( ".app" ) == false
                {
                    e = enumerator.nextObject()

                    return
                }
                
                if self.recurseIntoApps == false
                {
                    enumerator.skipDescendents()
                }
                
                if let app = App( path: path )
                {
                    DispatchQueue.main.async
                    {
                        if self.excludeAppleApps && ( app.bundleID?.starts( with: "com.apple." ) ?? false  )
                        {
                            return
                        }
                        
                        self.allApps.addObject( app )
                        
                        self.appCount += 1
                    }
                }
                
                e = enumerator.nextObject()
            }
        }
    }
}
