# Agents Guide — Silicon

This document describes how AI coding agents should understand and work within this codebase.

---

## What This App Does

Silicon scans macOS `.app` bundles, reads their Mach-O binaries, and reports each application's CPU architecture(s). It can also cross-reference Homebrew to show the latest available version for each installed app. The central questions it answers are: "Does this app run natively on Apple Silicon?" and "Is there a newer version available via Homebrew?"

---

## Tech Stack at a Glance

| Concern | Technology |
|---------|-----------|
| Language | Swift 5 |
| UI | AppKit, XIB files, Cocoa Bindings |
| Data binding | `@objc dynamic` + `NSArrayController` |
| Persistence | `UserDefaults` |
| Concurrency | GCD (`DispatchQueue`) |
| Networking | `URLSession` + `DispatchGroup` |
| Build | Xcode project only (no SPM) |
| Updates | `GitHubUpdates` submodule framework |
| CI | GitHub Actions (`.github/workflows/`) |

---

## Where to Find Things

| Task | Location |
|------|---------|
| App model / architecture classification | `Silicon/Classes/App.swift` |
| Mach-O binary parsing | `Silicon/Classes/MachOFile.swift` |
| Scan logic, filter state, sorting, brew columns | `Silicon/Classes/MainWindowController.swift` |
| Homebrew cask/formula fetch and lookup | `Silicon/Classes/HomebrewService.swift` |
| Main window UI layout | `Silicon/UI/Base.lproj/MainWindowController.xib` |
| App entry point | `Silicon/Classes/ApplicationDelegate.swift` |
| Preferences window (blacklist + Homebrew toggle) | `Silicon/Classes/PreferencesWindowController.swift` |
| Drag-and-drop support | `Silicon/Classes/DropView.swift` |
| Persisted settings keys | Properties in `MainWindowController.swift` with `UserDefaults` in `didSet` |
| CI workflow | `.github/workflows/ci.yaml` |
| Release workflow | `.github/workflows/release.yaml` |

---

## Architecture Classification Reference

Architecture strings stored in `App.architectures` (raw, from Mach-O):

| Raw string | Meaning |
|-----------|---------|
| `arm64` | Apple Silicon / ARM 64-bit |
| `arm` | 32-bit ARM (older iOS) |
| `x86_64` | Intel 64-bit |
| `i386` | Intel 32-bit |
| `ppc` | PowerPC |

The `App.architecture` property is a derived human-readable label: `"Apple"`, `"Universal"`, `"Intel 64"`, `"Intel 32"`, `"PowerPC"`, and compound variants like `"PowerPC/Intel 32/64"`.

`isAppleSiliconReady` is `true` when `architectures` contains `"arm64"`.

---

## The Three-Controller Data Pipeline

The UI displays results through a chain of three `NSArrayController` instances wired in IB:

```
allApps  →  archFilteredApps  →  arrayController  →  NSTableView
  (raw)       (arch predicate)    (sort descriptors)
```

When adding a new filter dimension, apply it as a `filterPredicate` on `archFilteredApps` (or chain a fourth controller if the filter is independent of architecture). Do not filter inside `findApps()` — keep scanning and display concerns separate.

---

## Scanning Architecture

`findApps()` runs on a background GCD queue (`userInitiated`). It uses `FileManager.enumerator` to walk directories. For each `.app` path found, it initializes an `App` object (which parses the binary synchronously on the background thread), then dispatches the result to the main queue to add it to `allApps`.

Key skip conditions already in place:
- Paths under `/Volumes` are skipped
- Non-`.app` paths are skipped
- If `recurseIntoApps` is false, `enumerator.skipDescendents()` is called after finding a `.app`
- `com.apple.*` bundles are optionally excluded at the main-queue insertion point
- Paths matching any entry in `folderBlacklist` cause `enumerator.skipDescendents()`

When adding new skip conditions, add them in the background-thread enumeration body, before the `App(path:)` initialization, to avoid wasting work.

---

## Homebrew Lookup

`HomebrewService.shared` fetches cask and formula JSON from Homebrew in parallel, caches them under `~/.Silicon/homebrew_cache/` for 24 hours, then exposes a single `lookup(bundleID:appName:) -> Entry?` method.

Lookup priority (highest to lowest confidence):
1. Bundle ID → cask (from `artifacts[].uninstall[].quit`)
2. App display name → cask (from `artifacts[].app[]`)
3. App display name → formula (from `name`)

After a scan completes, if `checkHomebrew` is enabled, `MainWindowController.runBrewLookup()` calls `HomebrewService.shared.load` then `applyBrewLookup()`, which writes `brewToken` and `brewVersion` onto each `App` and calls `tableView.reloadData()`.

**Important**: The `artifacts["app"]` array can contain plain strings (`"Firefox.app"`) or dicts (`{"target": "App.app"}`). Always cast to `[Any]` and check each element as both `String` and `[String: String]`.

---

## NSTableViewDelegate and Prototype Cells

The main NSTableView is **view-based** with a delegate set. When a delegate is present, `tableView(_:viewFor:row:)` must explicitly dequeue prototype cells via `makeView(withIdentifier:owner:)` — returning `nil` renders nothing (the prototype is not used automatically). The prototype cell's `identifier` in the XIB must match the column identifier exactly.

Dynamically-added columns (Brew Formula, Brew Version) create their cells programmatically in the delegate since they have no prototype in the XIB.

---

## Cocoa Bindings — Timing Gotcha

`PreferencesWindowController` is instantiated as a stored property of `ApplicationDelegate`, meaning it initializes before `NSApp.delegate` is set. Any code in `PreferencesWindowController.init()` that tries `NSApp.delegate as? ApplicationDelegate` will get `nil`. Use target/action for controls that need to call back to `MainWindowController`, getting `NSApp.delegate` lazily at action time.

---

## Adding a New Persistent Setting

1. Add a property to `MainWindowController` following the established pattern:
   ```swift
   @objc public private(set) dynamic var myNewSetting = UserDefaults.standard.bool(forKey: "myNewSetting") {
       didSet { UserDefaults.standard.set(self.myNewSetting, forKey: "myNewSetting") }
   }
   ```
2. For settings that need to be writable from an external class via Cocoa Bindings, omit `private(set)` — KVC treats `private(set)` as read-only from other modules.
3. For array/dictionary types, use `UserDefaults.standard.array(forKey:)` / `stringArray(forKey:)` and encode with `set(_:forKey:)`.

---

## Adding a New Window (e.g., Preferences)

1. Create `MyWindowController.swift` — subclass `NSWindowController`.
2. Create `MyWindowController.xib` in `UI/Base.lproj/`.
3. Set File's Owner to `MyWindowController` in Interface Builder.
4. Override `windowNibName` to return `"MyWindowController"`.
5. In `ApplicationDelegate.swift`, create an instance (`let myWindowController = MyWindowController()`) and hold it as a `let` property so it is not deallocated.
6. Wire the menu item to a method on the delegate that calls `myWindowController.showWindow(nil)`.

---

## NSPredicate Patterns for Architecture Filtering

`App.architectures` is `[String]` — an `NSArray` in the ObjC runtime. NSPredicate can query it with `ANY`:

```swift
// Single arch
NSPredicate(format: "ANY architectures == %@", "arm64")

// Multi-arch (Universal)
NSPredicate(format: "architectures.@count > 1")

// Non-ARM
NSPredicate(format: "NOT (ANY architectures BEGINSWITH %@)", "arm")

// Compound OR
let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
```

---

## Export Pattern

To export the current table contents:

```swift
// Get sorted, filtered results
let apps = self.arrayController.arrangedObjects as? [App] ?? []

// Use NSSavePanel to choose destination
let panel = NSSavePanel()
panel.allowedContentTypes = [.commaSeparatedText]
panel.beginSheetModal(for: self.window!) { response in
    guard response == .OK, let url = panel.url else { return }
    // write to url
}
```

When `checkHomebrew` is enabled, append `app.brewToken` and `app.brewVersion` columns to both CSV and HTML exports.

---

## Table Column Headers

The XIB's `NSScrollView` has no `headerView` clip view, so the column header bar must be installed programmatically. In `windowDidLoad`:

```swift
self.tableView.headerView = NSTableHeaderView()
```

Setting `headerView` on NSTableView causes it to "reset its scroll view to accommodate the specified header view" (Apple docs). The main column title is set via `title` on the `tableHeaderCell` in the XIB. Brew columns get titles from `addBrewColumns()`.

**Do not** try to add `<clipView key="headerView">` inside `<scrollView>` in the XIB — `ibtool` rejects it (error -1) because NSScrollView has no public KVC setter for `headerView`.

## Welcome Screen

`addFeaturesLabel()` in `windowDidLoad` adds a left-panel bullet list to the `DropView`. The `DropView` is bound to `self.started` (hidden once a scan begins), so the feature list disappears automatically when the table populates. The label sits at leading+40pt, width 280pt, centered vertically — well clear of the centered icon/button content.

## Help Menu

The Help menu in `MainMenu.xib` was previously `hidden="YES"`. It is now visible and contains a **GitHub Repository** item that sends `openGitHub:` through the responder chain to `ApplicationDelegate.openGitHub(_:)`, which opens the repo URL via `NSWorkspace.shared.open(_:)`.

## CI / Release

- **CI** (`.github/workflows/ci.yaml`): Builds Debug + Release on every push/PR to `main`. Uses `OTHER_CFLAGS="-Wno-implicit-int-float-conversion -Wno-conversion"` to suppress warnings from the `GitHubUpdates` submodule's xcconfig.
- **Release** (`.github/workflows/release.yaml`): Triggered by pushing a `v*.*.*` tag. Builds Release, zips `Silicon.app` with `ditto`, and publishes a GitHub Release with the archive. Release notes are written manually with `gh release create`.

To cut a release:
```bash
git tag v1.x.y
git push origin v1.x.y
gh release create v1.x.y --title "Silicon v1.x.y" --notes "..."
```

---

## Things to Avoid

- Do not mutate `NSArrayController` content from a background thread.
- Do not add filtering logic inside `findApps()` — keep it in `updateArchFilter()` via predicates.
- Do not use `NSWorkspace` APIs on a background thread; they are main-thread only.
- Do not call `UserDefaults.synchronize()` — it is deprecated and unnecessary.
- Do not add a `ppc64` CPU type without verifying the constant against Apple's `<mach/machine.h>` (it is `18 | 0x01000000`).
- This app has no sandbox entitlements intentionally — do not add sandbox entitlements without understanding the access implications for filesystem scanning.
- Do not cache `NSApp.delegate` at init time from a stored property initializer — it is nil until after the delegate object finishes initializing.
