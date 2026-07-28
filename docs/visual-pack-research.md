# Optional visual-pack research

Status: research note only<br>
Last checked: 2026-07-28

This is not a committed release feature. It records the current options and
constraints so the idea can be revisited without repeating the initial
research.

## What Starship already supports

Upstream Starship loads custom `.o2r` and `.otr` archives from its `mods`
directory. StarshipPad currently maps that to the Files-visible app container
and recursively loads matching archives under `Documents/mods` at startup.

The existing **Settings > Graphics > Enable Alternative Assets** control
switches resources stored with Starship's `alt/` path prefix. It does not
disable ordinary replacement resources that use the original asset paths.

Upstream reference:

- <https://github.com/HarbourMasters/Starship#custom-assets>

## Current full-pack candidate

[LR2EB Preview 2 + Models][lr2eb] is the only full Starship visual overhaul
found in the current Thunderstore Starship catalog.

- Package: `LR2EB-LR2EB_Preview_2_plus_Models-0.0.2`
- Published: 2025-03-16
- Download size: 64,788,631 bytes
- Expanded archive contents: approximately 251 MB
- Download SHA-256 when checked:
  `d8f1e5999d7cccb18ba75107f14c9643208b79f37df63d0d5a049308d1027ae6`
- Format: eight Starship `.o2r` archives plus documentation and metadata
- Coverage includes menus, text, HUD, Arwing, sky objects, Corneria textures,
  character heads, Great Fox elements, and several models.

The package is explicitly a work-in-progress preview. Its own documentation
lists visual defects and warns that the Corneria tree models can cause major
interpolation-related performance loss. The author also states that this
release is not toggleable. Inspection confirms that most replacements use
ordinary asset paths; only the optional HD boost-dial archive uses `alt/`
paths.

The published ZIP contains no license file, and its manifest provides no
project website or source repository. It also says that some textures came
from the earlier Lylat Reloaded project. Do not bundle, mirror, modify, or add
an in-app direct-download integration without explicit permission and
attribution terms from the relevant creators.

[lr2eb]: https://thunderstore.io/c/starship/p/LR2EB/LR2EB_Preview_2_plus_Models/

## Other results

- [Faithful HD Reticle][reticle] is a small Starship-native texture
  replacement, not a complete visual pack.
- [UnaidedCoder's Star Fox 64 high-resolution pack][rice-pack] is an older
  Rice-emulator-format pack. It is not directly usable as a Starship `.o2r`
  archive.

[reticle]: https://gamebanana.com/mods/681790
[rice-pack]: https://www.n64textures.com/downloads/?lang=en

## Sensible experiment if revisited

Keep the first experiment local and reversible:

1. Obtain creator permission or treat the package strictly as a user-supplied
   local mod.
2. Import the archives through Files rather than bundling them with
   StarshipPad.
3. Start with texture-only content. Exclude `ast_corneria.o2r` and the other
   model archives until the basic pack is stable.
4. Test on the physical iPad at the 60 FPS and 4x MSAA baseline across
   Corneria, Macbeth, Aquas, Venom, menus, background/foreground cycles, and a
   cold relaunch.
5. Record memory use, sustained frame pacing, storage growth, load time, and
   crash/CPU reports.

If a properly `alt/`-prefixed and licensed pack becomes available, a small
Visual Packs menu could download or import a versioned package, verify its
size and SHA-256, show attribution and WIP warnings, and use Starship's native
Alternative Assets control.

If only the current non-toggleable format is available, the simplest safe
design would move its archives between an inactive directory and
`Documents/mods`, then require a restart. It should not pretend to support a
live toggle.

## Decision gate

Do not implement the feature until all of these are true:

- redistribution or direct-download permission is clear;
- the selected pack has stable versioning and integrity metadata;
- enable and disable behavior is honest and reversible;
- the original assets remain available without reinstalling the app;
- physical-iPad performance and lifecycle testing passes; and
- no proprietary pack content enters this Git repository or the app bundle.
