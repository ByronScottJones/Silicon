# Silicon Changelog

Every unit of work, newest first. Branch merge facts (pull request, merge time,
commit ids) are deliberately not recorded here; read them from git. See
[ENGINEERING.md](ENGINEERING.md) and [HANDOFF.md](HANDOFF.md).

## Entries

---

### chore/format-and-logging: os.Logger for Homebrew and formatter decision

- Branch: `chore/format-and-logging`, base `ci/rework-workflows`
- Worked on by: Byron Scott Jones (owner); Claude Sonnet 5.5 (Claude Code, author)
- What it did:
  - `HomebrewService` logs load failures, non-200 responses, and unparseable JSON
    through `os.Logger`.
  - Recorded decision D-4: formatter work deferred; the existing code style is
    kept and `swift-format` is not enforced.
  - Logged low-priority future work in HANDOFF (H-10 to H-14): `diskutil` DMG
    packaging, About copyright lines, footer counter width, startup screen
    redesign, and a separate audio plugin section.
- Spec and docs: section 8, decision D-4, HANDOFF section 5.
- Verification: 25 tests pass. The log calls themselves were not exercised.
- Notes: `swift format lint` with default rules reported 3,923 findings on
  `Silicon/Classes`, measured 2026-11-25; no `.swift-version` was added because
  CI selects the toolchain through the installed Xcode.

---

### ci/rework-workflows: single gated CI workflow with pinned actions

- Branch: `ci/rework-workflows`, base `test/unit-tests`
- Worked on by: Byron Scott Jones (owner); Claude Sonnet 5.5 (Claude Code, author)
- What it did:
  - Removed `ci-mac.yaml`, which duplicated `ci.yaml` and used `checkout@v1`.
  - Gated `ci.yaml` behind `workflow_dispatch` or `vars.AUTO_CI == 'true'`, added
    `contents: read` permissions, concurrency, timeouts, shallow checkout, a
    `lipo` arm64 assertion, and a test step.
  - Pinned `actions/checkout` (v7.0.1) and `softprops/action-gh-release` (v3.0.4)
    to commit SHAs, resolved from the GitHub API on 2026-11-25.
  - Release workflow asserts arm64, names the archive `-arm64.zip`, and can also
    be started manually with a `tag` input naming an existing `vX.Y.Z` tag
    (validated, then checked out).
  - Added Dependabot for GitHub Actions.
- Spec and docs: section 10, AGENTS CI section.
- Verification: workflow YAML parses; the SHAs were read from GitHub. The
  workflows have not run on GitHub, and `actionlint` was not available.
- Notes: the release workflow keeps its tag trigger ungated because pushing a
  tag is already a deliberate action.

---

### test/unit-tests: Swift Testing target and fat-header validation

- Branch: `test/unit-tests`, base `chore/modernize-toolchain`
- Worked on by: Byron Scott Jones (owner); Claude Sonnet 5.5 (Claude Code, author)
- What it did:
  - Added the `SiliconTests` unit-test target and a shared `Silicon` scheme whose
    test action runs it. The target compiles `MachOFile`, `BinaryStream`, `App`,
    `AppInfo`, and `HomebrewService` directly, so no app launch is needed.
  - Added Swift Testing suites for the Mach-O parser, the label rules, Homebrew
    lookup, and spec drift (`SpecificationTests`).
  - `MachOFile` now rejects fat headers with 0 or 20 or more slices, which also
    stops Java class files being reported as binaries (H-3).
  - `HomebrewService` gained an internal `init( cacheDirectory: )` for tests.
- Spec and docs: section 4 quirks, section 11, REQ-SEC-3, REQ-QA-2.
- Verification: 25 tests pass with `xcodebuild test` (ad-hoc signed). The
  spec-drift test was shown to fail by changing the `0x0100000C` table row, then
  the spec was restored. The new fat-count tests were not run against the old
  parser, so their ability to fail is unproven. UI, scan, and export paths are
  not covered.
- Notes: the project file was edited by hand because no `xcodeproj` tooling was
  installed; Xcode opened no part of it.

---

### chore/modernize-toolchain: macOS 14 target, Swift 6, structured concurrency

- Branch: `chore/modernize-toolchain`, base `docs/project-standards`
- Worked on by: Byron Scott Jones (owner); Claude Sonnet 5.5 (Claude Code, author)
- What it did:
  - Raised `MACOSX_DEPLOYMENT_TARGET` from 11.0 to 14.0 and set Swift 6 language
    mode at project level.
  - Replaced the GCD scan and its `loading` and `stop` polling with a cancellable
    `Task` and an `AsyncStream` fed by a `Sendable` `AppScanner`.
  - Rewrote `HomebrewService` with `async`/`await`, lock-protected tables, and an
    HTTP status check (a non-200 response is now an error).
  - Replaced deprecated `allowedFileTypes` with `allowedContentTypes`.
  - Removed the obsolete `OTHER_CFLAGS` warning workaround from the Makefile and
    packaging script; marked `ApplicationDelegate` `@MainActor`.
- Spec and docs: REQ-SCAN-1, REQ-UI-4, REQ-QA-1; sections 5.1, 6, 8, 9; AGENTS,
  BUILDING, README.
- Verification: Debug and Release `xcodebuild` succeed with no first-party
  warnings; Release executable is `arm64` and `LSMinimumSystemVersion` is 14.0.
  Not exercised: a manual scan, export, cancel, and Homebrew refresh in the
  running app; there are no automated tests yet (HANDOFF H-5).
- Notes: the Release run script phase rewrites `Silicon/Info.plist` during a
  build; the change was reverted by hand. `.gitmodules` could not be edited from
  the agent sandbox (H-8). An earlier draft of this work's plan wrongly said the
  code used `print`; it contains none.

---

### docs/project-standards: adopt the project documentation standard

- Branch: `docs/project-standards`, base `feat/arm64-only-and-copyright`
- Worked on by: Byron Scott Jones (owner); Claude Sonnet 5.5 (Claude Code, author)
- What it did:
  - Renamed `Agents.md` to `AGENTS.md` and `Engineering.md` to `ENGINEERING.md`.
  - Rewrote `ENGINEERING.md` as a requirement-ID specification with the twelve
    required sections.
  - Added `HANDOFF.md`, this file, and the project `agents/` folder with
    snapshots of the global topic files.
- Spec and docs: all of `ENGINEERING.md`; `AGENTS.md` routing table.
- Verification: spec statements checked by reading `MachOFile.swift`,
  `App.swift`, and `MainWindowController.swift`. `markdownlint-cli2` passes on
  `AGENTS.md`, `ENGINEERING.md`, `HANDOFF.md`, and `CHANGELOG.md` (the other
  Markdown files are excluded, HANDOFF H-9).
- Notes: spec drift found while writing it (fat header count not validated,
  `print` logging, deployment target rejected by current Xcode) is in HANDOFF.

---

### feat/arm64-only-and-copyright: arm64-only builds and fork copyright

- Branch: `feat/arm64-only-and-copyright`, base `main`
- Worked on by: Byron Scott Jones (owner); Claude Sonnet 5.5 (Claude Code, author)
- What it did:
  - Set `ARCHS = arm64` at project level for Debug and Release.
  - Removed the Intel Makefile targets and packaging path; the script accepts only
    `--arch arm64`.
  - Added `Enhancements Copyright @ 2026 - Byron Scott Jones` to `LICENSE`,
    `Info.plist`, and every Swift header.
- Spec and docs: REQ-PLAT-1; README and BUILDING command lists.
- Verification: `xcodebuild -showBuildSettings` reported `ARCHS = arm64` for both
  configurations. A full build was not completed (HANDOFF H-1).

---

### Fork history on `main` (backfilled)

- Backfilled history: written 2026-11-25T15:40:00Z from the repository log.
- Worked on by: Byron Scott Jones (owner); git identity `ByronJones-Elsevier`
  (unconfirmed alias); Claude.ai and an OpenAI model (author, as stated in the
  README, model versions not recorded).
- What it did, from 2026-08-03 onward:
  - Added architecture filter checkboxes, sort options, CSV and HTML export,
    Special Folders preferences, Homebrew lookup, and the Help menu GitHub link.
  - Added audio plugin scanning, GitHub Actions CI and release workflows,
    screenshots, AI and security notices, and `AGENTS` and engineering guides.
  - Removed the failing update check and bumped the version to 1.1.5.

---

### Upstream history (backfilled)

- Backfilled history: written 2026-11-25T15:40:00Z from the repository log.
- Worked on by: DigiDNA (upstream author `macmade`, Jean-David Gadina).
- What it did: released versions 1.0.0 through 1.0.5, including Chinese
  localization, the Apple-apps exclusion checkbox, iOS app detection,
  persistent settings, and Xcode 14.1 support.
