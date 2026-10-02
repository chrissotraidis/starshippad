# StarshipPad release checklist

Public releases are source only. `padmint.json` sets `public_binaries: false`.
Personal app/IPA builds are local validation outputs, not public assets.

AGENTS.md pauses all public releases and download links until this repository
is verified **Clear** in the maintainer's private release audit. Owner approval
and the mandatory local artifact gate are required; drafting this checklist
or obtaining a heuristic gate PASS does not provide rights clearance.

## Every public source update

- [ ] Private release audit is verified Clear and owner approves publication.
- [ ] The final release tag resolves to the reviewed immutable source commit.
- [ ] Tag, release name and `version.json` agree on the version; build number
      advances deliberately. Configuration and app audit read `version.json`.
- [ ] Release assets contain only the versioned PadMint recipe and matching
      SHA256SUMS, never a full app/IPA or other compiled game binary.
- [ ] Versioned recipe is byte-identical to tracked `padmint.json`, parses
      with the actual packaged PadMint, and retains `public_binaries: false`.
- [ ] Every exact final asset and source archive passes
      `python3 ~/.codex/release-gate/release_gate.py <artifact>`.
      Any failure stops publication. Recheck after any artifact/source change.
- [ ] `scripts/check-repo-safety.sh` passes.
- [ ] `scripts/test-controller-reconnect.sh` passes.
- [ ] The three pinned source revisions replay without manual edits.
- [ ] All maintained patches apply, pass `git diff --check`, and
      reverse-apply from the exact pins.
- [ ] `scripts/build-ios.sh --device` produces the unsigned arm64 app.
- [ ] `scripts/package-ios.sh` accepts that app.
- [ ] `REQUIRE_SIGNED=1 scripts/package-ios.sh` rejects the unsigned app.
- [ ] `starship.o2r` exactly matches the tracked upstream `port/` manifest.
- [ ] README setup steps and status match the current interface and evidence.
- [ ] No ROM, `sf64*.o2r`, `.otr`, extracted Nintendo asset, signing material,
      signed app, or IPA appears in the current tree or Git history.
- [ ] Remaining physical-device limitations are stated plainly.

## Proposed v0.2.1 source-only successor (not published)

- `version.json`: 0.2.1 / build 7.
- Staged assets: `releases/v0.2.1/StarshipPad-v0.2.1-padmint.json` and
  `releases/v0.2.1/SHA256SUMS`. The recipe commands/schema are unchanged.
- Depends on reviewed SDK repair #20. Do not tag source that lacks that fix.
- Preserve published v0.2.0 assets, checksums and player caches unchanged.
- The tested SDK candidate was `731addea90a4acfeb77cbe191f3e1bd025426a66`
  with 0.2.0/build 6 metadata. Its complete packaged PadMint 0.2.8 build and
  hosted CI passed; this is not a new 0.2.1 app/runtime acceptance claim.
- After approved source publication, independently run actual packaged
  PadMint 0.2.8 `make starshippad ios --jobs 1`. Record selected tag, resolved
  source commit, cache identity and all pipeline stages. Until then, the
  default published-player route remains unverified against the repair.
- For explicit candidate source, use supported generic `build --repo ...
  --revision <reviewed-full-commit> --target ios --jobs 1`; `make` has no
  supported explicit-revision flag.

## Current blockers

- Private-audit Clear status and publication approval must be verified.
- Full app/IPA publication is prohibited by the current source-only policy,
  independent of signing. The SDK candidate's personal IPA also fails the
  public-content heuristic gate; ordinary app audit PASS is not clearance.
- Physical-device speaker and interruption behavior remain untested.
- Physical controller pairing, reconnect, and rumble remain untested.
- End-to-end regional Voice Pack extraction needs a lawful regional input.

Describe StarshipPad as an experimental source preview with user-local
builds, not a finished or publicly distributed installable binary release.
SDK/build proof is not runtime or physical-device acceptance. Keep the
existing hardware/input/voice acceptance matrix separate from source-only
publication and do not infer its completion from CI.

## When changing repository visibility to public

- [ ] Require full commit-SHA pins for GitHub Actions.
- [ ] Enable private vulnerability reporting.
- [ ] Enable available default-branch protections after the repository plan
      supports them.
- [ ] Verify the repository description leads with Starship/StarshipPad, not
      the supported game title.
