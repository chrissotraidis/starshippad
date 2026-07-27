#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_root="$repo_root/sources/Starship"
test_source="$repo_root/scripts/tests/verify_phase4_routes.cpp"
test_binary="${TMPDIR:-/tmp}/starshippad-verify-phase4-routes"

if [ ! -f "$source_root/src/port/extractor/GameExtractorRoutes.h" ]; then
  echo "error: patched Starship sources are missing; run scripts/clone-sources.sh and scripts/apply-source-patches.sh" >&2
  exit 1
fi

sdk_path=$(xcrun --sdk macosx --show-sdk-path)
xcrun --sdk macosx clang++ -std=c++20 -Wall -Wextra -Werror \
  -isysroot "$sdk_path" -I"$source_root" "$test_source" -o "$test_binary"
"$test_binary"
