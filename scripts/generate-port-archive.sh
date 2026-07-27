#!/usr/bin/env bash
# Generate and audit Starship's ROM-free port archive on the macOS host.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/sources/Starship"
BUILD_DIR="$ROOT/build-host"
SOURCE_ARCHIVE="$SOURCE/starship.o2r"
BUILD_ARCHIVE="$BUILD_DIR/starship.o2r"

if [ ! -d "$SOURCE/.git" ]; then
    echo "Missing sources/Starship. Run scripts/clone-sources.sh first." >&2
    exit 1
fi

cmake -S "$SOURCE" -B "$BUILD_DIR" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SCRIPTING=OFF
cmake --build "$BUILD_DIR" --target GeneratePortO2R

if [ ! -f "$SOURCE_ARCHIVE" ] || [ ! -f "$BUILD_ARCHIVE" ]; then
    echo "Expected ROM-free port archive was not generated." >&2
    exit 1
fi
cmp -s "$SOURCE_ARCHIVE" "$BUILD_ARCHIVE" || {
    echo "Source and build copies of starship.o2r differ." >&2
    exit 1
}

archive_entries="$(unzip -Z1 "$SOURCE_ARCHIVE")"
[ -n "$archive_entries" ] || {
    echo "ROM-free port archive is empty." >&2
    exit 1
}
if grep -Eiq '(^|/).*\.(z64|n64|v64|rom|otr|mpq)$|(^|/)sf64.*\.o2r$|(^|/)baserom' \
    <<< "$archive_entries"; then
    echo "Refusing starship.o2r containing prohibited entries." >&2
    exit 1
fi
if grep -Eq '(^|/)\.\.?(/|$)|^/' <<< "$archive_entries"; then
    echo "Refusing starship.o2r containing unsafe paths." >&2
    exit 1
fi
unzip -tq "$SOURCE_ARCHIVE" >/dev/null

archive_manifest="$(mktemp /tmp/starshippad-port-archive.XXXXXX)"
source_manifest="$(mktemp /tmp/starshippad-port-source.XXXXXX)"
trap 'rm -f "$archive_manifest" "$source_manifest"' EXIT
printf '%s\n' "$archive_entries" | sort > "$archive_manifest"
git -C "$SOURCE" ls-files port | sed 's#^port/##' | sort > "$source_manifest"
if ! cmp -s "$archive_manifest" "$source_manifest"; then
    echo "starship.o2r does not exactly match the tracked port/ manifest." >&2
    diff -u "$source_manifest" "$archive_manifest" >&2 || true
    exit 1
fi
while IFS= read -r entry; do
    if ! unzip -p "$SOURCE_ARCHIVE" "$entry" | cmp -s - "$SOURCE/port/$entry"; then
        echo "Archive entry differs from tracked source: $entry" >&2
        exit 1
    fi
done < "$archive_manifest"

echo "Generated ROM-free port archive: $SOURCE_ARCHIVE"
printf 'entries: %s\n' "$(wc -l <<< "$archive_entries" | tr -d ' ')"
shasum -a 256 "$SOURCE_ARCHIVE"
