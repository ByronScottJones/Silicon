# Silicon Handoff

Outstanding work only. Finished work is recorded in [CHANGELOG.md](CHANGELOG.md)
and the specification is [ENGINEERING.md](ENGINEERING.md).

## 1. Status

- Last updated (UTC): 2026-11-25T18:31:11Z
- In flight: none. All feature branches are merged; this handoff update is the
  only open branch (`docs/handoff-update`).
- Build: Debug and Release build with Xcode 27 and no first-party warnings
  (verified 2026-11-25). The built executable is `arm64` with
  `LSMinimumSystemVersion` 14.0.
- Tests: 25 Swift Testing cases in `SiliconTests` pass locally (verified
  2026-11-25). They run in the Debug CI job once CI has run.
- CI: manual only. The reworked workflows have never run on GitHub; start `CI`
  from the Actions tab (`workflow_dispatch`) and confirm both jobs pass. If one
  fails, fix it before anything else.
- Manual checks done by the owner: footer counter width during a scan
  (2026-11-25). Not yet done: scan cancel, CSV and HTML export, Homebrew
  refresh, audio plugin scan.

## 2. Resume here

1. Run `CI` once from the Actions tab and confirm it passes (see Status).
2. Run the unchecked manual checks listed in Status on a Release build.
3. Then take H-9, followed by the low-priority items H-10, H-11, H-13, H-14.

```bash
make submodules    # not yet run since the .gitmodules cleanup
make build
```

## 3. In progress

None.

## 4. Outstanding work

| ID | Item | Reason | Acceptance | Owner | Blocked by |
| --- | --- | --- | --- | --- | --- |
| H-9 | Bring `README.md`, `BUILDING.md`, `SECURITY.md`, `AI_NOTICE.md`, and `CODE_OF_CONDUCT.md` to the Markdown lint rules and drop them from the ignore list in `.markdownlint-cli2.jsonc` | Inherited style does not pass | Lint passes with no ignores for these files | Byron Scott Jones | none |
| H-10 | Low priority. Replace `hdiutil create` in `Scripts/package_arch.sh` with `diskutil image create from` | `hdiutil create` is deprecated and prints a warning; a future macOS may remove it | DMG builds without the warning, keeps the UDZO format, volume name and Applications link, and mounts correctly | Byron Scott Jones | none |
| H-11 | Low priority. Split the About dialog copyright onto three lines, keeping the existing text: `Copyright © 2020 DigiDNA.`, `Enhancements Copyright © 2026 - Byron Scott Jones.`, `All rights reserved.` | The single-line notice in `NSHumanReadableCopyright` is hard to read | About window shows exactly those three lines with the current wording; `LICENSE` and source headers are unchanged; the label is tall enough that no line is clipped | Byron Scott Jones | none |
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
- The owner merges pull requests. The agent pushes branches and opens pull
  requests through the GitHub REST API (`ghx --owner ByronScottJones api -X POST
  repos/ByronScottJones/silicon/pulls --input <file>`), because `ghx pr create`
  (GraphQL) is refused even though the token has pull request write access.
  Cause not investigated. The fine-grained token expires 2027-10-04.
- The agent sandbox cannot write `.gitmodules`; the owner edits it.
- Before pushing a rebased branch use `git push --force-with-lease`.
- No credentials are recorded here.

## 8. Cleanup debt

- `build/` holds ignored local build output.
- `Silicon/Info.plist` has an uncommitted local change (`CFBundleVersion`
  rewritten by a Release build). Do not commit it; discard it with the owner's
  agreement.
- Merged branches still on the remote and safe to delete: `chore/format-and-logging`,
  `docs/project-standards`, `fix/footer-counter-width`.
