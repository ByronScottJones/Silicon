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

public class PreferencesWindowController: NSWindowController, NSTableViewDataSource
{
    private var tableView: NSTableView!

    public init()
    {
        let window = NSWindow(
            contentRect: NSRect( x: 0, y: 0, width: 480, height: 380 ),
            styleMask:   [ .titled, .closable ],
            backing:     .buffered,
            defer:       false
        )

        window.title = "Preferences"

        super.init( window: window )

        self.buildUI( in: window.contentView! )
    }

    required public init?( coder: NSCoder ) { fatalError( "init(coder:) not supported" ) }

    private var blacklistedFolders: [ String ]
    {
        get { UserDefaults.standard.stringArray( forKey: "folderBlacklist" ) ?? [] }
        set { UserDefaults.standard.set( newValue, forKey: "folderBlacklist" ) }
    }

    private func buildUI( in contentView: NSView )
    {
        let titleLabel        = NSTextField( labelWithString: "Folder Blacklist" )
        titleLabel.font       = NSFont.boldSystemFont( ofSize: NSFont.systemFontSize )
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( titleLabel )

        let infoLabel           = NSTextField( labelWithString: "Folders listed here are excluded from all scans." )
        infoLabel.font          = NSFont.systemFont( ofSize: NSFont.smallSystemFontSize )
        infoLabel.textColor     = .secondaryLabelColor
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( infoLabel )

        let column              = NSTableColumn( identifier: NSUserInterfaceItemIdentifier( "path" ) )
        column.title            = "Excluded Folder"
        column.resizingMask     = [ .autoresizingMask ]
        column.width            = 440

        let table               = NSTableView()
        table.addTableColumn( column )
        table.dataSource        = self
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.rowHeight         = 20
        table.usesAlternatingRowBackgroundColors = true
        self.tableView          = table

        let scroll              = NSScrollView()
        scroll.documentView     = table
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers  = true
        scroll.borderType       = .lineBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( scroll )

        let separator           = NSBox()
        separator.boxType       = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( separator )

        let addButton           = NSButton( image: NSImage( named: NSImage.addTemplateName )!, target: self, action: #selector( addFolder( _: ) ) )
        addButton.bezelStyle    = .smallSquare
        addButton.setButtonType( .momentaryPushIn )
        addButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( addButton )

        let removeButton        = NSButton( image: NSImage( named: NSImage.removeTemplateName )!, target: self, action: #selector( removeFolder( _: ) ) )
        removeButton.bezelStyle = .smallSquare
        removeButton.setButtonType( .momentaryPushIn )
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( removeButton )

        NSLayoutConstraint.activate(
        [
            titleLabel.topAnchor.constraint( equalTo: contentView.topAnchor, constant: 16 ),
            titleLabel.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            titleLabel.trailingAnchor.constraint( equalTo: contentView.trailingAnchor, constant: -16 ),

            infoLabel.topAnchor.constraint( equalTo: titleLabel.bottomAnchor, constant: 4 ),
            infoLabel.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            infoLabel.trailingAnchor.constraint( equalTo: contentView.trailingAnchor, constant: -16 ),

            scroll.topAnchor.constraint( equalTo: infoLabel.bottomAnchor, constant: 8 ),
            scroll.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            scroll.trailingAnchor.constraint( equalTo: contentView.trailingAnchor, constant: -16 ),
            scroll.bottomAnchor.constraint( equalTo: separator.topAnchor, constant: -4 ),

            separator.leadingAnchor.constraint( equalTo: contentView.leadingAnchor ),
            separator.trailingAnchor.constraint( equalTo: contentView.trailingAnchor ),
            separator.bottomAnchor.constraint( equalTo: contentView.bottomAnchor, constant: -50 ),

            addButton.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            addButton.bottomAnchor.constraint( equalTo: contentView.bottomAnchor, constant: -16 ),
            addButton.widthAnchor.constraint( equalToConstant: 22 ),
            addButton.heightAnchor.constraint( equalToConstant: 22 ),

            removeButton.leadingAnchor.constraint( equalTo: addButton.trailingAnchor, constant: 2 ),
            removeButton.centerYAnchor.constraint( equalTo: addButton.centerYAnchor ),
            removeButton.widthAnchor.constraint( equalToConstant: 22 ),
            removeButton.heightAnchor.constraint( equalToConstant: 22 ),
        ] )
    }

    public func numberOfRows( in tableView: NSTableView ) -> Int
    {
        self.blacklistedFolders.count
    }

    public func tableView( _ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int ) -> Any?
    {
        self.blacklistedFolders[ row ]
    }

    @objc private func addFolder( _ sender: Any? )
    {
        let panel = NSOpenPanel()

        panel.canChooseDirectories    = true
        panel.canChooseFiles          = false
        panel.allowsMultipleSelection = false
        panel.prompt                  = "Add to Blacklist"

        guard let window = self.window else { return }

        panel.beginSheetModal( for: window )
        { response in
            guard response == .OK, let url = panel.url else { return }

            let path    = url.path
            var folders = self.blacklistedFolders

            guard !folders.contains( path ) else { return }

            folders.append( path )
            self.blacklistedFolders = folders
            self.tableView.reloadData()
        }
    }

    @objc private func removeFolder( _ sender: Any? )
    {
        let row = self.tableView.selectedRow

        guard row >= 0 else
        {
            NSSound.beep()
            return
        }

        var folders = self.blacklistedFolders
        folders.remove( at: row )
        self.blacklistedFolders = folders
        self.tableView.reloadData()
    }
}
