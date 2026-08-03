# Agents Guide — Silicon

This document describes how AI coding agents should understand and work within this codebase.

---

## What This App Does

Silicon scans macOS `.app` bundles, reads their Mach-O binaries, and reports each application's CPU architecture(s). The central question it answers is: "Does this app run natively on Apple Silicon, or does it require Rosetta 2 emulation?"

---

## Tech Stack at a Glance

| Concern | Technology |
|---------|-----------|
| Language | Swift 5 |
| UI | AppKit, XIB files, Cocoa Bindings |
| Data binding | `@objc dynamic` + `NSArrayController` |
| Persistence | `UserDefaults` |
| Concurrency | GCD (`DispatchQueue`) |
| Build | Xcode project only (no SPM) |
| Updates | `GitHubUpdates` submodule framework |

---

## Where to Find Things

| Task | Location |
|------|---------|
| App model / architecture classification | `Silicon/Classes/App.swift` |
| Mach-O binary parsing | `Silicon/Classes/MachOFile.swift` |
| Scan logic, filter state, sorting | `Silicon/Classes/MainWindowController.swift` |
| Main window UI layout | `Silicon/UI/Base.lproj/MainWindowController.xib` |
| App entry point | `Silicon/Classes/ApplicationDelegate.swift` |
| Drag-and-drop support | `Silicon/Classes/DropView.swift` |
| Persisted settings keys | Properties in `MainWindowController.swift` with `UserDefaults` in `didSet` |

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

When adding new skip conditions (e.g., folder blacklists), add them in the background-thread enumeration body, before the `App(path:)` initialization, to avoid wasting work.

---

## Adding a New Persistent Setting

1. Add a property to `MainWindowController` following the established pattern:
   ```swift
   @objc public private(set) dynamic var myNewSetting = UserDefaults.standard.bool(forKey: "myNewSetting") {
       didSet { UserDefaults.standard.set(self.myNewSetting, forKey: "myNewSetting") }
   }
   ```
2. For array/dictionary types, use `UserDefaults.standard.array(forKey:)` / `stringArray(forKey:)` and encode with `set(_:forKey:)`.
3. Bind the corresponding UI control to `File's Owner` in Interface Builder using the property name.

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
NSPredicate(format: "ANY architectures == 'arm64'")

// Multiple arches (OR)
NSPredicate(format: "ANY architectures == 'arm64' OR ANY architectures == 'x86_64'")

// Compound with NSCompoundPredicate
let subpredicates = checkedArchs.map {
    NSPredicate(format: "ANY architectures == %@", $0)
}
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

---

## Things to Avoid

- Do not mutate `NSArrayController` content from a background thread.
- Do not add filtering logic inside `findApps()` — keep it in `updateArchFilter()` via predicates.
- Do not use `NSWorkspace` APIs on a background thread; they are main-thread only.
- Do not call `UserDefaults.synchronize()` — it is deprecated and unnecessary.
- Do not add a `ppc64` CPU type without verifying the constant against Apple's `<mach/machine.h>` (it is `18 | 0x01000000`).
- This app has no sandbox entitlements intentionally — do not add sandbox entitlements without understanding the access implications for filesystem scanning.
