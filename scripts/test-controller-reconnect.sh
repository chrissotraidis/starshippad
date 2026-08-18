#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/sources/Starship/libultraship/src"
TEST_ROOT="$ROOT/tests/controller-reconnect"
OUTPUT="$(mktemp /tmp/starshippad-controller-reconnect.XXXXXX)"
trap 'rm -f "$OUTPUT"' EXIT

if [ ! -f "$SOURCE/controller/physicaldevice/ConnectedPhysicalDeviceManager.cpp" ]; then
    echo "Missing patched source inputs. Run scripts/clone-sources.sh and scripts/apply-source-patches.sh first." >&2
    exit 1
fi

"${CXX:-clang++}" -std=c++20 -Wall -Wextra -Werror \
    -I"$TEST_ROOT" -I"$SOURCE" \
    "$TEST_ROOT/controller_manager_test.cpp" \
    "$SOURCE/controller/physicaldevice/ConnectedPhysicalDeviceManager.cpp" \
    -o "$OUTPUT"

"$OUTPUT"
