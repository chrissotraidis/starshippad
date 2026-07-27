#!/usr/bin/env bash
# Reproduce the unsigned or locally signed StarshipPad app.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:---device}"

case "$MODE" in
    --device)
        BUILD_DIR="$ROOT/build-ios"
        DESTINATION="generic/platform=iOS"
        ;;
    --simulator)
        BUILD_DIR="$ROOT/build-ios-sim"
        DESTINATION="generic/platform=iOS Simulator"
        ;;
    *)
        echo "Usage: scripts/build-ios.sh [--device|--simulator]" >&2
        exit 2
        ;;
esac

"$ROOT/scripts/clone-sources.sh"
"$ROOT/scripts/apply-source-patches.sh"

if [ "$MODE" = "--simulator" ]; then
    IOS_PLATFORM=SIMULATORARM64 "$ROOT/scripts/configure-ios.sh"
else
    "$ROOT/scripts/configure-ios.sh"
fi

set -- cmake --build "$BUILD_DIR" --target Starship --config Release -- \
    -destination "$DESTINATION"
if [ -z "${DEVELOPMENT_TEAM:-}" ]; then
    set -- "$@" CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
fi
"$@"

if [ "$MODE" = "--simulator" ]; then
    echo "Simulator app: $BUILD_DIR/Release-iphonesimulator/StarshipPad.app"
else
    echo "Device app: $BUILD_DIR/Release-iphoneos/StarshipPad.app"
fi
