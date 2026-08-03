Silicon
=======

[![CI](https://github.com/byronjones-elsevier/Silicon/actions/workflows/ci.yaml/badge.svg)](https://github.com/byronjones-elsevier/Silicon/actions/workflows/ci.yaml)
[![Release](https://img.shields.io/github/v/release/byronjones-elsevier/Silicon?logo=github)](https://github.com/byronjones-elsevier/Silicon/releases)
[![Issues](http://img.shields.io/github/issues/byronjones-elsevier/Silicon.svg?logo=github)](https://github.com/byronjones-elsevier/Silicon/issues)
![Status](https://img.shields.io/badge/status-active-brightgreen.svg?logo=git)
![License](https://img.shields.io/badge/license-mit-brightgreen.svg?logo=open-source-initiative)

About
-----

Identify the binary architecture of every app installed on your Mac:

Silicon scans `.app` bundles, parses their Mach-O executables, and classifies each application as Apple Silicon (ARM), Universal, Intel 64, Intel 32, or PowerPC — or any combination. It optionally cross-references Homebrew to show the latest available version alongside each installed app.

![Main window](Assets/Screen1.png "Main window")

![Preferences](Assets/Screen2.png "Preferences")

![Export menu](Assets/Screen3.png "Export menu")

Features
--------

- **Architecture detection** — Apple Silicon, Universal, Intel 64/32, PowerPC
- **Flexible filtering** — independent checkboxes for each architecture, plus Universal and Non-ARM filters
- **Homebrew version lookup** — compares installed apps against Homebrew cask and formula data (24-hour cache)
- **Export** — CSV and HTML exports with architecture, version, bundle ID, path, and optional Homebrew columns
- **Folder blacklist** — exclude directories from scans via Preferences
- **Sort options** — by name, architecture, or path (ascending/descending)

Installation
------------

Download the latest release from the [Releases page](https://github.com/byronjones-elsevier/Silicon/releases) and move `Silicon.app` to your `/Applications` folder.

Or build from source — see [Engineering.md](Engineering.md).

Changelog
---------

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
