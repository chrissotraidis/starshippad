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

## Before publishing a downloadable IPA

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

- No physical iPhone or iPad is connected to the development machine.
- No signing team/profile is available for an installable package.
- Physical-device speaker and interruption behavior remain untested.
- Physical controller pairing, reconnect, and rumble remain untested.
- End-to-end regional Voice Pack extraction needs a lawful regional input.

Until those gates are resolved, describe StarshipPad as a source preview with
an audited unsigned reproducibility artifact—not a finished binary release.
