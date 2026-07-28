# StarshipPad future work

This document holds scoped follow-up ideas that are not part of the currently
validated StarshipPad baseline. Do not describe an item here as working until
its implementation, tests, and relevant Simulator or hardware gate have
passed.

## Voice Pack installation

StarshipPad already distinguishes the supported US base-game route from the
regional voice routes. A future settings workflow should make regional Voice
Pack installation clearer and safer:

- add **Settings → Language → Voice Pack** as the explicit entry point;
- scan only for a supported JP, EU, Spanish, or CN ROM in the Files-visible
  StarshipPad folder;
- never rebuild the US base archive from this action;
- keep rendering responsive while extraction runs;
- report missing, unsupported, successful, and failed inputs clearly;
- require a restart only after a valid regional archive is ready; and
- cover the route selection and background task with focused regression tests.

## Physical-controller handoff

The existing SDL and Apple controller paths still need a deliberate handoff
between touch analog input and a connected physical controller:

- give a connected SDL-compatible controller Player 1 analog priority;
- suspend only the virtual analog-touch controller, keeping touch buttons
  available as a fallback;
- restore analog touch automatically after disconnect;
- avoid duplicate controller events during reconnect; and
- verify gameplay, reconnect, rumble, and menu navigation on named MFi, Xbox,
  and PlayStation controller models.

Simulator or source-level proof does not close the physical-controller gate.

## Optional visual packs

Starship can load user-supplied replacement archives from its `mods`
directory, but StarshipPad should not bundle or download a third-party visual
pack until redistribution, attribution, versioning, integrity, reversibility,
and physical-iPad performance are all clear.

The current candidates and constraints are recorded in
[`visual-pack-research.md`](visual-pack-research.md). The smallest safe first
experiment is a local, user-supplied, texture-only pack imported through
Files, with model archives excluded until performance is measured.

## Promotion gate

Move an item from this document into the README's current-feature sections
only after:

1. the focused implementation and regression tests are committed;
2. the maintained upstream patch replays cleanly;
3. the relevant build, Simulator, package, and repository-safety checks pass;
4. physical behavior is labeled honestly where hardware testing remains open;
   and
5. `docs/remaining-work.md` records the exact evidence and remaining boundary.
