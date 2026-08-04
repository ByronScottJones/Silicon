# Engineering Guide — Silicon

## Overview

Silicon is a native macOS utility that identifies the binary architecture of installed applications and supported plugin binaries. It scans `.app` bundles, parses their Mach-O executables, and classifies each one as Apple Silicon, Universal, Intel 64, Intel 32, PowerPC, or combinations thereof. When audio plugin scanning is enabled, it also scans the standard macOS audio plugin folders and reports standalone Mach-O binaries found there.

- **Language:** Swift 5
- **UI Framework:** AppKit (XIB-based, Cocoa Bindings)
- **Minimum OS:** macOS 10.13 (High Sierra)
- **Build System:** Xcode project (`Silicon.xcodeproj`) — no Swift Package Manager
- **Bundle ID:** `com.DigiDNA.Silicon`
- **License:** MIT

---

## Project Structure

```
Silicon/
├── Silicon/
│   ├── Classes/                  # All Swift source files
│   │   ├── App.swift             # Core model — represents one .app bundle or Mach-O binary
│   │   ├── AppInfo.swift         # Reads Info.plist; resolves executable path
│   │   ├── MachOFile.swift       # Parses Mach-O binaries; extracts architectures
│   │   ├── BinaryStream.swift    # Low-level byte reader (used by MachOFile)
│   │   ├── MainWindowController.swift  # Main window logic; scanning; filtering
│   │   ├── ApplicationDelegate.swift   # App entry point; GitHub updater
│   │   ├── AboutWindowController.swift # About window
│   │   ├── DropView.swift              # Drag-and-drop NSView subclass
│   │   ├── NumberToString.swift        # Value transformer: UInt64 → String
│   │   ├── IsZero.swift                # Value transformer: number == 0
│   │   └── IsNotZero.swift             # Value transformer: number != 0
│   └── UI/
│       └── Base.lproj/
│           ├── MainWindowController.xib
│           ├── AboutWindowController.xib
│           └── MainMenu.xib
├── Submodules/
│   ├── GitHubUpdates/            # In-app update checking framework
│   └── xcconfig/                 # Shared build settings (.xcconfig files)
└── Silicon.xcodeproj/
```

---

## Architecture

### Data Flow

```
FileManager.enumerator
    → findApps(in:)                      [background queue]
        → App(path:)                     for .app bundles
            → AppInfo(path:)             reads Info.plist
            → MachOFile(path:)           parses binary
        → App(binaryPath:)               for included audio plugin binaries
            → MachOFile(path:)           parses binary
        → allApps NSArrayController      [main queue]
            → archFilteredApps NSArrayController   (predicate filter)
                → arrayController NSArrayController (sorted, displayed)
                    → NSTableView
```

### Key Classes

#### `App` — Model (`App.swift`)
The central model object. `App(path:)` initializes from a `.app` bundle path and returns `nil` if the bundle metadata or executable cannot be parsed. `App(binaryPath:)` initializes from a direct Mach-O binary path, which is used for audio plugin folders where plugin executables may live inside bundle-style directories or nested support folders.

Key properties (all `@objc dynamic` for Cocoa Bindings):
- `name: String` — display name from `FileManager.displayName`
- `path: String` — absolute path to the `.app` bundle or direct binary
- `architectures: [String]` — raw arch strings from the binary (`"arm64"`, `"x86_64"`, `"i386"`, `"ppc"`)
- `architecture: String` — human-readable label (`"Universal"`, `"Intel 64"`, etc.)
- `isAppleSiliconReady: Bool` — true if `architectures` contains `"arm64"`
- `bundleID: String?` — `CFBundleIdentifier`; `nil` for direct binary results
- `version: String?` — `CFBundleShortVersionString`; `nil` for direct binary results
- `icon: NSImage?` — app icon via `NSWorkspace`; `nil` for direct binary results

#### `MachOFile` — Binary Parser (`MachOFile.swift`)
Parses the raw bytes of a Mach-O executable. Handles all five magic numbers:

| Magic        | Format                          |
|--------------|---------------------------------|
| `0xCAFEBABE` | Fat/Universal binary            |
| `0xCEFAEDFE` | Little-endian 32-bit Mach-O     |
| `0xFEEDFACE` | Big-endian 32-bit Mach-O        |
| `0xCFFAEDFE` | Little-endian 64-bit Mach-O     |
| `0xFEEDFACF` | Big-endian 64-bit Mach-O        |

CPU type constants → arch strings: `7` → `i386`, `0x01000007` → `x86_64`, `12` → `arm`, `0x0100000C` → `arm64`, `18` → `ppc`.

#### `MainWindowController` — UI & Scan Logic (`MainWindowController.swift`)
Owns the scan state, persisted user settings, and three chained `NSArrayController` outlets:

- `allApps` — raw scan results (no filter)
- `archFilteredApps` — filtered by architecture predicate; content bound from `allApps`
- `arrayController` — displayed and sorted; content bound from `archFilteredApps`

Scanning runs on a `userInitiated` GCD queue. Results are dispatched to the main queue for `NSArrayController` insertion.

Persisted `UserDefaults` keys:
| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `appsFolderOnly` | Bool | `true` | Scan only `/Applications` |
| `recurseIntoApps` | Bool | `false` | Descend into `.app` subdirectories |
| `excludeAppleApps` | Bool | `false` | Skip `com.apple.*` bundles |
| `showIntel32` | Bool | `true` | Show Intel 32-bit apps in results |
| `showIntel64` | Bool | `true` | Show Intel 64-bit apps in results |
| `showPowerPC` | Bool | `true` | Show PowerPC apps in results |
| `showAppleARM` | Bool | `true` | Show Apple ARM apps in results |
| `sortOption` | Int | `0` | 0=Name↑ 1=Name↓ 2=Arch↑ 3=Arch↓ 4=Path↑ 5=Path↓ |
| `specialFolders` | [[String:String]] | `[]` | Extra folder entries with `path` and `mode` (`included` or `excluded`) |
| `scanAudioPlugins` | Bool | `false` | Adds the standard audio plugin folders as included special folders |
| `folderBlacklist` | [String] | `[]` | Legacy excluded paths; migrated to `specialFolders` and still honored for compatibility |

### Cocoa Bindings Pattern

All model properties exposed to the UI are marked `@objc dynamic`. The XIBs bind directly to properties through `NSArrayController` without explicit target/action wiring. Adding a new bindable property requires:

1. Mark the property `@objc public private(set) dynamic var` in the controller.
2. In Interface Builder, bind the UI control to `File's Owner` (the window controller) or to the relevant `NSArrayController`.

**`private(set)` gotcha:** Properties marked `@objc public private(set) dynamic` are read-only from other modules via KVC. Cocoa Bindings from an external class (e.g. `PreferencesWindowController` binding to `MainWindowController`) will silently fail to write. Use `@objc public dynamic var` (no `private(set)`) for any property that must be set via a binding from another class.

**Binding timing gotcha:** `PreferencesWindowController` is instantiated as a stored property of `ApplicationDelegate`, which means its `init` runs before `NSApp.delegate` is set. Any code in `PreferencesWindowController.init` that calls `NSApp.delegate as? ApplicationDelegate` will get `nil`. Use target/action (not bindings) for controls in `PreferencesWindowController` that need to call back to `MainWindowController`, resolving `NSApp.delegate` lazily at action time.

---

## Building

### Prerequisites
- Xcode 14.1 or later
- Git submodules initialized: `git submodule update --init --recursive`

### Build
Open `Silicon.xcodeproj` in Xcode and build the `Silicon` scheme, or use:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Silicon.xcodeproj -scheme Silicon -configuration Debug \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  OTHER_CFLAGS="-Wno-implicit-int-float-conversion -Wno-conversion" \
  build
```
The `OTHER_CFLAGS` override suppresses implicit-conversion warnings in the `GitHubUpdates` submodule, which uses strict xcconfig warning settings incompatible with newer Clang versions. Xcode IDE builds are unaffected — this is a command-line workaround only.

### Release
The Release build configuration auto-populates `CFBundleVersion` from `git rev-list --count HEAD` via a build phase shell script.

### CI
GitHub Actions runs `.github/workflows/ci.yaml` on push and pull requests to `main`. It builds both Debug and Release configurations on a `macos-latest` runner using the same `OTHER_CFLAGS` override required locally.

### Release
Pushing a tag matching `v*.*.*` triggers `.github/workflows/release.yaml`, which builds the Release configuration, zips `Silicon.app` with `ditto`, and publishes a GitHub Release with the archive attached. Release notes are written manually via `gh release edit`.

To cut a release:
```bash
git tag v1.x.y
git push origin v1.x.y
gh release create v1.x.y --title "Silicon v1.x.y" --notes "..."
```

---

## Conventions

### Formatting
The existing code uses a wide-brace style with aligned parentheses — maintain this style. No external formatter is enforced; match surrounding code exactly.

### Error Handling
- `MachOFile` and `App` use failable initializers (`init?`) rather than throwing, because failure is the normal case for non-app files encountered during directory enumeration.
- `BinaryStream` throws `Error` from its read methods; `MachOFile` catches and returns `nil`.

### Threading
All UI mutations (adding to `NSArrayController`, updating `appCount`) must happen on the main queue. Background work uses `DispatchQueue.global(qos: .userInitiated)`.

### UserDefaults Persistence
Each persisted property follows the pattern:
```swift
@objc public private(set) dynamic var myPref = UserDefaults.standard.bool(forKey: "myPref") {
    didSet { UserDefaults.standard.set(self.myPref, forKey: "myPref") }
}
```
For non-Bool types that may not have a stored value yet (like the initial `appsFolderOnly`), guard against `nil` using `.value(forKey:) == nil`.

### Adding a New Window
1. Create a new `NSWindowController` subclass in `Classes/`.
2. Create a matching `.xib` in `UI/Base.lproj/`.
3. Set the XIB's File's Owner class to your controller.
4. Override `windowNibName` to return the XIB name.
5. Instantiate and hold a reference in `ApplicationDelegate`.

---

## Features

### Architecture Filter Checkboxes (v1.1)
Six independent checkboxes in the bottom bar: Intel 32, Intel 64, PowerPC, Apple ARM, Universal, and Non-ARM. Each maps to an `NSPredicate` against `App.architectures`: single-arch types use `ANY architectures == %@`; Universal uses `architectures.@count > 1`; Non-ARM uses `NOT (ANY architectures BEGINSWITH "arm")`. Combined with `NSCompoundPredicate(orPredicateWithSubpredicates:)`. All checked or all unchecked shows everything (filter predicate set to `nil`).

### Sort Options (v1.1)
A "Sort By" popup in the bottom bar with six options: Name/Architecture/Path each ascending and descending. Selection drives `arrayController.sortDescriptors` via `updateSort()`. Persisted in `UserDefaults.sortOption`.

### Export (v1.1)
File > Export to CSV… / Export to HTML… exports the currently visible (filtered + sorted) app list from `arrayController.arrangedObjects`. Destination chosen via `NSSavePanel`. HTML is a self-contained document with inline styles; CSV includes header row with proper quoting.

### Special Folders / Audio Plugins (Unreleased)
Silicon > Preferences (⌘,) opens `PreferencesWindowController` -- a programmatic (no XIB) window with a Special Folders table. Each row stores a folder `path` and `mode` in `UserDefaults.specialFolders`; `included` rows add extra scan roots, while `excluded` rows prune matching directory trees during enumeration. The legacy `folderBlacklist` key is migrated into excluded Special Folders and remains honored by the scanner for compatibility.

The **Scan for Audio Plugins** checkbox persists `UserDefaults.scanAudioPlugins`. When enabled, it adds `/Library/Audio/Plug-Ins/` and `~/Library/Audio/Plug-Ins/` as included Special Folders. Those roots are scanned recursively as files instead of app bundles: every non-directory path is passed to `App(binaryPath:)`, and any parseable Mach-O binary is added to the application list.

### Homebrew Lookup (v1.1)
`HomebrewService` fetches `https://formulae.brew.sh/api/cask.json` and `https://formulae.brew.sh/api/formula.json` in parallel on a background queue using `URLSession` + `DispatchGroup`. Results are cached under `~/.Silicon/homebrew_cache/` with a 24-hour TTL. Lookup priority: bundle ID → app display name → formula name. Bundle IDs are extracted from `artifacts[].uninstall[].quit` in the cask JSON; app names from `artifacts[].app[]` which can be either plain strings or `{"target": "Name.app"}` dicts.

Persisted `UserDefaults` keys added in v1.1:
| Key | Type | Default | Meaning |
|-----|------|---------|---------|
| `showUniversal` | Bool | `true` | Show Universal (multi-arch) apps in results |
| `showNonARM` | Bool | `true` | Show non-ARM apps in results |
| `checkHomebrew` | Bool | `false` | Fetch and display Homebrew version data |

### Table Column Headers (v1.1.1)
The XIB's `NSScrollView` was built without a `headerView` clip view, so `NSTableView`'s header bar was never rendered. Fix: in `windowDidLoad`, assign `self.tableView.headerView = NSTableHeaderView()`. Per Apple's docs, setting `headerView` causes NSTableView to "reset its scroll view to accommodate the specified header view." The main column title ("Application") is set via `title` on the `tableHeaderCell` in the XIB. The Brew Formula / Brew Version columns get their titles from `addBrewColumns()`.

> **Note:** Do not attempt to add `<clipView key="headerView">` directly inside `<scrollView>` in the XIB — `ibtool` rejects it with error -1 because NSScrollView has no public `setHeaderView:` KVC setter.

### Welcome Screen Features List (v1.1.1)
`addFeaturesLabel()` in `windowDidLoad` programmatically adds a left-panel bullet list to the `DropView` (the welcome screen shown before scanning). The label is constrained to the leading edge of the DropView at 40pt margin, 280pt wide, centered vertically. Because `DropView` is hidden once scanning starts (bound to `self.started`), the label is automatically hidden during and after scans.

### Help Menu GitHub Link (v1.1.1)
The Help menu (`MainMenu.xib`) was previously `hidden="YES"`. It is now visible and contains a **GitHub Repository** menu item that sends `openGitHub:` through the responder chain. `ApplicationDelegate.openGitHub(_:)` opens `https://github.com/ByronScottJones/silicon` via `NSWorkspace.shared.open(_:)`.

## Known Limitations

- No sandbox entitlements — the app must be distributed outside the Mac App Store (or with a special exception) to freely enumerate all installed applications.
- Submodule `GitHubUpdates` must be checked out for the build to succeed.
- Normal app-bundle architecture detection is based solely on the primary executable; helper tools or frameworks within a bundle are not inspected unless they are direct Mach-O files found during audio plugin folder scanning.
- The `ppc64` CPU type is not explicitly handled and would fall through as `<unknown>`.
- There are no unit or integration tests.
- `allowedFileTypes` (deprecated in macOS 12) is used in export panels for 10.13 compatibility; migrate to `allowedContentTypes` when the deployment target is raised to 11+.
