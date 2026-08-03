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

.PHONY: help submodules build build-debug build-release build-intel build-arm app-intel app-arm dmg-intel dmg-arm dist clean

help:
	@printf '%s\n' \
		'Targets:' \
		'  make submodules    Fetch required Git submodules' \
		'  make build         Build Release for the host/default architecture' \
		'  make build-intel   Build Release Silicon.app for x86_64' \
		'  make build-arm     Build Release Silicon.app for arm64' \
		'  make app-intel     Stage build/dist/x86_64/Silicon.app' \
		'  make app-arm       Stage build/dist/arm64/Silicon.app' \
		'  make dmg-intel     Create build/dist/Silicon-<version>-x86_64.dmg' \
		'  make dmg-arm       Create build/dist/Silicon-<version>-arm64.dmg' \
		'  make dist          Create both architecture-specific apps and DMGs' \
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

build-intel:
	$(XCODEBUILD) $(XCODE_COMMON) -derivedDataPath "$(DERIVED_DATA)-x86_64" $(SIGNING_SETTINGS) ARCHS=x86_64 ONLY_ACTIVE_ARCH=NO build

build-arm:
	$(XCODEBUILD) $(XCODE_COMMON) -derivedDataPath "$(DERIVED_DATA)-arm64" $(SIGNING_SETTINGS) ARCHS=arm64 ONLY_ACTIVE_ARCH=NO MACOSX_DEPLOYMENT_TARGET="$(ARM64_DEPLOYMENT_TARGET)" build

app-intel:
	"$(PACKAGE_SCRIPT)" --arch x86_64 --app-only --configuration "$(CONFIGURATION)" --project "$(PROJECT)" --scheme "$(SCHEME)" --derived-data "$(DERIVED_DATA)-x86_64" --dist-dir "$(DIST_DIR)" --signing "$(SIGNING)" --other-cflags "$(OTHER_CFLAGS)"

app-arm:
	"$(PACKAGE_SCRIPT)" --arch arm64 --app-only --configuration "$(CONFIGURATION)" --project "$(PROJECT)" --scheme "$(SCHEME)" --derived-data "$(DERIVED_DATA)-arm64" --dist-dir "$(DIST_DIR)" --signing "$(SIGNING)" --other-cflags "$(OTHER_CFLAGS)" --deployment-target "$(ARM64_DEPLOYMENT_TARGET)"

dmg-intel:
	"$(PACKAGE_SCRIPT)" --arch x86_64 --configuration "$(CONFIGURATION)" --project "$(PROJECT)" --scheme "$(SCHEME)" --derived-data "$(DERIVED_DATA)-x86_64" --dist-dir "$(DIST_DIR)" --signing "$(SIGNING)" --other-cflags "$(OTHER_CFLAGS)"

dmg-arm:
	"$(PACKAGE_SCRIPT)" --arch arm64 --configuration "$(CONFIGURATION)" --project "$(PROJECT)" --scheme "$(SCHEME)" --derived-data "$(DERIVED_DATA)-arm64" --dist-dir "$(DIST_DIR)" --signing "$(SIGNING)" --other-cflags "$(OTHER_CFLAGS)" --deployment-target "$(ARM64_DEPLOYMENT_TARGET)"

dist: dmg-intel dmg-arm

clean:
	rm -rf build
