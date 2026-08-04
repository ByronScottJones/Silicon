Silicon
=======

[![CI](https://github.com/byronjones-elsevier/Silicon/actions/workflows/ci.yaml/badge.svg)](https://github.com/byronjones-elsevier/Silicon/actions/workflows/ci.yaml)
[![Release](https://img.shields.io/github/v/release/byronjones-elsevier/Silicon?logo=github)](https://github.com/byronjones-elsevier/Silicon/releases)
[![Issues](http://img.shields.io/github/issues/byronjones-elsevier/Silicon.svg?logo=github)](https://github.com/byronjones-elsevier/Silicon/issues)
![Status](https://img.shields.io/badge/status-active-brightgreen.svg?logo=git)
![License](https://img.shields.io/badge/license-mit-brightgreen.svg?logo=open-source-initiative)

About
-----

Identify the binary architecture of every app and supported plugin installed on your Mac:

Silicon scans `.app` bundles, parses their Mach-O executables, and classifies each application as Apple Silicon (ARM), Universal, Intel 64, Intel 32, or PowerPC -- or any combination. It can also scan macOS audio plugin folders for Mach-O binaries and optionally cross-reference Homebrew to show the latest available version alongside each installed app.

![All binaries](Assets/Silicon_AllBinaries.png "All binaries")

![Non-ARM filter](Assets/Silicon_NonArm.png "Non-ARM filter")

![Sort options](Assets/Silicon_SortOptions.png "Sort options")

![Preferences](Assets/Silicon_Preferences.png "Preferences")

![Export menu](Assets/Silicon_ExportMenu.png "Export menu")

Features
--------

- **Architecture detection** — Apple Silicon, Universal, Intel 64/32, PowerPC
- **Flexible filtering** — independent checkboxes for each architecture, plus Universal and Non-ARM filters
- **Homebrew version lookup** — compares installed apps against Homebrew cask and formula data (24-hour cache)
- **Export** — CSV and HTML exports with architecture, version, bundle ID, path, and optional Homebrew columns
- **Special Folders** — include extra scan roots or exclude directories from scans via Preferences
- **Audio plugin scanning** — optionally scans `/Library/Audio/Plug-Ins/` and `~/Library/Audio/Plug-Ins/` for Mach-O binaries
- **Sort options** — by name, architecture, or path (ascending/descending)

Installation
------------

Download the latest release from the [Releases page](https://github.com/byronjones-elsevier/Silicon/releases) and move `Silicon.app` to your `/Applications` folder.

Or build from source with Xcode and the local Makefile targets below.

Building From Source
--------------------

Prerequisites:

- Xcode with command line tools installed
- Git submodules initialized

Fetch the required submodules first:

```sh
make submodules
```

Common local build commands:

```sh
make build        # Build Release for the host/default architecture
make app-intel    # Build and stage build/dist/x86_64/Silicon.app
make app-arm      # Build and stage build/dist/arm64/Silicon.app
make dmg-intel    # Create build/dist/Silicon-<version>-x86_64.dmg
make dmg-arm      # Create build/dist/Silicon-<version>-arm64.dmg
make dist         # Create both Intel and Apple Silicon DMGs
make clean        # Remove build output
```

Local builds are unsigned by default so they work without a developer
certificate:

```sh
make dist SIGNING=unsigned
```

Other signing modes:

```sh
make dist SIGNING=adhoc
make dist SIGNING=automatic
```

Apple Silicon builds use `MACOSX_DEPLOYMENT_TARGET=11.0` by default because
macOS arm64 apps require Big Sur or later. Output is written under
`build/dist/`. Additional build details are in [BUILDING.md](BUILDING.md) and
[Engineering.md](Engineering.md).

Changelog
---------

### Unreleased
- Replaced the Folder Blacklist preferences table with Special Folders that can be marked Included or Excluded
- Added a **Scan for Audio Plugins** preference that includes `/Library/Audio/Plug-Ins/` and `~/Library/Audio/Plug-Ins/`
- Audio plugin folders scan every file recursively and report Mach-O binaries as application-style results

### v1.1.0
- Added Universal and Non-ARM architecture filter checkboxes
- Added Homebrew version lookup (cask + formula, 24-hour cache)
- Added Brew Formula and Brew Version columns to table and exports
- Fixed version information missing from CSV/HTML exports
- Added GitHub Actions CI and release workflows

### v1.0.5
- Bug fixes and stability improvements

### v1.0.4
- Initial public release

License
-------

Project is released under the terms of the MIT License.

Repository Infos
----------------

    Owner:          DigiDNA SARL
    Web:            www.imazing.com
    Blog:           blog.imazing.com
    Twitter:        @DigiDNA
    GitHub:         github.com/DigiDNA

    Fork Owner:     Byron Scott Jones
    Fork Github:    ByronScottJones/silicon

# Disclaimers

## App Notarization

This application is open source, and not notarized at this time. I will not be submitting it to the app store. If the original developer wishes to pull in my updates and release it in the app store, they are welcome to do so.

## Privacy Policy

 I have seen no evidence in the code that the original application transmits data to third parties. My additions pull two JSON files from HomeBrew, but I do not transmit information to them, or any other entities. All processing stays on your local system.

## AI

I am a software engineer with nearly 50 years of experience. I now use AI tools to assist me with development. For this project, I have used Claude.ai and Anthropic GPT 5.5. After each feature update, I reviewed the application to ensure that it was working as I intended. As someone with Frontotemporal Dementia, AI tools are literally saving my career, and allowing me to continue working longer in a field that I love. If you don't like AI, you are welcome to not use my fork of this application. If you do not like that I use AI, tough.

In the words of Bender:

![Bender](Assets/futurama-bender.gif "Bender - Bite My Shiny Metal Ass")
