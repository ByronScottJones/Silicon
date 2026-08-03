#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: Scripts/package_arch.sh --arch x86_64|arm64 [options]

Builds Silicon.app for one architecture, stages the .app under build/dist,
and optionally creates a matching DMG.

Options:
  --app-only                 Stage the .app without creating a DMG
  --configuration NAME       Xcode configuration (default: Release)
  --project PATH             Xcode project (default: Silicon.xcodeproj)
  --scheme NAME              Xcode scheme (default: Silicon)
  --derived-data PATH        DerivedData path (default: build/DerivedData-ARCH)
  --dist-dir PATH            Output directory (default: build/dist)
  --signing MODE             unsigned, adhoc, or automatic (default: unsigned)
  --other-cflags FLAGS       Extra C flags passed to xcodebuild
  --deployment-target VALUE  Override MACOSX_DEPLOYMENT_TARGET
  --help                     Show this help
USAGE
}

ARCH=""
APP_ONLY=0
CONFIGURATION="Release"
PROJECT="Silicon.xcodeproj"
SCHEME="Silicon"
DERIVED_DATA=""
DIST_DIR="build/dist"
SIGNING="unsigned"
OTHER_CFLAGS="-Wno-implicit-int-float-conversion -Wno-conversion -Wno-deprecated-declarations"
DEPLOYMENT_TARGET=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --arch)
            ARCH="${2:?missing --arch value}"
            shift 2
            ;;
        --app-only)
            APP_ONLY=1
            shift
            ;;
        --configuration)
            CONFIGURATION="${2:?missing --configuration value}"
            shift 2
            ;;
        --project)
            PROJECT="${2:?missing --project value}"
            shift 2
            ;;
        --scheme)
            SCHEME="${2:?missing --scheme value}"
            shift 2
            ;;
        --derived-data)
            DERIVED_DATA="${2:?missing --derived-data value}"
            shift 2
            ;;
        --dist-dir)
            DIST_DIR="${2:?missing --dist-dir value}"
            shift 2
            ;;
        --signing)
            SIGNING="${2:?missing --signing value}"
            shift 2
            ;;
        --other-cflags)
            OTHER_CFLAGS="${2:?missing --other-cflags value}"
            shift 2
            ;;
        --deployment-target)
            DEPLOYMENT_TARGET="${2:?missing --deployment-target value}"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "arm64" ]; then
    echo "--arch must be x86_64 or arm64" >&2
    exit 2
fi

if [ -z "$DERIVED_DATA" ]; then
    DERIVED_DATA="build/DerivedData-${ARCH}"
fi

case "$SIGNING" in
    unsigned)
        SIGNING_SETTINGS=(CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO)
        ;;
    adhoc)
        SIGNING_SETTINGS=(CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=YES CODE_SIGNING_ALLOWED=YES)
        ;;
    automatic)
        SIGNING_SETTINGS=()
        ;;
    *)
        echo "--signing must be unsigned, adhoc, or automatic" >&2
        exit 2
        ;;
esac

if [ ! -d "Submodules/GitHubUpdates/GitHubUpdates.xcodeproj" ] || [ ! -f "Submodules/xcconfig/Release.xcconfig" ]; then
    echo "Required submodules are missing. Run: make submodules" >&2
    exit 1
fi

DEPLOYMENT_SETTING=()
if [ -n "$DEPLOYMENT_TARGET" ]; then
    DEPLOYMENT_SETTING=(MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET")
fi

echo "Building ${SCHEME} ${CONFIGURATION} for ${ARCH}"
xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA" \
    ARCHS="$ARCH" \
    ONLY_ACTIVE_ARCH=NO \
    OTHER_CFLAGS="$OTHER_CFLAGS" \
    "${DEPLOYMENT_SETTING[@]}" \
    "${SIGNING_SETTINGS[@]}" \
    build

APP_NAME="${SCHEME}.app"
BUILT_APP="${DERIVED_DATA}/Build/Products/${CONFIGURATION}/${APP_NAME}"
if [ ! -d "$BUILT_APP" ]; then
    echo "Expected app was not produced: $BUILT_APP" >&2
    exit 1
fi

STAGED_ARCH_DIR="${DIST_DIR}/${ARCH}"
STAGED_APP="${STAGED_ARCH_DIR}/${APP_NAME}"
DMG_ROOT="${DIST_DIR}/dmgroot-${ARCH}"
DITTO_FLAGS=(--noextattr --noacl)
mkdir -p "$STAGED_ARCH_DIR"
rm -rf "$STAGED_APP"
ditto "${DITTO_FLAGS[@]}" "$BUILT_APP" "$STAGED_APP"

EXECUTABLE="${STAGED_APP}/Contents/MacOS/${SCHEME}"
if [ -f "$EXECUTABLE" ]; then
    echo "Built executable architecture:"
    lipo -archs "$EXECUTABLE"
fi

if [ "$APP_ONLY" -eq 1 ]; then
    echo "App staged at: $STAGED_APP"
    exit 0
fi

VERSION="${VERSION:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "Silicon/Info.plist")
fi

DMG_NAME="Silicon-${VERSION}-${ARCH}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"
VOL_NAME="Silicon ${VERSION} ${ARCH}"

rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"
ditto "${DITTO_FLAGS[@]}" "$STAGED_APP" "${DMG_ROOT}/${APP_NAME}"
ln -s /Applications "${DMG_ROOT}/Applications"

rm -f "$DMG_PATH"
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

echo "App staged at: $STAGED_APP"
echo "DMG created at: $DMG_PATH"
