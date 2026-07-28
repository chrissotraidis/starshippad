#!/usr/bin/env bash
# Reproduce the unsigned or locally signed StarshipPad app.
#
# The build is ROM-free. A legally acquired supported ROM may be kept under
# ignored ref/ for later import into the installed app, but this script never
# reads or packages it.
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
"$ROOT/scripts/generate-port-archive.sh"

if find "$ROOT/ref" -maxdepth 1 -type f \
    \( -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' \) \
    -print -quit 2>/dev/null | grep -q .; then
    echo "ROM detected under ignored ref/; it remains local and is not part of the build."
fi

if [ "$MODE" = "--simulator" ]; then
    IOS_PLATFORM=SIMULATORARM64 "$ROOT/scripts/configure-ios.sh"
else
    "$ROOT/scripts/configure-ios.sh"
fi

# Do not let an earlier signed build leave a profile or _CodeSignature in a
# later unsigned product.
rm -rf "$BUILD_DIR/Release-iphoneos/StarshipPad.app" \
    "$BUILD_DIR/Release-iphonesimulator/StarshipPad.app"

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
    if [ -z "${DEVELOPMENT_TEAM:-}" ]; then
        echo "Unsigned compile proof; set DEVELOPMENT_TEAM and BUNDLE_ID to sign."
    else
        echo "Signing requested for team $DEVELOPMENT_TEAM."
    fi
fi
