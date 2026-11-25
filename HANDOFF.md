# Silicon Handoff

Outstanding work only. Finished work is recorded in [CHANGELOG.md](CHANGELOG.md)
and the specification is [ENGINEERING.md](ENGINEERING.md).

## 1. Status

- Last updated (UTC): 2026-11-25T15:40:00Z
- In flight: none on this branch (documentation only).
- Build: not passing with the current Xcode. The project's
  `MACOSX_DEPLOYMENT_TARGET = 11.0` is rejected (supported range starts at 12.0)
  and `allowedFileTypes` deprecation errors follow (H-1). Verified 2026-11-25.
- Tests: none exist (H-5).
- CI: not verified.

## 2. Resume here

Start with H-1, then H-2:

```bash
make submodules
xcodebuild -project Silicon.xcodeproj -scheme Silicon -configuration Release \
  CODE_SIGNING_ALLOWED=NO build
```

## 3. In progress

None.

## 4. Outstanding work

| ID | Item | Reason | Acceptance | Owner | Blocked by |
| --- | --- | --- | --- | --- | --- |
| H-1 | Raise the deployment target to a supported macOS and replace `allowedFileTypes` with `allowedContentTypes` | Build fails on current Xcode | Release build succeeds; REQ-PLAT-2 | Byron Scott Jones | none |
| H-2 | Move to Swift 6 language mode with warnings as errors for first-party code | `swift.md` standard | REQ-QA-1 | Byron Scott Jones | H-1 |
| H-3 | Validate the fat header architecture count in `MachOFile` | Hostile or Java class files cause long failing loops | REQ-SEC-3 | Byron Scott Jones | H-5 |
| H-4 | Replace `print` with `os.Logger` | `swift.md` standard | Section 8 updated | Byron Scott Jones | none |
| H-5 | Add a test target with Swift Testing for `MachOFile`, `App.describe`, and `HomebrewService` | No tests exist | REQ-QA-2; section 11 | Byron Scott Jones | H-1 |
| H-6 | Add formatter and linter configuration, `.swift-version`, and a CI test step | `swift.md` standard | `swift format lint --strict` passes in CI | Byron Scott Jones | H-2 |
| H-7 | Rework CI: single workflow, SHA-pinned actions, `permissions`, manual trigger gate, arm64 artifact check | `githubactions.md` standard | `validate-github-actions` reports clean | Byron Scott Jones | none |
| H-9 | Bring `README.md`, `BUILDING.md`, `SECURITY.md`, `AI_NOTICE.md`, and `CODE_OF_CONDUCT.md` to the Markdown lint rules and drop them from the ignore list in `.markdownlint-cli2.jsonc` | Inherited style does not pass | Lint passes with no ignores for these files | Byron Scott Jones | none |
| H-8 | Remove the stale `xcconfig` entry in `.gitmodules` and the dangling `GitHubUpdates` references | Duplicate and missing submodule | `git submodule status` clean | Byron Scott Jones | none |

## 5. Decisions needed

- Which Git identity is the maintainer's? History shows both `Byron Scott Jones`
  and `ByronJones-Elsevier`. Recommendation: record the second as an alias of the
  first only after the owner confirms it.

## 6. Known issues, risks, and unverified areas

- Behavior of scanning has no automated coverage; all verification is manual.
- The Release run script phase edits `Silicon/Info.plist` in place, which can
  dirty the working tree after a build.

## 7. Environment and access notes

- Xcode 27 era toolchain on macOS 27; the sandboxed agent shell cannot run
  `xcodebuild` and needs to run it unsandboxed.
- The owner pushes and merges. No credentials are recorded here.

## 8. Cleanup debt

- `build/` holds ignored local build output.
