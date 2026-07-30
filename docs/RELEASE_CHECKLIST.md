# StarshipPad release checklist

This is the final gate for a public source snapshot or downloadable IPA.

## Every public source update

- [ ] `scripts/check-repo-safety.sh` passes.
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

## Before publishing an unsigned preview IPA

- [ ] Build from a clean checkout at the preview tag.
- [ ] `scripts/build-ios.sh --device` produces an unsigned arm64 app.
- [ ] `scripts/package-ios.sh` accepts the app and records the IPA SHA-256.
- [ ] `REQUIRE_SIGNED=1 scripts/package-ios.sh` rejects the same app.
- [ ] Confirm the IPA and its bundled `starship.o2r` contain no ROM,
      ROM-derived archive, extracted asset, or signing material.
- [ ] Confirm the app contains StarshipPad's `LICENSE`,
      `THIRD_PARTY_NOTICES.md`, and the complete Apache 2.0 license text.
- [ ] Confirm bundle version, build number, and identifier are deliberate and
      no local build path appears in the executable.
- [ ] Publish the checksum beside the IPA.
- [ ] State prominently that the artifact is ROM-free, unsigned, and requires
      the user to supply both signing and legally acquired game data.

## Before publishing a signed, installable IPA

- [ ] Build from a clean checkout at a tagged commit.
- [ ] Use a deliberate distribution bundle identifier and fresh signing
      identity/profile.
- [ ] `REQUIRE_SIGNED=1 scripts/package-ios.sh` passes on the exact app being
      distributed.
- [ ] Record the tag, commit, Xcode version, SDK, bundle version, signing type,
      IPA SHA-256, and supported device/OS range in the release notes.
- [ ] Install the packaged IPA on clean physical hardware.
- [ ] Import and extract a supported `.z64` and byteswapped `.v64` through
      Files, then prove relaunch without re-extraction.
- [ ] Exercise the regional Voice Pack route with a legally acquired supported
      JP, EU/Spanish, or CN ROM.
- [ ] Play through the full touch-only action matrix.
- [ ] Complete the lifecycle, save, speaker/audio-interruption, and physical
      controller/reconnect/rumble matrix.
- [ ] Confirm the IPA contains only the ROM-free `starship.o2r`; it must never
      contain the user's ROM or generated `sf64*.o2r`.
- [ ] Publish known limitations, installation/signing requirements, and a
      rollback path.

## Current blockers

- Development-signed builds have been installed and launched on a physical
  iPhone 14 and 12.9-inch iPad Pro, but no redistributable signing
  identity/profile is available for a public installable package.
- Physical-device speaker and interruption behavior remain untested.
- Physical controller pairing, reconnect, and rumble remain untested.
- End-to-end regional Voice Pack extraction needs a lawful regional input.

Until those gates are resolved, describe StarshipPad as a source preview with
an audited unsigned preview IPA—not a finished installable binary release.

## When changing repository visibility to public

- [ ] Require full commit-SHA pins for GitHub Actions.
- [ ] Enable private vulnerability reporting.
- [ ] Enable available default-branch protections after the repository plan
      supports them.
- [ ] Verify the repository description leads with Starship/StarshipPad, not
      the supported game title.
