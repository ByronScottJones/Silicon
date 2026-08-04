# Building Silicon Locally

Silicon is an Xcode macOS app. The root `Makefile` wraps `xcodebuild` and
`hdiutil` so local builds can produce architecture-specific `.app` bundles and
DMG files.

## Prerequisites

1. Install Xcode and command line tools.
2. Initialize the required submodules:

   ```sh
   make submodules
   ```

## Common Commands

```sh
make build        # Build Release for the host/default architecture
make app-intel    # Build and stage build/dist/x86_64/Silicon.app
make app-arm      # Build and stage build/dist/arm64/Silicon.app
make dmg-intel    # Create build/dist/Silicon-<version>-x86_64.dmg
make dmg-arm      # Create build/dist/Silicon-<version>-arm64.dmg
make dist         # Create both Intel and Apple Silicon DMGs
make clean        # Remove build output
```

Apple Silicon builds default to `MACOSX_DEPLOYMENT_TARGET=11.0` because macOS
arm64 apps require macOS Big Sur or later. Override it only if your Xcode setup
supports the value:

```sh
make dmg-arm ARM64_DEPLOYMENT_TARGET=11.0
```

The default wrapper flags suppress warning noise from the `GitHubUpdates`
submodule, including macOS 11 deprecation warnings that otherwise break arm64
Release builds because that submodule treats warnings as errors.

By default, the Makefile creates unsigned local builds, matching CI:

```sh
make dist SIGNING=unsigned
```

For ad-hoc signing:

```sh
make dist SIGNING=adhoc
```

For the Xcode project's automatic signing settings:

```sh
make dist SIGNING=automatic
```

Output is written under `build/dist/`.

## Testing Local Changes

Use `make build` before review to validate the current source against the
Release configuration. The built app is written to
`build/DerivedData/Build/Products/Release/Silicon.app`; architecture-specific
apps and DMGs are produced by the `app-*` and `dmg-*` targets above.
