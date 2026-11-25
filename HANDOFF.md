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
  2026-11-25). They are not yet run in CI (H-6, H-7).
- CI: not verified.

## 2. Resume here

Start with H-7 (CI), then H-6 (formatter and linter):

```bash
make submodules
make build
```

## 3. In progress

None.

## 4. Outstanding work

| ID | Item | Reason | Acceptance | Owner | Blocked by |
| --- | --- | --- | --- | --- | --- |
| H-4 | Add `os.Logger` output for scan and Homebrew failures | `swift.md` standard; failures are silent today | Section 8 updated | Byron Scott Jones | none |
| H-6 | Add formatter and linter configuration, `.swift-version`, and a CI test step | `swift.md` standard | `swift format lint --strict` passes in CI | Byron Scott Jones | H-7 |
| H-7 | Rework CI: single workflow, SHA-pinned actions, `permissions`, manual trigger gate, arm64 artifact check, test step | `githubactions.md` standard | `validate-github-actions` reports clean | Byron Scott Jones | none |
| H-8 | Remove the duplicate `xcconfig` entry (path `xcconfig`) in `.gitmodules`; the agent sandbox cannot write that file | Duplicate submodule entry | `git submodule status` clean | Byron Scott Jones | none |
| H-9 | Bring `README.md`, `BUILDING.md`, `SECURITY.md`, `AI_NOTICE.md`, and `CODE_OF_CONDUCT.md` to the Markdown lint rules and drop them from the ignore list in `.markdownlint-cli2.jsonc` | Inherited style does not pass | Lint passes with no ignores for these files | Byron Scott Jones | none |

## 5. Decisions needed

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
