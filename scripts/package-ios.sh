#!/usr/bin/env bash
# Audit an iPhoneOS StarshipPad app and wrap it as an IPA.
#
# This does not sign an unsigned app. Set REQUIRE_SIGNED=1 when producing an
# installable device artifact; that mode requires both a valid code signature
# and an embedded provisioning profile.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-$ROOT/build-ios/Release-iphoneos/StarshipPad.app}"

if [[ "$APP" != /* ]]; then
    APP="$ROOT/$APP"
fi

fail() {
    echo "iOS package failed: $*" >&2
    exit 1
}

if [ ! -d "$APP" ] || [ ! -f "$APP/StarshipPad" ]; then
    fail "device app not found: $APP"
fi

REQUIRE_PORT_ARCHIVE=1 "$ROOT/scripts/audit-ios-app.sh" "$APP"

signature_state="unsigned"
if codesign --verify --strict "$APP" >/dev/null 2>&1 &&
   [ -f "$APP/embedded.mobileprovision" ]; then
    signature_state="signed"
fi

if [ "$signature_state" = "unsigned" ] &&
   { [ -d "$APP/_CodeSignature" ] || [ -f "$APP/embedded.mobileprovision" ]; }; then
    fail "unsigned app contains stale signing material: $APP"
fi

if [ "${REQUIRE_SIGNED:-0}" = "1" ] && [ "$signature_state" != "signed" ]; then
    fail "REQUIRE_SIGNED=1, but the app lacks a valid device signature/profile"
fi

version="$(/usr/libexec/PlistBuddy \
    -c 'Print :CFBundleShortVersionString' "$APP/Info.plist")"
output="${2:-$ROOT/artifacts/StarshipPad-${version}-${signature_state}.ipa}"
if [[ "$output" != /* ]]; then
    output="$ROOT/$output"
fi

mkdir -p "$(dirname "$output")"
package_root="$(mktemp -d /tmp/starshippad-package.XXXXXX)"
trap 'rm -rf "$package_root"' EXIT
mkdir "$package_root/Payload"
ditto "$APP" "$package_root/Payload/StarshipPad.app"
ditto -c -k --norsrc --keepParent "$package_root/Payload" "$output"

ipa_entries="$(unzip -Z1 "$output")"
grep -Fxq 'Payload/StarshipPad.app/StarshipPad' <<< "$ipa_entries" ||
    fail "IPA payload executable is missing"
grep -Fxq 'Payload/StarshipPad.app/starship.o2r' <<< "$ipa_entries" ||
    fail "IPA payload ROM-free archive is missing"

if grep -Eiq \
    '\.(z64|n64|v64|rom|otr|mpq)$|Payload/.*/sf64.*\.o2r$|Payload/.*/baserom' \
    <<< "$ipa_entries"; then
    fail "IPA contains ROM or ROM-derived data: $output"
fi

packaged_archive="$package_root/starship.o2r"
unzip -p "$output" 'Payload/StarshipPad.app/starship.o2r' > "$packaged_archive"
unzip -tq "$packaged_archive" >/dev/null ||
    fail "packaged starship.o2r is corrupt"
archive_entries="$(unzip -Z1 "$packaged_archive")"
if grep -Eiq \
    '(^|/).*\.(z64|n64|v64|rom|otr|mpq)$|(^|/)sf64.*\.o2r$|(^|/)baserom' \
    <<< "$archive_entries"; then
    fail "packaged starship.o2r contains prohibited data"
fi

echo "Packaged ${signature_state} StarshipPad IPA: $output"
shasum -a 256 "$output"
if [ "$signature_state" != "signed" ]; then
    echo "This proof artifact is not installable on a standard device until signed."
fi
