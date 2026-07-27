#!/usr/bin/env bash
# Fetch StarshipPad's pinned, disposable upstream source inputs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_ROOT="$ROOT/sources"
STARSHIP="$SOURCE_ROOT/Starship"
LUS="$STARSHIP/libultraship"
TORCH="$STARSHIP/tools/Torch"

STARSHIP_REPOSITORY="https://github.com/HarbourMasters/Starship.git"
LUS_REPOSITORY="https://github.com/Kenix3/libultraship.git"
TORCH_REPOSITORY="https://github.com/HarbourMasters/Torch.git"

STARSHIP_PIN="6202c44356fee70dd23e80a16933b211863d3e2d"
LUS_PIN="eaaf9d0fc91e2c400f49ef2a1f8547a691ce4d3c"
LUS_BASE_PIN="09dfab5fb2a9a047a6e268dc9db2daad9b2ce5f0"
LUS_PIN_TREE="1e27f25eeecab5b262dd274fab4ebeeb9e8cb2e4"
TORCH_PIN="cd92cc0f161c5e79e36f5dda0d0029edd3fc8d50"
DISABLED_PUSH_URL="disabled://starshippad-upstream-input"
INSURANCE_PATCH="$ROOT/patches/lus-925-metal-prism.patch"

mkdir -p "$SOURCE_ROOT" "$ROOT/patches"

configure_input_remote() {
    local tree="$1"
    local repository="$2"

    git -C "$tree" remote set-url origin "$repository"
    git -C "$tree" config remote.origin.pushurl "$DISABLED_PUSH_URL"
}

clone_if_missing() {
    local repository="$1"
    local tree="$2"
    local label="$3"
    local detected_root=""

    detected_root="$(git -C "$tree" rev-parse --show-toplevel 2>/dev/null || true)"
    if [ "$detected_root" != "$tree" ]; then
        echo "==> Cloning $label..."
        git clone --no-checkout "$repository" "$tree"
    fi
    configure_input_remote "$tree" "$repository"
}

checkout_pin() {
    local tree="$1"
    local pin="$2"
    local label="$3"

    if ! git -C "$tree" rev-parse --verify "$pin^{commit}" >/dev/null 2>&1; then
        git -C "$tree" fetch --no-tags origin "$pin"
    fi
    git -C "$tree" checkout --detach "$pin"
    local actual
    actual="$(git -C "$tree" rev-parse HEAD)"
    if [[ "$actual" != "$pin"* ]]; then
        echo "Unexpected $label revision: $actual" >&2
        echo "Expected: $pin" >&2
        exit 1
    fi
}

clone_if_missing "$STARSHIP_REPOSITORY" "$STARSHIP" "Starship"
echo "==> Checking out Starship $STARSHIP_PIN..."
checkout_pin "$STARSHIP" "$STARSHIP_PIN" "Starship"

clone_if_missing "$LUS_REPOSITORY" "$LUS" "libultraship"
echo "==> Fetching dangling libultraship pin $LUS_PIN..."
if git -C "$LUS" fetch --no-tags origin "$LUS_PIN"; then
    git -C "$LUS" checkout --detach "$LUS_PIN"
    if ! git -C "$LUS" rev-parse --verify "$LUS_BASE_PIN^{commit}" >/dev/null 2>&1; then
        git -C "$LUS" fetch --no-tags origin "$LUS_BASE_PIN"
    fi

    generated_patch="$(mktemp /tmp/starshippad-lus-insurance.XXXXXX)"
    trap 'rm -f "$generated_patch"' EXIT
    git -C "$LUS" diff "$LUS_BASE_PIN..$LUS_PIN" > "$generated_patch"
    if [ ! -s "$generated_patch" ]; then
        echo "Generated LUS insurance patch is empty." >&2
        exit 1
    fi
    if [ -f "$INSURANCE_PATCH" ]; then
        if ! cmp -s "$generated_patch" "$INSURANCE_PATCH"; then
            echo "Tracked LUS insurance patch does not match the pinned diff." >&2
            exit 1
        fi
    else
        cp "$generated_patch" "$INSURANCE_PATCH"
        echo "Generated $(basename "$INSURANCE_PATCH")"
    fi
else
    if [ ! -s "$INSURANCE_PATCH" ]; then
        echo "The dangling LUS pin is unavailable and its insurance patch is missing." >&2
        exit 1
    fi
    echo "==> Reconstructing libultraship from $LUS_BASE_PIN..."
    checkout_pin "$LUS" "$LUS_BASE_PIN" "libultraship base"
    git -C "$LUS" apply --check "$INSURANCE_PATCH"
    git -C "$LUS" apply --index "$INSURANCE_PATCH"
    reconstructed_tree="$(git -C "$LUS" write-tree)"
    if [ "$reconstructed_tree" != "$LUS_PIN_TREE" ]; then
        echo "Reconstructed LUS tree does not match the pinned tree." >&2
        echo "Expected: $LUS_PIN_TREE" >&2
        echo "Actual:   $reconstructed_tree" >&2
        exit 1
    fi
    git -C "$LUS" restore --staged -- .
    git -C "$LUS" diff --check
fi

clone_if_missing "$TORCH_REPOSITORY" "$TORCH" "Torch"
echo "==> Checking out Torch $TORCH_PIN..."
checkout_pin "$TORCH" "$TORCH_PIN" "Torch"

for input_tree in "$STARSHIP" "$LUS" "$TORCH"; do
    if [ "$(git -C "$input_tree" remote get-url --push origin)" != "$DISABLED_PUSH_URL" ]; then
        echo "Push URL was not disabled for $input_tree" >&2
        exit 1
    fi
done

echo
echo "Pinned source inputs are ready:"
echo "  Starship:     $(git -C "$STARSHIP" rev-parse HEAD)"
echo "  libultraship: $(git -C "$LUS" rev-parse HEAD)"
echo "  Torch:        $(git -C "$TORCH" rev-parse HEAD)"
echo "All upstream push URLs: $DISABLED_PUSH_URL"
