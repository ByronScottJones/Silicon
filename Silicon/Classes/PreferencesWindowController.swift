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
    private static let specialFoldersKey  = "specialFolders"
    private static let folderPathKey      = "path"
    private static let folderModeKey      = "mode"
    private static let includedFolderMode = "included"
    private static let excludedFolderMode = "excluded"
    private static let audioPluginsKey    = "scanAudioPlugins"
    private static let audioPluginFolders = [ "/Library/Audio/Plug-Ins/", "~/Library/Audio/Plug-Ins/" ]

    private var tableView: NSTableView!
    private var audioPluginsCheckbox: NSButton!
    private var refreshButton: NSButton!

    public init()
    {
        let window = NSWindow(
            contentRect: NSRect( x: 0, y: 0, width: 520, height: 520 ),
            styleMask:   [ .titled, .closable ],
            backing:     .buffered,
            defer:       false
        )

        window.title = "Preferences"

        super.init( window: window )

        self.migrateFolderBlacklist()
        self.syncAudioPluginFolders( enabled: UserDefaults.standard.bool( forKey: PreferencesWindowController.audioPluginsKey ) )
        self.buildUI( in: window.contentView! )
    }

    required public init?( coder: NSCoder ) { fatalError( "init(coder:) not supported" ) }

    private var specialFolders: [ [ String: String ] ]
    {
        get { UserDefaults.standard.array( forKey: PreferencesWindowController.specialFoldersKey ) as? [ [ String: String ] ] ?? [] }
        set { UserDefaults.standard.set( newValue, forKey: PreferencesWindowController.specialFoldersKey ) }
    }

    private func buildUI( in contentView: NSView )
    {
        let titleLabel        = NSTextField( labelWithString: "Special Folders" )
        titleLabel.font       = NSFont.boldSystemFont( ofSize: NSFont.systemFontSize )
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( titleLabel )

        let infoLabel           = NSTextField( labelWithString: "Included folders are scanned in addition to the normal scan roots. Excluded folders are skipped." )
        infoLabel.font          = NSFont.systemFont( ofSize: NSFont.smallSystemFontSize )
        infoLabel.textColor     = .secondaryLabelColor
        infoLabel.lineBreakMode = .byWordWrapping
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( infoLabel )

        let modeColumn              = NSTableColumn( identifier: NSUserInterfaceItemIdentifier( "mode" ) )
        modeColumn.title            = "Mode"
        modeColumn.resizingMask     = []
        modeColumn.width            = 84

        let pathColumn              = NSTableColumn( identifier: NSUserInterfaceItemIdentifier( "path" ) )
        pathColumn.title            = "Folder"
        pathColumn.resizingMask     = [ .autoresizingMask ]
        pathColumn.width            = 388

        let table               = NSTableView()
        table.addTableColumn( modeColumn )
        table.addTableColumn( pathColumn )
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

        let includeButton       = NSButton( title: "Mark Included", target: self, action: #selector( markIncluded( _: ) ) )
        includeButton.bezelStyle = .rounded
        includeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( includeButton )

        let excludeButton       = NSButton( title: "Mark Excluded", target: self, action: #selector( markExcluded( _: ) ) )
        excludeButton.bezelStyle = .rounded
        excludeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( excludeButton )

        let audioCheckbox       = NSButton( checkboxWithTitle: "Scan for Audio Plugins", target: self, action: #selector( audioPluginsToggled( _: ) ) )
        audioCheckbox.state     = UserDefaults.standard.bool( forKey: PreferencesWindowController.audioPluginsKey ) ? .on : .off
        audioCheckbox.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( audioCheckbox )
        self.audioPluginsCheckbox = audioCheckbox

        let audioInfoLabel           = NSTextField( labelWithString: "Adds /Library/Audio/Plug-Ins/ and ~/Library/Audio/Plug-Ins/ as included folders. Every Mach-O binary file inside them is reported." )
        audioInfoLabel.font          = NSFont.systemFont( ofSize: NSFont.smallSystemFontSize )
        audioInfoLabel.textColor     = .secondaryLabelColor
        audioInfoLabel.lineBreakMode = .byWordWrapping
        audioInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview( audioInfoLabel )

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
            addButton.bottomAnchor.constraint( equalTo: audioCheckbox.topAnchor, constant: -10 ),
            addButton.widthAnchor.constraint( equalToConstant: 22 ),
            addButton.heightAnchor.constraint( equalToConstant: 22 ),

            removeButton.leadingAnchor.constraint( equalTo: addButton.trailingAnchor, constant: 2 ),
            removeButton.centerYAnchor.constraint( equalTo: addButton.centerYAnchor ),
            removeButton.widthAnchor.constraint( equalToConstant: 22 ),
            removeButton.heightAnchor.constraint( equalToConstant: 22 ),

            includeButton.leadingAnchor.constraint( equalTo: removeButton.trailingAnchor, constant: 10 ),
            includeButton.centerYAnchor.constraint( equalTo: addButton.centerYAnchor ),

            excludeButton.leadingAnchor.constraint( equalTo: includeButton.trailingAnchor, constant: 6 ),
            excludeButton.centerYAnchor.constraint( equalTo: addButton.centerYAnchor ),

            audioCheckbox.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            audioCheckbox.trailingAnchor.constraint( equalTo: contentView.trailingAnchor, constant: -16 ),
            audioCheckbox.bottomAnchor.constraint( equalTo: audioInfoLabel.topAnchor, constant: -4 ),

            audioInfoLabel.leadingAnchor.constraint( equalTo: contentView.leadingAnchor, constant: 16 ),
            audioInfoLabel.trailingAnchor.constraint( equalTo: contentView.trailingAnchor, constant: -16 ),
            audioInfoLabel.bottomAnchor.constraint( equalTo: brewSep.topAnchor, constant: -12 ),

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
        self.specialFolders.count
    }

    public func tableView( _ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int ) -> Any?
    {
        let folder = self.specialFolders[ row ]

        switch tableColumn?.identifier.rawValue
        {
            case "mode":
                return folder[ PreferencesWindowController.folderModeKey ] == PreferencesWindowController.includedFolderMode ? "Included" : "Excluded"
            default:
                return folder[ PreferencesWindowController.folderPathKey ] ?? ""
        }
    }

    @objc private func addFolder( _ sender: Any? )
    {
        let panel = NSOpenPanel()

        panel.canChooseDirectories    = true
        panel.canChooseFiles          = false
        panel.allowsMultipleSelection = false
        panel.prompt                  = "Add Special Folder"

        guard let window = self.window else { return }

        panel.beginSheetModal( for: window )
        { response in
            guard response == .OK, let url = panel.url else { return }

            self.addSpecialFolder( path: url.path, mode: PreferencesWindowController.excludedFolderMode )
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

        var folders = self.specialFolders
        folders.remove( at: row )
        self.specialFolders = folders
        self.syncAudioCheckboxState()
        self.tableView.reloadData()
    }

    @objc private func markIncluded( _ sender: Any? )
    {
        self.setModeForSelectedFolder( PreferencesWindowController.includedFolderMode )
    }

    @objc private func markExcluded( _ sender: Any? )
    {
        self.setModeForSelectedFolder( PreferencesWindowController.excludedFolderMode )
    }

    private func setModeForSelectedFolder( _ mode: String )
    {
        let row = self.tableView.selectedRow

        guard row >= 0 else
        {
            NSSound.beep()
            return
        }

        var folders = self.specialFolders
        folders[ row ][ PreferencesWindowController.folderModeKey ] = mode
        self.specialFolders = folders
        self.syncAudioCheckboxState()
        self.tableView.reloadData()
    }

    @objc private func audioPluginsToggled( _ sender: NSButton )
    {
        let enabled = sender.state == .on

        UserDefaults.standard.set( enabled, forKey: PreferencesWindowController.audioPluginsKey )
        self.syncAudioPluginFolders( enabled: enabled )
        self.tableView.reloadData()
    }

    private func syncAudioPluginFolders( enabled: Bool )
    {
        if enabled
        {
            for path in PreferencesWindowController.audioPluginFolders
            {
                self.addSpecialFolder( path: path, mode: PreferencesWindowController.includedFolderMode )
            }
        }
        else
        {
            self.specialFolders = self.specialFolders.filter
            {
                guard let path = $0[ PreferencesWindowController.folderPathKey ] else { return true }

                return self.isAudioPluginFolder( path ) == false
            }
        }
    }

    private func syncAudioCheckboxState()
    {
        let enabled = PreferencesWindowController.audioPluginFolders.allSatisfy
        { audioPath in
            self.specialFolders.contains
            { folder in
                guard let path = folder[ PreferencesWindowController.folderPathKey ],
                      folder[ PreferencesWindowController.folderModeKey ] == PreferencesWindowController.includedFolderMode
                else
                {
                    return false
                }

                return self.normalizedPath( path ) == self.normalizedPath( audioPath )
            }
        }

        UserDefaults.standard.set( enabled, forKey: PreferencesWindowController.audioPluginsKey )
        self.audioPluginsCheckbox?.state = enabled ? .on : .off
    }

    private func addSpecialFolder( path: String, mode: String )
    {
        let normalized = self.normalizedPath( path )
        var folders    = self.specialFolders

        if let index = folders.firstIndex( where: { self.normalizedPath( $0[ PreferencesWindowController.folderPathKey ] ?? "" ) == normalized } )
        {
            folders[ index ][ PreferencesWindowController.folderPathKey ] = path
            folders[ index ][ PreferencesWindowController.folderModeKey ] = mode
        }
        else
        {
            folders.append(
            [
                PreferencesWindowController.folderPathKey: path,
                PreferencesWindowController.folderModeKey: mode
            ] )
        }

        self.specialFolders = folders
    }

    private func migrateFolderBlacklist()
    {
        guard UserDefaults.standard.object( forKey: PreferencesWindowController.specialFoldersKey ) == nil else
        {
            return
        }

        self.specialFolders = ( UserDefaults.standard.stringArray( forKey: "folderBlacklist" ) ?? [] ).map
        {
            [
                PreferencesWindowController.folderPathKey: $0,
                PreferencesWindowController.folderModeKey: PreferencesWindowController.excludedFolderMode
            ]
        }
    }

    private func isAudioPluginFolder( _ path: String ) -> Bool
    {
        let normalized = self.normalizedPath( path )

        return PreferencesWindowController.audioPluginFolders.contains
        {
            self.normalizedPath( $0 ) == normalized
        }
    }

    private func normalizedPath( _ path: String ) -> String
    {
        ( ( path as NSString ).expandingTildeInPath as NSString ).standardizingPath
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
        self.refreshButton.title     = "Refreshing..."

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
