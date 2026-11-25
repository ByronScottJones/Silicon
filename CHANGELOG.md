# Silicon Changelog

Every unit of work, newest first. Branch merge facts (pull request, merge time,
commit ids) are deliberately not recorded here; read them from git. See
[ENGINEERING.md](ENGINEERING.md) and [HANDOFF.md](HANDOFF.md).

## Entries

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
  `App.swift`, and `MainWindowController.swift`; Markdown lint not yet run
  (see Notes).
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
