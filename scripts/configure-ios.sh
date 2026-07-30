#!/usr/bin/env bash
# Configure StarshipPad's pinned Starship app for iPhoneOS or Simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/sources/Starship"
DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET:-16.0}"
BUNDLE_ID="${BUNDLE_ID:-com.chrissotraidis.starshippad}"
STARSHIPPAD_VERSION="${STARSHIPPAD_VERSION:-0.1.0}"
STARSHIPPAD_BUILD_NUMBER="${STARSHIPPAD_BUILD_NUMBER:-2}"
IOS_PLATFORM="${IOS_PLATFORM:-OS64}"
BUILD_DIR="$ROOT/build-ios"

if [ "$IOS_PLATFORM" = "SIMULATORARM64" ]; then
    BUILD_DIR="$ROOT/build-ios-sim"
fi

if [ ! -d "$SOURCE/.git" ]; then
    echo "Missing sources/Starship. Run scripts/clone-sources.sh first." >&2
    exit 1
fi

set -- cmake -Wno-unused-cli \
    -S "$SOURCE" -B "$BUILD_DIR" \
    -GXcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_SYSTEM_VERSION="$DEPLOYMENT_TARGET" \
    -DDEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_BUILD_TYPE:STRING=Release \
    -DENABLE_SCRIPTING=OFF \
    -DPLATFORM="$IOS_PLATFORM" \
    -DBUNDLE_ID="$BUNDLE_ID" \
    -DSTARSHIPPAD_VERSION="$STARSHIPPAD_VERSION" \
    -DSTARSHIPPAD_BUILD_NUMBER="$STARSHIPPAD_BUILD_NUMBER" \
    -DSTARSHIPPAD_NOTICES_FILE="$ROOT/THIRD_PARTY_NOTICES.md" \
    -DSTARSHIPPAD_APACHE_LICENSE_FILE="$ROOT/LICENSE-APACHE-2.0.txt"

if [ -n "${DEVELOPMENT_TEAM:-}" ]; then
    set -- "$@" \
        "-DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM" \
        -DSIGN_LIBRARY=ON
fi

"$@"

echo "Configured $BUILD_DIR for $IOS_PLATFORM at iOS $DEPLOYMENT_TARGET."
