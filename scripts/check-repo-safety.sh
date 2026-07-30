#!/usr/bin/env bash
# ROM-free repository gate for local checks and CI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() {
    echo "Repository safety check failed: $*" >&2
    exit 1
}

current_files="$(git ls-files --cached --others --exclude-standard | sort -u)"

tracked_reference_files="$(printf '%s\n' "$current_files" | grep '^ref/' || true)"
if [ -n "$tracked_reference_files" ]; then
    printf '%s\n' "$tracked_reference_files" >&2
    fail "ref/ is local-only and must not contain tracked files"
fi

forbidden_extensions='\.(z64|n64|v64|rom|o2r|otr|mpq|ipa|xcarchive|mobileprovision|provisionprofile|p12|p8|pem|key)(/|$)'
forbidden_names='(^|/)(baserom[^/]*|sf64[^/]*\.o2r)(/|$)'
forbidden_current="$(printf '%s\n' "$current_files" |
    grep -Ei "$forbidden_extensions|$forbidden_names|(^|/)[^/]+\.app/" || true)"
if [ -n "$forbidden_current" ]; then
    printf '%s\n' "$forbidden_current" >&2
    fail "proprietary, generated, packaged, or signing material is tracked"
fi

history_paths="$(git rev-list --objects --all |
    awk 'NF > 1 { sub(/^[^ ]+ /, ""); print }')"
forbidden_history="$(printf '%s\n' "$history_paths" |
    grep -Ei "$forbidden_extensions|$forbidden_names|(^|/)[^/]+\.app/|^ref/" || true)"
if [ -n "$forbidden_history" ]; then
    printf '%s\n' "$forbidden_history" >&2
    fail "proprietary, generated, packaged, signing, or reference material exists in Git history"
fi

while IFS= read -r file; do
    [ -f "$file" ] || continue
    size="$(wc -c < "$file")"
    if [ "$size" -gt 5242880 ]; then
        echo "$file ($size bytes)" >&2
        fail "tracked file exceeds the 5 MiB review limit"
    fi
done < <(printf '%s\n' "$current_files")

credential_pattern='(-----BEGIN [A-Z ]*PRIVATE KEY-----|github_pat_[A-Za-z0-9_]{20,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})'
credential_hits=""
while IFS= read -r file; do
    [ -f "$file" ] || continue
    matches="$(grep -nEI "$credential_pattern" "$file" 2>/dev/null || true)"
    if [ -n "$matches" ]; then
        credential_hits="${credential_hits}${file}:${matches}"$'\n'
    fi
done < <(printf '%s\n' "$current_files")
if [ -n "$credential_hits" ]; then
    printf '%s' "$credential_hits" >&2
    fail "a likely credential or private key exists in the current tree"
fi

for notice in LICENSE THIRD_PARTY_NOTICES.md LICENSE-APACHE-2.0.txt \
    docs/ASSET_AND_TRADEMARK_NOTICE.md; do
    printf '%s\n' "$current_files" | grep -Fxq "$notice" ||
        fail "required distribution notice is missing: $notice"
done

workflow_uses="$(grep -RhoE 'uses:[[:space:]]+[^[:space:]#]+' .github/workflows 2>/dev/null || true)"
mutable_workflow_uses="$(printf '%s\n' "$workflow_uses" |
    grep -Ev 'uses:[[:space:]]+[^@[:space:]]+@[0-9a-f]{40}$' || true)"
if [ -n "$mutable_workflow_uses" ]; then
    printf '%s\n' "$mutable_workflow_uses" >&2
    fail "GitHub Actions must be pinned to full commit SHAs"
fi

mutable_added_cmake_tags="$(grep -hE '^\+.*GIT_TAG' patches/*.patch |
    grep -Ev 'GIT_TAG[[:space:]]+[0-9a-f]{40}([[:space:]]|$)' || true)"
if [ -n "$mutable_added_cmake_tags" ]; then
    printf '%s\n' "$mutable_added_cmake_tags" >&2
    fail "added CMake dependencies must be pinned to full commit SHAs"
fi

bash -n scripts/*.sh
for script in scripts/*.sh; do
    [ -x "$script" ] || fail "$script is not executable"
done

for patch in patches/*.patch; do
    [ -f "$patch" ] || continue
    git apply --numstat "$patch" >/dev/null ||
        fail "$patch is not a syntactically valid patch"
done

git fsck --full --strict --no-dangling

echo "Repository safety checks passed."
