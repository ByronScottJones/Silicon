# Engineering Guide — Silicon

## Overview

Silicon is a native macOS utility that identifies the binary architecture of installed applications. It scans `.app` bundles, parses their Mach-O executables, and classifies each one as Apple Silicon, Universal, Intel 64, Intel 32, PowerPC, or combinations thereof.

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
│   │   ├── App.swift             # Core model — represents one .app bundle
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
        → App(path:)
            → AppInfo(path:)             reads Info.plist
            → MachOFile(path:)           parses binary
        → allApps NSArrayController      [main queue]
            → archFilteredApps NSArrayController   (predicate filter)
                → arrayController NSArrayController (sorted, displayed)
                    → NSTableView
```

### Key Classes

#### `App` — Model (`App.swift`)
The central model object. Initialized with a `.app` bundle path; returns `nil` if the path is not a valid app or the binary cannot be parsed.

Key properties (all `@objc dynamic` for Cocoa Bindings):
- `name: String` — display name from `FileManager.displayName`
- `path: String` — absolute path to the `.app` bundle
- `architectures: [String]` — raw arch strings from the binary (`"arm64"`, `"x86_64"`, `"i386"`, `"ppc"`)
- `architecture: String` — human-readable label (`"Universal"`, `"Intel 64"`, etc.)
- `isAppleSiliconReady: Bool` — true if `architectures` contains `"arm64"`
- `bundleID: String?` — `CFBundleIdentifier`
- `version: String?` — `CFBundleShortVersionString`
- `icon: NSImage?` — app icon via `NSWorkspace`

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
| `folderBlacklist` | [String] | `[]` | Paths excluded from all scans |

### Cocoa Bindings Pattern

All model properties exposed to the UI are marked `@objc dynamic`. The XIBs bind directly to properties through `NSArrayController` without explicit target/action wiring. Adding a new bindable property requires:

1. Mark the property `@objc public private(set) dynamic var` in the controller.
2. In Interface Builder, bind the UI control to `File's Owner` (the window controller) or to the relevant `NSArrayController`.

---

## Building

### Prerequisites
- Xcode 14.1 or later
- Git submodules initialized: `git submodule update --init --recursive`

### Build
Open `Silicon.xcodeproj` in Xcode and build the `Silicon` scheme, or use:
```bash
xcodebuild -project Silicon.xcodeproj -scheme Silicon -configuration Debug build
```

### Release
The Release build configuration auto-populates `CFBundleVersion` from `git rev-list --count HEAD` via a build phase shell script.

### CI
GitHub Actions runs `ci-mac.yaml` on push/PR. It builds both Debug and Release configurations on a `macos-latest` runner.

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
Four independent checkboxes in the bottom bar — Intel 32, Intel 64, PowerPC, Apple ARM — replace the old single-selection filter popup. Each maps to a raw arch string (`i386`, `x86_64`, `ppc`, `arm64`) checked against `App.architectures` via `NSCompoundPredicate`. All checked or all unchecked shows everything.

### Sort Options (v1.1)
A "Sort By" popup in the bottom bar with six options: Name/Architecture/Path each ascending and descending. Selection drives `arrayController.sortDescriptors` via `updateSort()`. Persisted in `UserDefaults.sortOption`.

### Export (v1.1)
File > Export to CSV… / Export to HTML… exports the currently visible (filtered + sorted) app list from `arrayController.arrangedObjects`. Destination chosen via `NSSavePanel`. HTML is a self-contained document with inline styles; CSV includes header row with proper quoting.

### Folder Blacklist / Preferences (v1.1)
Silicon > Preferences (⌘,) opens `PreferencesWindowController` — a programmatic (no XIB) window with a table of excluded folder paths. Paths are stored as `[String]` in `UserDefaults` under `"folderBlacklist"`. During `findApps(in:)`, any path that has a blacklisted prefix causes `enumerator.skipDescendents()` so entire directory trees are skipped efficiently.

## Known Limitations

- No sandbox entitlements — the app must be distributed outside the Mac App Store (or with a special exception) to freely enumerate all installed applications.
- Submodule `GitHubUpdates` must be checked out for the build to succeed.
- Architecture detection is based solely on the primary executable; helper tools or frameworks within a bundle are not inspected.
- The `ppc64` CPU type is not explicitly handled and would fall through as `<unknown>`.
- There are no unit or integration tests.
- `allowedFileTypes` (deprecated in macOS 12) is used in export panels for 10.13 compatibility; migrate to `allowedContentTypes` when the deployment target is raised to 11+.
