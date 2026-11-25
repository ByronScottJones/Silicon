# Silicon Handoff

Outstanding work only. Finished work is recorded in [CHANGELOG.md](CHANGELOG.md)
and the specification is [ENGINEERING.md](ENGINEERING.md).

## 1. Status

- Last updated (UTC): 2026-11-25T15:40:00Z
- In flight: none on this branch (documentation only).
- Build: Debug and Release build with Xcode 27 and no first-party warnings
  (verified 2026-11-25). The built executable is `arm64` with
  `LSMinimumSystemVersion` 14.0.
- Tests: 25 Swift Testing cases in `SiliconTests` pass locally (verified
  2026-11-25). They run in the Debug CI job once CI has run.
- CI: the reworked workflows have not run on GitHub yet. First run: start `CI`
  from the Actions tab (`workflow_dispatch`) and confirm both jobs pass.

## 2. Resume here

Start with H-8, then H-9:

```bash
make submodules
make build
```

## 3. In progress

None.

## 4. Outstanding work

| ID | Item | Reason | Acceptance | Owner | Blocked by |
| --- | --- | --- | --- | --- | --- |
| H-8 | Remove the duplicate `xcconfig` entry (path `xcconfig`) in `.gitmodules`; the agent sandbox cannot write that file | Duplicate submodule entry | `git submodule status` clean | Byron Scott Jones | none |
| H-9 | Bring `README.md`, `BUILDING.md`, `SECURITY.md`, `AI_NOTICE.md`, and `CODE_OF_CONDUCT.md` to the Markdown lint rules and drop them from the ignore list in `.markdownlint-cli2.jsonc` | Inherited style does not pass | Lint passes with no ignores for these files | Byron Scott Jones | none |
| H-10 | Low priority. Replace `hdiutil create` in `Scripts/package_arch.sh` with `diskutil image create from` | `hdiutil create` is deprecated and prints a warning; a future macOS may remove it | DMG builds without the warning, keeps the UDZO format, volume name and Applications link, and mounts correctly | Byron Scott Jones | none |
| H-11 | Low priority. About dialog copyright on three lines: `Original Author`, `Byron Jones`, `All Rights Reserved`. Confirm the exact text first (for example whether line 1 names DigiDNA) | Single-line notice in `NSHumanReadableCopyright` is hard to read and does not separate the original author from the fork | About window shows the three lines; `LICENSE` and source headers are unchanged | Byron Scott Jones | none |
| H-12 | Low priority. Give the appCount in the main window footer a fixed minimum width of at least 4 digits | The footer shifts and flickers as the counter's width changes during a scan | Rest of the footer does not move while the count goes from 0 to 10,000; checked during a real scan | Byron Scott Jones | none |
| H-13 | Low priority. Redesign the initial startup (drop) screen in `DropView` and `MainWindowController.xib` | The current screen is not elegant and looks dated | Modern layout agreed with the owner; drag and drop and the Scan button still work | Byron Scott Jones | none |
| H-14 | Low priority. Show audio plugins as a separate section of the results list | Plugin binaries are mixed in with applications | Plugins are grouped together and visibly separate; filters, sorting and export still work, and ENGINEERING.md sections 4 and 5 describe the grouping | Byron Scott Jones | none |

## 5. Decisions needed

- Format the code base with `swift-format`? Deferred (decision D-4): the owner
  is investigating whether an automated tool can bring the code into
  compliance. Options: keep the upstream style, or reformat everything once and
  enforce `swift format lint --strict` in CI.
- Which Git identity is the maintainer's? History shows both `Byron Scott Jones`
  and `ByronJones-Elsevier`. Recommendation: record the second as an alias of the
  first only after the owner confirms it.

## 6. Known issues, risks, and unverified areas

- Scanning, filtering, export, and the UI have no automated coverage; only
  parsing, classification, Homebrew lookup, and the spec tables are tested.
- The Release run script phase edits `Silicon/Info.plist` in place, which can
  dirty the working tree after a build.

## 7. Environment and access notes

- Xcode 27 era toolchain on macOS 27; the sandboxed agent shell cannot run
  `xcodebuild` and needs to run it unsandboxed.
- The owner pushes and merges. No credentials are recorded here.

## 8. Cleanup debt

- `build/` holds ignored local build output.
