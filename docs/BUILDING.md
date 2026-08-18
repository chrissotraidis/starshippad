# Building StarshipPad for iOS and iPadOS

StarshipPad builds only from this repository. Starship, LibUltraShip, and
Torch are pinned, disposable source inputs; the scripts disable their push
URLs and never publish changes to them.

## Requirements

- macOS with Xcode and its command-line tools
- Homebrew
- iOS/iPadOS 16 or later
- a legally acquired supported Star Fox 64 ROM for first-run extraction
- for physical-device installation: an Apple ID configured in Xcode, a unique
  bundle identifier, and a registered iPhone or iPad

Install the host tools and libraries used to generate the ROM-free port
archive:

```sh
brew install cmake ninja pkgconf sdl2 glew nlohmann-json libzip \
  tinyxml2 libogg libvorbis
```

ROMs and ROM-derived archives belong only in ignored local storage such as
`ref/` or the app's Files-visible Documents folder. Never add them to Git,
`starship.o2r`, an app bundle, or an IPA.

## One-command build

From a clean checkout, optionally place one legally acquired supported ROM
under ignored `ref/` for later import:

```sh
git clone https://github.com/chrissotraidis/starshippad.git
cd starshippad
cp "/path/to/your-supported-sf64-rom.v64" ref/

scripts/build-ios.sh --simulator
```

The ROM is not a compile input. The wrapper fetches and verifies every pinned
source revision, disables upstream push URLs, applies the maintained patches,
generates and audits the ROM-free `starship.o2r`, and builds the app.

Use the unsigned generic-device build for compile and package proof:

```sh
scripts/build-ios.sh --device
scripts/package-ios.sh
```

The generated `artifacts/StarshipPad-2.0.0-unsigned.ipa` is intentionally not
installable on a standard device. `REQUIRE_SIGNED=1 scripts/package-ios.sh`
must reject it.

## Individual build steps

The wrapper is equivalent to:

```sh
scripts/clone-sources.sh
scripts/apply-source-patches.sh
scripts/generate-port-archive.sh
scripts/configure-ios.sh
cmake --build build-ios --target Starship --config Release -- \
  -destination generic/platform=iOS \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
scripts/audit-ios-app.sh
```

For an arm64 Simulator product:

```sh
IOS_PLATFORM=SIMULATORARM64 scripts/configure-ios.sh
cmake --build build-ios-sim --target Starship --config Release -- \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

Products are written to:

- `build-ios/Release-iphoneos/StarshipPad.app`
- `build-ios-sim/Release-iphonesimulator/StarshipPad.app`

## First run

Install the Simulator app through Xcode or `simctl`. Keep StarshipPad open,
switch to Files, and copy any supported `.z64`, `.v64`, or `.n64` file—under
any filename—to:

- `On My iPhone > StarshipPad`, or
- `On My iPad > StarshipPad`.

Return to StarshipPad and choose **Rescan**. Extraction runs on a worker while
the setup view stays responsive. The generated `sf64.o2r` remains inside the
app container and is reused on later launches.

US ROMs produce the base archive. Supported Japanese, European, Spanish, and
Chinese ROMs route to the regional Voice Pack path. The settings action is
available under **Settings > Language > Voice Pack**. It scans only for a
supported regional ROM, keeps the game responsive while extracting, and asks
for a restart when the pack is ready. A US ROM is never re-extracted by this
action. Never copy a generated `sf64*.o2r` back into this repository.

## Sign for a physical device

Find the 10-character development-team identifier shown for your Apple ID in
Xcode, choose a bundle identifier you control, then build:

```sh
DEVELOPMENT_TEAM=ABCDE12345 \
BUNDLE_ID=com.yourname.starshippad \
scripts/build-ios.sh --device

REQUIRE_SIGNED=1 scripts/package-ios.sh
```

If automatic signing needs to register the device or create a profile, open
`build-ios/Starship.xcodeproj`, select the Starship scheme and the device,
confirm the team under Signing & Capabilities, and build once. A free personal
team is suitable for local testing but has shorter provisioning validity.

`REQUIRE_SIGNED=1` refuses a Simulator product, an invalid signature, missing
provisioning, stale signing material, ROM data, generated `sf64*.o2r`, or a
`starship.o2r` containing prohibited inputs.

## Touch controls

Touch controls are enabled by default. The HarkinianPad-derived low-grip
layout keeps the stick, D-pad, and Z shoulder under the left hand and the
R/Pause, face-button, and C-action groups under the right. Empty overlay space
passes through to the game. Every gameplay target is at least 44 points. The
persistent **•••** button opens the menu; opening it cancels held input and
hides gameplay controls, and closing it restores them.

| Touch control | Star Fox action | Diagnostic keyboard binding |
|---|---|---|
| Stick | Flight/menu stick | W/A/S/D |
| Fire | Fire/charge | X |
| Bomb | Bomb | C |
| Z / R | Bank left/right and barrel roll | Z / R |
| Boost / Brake | Boost / brake | Arrow Left / Arrow Down |
| View / Talk | Camera / C-Right answer | Arrow Up / Arrow Right |
| Pause | Start/pause | Space or Return |
| D-pad | Four D-pad directions | T/G/F/H |
| Menu | Starship menu | F1 |

Under **Settings > Controller**:

- **Touch Controls** enables or disables the overlay without a restart.
- **Analog Touch** uses the SDL virtual-controller path; disabling it keeps
  the complete eight-way keyboard fallback.
- **Invert Flight Y Axis** is persisted in the app configuration.

When an SDL-compatible physical controller connects, it takes Player 1
priority and the virtual analog-touch controller is suspended. The visible
touch buttons remain usable through their keyboard fallback. Disconnecting
the physical controller restores analog touch automatically.

Touch-only mission verification must cover fire, charged fire, bomb, boost,
brake, both banks, double-tap barrel roll, boost plus stick-down somersault,
brake plus stick-down all-range U-turn, Talk/C-Right, pause, and menu behavior.
The exact geometry, duplicate reachable Z, accessibility actions, and
Simulator-versus-hardware boundary are documented in
[`touch-controls-design.md`](touch-controls-design.md).

## Physical controller and lifecycle protocol

Run the deterministic ownership regression before hardware testing:

```sh
scripts/test-controller-reconnect.sh
```

It simulates a missed removal while button and axis input is held, stale-handle
release and neutral input, Player 1 reclaim, additional-controller Player 2
assignment, two-controller preservation, virtual-touch takeover, and
foreground reconciliation against the patched LibUltraShip SDL2 manager.

Pair an iOS-supported MFi, Xbox, or PlayStation extended gamepad before
launch. For Simulator diagnostics, connect it to the Mac and enable
**I/O > Input > Send Game Controller to Device**. Simulator forwarding is not
physical-device evidence.

Record the exact controller model, connection, device, and OS, then verify:

1. menu navigation, flight input, buttons, pause, and C-Right;
2. disconnect/reconnect without a crash or lost save;
3. rumble as works, unsupported, or not exposed for that model;
4. three background/foreground cycles during gameplay on one PID;
5. no simulation advance while backgrounded;
6. an immediate save survives background, termination, and cold relaunch;
7. speaker, headphones/Bluetooth, and a real audio interruption.

Build and device-launch proof does not close the controller gate. A physical
controller model still needs the protocol above before its gameplay,
reconnect, and rumble behavior can be called verified; see
[`remaining-work.md`](remaining-work.md).
