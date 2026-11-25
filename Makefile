PROJECT ?= Silicon.xcodeproj
SCHEME ?= Silicon
CONFIGURATION ?= Release
DERIVED_DATA ?= build/DerivedData
DIST_DIR ?= build/dist
PACKAGE_SCRIPT ?= Scripts/package_arch.sh
OTHER_CFLAGS ?= -Wno-implicit-int-float-conversion -Wno-conversion -Wno-deprecated-declarations
ARM64_DEPLOYMENT_TARGET ?= 11.0

XCODEBUILD ?= xcodebuild
XCODE_COMMON = -project "$(PROJECT)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" OTHER_CFLAGS="$(OTHER_CFLAGS)"

# Local packaging defaults to unsigned apps so it works without a developer
# certificate. For signed builds, pass SIGNING=automatic or SIGNING=adhoc.
SIGNING ?= unsigned

ifeq ($(SIGNING),unsigned)
SIGNING_SETTINGS = CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
else ifeq ($(SIGNING),adhoc)
SIGNING_SETTINGS = CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES
else ifeq ($(SIGNING),automatic)
SIGNING_SETTINGS =
else
$(error SIGNING must be one of: unsigned, adhoc, automatic)
endif

.PHONY: help submodules build build-debug build-release build-arm app-arm dmg-arm dist clean

help:
	@printf '%s\n' \
		'Targets:' \
		'  make submodules    Fetch required Git submodules' \
		'  make build         Build Release for arm64 (the project is arm64-only)' \
		'  make build-arm     Build Release Silicon.app for arm64' \
		'  make app-arm       Stage build/dist/arm64/Silicon.app' \
		'  make dmg-arm       Create build/dist/Silicon-<version>-arm64.dmg' \
		'  make dist          Create the arm64 app and DMG' \
		'  make clean         Remove local build output' \
		'' \
		'Options:' \
		'  SIGNING=unsigned   Default; no local certificate required' \
		'  SIGNING=adhoc      Ad-hoc code sign with identity "-"' \
		'  SIGNING=automatic  Use the Xcode project signing settings'

submodules:
	git submodule update --init --recursive

build:
	$(XCODEBUILD) $(XCODE_COMMON) -derivedDataPath "$(DERIVED_DATA)" $(SIGNING_SETTINGS) build

build-debug:
	$(MAKE) build CONFIGURATION=Debug

build-release:
	$(MAKE) build CONFIGURATION=Release

build-arm:
	$(XCODEBUILD) $(XCODE_COMMON) -derivedDataPath "$(DERIVED_DATA)-arm64" $(SIGNING_SETTINGS) ARCHS=arm64 ONLY_ACTIVE_ARCH=NO MACOSX_DEPLOYMENT_TARGET="$(ARM64_DEPLOYMENT_TARGET)" build

app-arm:
	"$(PACKAGE_SCRIPT)" --arch arm64 --app-only --configuration "$(CONFIGURATION)" --project "$(PROJECT)" --scheme "$(SCHEME)" --derived-data "$(DERIVED_DATA)-arm64" --dist-dir "$(DIST_DIR)" --signing "$(SIGNING)" --other-cflags "$(OTHER_CFLAGS)" --deployment-target "$(ARM64_DEPLOYMENT_TARGET)"

dmg-arm:
	"$(PACKAGE_SCRIPT)" --arch arm64 --configuration "$(CONFIGURATION)" --project "$(PROJECT)" --scheme "$(SCHEME)" --derived-data "$(DERIVED_DATA)-arm64" --dist-dir "$(DIST_DIR)" --signing "$(SIGNING)" --other-cflags "$(OTHER_CFLAGS)" --deployment-target "$(ARM64_DEPLOYMENT_TARGET)"

dist: dmg-arm

clean:
	rm -rf build
