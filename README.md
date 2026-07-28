# StarshipPad

Star Fox 64 through HarbourMasters/Starship, built as a native iPhone and iPad
application with Metal rendering, Files-based on-device extraction, touch
flight controls, and physical-controller support.

StarshipPad is a source preview. The complete Simulator matrix and unsigned
iPhoneOS build/package gate pass; physical-device signing, speaker audio, and
controller/rumble validation remain open and are recorded explicitly in
[`docs/remaining-work.md`](docs/remaining-work.md).

## What works

- Native arm64 iOS/iPadOS 16+ app using Metal
- iPhone and iPad landscape layouts with safe-area-aware menus
- Files import for supported `.z64`, `.v64`, and `.n64` files under any name
- Responsive on-device Torch extraction with cached relaunch
- Regional JP/EU/Spanish/CN Voice Pack routing
- Touch-only fire, charge, bomb, boost, brake, banks, barrel roll,
  somersault, U-turn, wingman answer, pause, D-pad, and menu controls
- Analog virtual touch controller with a live eight-way fallback
- Lifecycle pause, config flush, and save persistence on Simulator
- Reproducible ROM-free unsigned IPA packaging and repository/history audits

## Build

You need macOS, Xcode, Homebrew, and a legally acquired supported Star Fox 64
ROM for first run. The ROM is never a compile input.

```sh
brew install cmake ninja pkgconf sdl2 glew nlohmann-json libzip \
  tinyxml2 libogg libvorbis

git clone https://github.com/chrissotraidis/starshippad.git
cd starshippad
scripts/build-ios.sh --simulator
```

For the unsigned device and packaging proof:

```sh
scripts/build-ios.sh --device
scripts/package-ios.sh
```

The IPA under ignored `artifacts/` is deliberately unsigned and not
installable on a standard device. Personal-device signing instructions,
first-run import, touch bindings, and the full test protocol are in
[`docs/BUILDING.md`](docs/BUILDING.md).

## Bring your own game

StarshipPad does not include a ROM, extracted Nintendo assets, or a generated
`sf64.o2r`. Keep the app open, use Files to copy a legally acquired supported
ROM to `On My iPhone/iPad > StarshipPad`, return to the app, and choose
**Rescan**. Extraction stays in the app container.

The bundled `starship.o2r` is different: it contains only the ROM-free,
tracked Starship `port/` files. The build verifies its exact manifest and
contents before packaging.

## Reproducibility and safety

Starship, LibUltraShip, and Torch are frozen inputs with disabled push URLs.
All project changes live here as scripts, maintained patches, iOS sources,
documentation, and CI. `ENABLE_SCRIPTING` remains off.

```sh
scripts/check-repo-safety.sh
```

That gate audits the current tree and full Git history for ROMs, derived
archives, packages, signing material, oversized files, likely credentials,
invalid scripts, and malformed patches. The release checklist is
[`docs/RELEASE_CHECKLIST.md`](docs/RELEASE_CHECKLIST.md); the exact permissive
iOS link closure is [`docs/LICENSES.md`](docs/LICENSES.md).

## Project boundaries

StarshipPad is independent of Nintendo and is not endorsed by Nintendo,
HarbourMasters, Starship, LibUltraShip, or Torch. Upstream projects are
read-only source inputs. Do not report StarshipPad-specific issues to those
projects or push StarshipPad changes to their repositories.

StarshipPad-owned work is MIT licensed. Upstream and third-party components
retain their own licenses.
