#!/usr/bin/env bash
# Audit a built StarshipPad iPhoneOS app without packaging it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-$ROOT/build-ios/Release-iphoneos/StarshipPad.app}"

if [[ "$APP" != /* ]]; then
    APP="$ROOT/$APP"
fi

fail() {
    echo "iOS app audit failed: $*" >&2
    exit 1
}

if [ ! -d "$APP" ] || [ ! -f "$APP/StarshipPad" ]; then
    fail "device app not found: $APP"
fi

build_metadata="$(xcrun vtool -show-build "$APP/StarshipPad")"
grep -Eq 'platform +IOS$' <<< "$build_metadata" ||
    fail "product is not an iPhoneOS binary"
grep -Eq 'minos +16\.0$' <<< "$build_metadata" ||
    fail "product does not declare iOS 16.0"
xcrun lipo -info "$APP/StarshipPad" | grep -Eq 'architecture: arm64$' ||
    fail "product is not arm64-only"

for required in Info.plist Assets.car config.yml gamecontrollerdb.txt LICENSE \
    THIRD_PARTY_NOTICES.md LICENSE-APACHE-2.0.txt; do
    [ -f "$APP/$required" ] || fail "required bundle file is missing: $required"
done
[ -d "$APP/assets/yaml" ] || fail "required assets/yaml tree is missing"
plutil -lint "$APP/Info.plist" >/dev/null

bundle_identifier="$(plutil -extract CFBundleIdentifier raw "$APP/Info.plist")"
bundle_version="$(plutil -extract CFBundleShortVersionString raw "$APP/Info.plist")"
bundle_build="$(plutil -extract CFBundleVersion raw "$APP/Info.plist")"
[[ "$bundle_identifier" != com.example.* ]] ||
    fail "placeholder bundle identifier remains: $bundle_identifier"
[ "$bundle_version" = "${STARSHIPPAD_VERSION:-0.1.0}" ] ||
    fail "unexpected release version: $bundle_version"
[ "$bundle_build" = "${STARSHIPPAD_BUILD_NUMBER:-4}" ] ||
    fail "unexpected build number: $bundle_build"

local_path="$(strings -a "$APP/StarshipPad" |
    grep -E -m 1 '(/Users/|/private/tmp/|/var/folders/)' || true)"
[ -z "$local_path" ] ||
    fail "executable exposes a local build path: $local_path"

for pattern in '*.z64' '*.n64' '*.v64' '*.rom' 'sf64*.o2r' 'baserom*' '*.otr' '*.mpq'; do
    forbidden="$(find "$APP" -type f -iname "$pattern" -print -quit)"
    [ -z "$forbidden" ] || fail "bundle contains prohibited data: $forbidden"
done

unexpected_o2r="$(find "$APP" -type f -iname '*.o2r' ! -name 'starship.o2r' -print -quit)"
[ -z "$unexpected_o2r" ] || fail "bundle contains unexpected archive: $unexpected_o2r"

if [ -f "$APP/starship.o2r" ]; then
    archive_entries="$(unzip -Z1 "$APP/starship.o2r")"
    if grep -Eiq '(^|/).*\.(z64|n64|v64|rom|otr|mpq)$|(^|/)sf64.*\.o2r$|(^|/)baserom' \
        <<< "$archive_entries"; then
        fail "ROM-free port archive contains prohibited entries"
    fi
elif [ "${REQUIRE_PORT_ARCHIVE:-0}" = "1" ]; then
    fail "required ROM-free port archive is missing"
fi

if ! codesign --verify --strict "$APP" >/dev/null 2>&1 &&
   { [ -d "$APP/_CodeSignature" ] || [ -f "$APP/embedded.mobileprovision" ]; }; then
    fail "unsigned app contains stale signing material"
fi

echo "iOS app audit passed: $APP"
