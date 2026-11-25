# Silicon Engineering Specification

- Status: active; reviewed against the code on this branch
- Last reviewed (UTC): 2026-11-25T15:30:00Z
- Base branch: `main`

This is the primary specification for Silicon. It describes the system as it is
now. History is in [CHANGELOG.md](CHANGELOG.md), unfinished work is in
[HANDOFF.md](HANDOFF.md), and agent routing is in [AGENTS.md](AGENTS.md).
Where this file and the code disagree, that is a defect to be resolved in the
same change set.

## 1. Overview

**Purpose.** Silicon is a native macOS utility that answers two questions: "Does
this application run natively on Apple Silicon?" and "Is there a newer version
available through Homebrew?" It scans `.app` bundles, parses their main Mach-O
executable, and classifies each as Apple Silicon, Universal, Intel 64, Intel 32,
PowerPC, or a combination. Optionally it scans the standard audio plugin
folders for standalone Mach-O binaries and cross-references Homebrew.

**Scope.** Scanning, classification, filtering, sorting, drag-and-drop of a
single bundle, CSV and HTML export, Special Folders preferences, Homebrew
lookup, and an About window.

**Non-goals.**

- Inspecting helper tools or frameworks inside a bundle.
- Running on Intel Macs (see REQ-PLAT-1).
- Mac App Store distribution (the app is not sandboxed, see REQ-SEC-1).
- Modifying or removing any scanned application.

**Audience.** Mac users who audit installed software, and the contributors and
agents who maintain this fork of DigiDNA's Silicon.

**Provenance.** Forked from DigiDNA's Silicon (MIT). Fork enhancements are by
Byron Scott Jones (GitHub: `ByronScottJones`).

## 2. Requirements

Requirements use RFC 2119 words. IDs are stable.

### Platform and build

- REQ-PLAT-1: The application MUST be built for `arm64` only. `ARCHS` MUST be
  `arm64` in every configuration and no Intel slice may be produced. Rationale:
  the app targets Apple Silicon Macs; Intel support only added build matrix cost.
- REQ-PLAT-2: The deployment target is recorded in section 9. The built bundle's
  `LSMinimumSystemVersion` MUST equal `MACOSX_DEPLOYMENT_TARGET`.
- REQ-PLAT-3: The application MUST classify binaries of every architecture in
  REQ-DATA-2 even though it runs only on `arm64`.

### Scanning

- REQ-SCAN-1: A scan MUST run off the main actor in a cancellable task, and
  cancelling it MUST stop the file system walk promptly.
- REQ-SCAN-2: Paths under `/Volumes` MUST be skipped.
- REQ-SCAN-3: Only directories whose name ends in `.app` MUST be treated as
  application bundles during a normal scan.
- REQ-SCAN-4: When `recurseIntoApps` is `false`, descendants of a found bundle
  MUST NOT be enumerated.
- REQ-SCAN-5: When `excludeAppleApps` is `true`, bundles whose bundle identifier
  begins with `com.apple.` MUST be omitted from results.
- REQ-SCAN-6: Paths inside an `excluded` Special Folder MUST be pruned from
  enumeration. Legacy `folderBlacklist` entries MUST be honored the same way.
- REQ-SCAN-7: `included` Special Folders MUST be scanned after the normal scan
  roots.
- REQ-SCAN-8: Audio plugin roots MUST be scanned as raw file trees: every
  non-directory file is parsed as a Mach-O, and parseable files are reported.
- REQ-SCAN-9: When `appsFolderOnly` is `true`, the scan roots are the paths
  returned by `NSSearchPathForDirectoriesInDomains(.applicationDirectory,
  .allDomainsMask, true)`; otherwise the single root is `/`.

### Classification

- REQ-CLASS-1: A bundle's architecture MUST be determined only from the
  executable named by `CFBundleExecutable`.
- REQ-CLASS-2: The label rules in section 5.2 MUST be applied exactly.
- REQ-CLASS-3: `isAppleSiliconReady` MUST be `true` exactly when the raw
  architectures contain `arm64`.

### Presentation

- REQ-UI-1: Results MUST be shown in one table that supports the six sort
  options in section 4.
- REQ-UI-2: The six filter checkboxes MUST filter results as defined in 5.3.
- REQ-UI-3: Export MUST write the currently visible, filtered, sorted rows.
- REQ-UI-4: UI state MUST be mutated on the main actor only.
- REQ-UI-5: The "Applications Found" counter in the footer MUST have a minimum
  width of 48 points (room for five digits in the 13 point system font, with
  the text field's padding), so the controls to its right do not move while the
  count rises. It MAY grow beyond that for six or more digits.

### Homebrew

- REQ-BREW-1: Homebrew lookup MUST be off by default and MUST run only when
  `checkHomebrew` is `true`.
- REQ-BREW-2: Cask and formula JSON MUST be fetched in parallel and cached for
  24 hours.
- REQ-BREW-3: Lookup MUST follow the priority order in 5.5.

### Security and privacy

- REQ-SEC-1: The app MUST NOT enable the App Sandbox, because enumerating all
  installed applications requires unrestricted read access. The hardened runtime
  MUST stay enabled.
- REQ-SEC-2: The app MUST NOT transmit any information about the user, the
  scanned applications, or the machine. The only network requests are the two
  Homebrew JSON downloads (REQ-BREW-2) and are anonymous `GET`s.
- REQ-SEC-3: Parsing MUST treat every scanned file as untrusted input and MUST
  fail by returning no result, never by crashing.

### Quality

- REQ-QA-1: First-party code MUST compile in Swift 6 language mode without
  warnings; warnings are errors in every configuration.
- REQ-QA-2: Parsing and classification MUST be covered by automated tests (see
  section 11).

## 3. External interfaces

Silicon is a GUI application. It has no command-line arguments beyond those of
the macOS launch services, so `cli.md` does not apply.

- **Window.** One main window: a drop area with a Scan button before a scan; a
  results table and bottom bar after.
- **Menus.** Silicon (About Silicon, Preferences with Command-comma, Hide, Quit),
  File (New, Open, Refresh, Export to CSV, Export to HTML, Close), Edit, Help
  (GitHub Repository). Inherited document-style items such as Save are present
  in the XIB but unused.
- **Preferences.** A window with a Special Folders table and the audio plugin
  and Homebrew toggles.
- **Persistence.** `UserDefaults` keys:

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `appsFolderOnly` | Bool | `true` | Scan only the application folders |
| `recurseIntoApps` | Bool | `false` | Descend into found bundles |
| `excludeAppleApps` | Bool | `false` | Skip `com.apple.*` bundles |
| `showIntel32` | Bool | `true` | Filter checkbox: Intel 32 |
| `showIntel64` | Bool | `true` | Filter checkbox: Intel 64 |
| `showPowerPC` | Bool | `true` | Filter checkbox: PowerPC |
| `showAppleARM` | Bool | `true` | Filter checkbox: Apple ARM |
| `showUniversal` | Bool | `true` | Filter checkbox: Universal |
| `showNonARM` | Bool | `true` | Filter checkbox: Non-ARM |
| `sortOption` | Int | `0` | 0 Name asc, 1 Name desc, 2 Arch asc, 3 Arch desc, 4 Path asc, 5 Path desc |
| `specialFolders` | array of dictionaries | `[]` | Entries with `path` and `mode` (`included` or `excluded`) |
| `scanAudioPlugins` | Bool | `false` | Adds the audio plugin folders as included Special Folders |
| `folderBlacklist` | array of String | `[]` | Legacy excluded paths, migrated into `specialFolders` |
| `checkHomebrew` | Bool | `false` | Fetch and show Homebrew data |

- **Network.** `GET https://formulae.brew.sh/api/cask.json` and
  `GET https://formulae.brew.sh/api/formula.json`, only when `checkHomebrew` is
  `true`.
- **Files written.** `~/.Silicon/homebrew_cache/` (cache), and files the user
  chooses through the export save panel.
- **Audio plugin folders.** `/Library/Audio/Plug-Ins/` and
  `~/Library/Audio/Plug-Ins/`.

## 4. Data

### Mach-O input

`MachOFile` reads the file header and recognizes these magic numbers:

| Value read | Format |
| --- | --- |
| `0xCAFEBABE` | Fat (universal) binary, big-endian header |
| `0xCEFAEDFE` | 32-bit Mach-O, little-endian |
| `0xFEEDFACE` | 32-bit Mach-O, big-endian |
| `0xCFFAEDFE` | 64-bit Mach-O, little-endian |
| `0xFEEDFACF` | 64-bit Mach-O, big-endian |

Known quirks: Java class files share the `0xCAFEBABE` magic with fat binaries.
A fat header whose architecture count is 0 or 20 or more MUST be rejected (the
same cut-off as `file(1)`), so a Java class file, whose count field is its
version number, is not reported as a binary. A count that passes but exceeds
the file's real entries ends in a failed bounds-checked read and no result.

CPU types map to raw architecture strings:

| CPU type | String |
| --- | --- |
| `7` | `i386` |
| `0x01000007` | `x86_64` |
| `12` | `arm` |
| `0x0100000C` | `arm64` |
| `18` | `ppc` |

Any other CPU type contributes the string `<unknown>`. A `ppc64` type
(`18 | 0x01000000`) is not handled and is therefore reported as `<unknown>`,
which yields the `Unknown` label.

### Result model

`App` carries: `name`, `path`, `version`, `icon`, `architectures`,
`isAppleSiliconReady`, `architecture` (label), `bundleID`, `brewToken`,
`brewVersion`. `bundleID`, `version`, and `icon` are `nil` for audio plugin
binaries.

### Export formats

- **CSV.** Header row, then one row per visible app. Fields are quoted when they
  contain a comma, quote, or newline; quotes are doubled. When `checkHomebrew`
  is `true`, `Brew Formula` and `Brew Version` columns are appended.
- **HTML.** A self-contained document with inline styles and one table row per
  visible app, with the same optional Homebrew columns.

### Homebrew cache

Two JSON files under `~/.Silicon/homebrew_cache/`, reused while younger than 24
hours.

## 5. Behavior and algorithms

### 5.1 Scan

1. Build the root list per REQ-SCAN-9, then append `included` Special Folders.
2. Enumerate each root with `FileManager.enumerator`, skipping `/Volumes` and
   `excluded` folders (pruning descendants).
3. For each `.app`, construct `App(path:)`. Failure returns `nil` and the
   entry is dropped silently. This is the normal case for non-app directories.
4. If `recurseIntoApps` is `false`, prune the bundle's descendants.
5. Audio plugin roots: every non-directory file goes to `App(binaryPath:)`.
6. Insert each result into the results controller on the main actor, omitting
   Apple bundles when `excludeAppleApps` is `true`.
7. When the scan finishes and `checkHomebrew` is `true`, run the Homebrew lookup
   over all results and refresh the table.

### 5.2 Architecture label

Input is the raw architecture list and an `isIOS` flag (true when the bundle
is an iOS app running on macOS). Apply the first matching rule:

1. Exactly one architecture:
   - `arm64` gives `Apple`, or `Apple (iOS)` when `isIOS`; ready is `true`.
   - `x86_64` gives `Intel 64`.
   - `i386` gives `Intel 32`.
   - `ppc` gives `PowerPC`.
   - anything else gives `Unknown`.
2. More than one architecture and it contains `arm64`: `Universal`, or
   `Universal (iOS)` when `isIOS`; ready is `true`.
3. Contains `ppc`, `i386`, `x86_64`: `PowerPC/Intel 32/64`.
4. Contains `ppc`, `x86_64`: `PowerPC/Intel 64`.
5. Contains `ppc`, `i386`: `PowerPC/Intel 32`.
6. Contains `i386`, `x86_64`: `Intel 32/64`.
7. Otherwise: `Unknown`.

Worked example: raw `["x86_64", "arm64"]` gives label `Universal`, ready `true`.
Raw `["i386", "x86_64"]` gives `Intel 32/64`, ready `false`.

### 5.3 Filtering

Six checkboxes map to predicates over `App.architectures`:

| Checkbox | Predicate |
| --- | --- |
| Intel 32 | `ANY architectures == "i386"` |
| Intel 64 | `ANY architectures == "x86_64"` |
| PowerPC | `ANY architectures == "ppc"` |
| Apple ARM | `ANY architectures == "arm64"` |
| Universal | `architectures.@count > 1` |
| Non-ARM | `NOT (ANY architectures BEGINSWITH "arm")` |

Checked predicates are combined with OR. When all six or none are checked, the
filter is removed and everything is shown.

### 5.4 Sorting

`sortOption` selects one sort descriptor on the displayed controller:
name, architecture label, or path, ascending or descending, using a
case-insensitive localized comparison.

### 5.5 Homebrew lookup

Given a bundle identifier and app display name, return the first match:

1. Bundle ID matched to a cask through `artifacts[].uninstall[].quit`.
2. Display name matched to a cask through `artifacts[].app[]`.
3. Display name matched to a formula `name`.

`artifacts[].app[]` entries are either a plain string (`"Firefox.app"`) or a
dictionary (`{"target": "App.app"}`); both MUST be handled.

## 6. Architecture

### Modules and data flow

```text
FileManager.enumerator
    -> AppScanner.apps() (detached task, AsyncStream)
        -> App(path:)       -> AppInfo -> MachOFile -> BinaryStream
        -> App(binaryPath:) -> MachOFile -> BinaryStream
    -> allApps (NSArrayController, main actor)
        -> archFilteredApps (predicate)
            -> arrayController (sort) -> NSTableView
```

The UI uses AppKit with XIBs and Cocoa Bindings. Model properties exposed to the
UI are `@objc dynamic`. A property that another class writes through a binding
MUST NOT be `private(set)`, because KVC treats it as read-only.
`PreferencesWindowController` is created before `NSApp.delegate` is set, so it
MUST resolve the delegate lazily at action time.

### File map

| File | Purpose |
| --- | --- |
| `Silicon/Classes/App.swift` | Result model and label rules |
| `Silicon/Classes/AppInfo.swift` | Reads `Info.plist`, resolves the executable |
| `Silicon/Classes/MachOFile.swift` | Mach-O and fat header parser |
| `Silicon/Classes/BinaryStream.swift` | Bounds-checked byte reader |
| `Silicon/Classes/MainWindowController.swift` | Scan, filter, sort, export, settings |
| `Silicon/Classes/PreferencesWindowController.swift` | Programmatic Preferences window |
| `Silicon/Classes/HomebrewService.swift` | Homebrew download, cache, lookup |
| `Silicon/Classes/ApplicationDelegate.swift` | App entry, menus, About, GitHub link |
| `Silicon/Classes/AboutWindowController.swift` | About window |
| `Silicon/Classes/DropView.swift` | Drag and drop target and welcome view |
| `Silicon/Classes/NumberToString.swift` | Value transformer, number to string |
| `Silicon/Classes/IsZero.swift` | Value transformer, number equals zero |
| `Silicon/Classes/IsNotZero.swift` | Value transformer, number not zero |
| `Silicon/UI/Base.lproj/*.xib` | Main window, About window, main menu |
| `Silicon/UI/*.lproj/*.strings` | Simplified and Traditional Chinese strings |
| `Silicon/Info.plist` | Bundle metadata and copyright |
| `Silicon/Silicon.entitlements` | Entitlements (no sandbox) |
| `Silicon.xcodeproj` | Project; `ARCHS = arm64` |
| `Submodules/xcconfig` | Shared build settings |
| `Makefile`, `Scripts/package_arch.sh` | Build and DMG packaging |
| `.github/workflows/*.yaml` | CI and release |

## 7. Security and privacy model

- **Trust boundary.** Everything on disk that is scanned is untrusted. The parser
  reads bytes only and never executes or loads scanned code.
- **Untrusted inputs.** Mach-O headers, `Info.plist` contents, and the Homebrew
  JSON. Each MUST be validated before use, and malformed input yields no result.
- **Permissions.** No sandbox (REQ-SEC-1); the hardened runtime is enabled.
  Reading protected locations may require the user to grant Full Disk Access.
- **Privacy.** No telemetry and no analytics (REQ-SEC-2).
- **Threats and mitigations.** A crafted binary could cause out-of-range reads;
  `BinaryStream` is bounds-checked and throws. A malicious Homebrew response is
  only parsed as JSON and never executed.

## 8. Error handling and logging

- `MachOFile` and `App` use failable initializers because non-app files are the
  normal case during enumeration.
- `BinaryStream` throws on out-of-range reads; `MachOFile` catches and returns
  `nil`.
- Homebrew fetch failures are returned to the caller as an `Error` through the
  completion handler; they do not stop or fail a scan.
- The app has no exit-code contract. `HomebrewService` logs failures with
  `os.Logger` (subsystem is the bundle identifier, category `homebrew`): failed
  loads, non-200 responses, and unparseable JSON. Error text is marked public;
  no user data or paths are logged. Scanning logs nothing because skipped files
  are the normal case.

## 9. Technology and dependencies

| Item | Value | Reason |
| --- | --- | --- |
| Language | Swift 6 language mode | `swift.md` standard; complete concurrency checking |
| UI | AppKit, XIB, Cocoa Bindings | Existing code base |
| Architectures | `arm64` | REQ-PLAT-1 |
| Deployment target | macOS 14.0 | Supported by current Xcode; macOS Sonoma and later |
| Bundle ID | `com.DigiDNA.Silicon` | Inherited from upstream |
| `Submodules/xcconfig` | Pinned by the submodule commit | Shared warnings and build settings |
| Build tool | Xcode and `xcodebuild` | No Swift Package Manager |

This fork has no in-app updater and no third-party runtime dependencies.

## 10. Build, run, test, and release

```bash
make submodules           # fetch the xcconfig submodule
make build                # Release build, arm64
make dmg-arm              # build/dist/Silicon-<version>-arm64.dmg
make dist                 # same as dmg-arm
make clean                # remove build output
```

- `SIGNING=unsigned` (default), `adhoc`, or `automatic`.
- Release builds write `CFBundleVersion` from the git commit count through a run
  script phase.
- CI: `.github/workflows/ci.yaml` builds Debug and Release on `macos-latest`,
  asserts `lipo -archs` prints exactly `arm64`, and runs the tests (Debug). It
  runs only through `workflow_dispatch` unless the repository variable
  `AUTO_CI` is `true`, which also enables the `push` and `pull_request`
  triggers on `main`.
- Third-party actions are pinned to full commit SHAs and updated by Dependabot
  (`.github/dependabot.yml`). Workflow permissions default to `contents: read`.
- Release: pushing a `v*.*.*` tag, or starting `.github/workflows/release.yaml`
  by hand with the `tag` input naming an existing tag, validates the tag name
  (`vMAJOR.MINOR.PATCH`), checks out that tag, builds, asserts the arm64-only
  executable, zips the app as `Silicon-<tag>-arm64.zip`, and publishes a GitHub
  Release (the only job with `contents: write`).

## 11. Verification plan

| Requirement | Verification |
| --- | --- |
| REQ-PLAT-1 | `xcodebuild -showBuildSettings` reports `ARCHS = arm64`; `lipo -archs` on the built executable prints `arm64` |
| REQ-PLAT-2 | Compare `LSMinimumSystemVersion` in the built `Info.plist` with the target |
| REQ-CLASS-2, REQ-CLASS-3 | `ClassificationTests` over every row in 5.2 |
| REQ-SEC-3 | `MachOFileTests`: truncated, oversized, zero, and Java-class headers |
| REQ-SCAN-* | Manual scan of a prepared folder tree; see HANDOFF |
| REQ-BREW-3 | `HomebrewServiceTests` with fixture JSON |

`SpecificationTests` fail when the CPU table, magic numbers, or label names in
this file drift from the code. Run all tests with:

```bash
xcodebuild -project Silicon.xcodeproj -scheme Silicon -configuration Debug \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES \
  CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= test
```

Results of running this plan are recorded in [CHANGELOG.md](CHANGELOG.md).

## 12. Decisions

### D-1: Arm64 only (accepted)

- Context: upstream built for Intel and Apple Silicon.
- Choice: build `arm64` only; keep classifying every architecture.
- Rationale: the fork targets Apple Silicon; fewer artifacts to test and ship.
- Rejected: universal binary; separate Intel and arm64 builds.
- Consequences: the app does not launch on Intel Macs.

### D-2: Unsandboxed distribution (accepted, inherited)

- Context: the app enumerates every installed application.
- Choice: no App Sandbox; distribute outside the Mac App Store.
- Consequences: not notarized by default; users may need to approve it.

### D-3: Keep Cocoa Bindings and XIBs (accepted)

- Context: the UI is built on bindings and array controllers.
- Choice: keep AppKit with XIBs rather than rewrite in SwiftUI.
- Consequences: concurrency and testing changes must preserve the KVC rules in
  section 6.

### D-4: Swift formatting deferred (deferred)

- Context: `swift.md` names `swift-format` as the default, but the code base
  uses the upstream author's style (opening brace on its own line, spaces inside
  parentheses, aligned assignments). `swift format lint` with default rules
  reports 3,923 findings on `Silicon/Classes`, and its options cannot express
  that brace style.
- Choice: defer formatter work. For now keep the existing style and do not
  enforce a formatter; new code matches the surrounding code. The owner is
  investigating whether an automated tool can bring the code into compliance.
  The project's own convention outranks the default, as `coding.md` allows.
- Rationale: reformatting every file would bury the real history of the fork in
  one change and make upstream merges harder.
- Rejected: adopting `swift-format` defaults and reformatting; a custom
  `.swift-format` that disables most rules (it would enforce almost nothing).
- Consequences: style is a review concern until the owner decides (HANDOFF
  section 5).
