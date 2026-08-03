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

    private var refreshButton: NSButton!

    public init()
    {
        let window = NSWindow(
            contentRect: NSRect( x: 0, y: 0, width: 480, height: 460 ),
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

        let listSep             = NSBox()
        listSep.boxType         = .separator
        listSep.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( listSep )

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

        // Homebrew section
        let brewSep             = NSBox()
        brewSep.boxType         = .separator
        brewSep.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( brewSep )

        let brewTitle           = NSTextField( labelWithString: "Homebrew" )
        brewTitle.font          = NSFont.boldSystemFont( ofSize: NSFont.systemFontSize )
        brewTitle.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( brewTitle )

        let brewCheckbox        = NSButton( checkboxWithTitle: "Check Homebrew for updated versions", target: self, action: #selector( homebrewToggled( _: ) ) )
        brewCheckbox.state      = UserDefaults.standard.bool( forKey: "checkHomebrew" ) ? .on : .off
        brewCheckbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( brewCheckbox )

        let brewInfoLabel        = NSTextField( labelWithString: "When enabled, fetches formula/cask data from Homebrew and adds version columns to the app list and exports. Data is cached for 24 hours." )
        brewInfoLabel.font       = NSFont.systemFont( ofSize: NSFont.smallSystemFontSize )
        brewInfoLabel.textColor  = .secondaryLabelColor
        brewInfoLabel.isEditable = false
        brewInfoLabel.isBordered = false
        brewInfoLabel.drawsBackground = false
        brewInfoLabel.lineBreakMode   = .byWordWrapping
        brewInfoLabel.setContentCompressionResistancePriority( .defaultLow, for: .horizontal )
        brewInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( brewInfoLabel )

        let refreshBtn           = NSButton( title: "Refresh Homebrew Cache", target: self, action: #selector( refreshBrewCache( _: ) ) )
        refreshBtn.bezelStyle    = .rounded
        refreshBtn.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( refreshBtn )
        self.refreshButton       = refreshBtn

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
            scroll.bottomAnchor.constraint( equalTo: listSep.topAnchor, constant: -4 ),

            listSep.leadingAnchor.constraint( equalTo: contentView.leadingAnchor ),
            listSep.trailingAnchor.constraint( equalTo: contentView.trailingAnchor ),
            listSep.bottomAnchor.constraint( equalTo: addButton.topAnchor, constant: -4 ),

            addButton.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            addButton.bottomAnchor.constraint( equalTo: brewSep.topAnchor, constant: -12 ),
            addButton.widthAnchor.constraint( equalToConstant: 22 ),
            addButton.heightAnchor.constraint( equalToConstant: 22 ),

            removeButton.leadingAnchor.constraint( equalTo: addButton.trailingAnchor, constant: 2 ),
            removeButton.centerYAnchor.constraint( equalTo: addButton.centerYAnchor ),
            removeButton.widthAnchor.constraint( equalToConstant: 22 ),
            removeButton.heightAnchor.constraint( equalToConstant: 22 ),

            brewSep.leadingAnchor.constraint( equalTo: contentView.leadingAnchor ),
            brewSep.trailingAnchor.constraint( equalTo: contentView.trailingAnchor ),
            brewSep.bottomAnchor.constraint( equalTo: brewTitle.topAnchor, constant: -8 ),

            brewTitle.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            brewTitle.trailingAnchor.constraint( equalTo: contentView.trailingAnchor, constant: -16 ),
            brewTitle.bottomAnchor.constraint( equalTo: brewCheckbox.topAnchor, constant: -6 ),

            brewCheckbox.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            brewCheckbox.trailingAnchor.constraint( equalTo: contentView.trailingAnchor, constant: -16 ),
            brewCheckbox.bottomAnchor.constraint( equalTo: brewInfoLabel.topAnchor, constant: -4 ),

            brewInfoLabel.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            brewInfoLabel.trailingAnchor.constraint( equalTo: contentView.trailingAnchor, constant: -16 ),
            brewInfoLabel.bottomAnchor.constraint( equalTo: refreshBtn.topAnchor, constant: -8 ),

            refreshBtn.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            refreshBtn.bottomAnchor.constraint( equalTo: contentView.bottomAnchor, constant: -16 ),
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

    @objc private func homebrewToggled( _ sender: NSButton )
    {
        let enabled = sender.state == .on
        if let mwc = ( NSApp.delegate as? ApplicationDelegate )?.mainWindowController
        {
            mwc.checkHomebrew = enabled
        }
        else
        {
            UserDefaults.standard.set( enabled, forKey: "checkHomebrew" )
        }
    }

    @objc private func refreshBrewCache( _ sender: Any? )
    {
        self.refreshButton.isEnabled = false
        self.refreshButton.title     = "Refreshing…"

        HomebrewService.shared.forceRefresh
        { [ weak self ] _ in
            self?.refreshButton.isEnabled = true
            self?.refreshButton.title     = "Refresh Homebrew Cache"

            if let mwc = ( NSApp.delegate as? ApplicationDelegate )?.mainWindowController,
               mwc.checkHomebrew
            {
                mwc.applyBrewLookup()
            }
        }
    }
}
