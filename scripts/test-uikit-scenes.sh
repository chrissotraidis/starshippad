#!/usr/bin/env bash
# Offline regression checks using locally populated pinned inputs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$ROOT/tests/uikit-scenes/test_patch_replay.py"
