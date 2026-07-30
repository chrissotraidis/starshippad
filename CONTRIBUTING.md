# Contributing to StarshipPad

StarshipPad accepts focused changes that preserve its reproducible,
ROM-free iOS build.

By submitting a contribution, you agree to license it under the repository's
MIT license.

Before opening a pull request:

1. Start from the current `main`.
2. Keep changes in this repository. Upstream Starship, LibUltraShip, Torch,
   their forks, and their pull requests are read-only inputs.
3. Never add a ROM, extracted Nintendo asset, `sf64*.o2r`, `.otr`, `.ipa`,
   signing credential, or provisioning profile.
4. Keep `ENABLE_SCRIPTING` disabled.
5. Make the smallest maintainable correction for a reproduced failure.
6. Update `docs/remaining-work.md` with the exact tested boundary.
7. Run:

   ```sh
   scripts/check-repo-safety.sh
   git diff --check
   ```

Touch changes must be exercised in an iPad Simulator and must preserve menu
cancellation, Touch Controls toggle recovery, Analog Touch fallback, and all
Star Fox action bindings. Simulator results must not be described as
physical-device results.

Bug reports should include the StarshipPad commit, iOS/iPadOS version, device
or Simulator model, exact input format and region without attaching the ROM,
reproduction steps, and relevant logs with personal paths or identifiers
removed.
