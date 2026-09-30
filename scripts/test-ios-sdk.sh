#!/usr/bin/env bash
# Real SDK regression probe; preserve its tiny build trees for inspection.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$(mktemp -d "${TMPDIR:-/tmp}/starshippad-ios-sdk.XXXXXX")"
HOST_SDK="$(xcrun --sdk macosx --show-sdk-path)"
for SDK in iphoneos iphonesimulator; do
    SDK_PATH="$(xcrun --sdk "$SDK" --show-sdk-path)"
    BUILD="$OUTPUT/$SDK"
    TARGET=arm64-apple-ios16.0
    if [ "$SDK" = iphonesimulator ]; then TARGET="$TARGET-simulator"; fi
    if xcrun --sdk "$SDK" clang++ -target "$TARGET" -isysroot "$SDK_PATH" \
        -F"$HOST_SDK/System/Library/Frameworks" -fsyntax-only \
        "$ROOT/tests/ios-sdk/UIKitProbe.mm" > "$OUTPUT/$SDK-headers-before.log" 2>&1; then
        echo "Expected mixed-SDK UIKit compile to fail" >&2; exit 1
    fi
    grep -q "'CoreVideo/CVOpenGLESTexture.h' file not found" "$OUTPUT/$SDK-headers-before.log"
    # Seed the actual cached host results seen in the failing player build.
    cmake -S "$ROOT/tests/ios-sdk" -B "$BUILD" -GNinja \
        -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$SDK_PATH" \
        -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=16.0 \
        -DKEEP_SENTINEL=preserved \
        "-DMETAL:FILEPATH=$HOST_SDK/System/Library/Frameworks/Metal.framework" \
        "-DOSX_FOUNDATION:FILEPATH=$HOST_SDK/System/Library/Frameworks/Foundation.framework" \
        "-DOSX_AVFOUNDATION:FILEPATH=$HOST_SDK/System/Library/Frameworks/AVFoundation.framework" \
        > "$OUTPUT/$SDK-before.log" 2>&1 && {
            echo "Expected contaminated-cache configure to fail" >&2; exit 1;
        }
    grep -q 'escaped the selected SDK' "$OUTPUT/$SDK-before.log"
    cmake -S "$ROOT/tests/ios-sdk" -B "$BUILD" \
        -C "$ROOT/scripts/ios-sdk-cache.cmake"
    cmake --build "$BUILD" --parallel 1
done
echo "PASS: cached host frameworks repaired; UIKit compiled for device and simulator."
echo "Probe evidence retained: $OUTPUT"
