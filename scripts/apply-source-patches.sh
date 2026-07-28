#!/usr/bin/env bash
# Apply StarshipPad's maintained changes to the pinned disposable inputs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STARSHIP="$ROOT/sources/Starship"
LUS="$STARSHIP/libultraship"
TORCH="$STARSHIP/tools/Torch"

for tree in "$STARSHIP" "$LUS" "$TORCH"; do
    expected_root="$(cd "$tree" 2>/dev/null && pwd -P || true)"
    actual_root="$(git -C "$tree" rev-parse --show-toplevel 2>/dev/null || true)"
    if [ "$actual_root" != "$expected_root" ]; then
        echo "Missing source input: $tree" >&2
        echo "Run scripts/clone-sources.sh first." >&2
        exit 1
    fi
done

apply_patch() {
    local tree="$1"
    local patch="$2"

    if git -C "$tree" apply --check "$patch" 2>/dev/null; then
        git -C "$tree" apply "$patch"
        echo "Applied $(basename "$patch")"
    elif git -C "$tree" apply --reverse --check "$patch" 2>/dev/null; then
        echo "Already applied: $(basename "$patch")"
    else
        echo "Patch does not apply cleanly: $patch" >&2
        exit 1
    fi
}

apply_patch "$LUS" "$ROOT/patches/libultraship-ios.patch"
apply_patch "$TORCH" "$ROOT/patches/torch-ios.patch"

if [ -s "$ROOT/patches/starship-ios.patch" ]; then
    apply_patch "$STARSHIP" "$ROOT/patches/starship-ios.patch"
    icon_source="$ROOT/ios-assets/AppIcon.png"
    icon_destination="$STARSHIP/ios/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    if [ ! -f "$icon_source" ]; then
        echo "Missing StarshipPad app icon: $icon_source" >&2
        exit 1
    fi
    mkdir -p "$(dirname "$icon_destination")"
    cp "$icon_source" "$icon_destination"
    echo "Installed StarshipPad app icon"
fi
