# StarshipPad — Implementation Plan

**Star Fox 64 (HarbourMasters/Starship) as a native iOS/iPadOS application.**

Research window: 2026-07-27 → 2026-07-28. Every load-bearing claim in this document was verified
against source — either the local `ref/harkinianpad/` tree, or fresh clones made during this
investigation. Citations are written `repo:path:line`, where `repo` is one of the trees in the
table below. Where something could not be determined, it says **unknown** and names what would
resolve it. Effort sizes are **estimates** throughout and are labeled as such.

## Trees examined

| Label | Repo | Revision | Notes |
|---|---|---|---|
| `S` | HarbourMasters/Starship | `6202c443` (main, 2026-06-15, "test: trigger CI") | the game/port |
| `LUSpin` | Kenix3/libultraship | `eaaf9d0fc91e2c400f49ef2a1f8547a691ce4d3c` | Starship's submodule pin (see Corrections C1) |
| `LUSpm` | Kenix3/libultraship | `f57f4d25` (`port-maintenance`, 2026-07-26) | what HarkinianPad builds against (via Shipwright pin `c57da1b4`) |
| `T` | HarbourMasters/Torch | `cd92cc0f` (Starship's `tools/Torch` pin, 2025-08-02) | asset extractor |
| `HP` | ref/harkinianpad | working tree in this repo's `ref/` | completed OoT iOS port, same developer |

---

## 1. Conclusions

Stated in order of how much they change the shape of the project.

**1.1 — No hard stop fired. The field is clear.** Nothing resembling a shipped or substantially
built Starship iOS/iPadOS port exists anywhere public. All 135 forks of HarbourMasters/Starship
were enumerated: zero iOS forks, zero iOS PRs or issues in the upstream repo, no `.ipa` in any
release, no AltStore/SideStore source references, nothing on Reddit/YouTube. The closest mobile
prior art is `izzy2lost/Starship` — an **Android** port with released APKs (latest v1.0.3,
2025-11-16) — which is a useful reference input, not competition on this platform. The only
in-tree iOS trace in Starship is KiritoDv's dormant, broken 2024 scaffolding (§3.1). StarshipPad
would be first.

**1.2 — No ROM or Nintendo content is ever required in the repository** (hard stop 2 passes), and
**no runtime code generation exists anywhere in the stack** (hard stop 3 passes). Direct grep of
Starship `src/`+`include/` and Torch `src/`+`lib/` for `PROT_EXEC|MAP_JIT|mprotect|VirtualProtect|
asmjit|xbyak|dynarec` returned zero hits; the only `LoadLibraryA` is in the vendored
Windows-only `portable-file-dialogs.h` (`S:include/portable-file-dialogs.h:208,801`), which is
already excluded on iOS (`S:src/port/extractor/GameExtractor.cpp:8-10`). LUS at Starship's pin
predates the TCC scripting subsystem entirely — `ENABLE_SCRIPTING` does not exist at `eaaf9d0`
(it appears only in later port-maintenance). Metal shader compilation at runtime
(`MTLDevice::newLibrary`) is GPU-shader compilation, App-Store-legal, not CPU codegen. Starship's
open scripting-layer PR (#255, unmerged) must simply never be adopted by StarshipPad.

**1.3 — This port is structurally *easier* than HarkinianPad was, on four axes.**

1. **Simpler runtime.** Starship's main loop is a plain blocking `while (WindowIsRunning())
   push_frame();` on the thread that called `main()` (`S:src/port/Game.cpp:45`); there are no
   cooperative fibers (every `osCreateThread` is commented out — `S:src/sys/sys_main.c:360-424`)
   and exactly one port-owned OS thread (audio producer, `S:src/port/Engine.cpp:433-438`). The
   UIKit main-thread story is trivially satisfied.
2. **The asset pipeline is already in-process and already half-aware of iOS.** Torch is linked
   statically into the game executable on every platform (`S:CMakeLists.txt:386-387`), first-run
   extraction runs inside the app on desktop today, and `GameExtractor.cpp` already carries
   `__IOS__` branches (`S:src/port/extractor/GameExtractor.cpp:8,27,35-37`). The "asset pipeline
   does not transfer" concern from the brief is true of the *code* (ZAPD ≠ Torch) but false of
   the *architecture*: Starship already has the exact shape HarkinianPad had to build.
3. **LUS at Starship's pin is closer to iOS-ready than expected.** `eaaf9d0` contains the full
   iOS CMake path (toolchain populate, `ios.cmake` dependency set, signing options, `__IOS__`
   define, Metal-only backend selection, sandbox paths, mobile keyboard shim) — and, decisively,
   **audio at that commit is SDL-only** (`CoreAudioAudioPlayer` does not exist yet;
   `LUSpin:src/audio/` contains only SDL and WASAPI players). SDL-only audio is exactly the end
   state HarkinianPad's iOS patch fights to reach on newer LUS. Seven of HarkinianPad's 37 LUS
   patch hunks are therefore moot at this pin. Exactly one confirmed link-breaker exists: the
   macOS-native-fullscreen calls under bare `__APPLE__` (§3.2).
4. **HarkinianPad solves every remaining platform problem with working, device-proven code**:
   lifecycle/suspend handling, Files-based ROM import UX, ImGui mobile scaling, touch overlay
   component, Info.plist template, packaging audit, repo-safety gates, CI shape, and build
   scripts. Most of it backports mechanically (§4).

**1.4 — Recommended architecture** (details and alternatives in §5):

- **Repo model**: StarshipPad follows the HarkinianPad model exactly — a single publication
  repository containing scripts, patches, docs, and iOS-only source files; Starship, LUS, and
  Torch are pinned, push-disabled, disposable upstream inputs fetched at build time. No forks.
- **LUS version (decision B)**: **Option 2 — backport HarkinianPad's iOS patches onto Starship's
  pinned `eaaf9d0`**, keeping Starship's submodule pin untouched. Zero game-side churn; ~30 of 37
  hunks port with mechanical path/API rewrites; 7 are moot. Bumping to `port-maintenance`
  (option 1) is a genuine porting project (76 `Context::GetInstance()` call sites, a removed
  `WindowBackend` enum, moved audio APIs, ~12 dead include paths) that still requires the same
  iOS patch on top, because upstream port-maintenance *also* lacks lifecycle handling and still
  has the fullscreen link-breaker.
- **Asset extraction (decision D)**: **Option 1 — Torch runs on device**, preserving both
  HarkinianPad's UX and Starship's own desktop UX. Torch is a portable, single-threaded,
  dependency-light C++ static library with no blockers (§3.3); upstream has since even run it
  under Emscripten. The real work is not Torch — it is restructuring Starship's boot-time
  extraction flow, which currently blocks in the `GameEngine` constructor behind SDL message
  boxes *before* the window exists (`S:src/port/Engine.cpp:82-101`), a pattern iOS's watchdog
  will not tolerate.
- **Touch input (decision C)**: HarkinianPad's overlay is game-side, mechanism-generic,
  layout-Ocarina-specific. Port the component, redesign the layout around Star Fox 64's real
  control set (derived from game code in §5.4), and plan a second stage that replaces the 8-way
  keyboard-event stick with a true analog virtual controller — Star Fox 64's aiming is fully
  analog (`S:src/engine/fox_play.c:3981,4005-4006`) and deserves better than WASD emulation.

**1.5 — Upstream health is degraded, and the plan treats it as such.** The `sonicdcer` GitHub
account is gone (404, with a brief restoration in early July 2026 and no public explanation; no
DMCA notice exists in github/dmca), taking the sf64 decompilation root repo with it. Starship's
`main` has been quiet since 2026-06-15; its README still links dead profiles; its `/releases`
list API returns `[]` (though the release objects still resolve individually). Additionally,
**Starship's LUS pin `eaaf9d0` is a dangling commit on no branch** — it is fetchable today only
because GitHub serves unadvertised objects by SHA (§2, C1). StarshipPad must be able to build
even if upstream degrades further: pins, mirrors-by-patch, and no reliance on upstream accepting
contributions. All engine and app changes stay in StarshipPad as replayable patches.

**1.6 — The project is worth doing.** It is first-of-its-kind, the technical risk is
concentrated in already-solved problem classes (HarkinianPad proves the LUS/SDL/Metal/iOS stack
end-to-end on physical hardware), the licensing posture is *cleaner* than HarkinianPad's
(Starship is CC0, Torch MIT, LUS MIT — and unlike Shipwright, Starship actually has a top-level
license), and the one genuinely new engineering artifact (a Star Fox-shaped touch controller
with analog aim) is well-scoped. The countervailing facts — Nintendo's official "Star Fox"
Switch 2 remake shipped 2026-06-25, and the decomp author's account vanished without explanation
— are risks to note (§7), not blockers.

---

## 2. Corrections

Every starting fact found wrong, stale, or materially incomplete, with evidence.

**C1 — The LUS pin's date is wrong, and its lineage is worse than stated.** `eaaf9d0` has
**author date 2025-10-05** but **commit date 2026-03-13** — it was rebased/recreated months
after authorship (`git show -s --format='%ai / %ci' eaaf9d0`). More importantly, "off the `main`
lineage" understates it: `eaaf9d0` is **on no branch of Kenix3/libultraship at all**
(`git branch -r --contains eaaf9d0` → empty; a fresh clone does not contain the object; it must
be fetched by explicit SHA, which GitHub happens to allow). PR #925 ("Fix metal compatibility
with prism", garrettjoecox) was **merged to `main` on 2025-10-06** with head SHA `2956565f` and
main-side squash commit `d1bbd53e` — `eaaf9d0` is a *different* squash of the same change,
parented directly on `09dfab5f`, existing only as a loose object in the repository network. The
#925 content itself **is** on main and (by ancestry) on port-maintenance. Consequence: Starship's
`git submodule update` works today but depends on GitHub never garbage-collecting an
unreferenced object. Mitigation in §7 (R1).

**C2 — The merge-base date is 2025-08-07, not 2025-08-08** (timezone rounding):
`09dfab5f` "obey app directory for default.sav (#908)", 2025-08-07 15:22:58 -0400. The commit
counts check out: main +116, Shipwright's pin `c57da1b4` +127, and current `port-maintenance`
HEAD (`f57f4d25`, 2026-07-26) +129 from that merge-base. One structural note the brief lacks:
`main` is **not** an ancestor of `port-maintenance` (PM carries 15 commits main lacks; main
carries 2 PM lacks).

**C3 — The pinned `ios.cmake` dependency list is broader than stated.** Confirmed: SDL2
`release-2.28.1` (static) and metal-cpp `briaguya-ai/single-header-metal-cpp @ macOS13_iOS16`,
ImGui with `imgui_impl_metal.mm` + `IMGUI_IMPL_METAL_CPP`. Also present and relevant: nlohmann-json
`v3.11.3`, tinyxml2 `10.0.0`, **spdlog `v1.14.1`**, libzip `v1.10.1` — all declared with
`OVERRIDE_FIND_PACKAGE` (`LUSpin:cmake/dependencies/ios.cmake:6-76`). The spdlog entry matters:
Torch in library mode does `find_package(spdlog REQUIRED)` (`T:CMakeLists.txt:236`), and because
LUS's iOS dependency file registers spdlog before `tools/Torch` is added
(`S:CMakeLists.txt:277` vs `:386`), this is expected to resolve for free on iOS (verify at
Phase 2).

**C4 — `copilot/disable-ios-builds-in-ci` has not merged.** The `build-ios` CI job (macos-14,
`-GXcode -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0`) is present and active in
`.github/workflows/build-validation.yml:36-61` on **both** `main` and `port-maintenance`. The
disable branch (head `3c72f790`) is unmerged and stale.

**C5 — Starship's 2024 iOS commit touched more than CMake.** `dc9e2584` "Added IOS Support"
(KiritoDv; authored 2024-04-19, committed 2024-09-17 — five months later than the brief's
2024-04-19, meaning it landed on the tree *after* LUS's own iOS commit, not eight days before)
also: vendored `cmake/ios.toolchain.cmake` in-repo (1,122 lines — leetal's file is copied, not
fetched, unlike LUS's `ios-toolchain-populate.cmake`), and edited `src/port/Game.cpp` to declare
`main` as `extern "C"` under `PLATFORM_IOS` (`S:src/port/Game.cpp:35-38`) — notably **not**
`SDL_main`, which is one of the things StarshipPad must fix.

**C6 — Confirmed as stated, with proof:** the four bundle files (`Launch.storyboard`,
`plist.in`, `Icon.png`, `PoweredBy.png`) have **never existed at any commit on any branch** of
Kenix3/libultraship (`git log --all --diff-filter=A -- 'ios/*'` → empty), so Starship's iOS
target cannot configure. `YOUR_TEAM_ID` and `dev.net64.game` placeholders are unedited at HEAD
(`S:CMakeLists.txt:64-65`). Where those files *should* live is answered in §5.6: the game repo,
per both HarkinianPad's and SpaghettiKart's precedent.

**C7 — ROM acceptance is much broader than "US 1.0 or 1.1", and the MD5 in the brief is
irrelevant to Starship.** The brief's md5 `741a94eee093c4c8684e66b89f8685e8` appears **nowhere**
in Starship or Torch — acceptance is SHA-1-of-ROM-bytes, looked up as a top-level key in
`config.yml` (`T:src/Companion.cpp:1009-1012`, hash via Chocobo1 SHA1 at `:1604-1606`).
Starship's `config.yml` + `GameExtractor` hash table (`S:src/port/extractor/GameExtractor.cpp:12-24`,
`S:config.yml:4-152`) accept **six** ROMs, each in compressed and uncompressed form: US 1.0
(`d8b10885…`), US 1.1 (`09f0d105…`), JP 1.0 (`9bd71afb…`), EU 1.0 (`05b307b8…`), an EU-Spanish
romhack (`e6dad752…`), and iQue/CN 1.1 (`c8a10699…`). US ROMs produce the base `sf64.o2r`;
JP/EU/CN produce voice/mod archives under `mods/` (`S:config.yml` `output.binary` entries). Two
real constraints the README understates: **byte-swapped `.v64`/`.n64` images are rejected**
(no byteswap exists anywhere in either tree — an unknown SHA-1 simply fails), and the existing
mobile code path hardcodes the filename `baserom.us.rev1.z64` (`GameExtractor.cpp:35-37`), i.e.
only US 1.1 is wired on iOS/Android/Switch today.

**C8 — The surviving-fork list is stale.** `theboy181/sf64` is now **404** (the account exists;
the repo is gone). `knowsuchpeace/sf64` exists but is stale (last commit 2025-05-05). The most
active surviving forks of the decomp are **`KiritoDv/sf64`** (2026-07-13 — owned by Lywx,
Starship's co-lead and Torch's author), `inspectredc/sf64` (2026-07-10), `DLDrago/sf64`, and
`petrie911/sf64`. Fork evidence also shows the sonicdcer account was briefly restored around
2026-07-05 (fork merge commits reference `sonicdcer:master` on that date) before vanishing again.

**C9 — The asset-pipeline framing needs inverting.** "Whatever HarkinianPad does for on-device
`.o2r` generation … will not carry over as code" is true, but the plan-relevant fact is the
opposite one: Starship needs *less* here than Shipwright did, because Torch is already an
in-process static library invoked by an in-app extractor with `__IOS__` stubs, and the
SpaghettiKart iOS effort already proved this exact Torch-in-app model on device (§3.5). What
does not transfer is HarkinianPad's ZAPD patch (22 lines, trivial); what transfers fully is the
first-run UX pattern, threading model, and packaging audit.

**C10 — SpaghettiKart's iOS work is partially recoverable, contrary to "repo 404 = lost".**
`Sunset-Dawn/*` is gone (profile, SpaghettiKart, Torch — all 404; the only Wayback snapshot,
2026-07-13, is already a 404). But the code survives: LUS **PR #1056**'s full patch (105 lines
— `ios/Launch.storyboard`, `ios/plist.in`, CoreAudio-on-iPhone avoidance, fullscreen stubs) is
fetchable via its head commit `37923731` from the Kenix3 network; SpaghettiKart **PR #684**'s
full 11-commit, 1,158-line patch (iOS CMake, GameExtractor/ModManager iOS handling, IPA build
docs; PR body confirms a working on-device IPA) is fetchable from the HarbourMasters network;
and **coco875's live branches carry it forward** (`coco875/SpaghettiKart@ios` via open PR #694;
`coco875/libultraship@ios` via open draft PR #1083, head `09426197`). Partial iOS CMake was even
**merged into SpaghettiKart main** on 2026-07-23 (PR #721: `SPAGHETTIKART_IOS`, bundle rules).
Retrieval commands are recorded in §3.5. Notably, the surviving SpaghettiKart approach did **not**
need a Torch fork — Torch builds as-is.

**C11 — Small confirmations.** Starship v2.0.0 "Barnard Alfa" tagged 2025-05-25; main last
commit 2026-06-15 — both confirmed. Nintendo's Switch 2 remake: official title is **"Star Fox"**,
released **2026-06-25** (nintendo.com announcement) — noted in §7 (R8) without commentary.
Supported-platforms claim: v2.0.0 release assets are Windows/Linux/Switch; macOS is built in CI
(`S:.github/workflows/mac.yml`) but not shipped as a release asset — minor nuance to the brief's
platform list. LUS PR #1083 head `09426197` — unchanged since HarkinianPad recorded it in July.

---

## 3. Current state

### 3.1 Starship at `6202c443`

**Build/toolchain.** CMake ≥3.16, C++20/C11, project version 2.0.0, languages `C CXX ASM`
(`S:CMakeLists.txt:1-31`). Game compiled from `src/{audio,engine,overlays,port,sys}` plus four
hand-picked libultra files (`S:CMakeLists.txt:130-154` — `aisetfreq.c`, `sqrtf.c`, `mtxutil.c`,
`ortho.c`); everything else libultra-shaped resolves to LUS bridges. Compile definitions:
`VERSION_US=1 ENABLE_RUMBLE=1 F3DEX_GBI=1 GBI_FLOATS=1 NON_MATCHING=1 NON_EQUIVALENT=1 AVOID_UB=1`
(`S:CMakeLists.txt:100-114`); `USE_NETWORKING` is a plain `set(… OFF)` with zero game-code
consumers (`S:CMakeLists.txt:99`; grep of `src/`+`include/` empty).

**The broken iOS blocks.** `if(IOS)` at `S:CMakeLists.txt:58-66`: `PLATFORM "OS64"`, includes the
vendored `cmake/ios.toolchain.cmake`, defines `PLATFORM_IOS=1`, sets placeholder
`DEVELOPMENT_TEAM "YOUR_TEAM_ID"` and `PROJECT_ID "dev.net64.game"`. Bundle block at
`S:CMakeLists.txt:168-190`: `MACOSX_BUNDLE` with `MACOSX_BUNDLE_INFO_PLIST
${IOS_DIR}/plist.in` and resources from `IOS_DIR = libultraship/ios/` — four files that have
never existed in LUS (C6). Two subtle interactions worth recording: (a) Starship sets
`PLATFORM "OS64"` *before* including the vendored toolchain, but if the LUS-side
`ios-toolchain-populate.cmake` also runs it **hardcodes `OS64COMBINED`**
(`LUSpin:cmake/ios-toolchain-populate.cmake:1`) — HarkinianPad's `if(NOT DEFINED PLATFORM)` guard
hunk resolves this; (b) `CMAKE_OSX_DEPLOYMENT_TARGET "10.15"` (`S:CMakeLists.txt:28`) is a macOS
value that must be overridden for iOS configures.

**Dependencies.** Windows: vcpkg static (`S:CMakeLists.txt:41-46`). Switch/WiiU: console arms.
Everything else — **the arm iOS currently falls into** — requires system `Ogg` and `Vorbis` via
`find_package(... REQUIRED)` with no fallback (`S:CMakeLists.txt:358-368`) → configure fails on
iOS. `dr_libs` and `sse2neon` are fetched (`S:CMakeLists.txt:226-236`; sse2neon from an
**unpinned master URL** — supply-chain nit worth fixing in the patch). Torch is added and linked
into the game with options pre-seeded: `USE_STANDALONE=OFF BUILD_STORMLIB=OFF
BUILD_SM64/MK64/FZERO=OFF` (`S:CMakeLists.txt:380-387`). A separate host-tool copy of Torch is
built via `ExternalProject_Add(TorchExternal)` to drive the desktop `ExtractAssets`
(`torch o2r baserom.z64` → `sf64.o2r`) and `GeneratePortO2R` (`torch pack port starship.o2r o2r`)
targets (`S:CMakeLists.txt:607-641`). `config.yml` + `assets/` are copied next to the binary
post-build (`S:CMakeLists.txt:600-605`). `gamecontrollerdb.txt` is curl'd from an unpinned
master URL (`S:CMakeLists.txt:643-644`).

**Include paths reference the old LUS layout** (`S:CMakeLists.txt:239-275`):
`libultraship/src/graphic/Fast3D/U64/PR`, `src/log`, `src/menu`, `src/public/bridge`, etc. These
exist at `LUSpin` and are gone in `LUSpm` — the concrete face of the version-gap decision (§5.2).

**Runtime shape.** Entry: `SDL_main` on Windows, plain `int main` elsewhere with the
`PLATFORM_IOS` `extern "C"` wart (`S:src/port/Game.cpp:33-38`). Startup: `GameEngine::Create()` →
`Main_SetVIMode` → `Lib_FillScreen` → `Main_Initialize` → `Main_ThreadEntry` (one-shot init:
audio engine, graphics init, controllers, message queues — `S:src/sys/sys_main.c:360-399`) →
`while (WindowIsRunning()) push_frame();` (`S:src/port/Game.cpp:40-49`). `push_frame` runs one
game tick + audio frame bracket (`S:src/port/Game.cpp:23-30`); the SDL event pump runs once per
frame inside `RunCommands` (`S:src/port/Engine.cpp:460`). No fibers. One port thread: the audio
producer (`S:src/port/Engine.cpp:362-438`), pushing 32 kHz s16 PCM through the LUS
`AudioPlayerPlayFrame` bridge with `AudioPlayerBuffered`/`AudioPlayerGetDesiredBuffered`
backpressure (`:383-405`); audio settings `{32000, 1024, 1680, channels}` passed to
`context->Init` (`:170-171`).

**Extraction flow (desktop).** In the `GameEngine` constructor, **before** window/context
creation: if `sf64.o2r` is missing, an SDL message box asks to select a US ROM, `pfd::open_file`
picks a `*.z64`, the whole file is read to memory, SHA-1 checked against the table, and
`Companion::Instance->Init(ExportType::Binary)` runs **synchronously on the boot thread**
(`S:src/port/Engine.cpp:82-101,268-293,558-592`; `S:src/port/extractor/GameExtractor.cpp:27-70`).
A second entry point, ImGui menu "Install JP/EU Audio", also calls `GenAssetFile` synchronously
then closes the window (`S:src/port/ui/ImguiUI.cpp:336-341`). On `__IOS__`/`__ANDROID__`/
`__SWITCH__` the picker is replaced by a hardcoded `GetPathRelativeToAppDirectory
("baserom.us.rev1.z64")` (`GameExtractor.cpp:35-37`).

**Filesystem contract** (all through `Ship::Context`): `sf64.o2r` via
`GetPathRelativeToAppDirectory` (`S:src/port/Engine.cpp:75`); `starship.o2r` via
`LocateFileAcrossAppDirs` (`:76`); `mods/` created and scanned recursively for `.otr/.o2r/.zip`
(`:107-125`); config `starship.cfg.json` (`:67`); saves via `osEeprom*`
(`S:src/sys/sys_save.c`) → LUS `os_eeprom.cpp` → `default.sav` in the app directory (the pin's
parent commit #908 is literally the fix that made that path honor the app directory). The only
cwd-relative I/O in the port layer is a `PIPE_DEBUG`-gated debug dump (`S:src/port/Engine.cpp:363-365`).

**Controls, from game code** (the ground truth for the touch design):
- Full-analog stick with software deadzone ±16, clamp ±60 (`S:src/sys/sys_joybus.c:13-49`);
  on-rails aim `Player_MoveArwingOnRails` (`S:src/engine/fox_play.c:3981,4005-4006`, with a
  `gInvertYAxis` CVar), all-range `Player_MoveArwing360` (`:3757-3760`).
- Defaults set at `S:src/engine/fox_game.c:438-441`: **A = fire/hold-to-charge**
  (`fox_play.c:3340,3373`), **B = smart bomb** (`:3420`), **C-Left = boost**, **C-Down = brake**
  (`gBoostButton`/`gBrakeButton`).
- **Z = bank left, R = bank right** (`Player_ArwingBank`, `fox_play.c:3544-3558`); **double-tap
  Z/R = barrel roll** (`:3574-3597`); Z+R together gates aim/loop variants (`:3350,3834,4079`).
- **Somersault** = press boost, then stick past −50 down within a 5-frame window
  (`fox_play.c:5262-5267, 5147-5163`) — *not* a double-tap. **U-turn** = brake + stick-down, only
  in all-range mode (`:5288-5291, 5276-5296`).
- **C-Up = view toggle** (`:5955-5966`); **C-Right = answer wingman/radio calls**
  (`EVC_PRESS_CRIGHT`, `S:src/engine/fox_enmy2.c:2694-2701`) and request supplies in all-range
  (`S:src/engine/fox_360.c:667-672`); **Start = pause** (`fox_play.c:7173,7196`); map screen uses
  C-Up/C-Right (`S:src/overlays/ovl_menu/fox_map.c:6844,6865`). No gameplay D-pad usage was
  found (see Q5).
- Input plumbing: LUS ControlDeck (`S:src/port/Engine.cpp:132-163` — explicit SDL gamepad
  defaults: A←pad-A, B←pad-X, C-Left←Y/RT, C-Down←B/LT, Z←LB, R←RB, C-Up/C-Right←right stick;
  keyboard maps passed empty, so LUS built-in keyboard defaults apply — X/C/Z/R/E, Space,
  arrows, WASD, `LUSpin:src/controller/.../ControllerDefaultMappings.cpp:53-84`). **Zero touch
  code anywhere in Starship.**
- Rumble: game sets `gControllerRumbleFlags` (dozens of sites, e.g. `fox_play.c:5881-5901`);
  `Controller_Rumble` (`S:src/sys/sys_joybus.c:107-139`) calls `osMotor*`, which resolve to LUS
  (the in-repo `motor.c` is not compiled). LUS's SDL rumble mapping exists at the pin
  (`LUSpin:src/controller/.../SDLRumbleMapping.cpp:21,29` → `SDL_GameControllerRumble`).
- Versus: compiled in (`fox_versus.c` in the glob, not excluded); `osContGetStatus` is stubbed
  true (`sys_joybus.c:63`) so all four player slots always read as plugged.

**GBI:** the port selects the ucode at runtime every frame:
`wnd->SetRendererUCode(UcodeHandlers::ucode_f3dex)` (`S:src/port/Engine.cpp:487`), matching the
`F3DEX_GBI=1`/`GBI_FLOATS=1` compile defs. `GBIMiddleware.cpp` shims `gSPDisplayList`/`gSPVertex`/
`gDPSetTileSizeInterp`/`gSPInvalidateTexCache` through the LUS ResourceManager
(`S:src/port/GBIMiddleware.cpp:6-52`). Does F3DEX (vs LUS's `F3DEX_GBI_2` CMake default)
interact badly with the Metal backend? No evidence of any coupling: ucode selection happens in
the interpreter, which feeds the backend a ucode-agnostic command stream; the Metal backend has
no GBI-variant branches. Better than absence-of-evidence: Starship's pin `eaaf9d0` *is* the
"Fix metal compatibility with prism" commit — it exists because Starship exercises Metal (its
supported macOS backend) against exactly this F3DEX content today. The combination is
production-tested on Apple GPUs, just not yet on iOS.

### 3.2 libultraship at `eaaf9d0` (Starship's pin) — iOS inventory

Layout is the **old** pre-refactor one: `src/graphic/Fast3D/…`, `src/audio`, `src/window`,
`src/Context.cpp`, `src/public/bridge/*`, `src/port/mobile/`, headers under
`include/libultraship/`. `Context` API is `shared_ptr GetInstance()` only — `GetRawInstance()`
does not exist (`LUSpin:src/Context.h:31`).

Present and iOS-relevant:
- `cmake/dependencies/ios.cmake` (dep set in C3, all `OVERRIDE_FIND_PACKAGE`);
  `cmake/ios-toolchain-populate.cmake` (hardcodes `OS64COMBINED`, fetches leetal ios-cmake
  @ `06465b27`); `SIGN_LIBRARY`/`BUNDLE_ID` options (`LUSpin:CMakeLists.txt:6-7`) with
  signing-disable logic (`LUSpin:src/CMakeLists.txt:263-281`).
- `__IOS__` defined for `CMAKE_SYSTEM_NAME STREQUAL "iOS"` (`LUSpin:src/CMakeLists.txt:252-261`),
  used in: `Context.cpp:230,408,466` (exit-on-missing-archive; `GetAppBundlePath` and
  `GetAppDirectoryPath` both → `$HOME/Documents`); `Fast3dWindow.cpp:70` (`gameMode=true` →
  always fullscreen); `gfx_sdl2.cpp:359` (borderless window flags); `gfx_metal.cpp:63,1157`
  (`GPUFamilyApple4` threadgroup check; `Metal_IsSupported()` unconditional true);
  `Gui.cpp:35,280,300` (viewports off, mobile keyboard hook); `StatsWindow.cpp:21`;
  `MobileImpl.cpp:1`.
- `src/port/mobile/MobileImpl.{h,cpp}` compiled for Android|iOS (`LUSpin:src/CMakeLists.txt:116-120`)
  — virtual-keyboard show/hide only, as the brief says.
- OpenGL excluded twice on iOS (source filter `LUSpin:src/CMakeLists.txt:156-158`;
  `ENABLE_OPENGL` non-iOS only `:293-302`). Metal backend clean: **zero
  `MTLResourceStorageModeManaged`**; `CAMetalLayer` via `SDL_RenderGetMetalLayer`.
- **Audio: `src/audio/` contains only `SDLAudioPlayer` and `WasapiAudioPlayer`.** Non-Windows
  default is SDL (`LUSpin:src/audio/Audio.cpp:12-32`). No CoreAudio player exists at this commit
  — the CoreAudio-vs-iOS problem HarkinianPad had to patch does not exist here.
- `AppleFolderManager.mm` compiled for **Darwin OR iOS** (`LUSpin:src/CMakeLists.txt:97-99`) with
  `FolderManager::getMainBundlePath()` (`LUSpin:src/utils/AppleFolderManager.mm:21`) — so
  HarkinianPad's bundle-path fix (delete the `__IOS__` Documents override in `GetAppBundlePath`,
  fall through to the `__APPLE__` branch at `LUSpin:src/Context.cpp:416-419`) works unchanged.
- Frame pacing: manual `nanosleep` pacing (`SyncFramerateWithTime`,
  `LUSpin:src/graphic/Fast3D/backends/gfx_sdl2.cpp:634-649`) plus `SDL_GL_SetSwapInterval`/
  `SDL_RenderSetVSync` (`:681-682`); `SetTargetFps` exists (`:697`). No `CADisplayLink` /
  `SDL_iPhoneSetAnimationCallback` anywhere.
- Controller stack: full SDL mapping set incl. `SDLRumbleMapping`, `SDLGyroMapping`,
  `SDLLEDMapping` (`LUSpin:src/controller/controldevice/controller/mapping/sdl/`).

**Confirmed defects at the pin an iOS build hits:**
1. **Link-breaker:** `gfx_sdl2.cpp` includes `macUtils.h` and calls
   `isNativeMacOSFullscreenActive`/`toggleNativeMacOSFullscreen` under bare `__APPLE__`
   (`LUSpin:src/graphic/Fast3D/backends/gfx_sdl2.cpp:22-25,231-236,614-620`) while `macUtils.mm`
   is compiled Darwin-only (`LUSpin:src/CMakeLists.txt:104-106`). Since iOS forces fullscreen
   (`Fast3dWindow.cpp:70-72`), the path is reached → undefined symbols. (Still unfixed on
   upstream `port-maintenance` too.)
2. **No `SDL_APP_*` lifecycle handling** (grep empty — true at pin and at PM; it exists only in
   HarkinianPad's patch).
3. **No iOS ImGui scaling** (2× is `__ANDROID__`-only, `LUSpin:src/window/gui/Gui.cpp:131-135`).
4. `GetAppBundlePath()` = Documents on iOS (`Context.cpp:408-411`) — wrong for reading bundled
   extraction yamls; fix per above.

### 3.3 Torch at `cd92cc0f`

Single target `torch`: static library when `USE_STANDALONE=OFF` (`T:CMakeLists.txt:106-113`),
which is how Starship consumes it. No platform conditionals that block iOS; **zero**
`__IOS__`/`__ANDROID__` hits; no fork/exec/dlopen/mmap/threads/GUI in the library build; every
dependency is portable C/C++ (yaml-cpp pinned `2f86d13`, tinyxml2 10.0.0, vendored miniz —
already `__APPLE__`-aware — mio0/yay0, Chocobo1 SHA1, binarytools, n64graphics/stb). StormLib is
vendored but OFF for Starship. The single acquisition gap: library mode requires an external
spdlog package (`T:CMakeLists.txt:226-238`) — expected to be satisfied by LUS's `ios.cmake`
`OVERRIDE_FIND_PACKAGE` registration (C3).

API: `Companion::Instance = new Companion(std::vector<uint8_t> rom, ArchiveType::O2R, debug,
srcDir, destPath)` then `Init(ExportType::Binary)` (`T:src/Companion.h:115-139`,
`T:src/Companion.cpp:124-215`). Inputs: `srcDir/config.yml` + recursive yaml tree
(`Companion.cpp:987-995,1073,1253-1276`) — for Starship that is `GetAppBundlePath()` + the ~50
files/≈1 MB of `assets/yaml/us/rev1/*` (`S:config.yml` `path:` keys). Outputs to `destPath`:
`sf64.o2r` + `torch.hash.yml` (`Companion.cpp:1082-1098,1286-1288`). Whole ROM held in RAM;
MIO0 preprocess makes several transient copies; the output zip is built fully in memory by miniz
before one `save()` (`T:src/archive/ZWrapper.cpp:37-43`). **Estimated** transient peak for a
12 MiB retail ROM: ~150–250 MB (allocation-site derivation, not measured — measure at Phase 4).
Strictly single-threaded; global-singleton design → run exactly one extraction, on a worker
thread. The pinned commit itself is the "empty src/dest paths" fix, so library mode has no cwd
dependence when `debug=false`.

Current Torch `main` (not pinned): Emscripten/WASM support, a parse/export **progress-reporting
split** (commit `d0042dc` — the natural backport for an iOS progress bar), exposed
`RegisterFactory`. SF64 audio is extracted by the in-tree `naudio v1` factories — pure C++, no
host tools ("NAudio" in the SpaghettiKart notes is this Torch module, not the .NET library).

### 3.4 HarkinianPad — what exists and what state it is in

Complete inventory of HarkinianPad's changes (all in `ref/harkinianpad/patches/`, replayed onto
pinned upstreams by `scripts/apply-source-patches.sh`; classification table in §4):

| Patch | Size | Targets |
|---|---|---|
| `libultraship-ios.patch` | 553 lines, 37 hunks, 18 files | LUS `port-maintenance` @ `2bfbde3` |
| `zapdtr-ios.patch` | 22 lines | ZAPDTR CMake `Darwin|iOS` (×2 sites) |
| `shipwright-ios.patch` | 854 lines | Shipwright CMake iOS arm, `CMake/ios.cmake` (FetchContent ogg/vorbis/opus/opusfile/libpng), `soh/ios/Info.plist.in`, `SDL_main`, first-run flow, per-file `__IOS__` decisions |
| `shipwright-ios-first-run.patch` | 132 lines | non-quitting, device-aware Files-import flow |
| `shipwright-ios-app-icon.patch` | 27 lines | `Assets.xcassets` AppIcon wiring |
| `shipwright-ios-touch-controls.patch` | 620 lines | `soh/ios/HarkinianPadTouchControls.{h,mm}` UIKit overlay + CVar toggle |

Substance of the LUS patch (the piece decision B is about): `ENABLE_SCRIPTING` hard-fail on iOS;
STB download hash-pinning; `PLATFORM` override guard in `ios-toolchain-populate.cmake`;
CoreAudio excluded on iOS (×5 sites); `AudioPlayer::SetPaused` API + SDL implementation
(pause + clear queue) + `SDL_HINT_AUDIO_CATEGORY playback`; `SDL_APP_WILLENTERBACKGROUND/
DIDENTERBACKGROUND/WILLENTERFOREGROUND/DIDENTERFOREGROUND/LOWMEMORY/TERMINATING` handling with a
synchronous window+config flush; `mIsBackgrounded`/`IsFrameReady()`; `GetPixelDepth[Prepare]`
frame-ready guards (fixes a real crash found in Simulator); a `WindowIsFrameReady()` C bridge
that pumps events and sleeps 16 ms while suspended; macOS-fullscreen carve-outs (the
link-breaker fix); `GetAppBundlePath` iOS = real NSBundle resource path; iOS ImGui scale rule
(1×/2× by shortest usable side ≥600 pt); mobile overlay text scale; Start=Space+Enter keyboard
default; iOS mouse defaults A/B/Z.

**How HarkinianPad's on-device extraction actually works** (the reference the brief asks for,
answering "which binary, how linked, how sandboxed"): ZAPD is compiled as the `ZAPDLib` static
library and linked into the app executable; `Extractor::CallZapd` builds a fake argv and calls
`zapd_report()` in-process — no process spawning exists (`HP:docs/findings/04-filesystem-extraction.md`
§B1). The first-run flow is an ImGui state machine (`OTRGlobals::RunExtract`) driving a 1-thread
worker pool; on iOS the desktop file dialog is replaced with Files-app guidance plus a Rescan
that scans the app's Documents directory (`.z64/.n64/.v64`, any filename). Sandbox/Files
integration is purely declarative: `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`
in the Info.plist expose the container's Documents in the Files app; the extractor reads its XML
metadata from the real app bundle (the `GetAppBundlePath` fix) and writes `oot.o2r` to
Documents. StarshipPad reproduces this pattern one-for-one with Torch/`Companion` in place of
ZAPDLib/`zapd_report` (§5.3, Phase 4) — same plist keys, same Documents-scan UX, same
worker-thread + progress-modal shape.

Project status per `ref/harkinianpad/docs/remaining-work.md` (evidence log through 2026-07-27):
signed install on a physical iPad Pro 6th gen (iPadOS 26.5.2) with Files ROM import, on-device
extraction, touch gameplay, and save persistence all exercised; deployment target 14.0 built
against the iPhoneOS 26.5 SDK. Open gates that transfer as *warnings* to StarshipPad: audible
physical-device audio (SDL device initializes 2ch/32kHz but no sound was heard — an active,
unresolved defect), the physical-controller matrix, and the full on-hardware lifecycle matrix.

### 3.5 Recoverable ecosystem prior art

- **LUS PR #1056 patch** (Sunset-Dawn era, 105 lines: `ios/Launch.storyboard`, `ios/plist.in`,
  CoreAudio avoidance, fullscreen stubs). Retrieve:
  `git fetch https://github.com/Kenix3/libultraship 3792373190753d871462115655cf62d38793ba63 &&
  git diff FETCH_HEAD~2..FETCH_HEAD` (head commit still served from the repo network). A copy
  was saved to this session's scratchpad during research.
- **SpaghettiKart PR #684 patch** (1,158 lines, 11 commits: iOS CMake, GameExtractor iOS flow,
  ModManager handling, `docs/BUILDING.md` iOS + IPA instructions; PR body confirms a working
  on-device IPA). Retrieve via `gh pr diff 684 -R HarbourMasters/SpaghettiKart` or the
  `.diff`/`.patch` URL.
- **Live branches:** `coco875/SpaghettiKart` branch `ios` (open PR
  HarbourMasters/SpaghettiKart#694, "move ios file in spaghettikart and use default lus");
  `coco875/libultraship` branch `ios` (open draft Kenix3/libultraship#1083, head `09426197`).
  SpaghettiKart main merged partial iOS CMake 2026-07-23 (PR #721).
- **`izzy2lost/Starship`** — Android port of *this exact game* with shipped APKs (v1.0.3,
  2025-11-16). Its touch-control and extraction approaches have not been read yet (Q3) and are
  the closest game-specific mobile reference that exists.

---

## 4. Reuse inventory

Classification of every HarkinianPad change. **Shared** = belongs at the LUS layer and applies
to StarshipPad (as a backported patch hunk — "unchanged" is impossible across the layout gap,
but the change is identical in content). **Portable** = game-side but structurally reusable with
renames/rebinding. **Ocarina-specific** = does not transfer.

| # | HarkinianPad change (file @ PM layout) | eaaf9d0 target | Class | Transfer notes |
|---|---|---|---|---|
| 1 | LUS `CMakeLists.txt` — `ENABLE_SCRIPTING` iOS hard-fail | `CMakeLists.txt` | Shared | **Moot at pin** (no scripting subsystem exists); re-add if LUS is ever bumped |
| 2 | LUS `cmake/dependencies/common.cmake` — STB sha-pin | same path | Shared | Applies nearly clean (pin lines 53-56); scripting-endif hunk has no target |
| 3 | LUS `cmake/ios-toolchain-populate.cmake` — `PLATFORM` overridable | same path | Shared | Applies nearly clean; **required** because Starship sets `PLATFORM OS64` |
| 4 | LUS `gfx_sdl.h` — `mIsBackgrounded` member | `src/graphic/Fast3D/backends/gfx_sdl.h` | Shared | Applies (anchor `mMouseWheelX/Y` at pin:56-57) |
| 5 | LUS audio `SetPaused` API (`Audio.h`, `AudioPlayer.h`, `SDLAudioPlayer.{h,cpp}`, `Audio.cpp` impl) | `src/audio/*` | Shared | Applies; the 5 CoreAudio-exclusion hunks are **moot at pin** (no CoreAudio) |
| 6 | LUS `SDLAudioPlayer.cpp` — `SDL_HINT_AUDIO_CATEGORY playback` | `src/audio/SDLAudioPlayer.cpp` | Shared | Applies (DoInit at pin:11) |
| 7 | LUS `Context.cpp` — remove `__IOS__` `GetAppBundlePath` override | `src/Context.cpp:408-411` | Shared | Applies; pin's `__APPLE__` fallback (`FolderManager::getMainBundlePath`, compiled Darwin|iOS) provides the correct bundle path |
| 8 | LUS `Fast3dWindow.cpp` — `GetPixelDepth[Prepare]` frame-ready guards | `src/graphic/Fast3D/Fast3dWindow.cpp:110-116` | Shared | Applies; Starship calls `GetPixelDepth` via LUS internals — keep the guard regardless |
| 9 | LUS `gfx_sdl2.cpp` — macOS-fullscreen carve-outs (×2) | pin `:231-236, 614-620` | Shared | **Mandatory link fix**; applies with `GetRawInstance()`→`GetInstance()` and include-path rewrites |
| 10 | LUS `gfx_sdl2.cpp` — `SDL_APP_*` cases + config flush + audio pause | pin `HandleSingleEvent` (~:624) | Shared | Applies with same rewrites |
| 11 | LUS `gfx_sdl2.cpp` — `IsFrameReady()` = `!mIsBackgrounded` | pin (~:625) | Shared | Applies |
| 12 | LUS `windowbridge.{h,cpp}` — `WindowIsFrameReady()` C bridge | `src/public/bridge/windowbridge.*` | Shared | Applies (drop `API_EXPORT`, `GetRawInstance`→`GetInstance`) |
| 13 | LUS `Gui.cpp` — iOS 1×/2× ImGui scale by display size | `src/window/gui/Gui.cpp:131-135` | Shared | Applies; the `HarkinianPad_SetTouchControlsMenuVisible` extern is renamed to the StarshipPad symbol (see #24) |
| 14 | LUS `GameOverlay.cpp` — mobile notification scale | `src/window/gui/GameOverlay.cpp:240-244` | Shared | Applies |
| 15 | LUS `ControllerDefaultMappings.cpp` — Start = Space+Enter | pin `:58` | Shared | 1-line rewrite (pin uses assignment shape, not map-initializer) |
| 16 | LUS `ControllerButton.cpp` — iOS mouse defaults A/B/Z | pin `:269` area | Shared | Applies; **remap semantics for SF64** (A=fire is good on left-click; B=bomb on right-click is debatable — decide at Phase 6) |
| 17 | `zapdtr-ios.patch` | — | Ocarina-specific | ZAPD is not in the Starship stack; nothing to port (Torch needs no equivalent) |
| 18 | Shipwright `CMake/ios.cmake` — FetchContent ogg/vorbis/opus/opusfile/libpng | new `S` file | Portable | Template. Starship needs **only Ogg+Vorbis** (`S:CMakeLists.txt:358-368`); no opus/opusfile (SoH-only), no libpng (ZAPD-only; Torch uses stb — verify at configure, Q6) |
| 19 | Shipwright top+soh CMake iOS arms (system version, OBJCXX, bundle props, compile defs, link set, `-Wl,-export-dynamic` removal, controller-db pin+sha, post-build o2r copy) | `S:CMakeLists.txt` | Portable | Same moves, Starship coordinates; Starship already has `enable_language(OBJCXX)` for APPLE (`S:CMakeLists.txt:23-25`) and its iOS compile-flags branch already exists (`:489`); `-mcpu=native`/`-export-dynamic` live in the non-Apple `else()` and need no change |
| 20 | `soh/ios/Info.plist.in` (63 lines: Files sharing, landscape, game-controller keys, arm64+metal required, full-screen, status-bar hidden) | new `S:ios/Info.plist.in` | Portable | Rename identifiers; contents transfer nearly verbatim |
| 21 | `main.c` — `SDL_main` for `_WIN32 || __IOS__` | `S:src/port/Game.cpp:33-38` | Portable | Same one-hunk change (replaces the `extern "C" main` wart) |
| 22 | `graph.c` — `WindowIsFrameReady()` gate in the game loop | `S:src/port/Game.cpp:45` | Portable | Identical pattern: `if (!WindowIsFrameReady()) continue;` before `push_frame()` |
| 23 | First-run Files-import flow (`RunExtract` iOS states: Continue/Rescan/Try-Again, compact-display wording, non-quitting recovery) | `S:src/port/Engine.cpp` + `GameExtractor.cpp` + new UI | Portable | The *pattern* transfers (popups, rescan, worker thread, no `exit()`); the code is rewritten against Starship's extractor because SoH's `RunExtract` is an OTRGlobals state machine that has no Starship equivalent — this is the largest genuinely new game-side work item (§6 Phase 4) |
| 24 | Touch overlay `HarkinianPadTouchControls.{h,mm}` (522 lines: button class posting SDL key events, 8-way stick view, safe-area layout, pass-through hit test, persistent menu button, menu-visibility hook) + CVar toggle + settings widget | new `S:ios/StarshipTouchControls.{h,mm}` | Portable | Mechanism is game-agnostic (SDL scancodes + LUS keyboard defaults, which are identical at the pin); layout, button set, colors, and the Ocarina binding table are replaced by the SF64 design (§5.4) |
| 25 | App icon asset-catalog wiring | new `S:ios/Assets.xcassets` | Portable | Mechanical |
| 26 | Extractor `GetRoms` iOS directory scan (`std::filesystem`, `.z64/.n64/.v64`) | `S:src/port/extractor/GameExtractor.cpp:35-37` | Portable | Replaces the hardcoded `baserom.us.rev1.z64`; add byteswap (C7) |
| 27 | Per-file `__IOS__` UX decisions (drag-drop hints, aspect-stretch option, controller-nav forced on, audio-backend list, menu sidebar sizing, reset confirmation) | various `S:src/port/ui/*` | Portable | Same decision *classes*; Starship's equivalents: `ImguiUI.cpp` backend picker/DX11 toggle, `ResolutionEditor.cpp`, notification overlay |
| 28 | Scripts: `clone-sources.sh`, `apply-source-patches.sh`, `configure-ios.sh`, `build-ios.sh`, `generate-port-archive.sh`, `package-ios.sh`, `check-repo-safety.sh` | StarshipPad `scripts/` | Portable | Direct adaptation: pins → Starship/LUS/Torch; forbidden patterns → `*.z64/n64/v64/rom`, `sf64*.o2r`, `baserom*`, `.otr`; required bundled artifact → `starship.o2r` (+ `config.yml`, `assets/yaml/**`, `gamecontrollerdb.txt`) |
| 29 | CI workflow (`ios-build.yml`: repo-safety job + full unsigned iPhoneOS build + audit + REQUIRE_SIGNED negative test on macos-15) | StarshipPad `.github/` | Portable | Direct adaptation |
| 30 | Docs (`BUILDING.md`, `RELEASE_CHECKLIST.md`, findings/evidence-ledger discipline) | StarshipPad `docs/` | Portable | Direct adaptation |
| 31 | SoH networking exclusion (`SOH_DISABLE_NETWORKING` source filters) | — | Ocarina-specific | Starship has no networking to exclude (`USE_NETWORKING` already off, no consumers) |
| 32 | Opus/OpusFile/libpng acquisition, `dr_libs` handling, speechsynthesizer gating, spoiler-log/randomizer/save-manager `__IOS__` arms | — | Ocarina-specific | No Starship counterparts |

Summary: **16 Shared items** (the entire LUS layer — every one already proven on device by
HarkinianPad, and 7 hunks get *simpler* at the pin), **13 Portable items** (game-side patterns
and infrastructure), **3 Ocarina-specific items** that die here. The genuinely new work not
covered by any row: the SF64 touch layout/bindings (design, not mechanism), the Starship
first-run flow restructure (row 23), and the analog virtual-controller upgrade (§5.4, stage 2).

---

## 5. Decisions

### 5.1 Repository model — patch-replay over pinned upstreams (chosen)

**Options:** (a) hard-fork Starship (+LUS +Torch) into StarshipPad-owned repos; (b) a monorepo
vendoring upstream source; (c) HarkinianPad's model — StarshipPad holds only scripts, patches,
iOS-only files, and docs; upstreams are pinned, push-disabled, fetched into git-ignored
`sources/` at build time.

**Chosen: (c).** Why: it is the developer's proven, tooled, already-audited pattern
(`HP:scripts/*`, `HP:docs/remaining-work.md` — the entire evidence-gate discipline assumes it);
it keeps the public repo free of any upstream code, which keeps the licensing surface minimal
and the ROM-safety audit simple; and it survives upstream account turbulence better than forks
that invite drift. Cost: patches need occasional refresh if pins ever move — acceptable because
the pins are deliberately frozen (§5.2).

### 5.2 LUS version — Option 2: backport onto `eaaf9d0` (chosen)

**Option 1 — bump Starship's submodule to current `port-maintenance` and fix Starship.**
Enumerated breakage (from a full two-tree API census):
- `Ship::Context::GetInstance()` removed → `GetRawInstance()`, raw pointers from `Create*`:
  **76 call sites** across Starship, plus the `std::shared_ptr<Ship::Context>` member
  (`S:src/port/Engine.h:30`) and `CreateUninitializedInstance` at `S:src/port/Engine.cpp:67`.
- `Ship::WindowBackend` enum removed → `int32_t` ids: rework of the backend picker,
  `S:src/port/ui/ImguiUI.cpp:465-487`.
- `Config::GetCurrentAudioChannelsSetting()` gone → `Audio::GetSavedAudioChannelsSetting()`;
  `AudioSettings.AudioSurround` renamed `ChannelSetting`: breaks `S:src/port/Engine.cpp:170-171`.
- `LUS::ControlDeck` needs a new explicit include (`S:src/port/Engine.cpp:163`).
- Include restructuring: of Starship's 15 unique LUS include lines (57 occurrences), 5 need
  source edits (`libultraship/src/Context.h` ×5 → `<ship/Context.h>`; `Fast3D/interpreter.h` ×4
  and `graphic/Fast3D/interpreter.h` ×1 → `<fast/interpreter.h>`; `Fast3D/Fast3dWindow.h`;
  `ControllerDefaultMappings.h` path), 5 more need CMake include-dir swaps, and ~12 of the
  `include_directories` entries in `S:CMakeLists.txt:239-275` point at directories that no
  longer exist.
- What survives untouched: `Fast3dWindow` ctor + `GetInterpreterWeak` +
  `DrawAndRunGraphicsCommands` + `SetRendererUCode` + `mInterpolationIndex`;
  `RegisterResourceFactory` signature (all ~30 Starship factory registrations);
  every C-bridge function Starship calls; runtime F3DEX ucode selection and
  `F3DEX_GBI`/`GBI_FLOATS` support.
- And after all that, **iOS is still not turnkey on PM**: the fullscreen link-breaker is
  unfixed there, and no lifecycle handling exists — HarkinianPad's patch still has to be applied
  on top. Overall delta `eaaf9d0 → port-maintenance`: 479 files, +21,894/−8,891 lines
  (src+include).

**Option 2 — backport HarkinianPad's LUS patch onto `eaaf9d0`.** All 18 patched files have pin
equivalents (zero "no equivalent"); ~30 of 37 hunks port with three mechanical rewrite classes
(`ship/…` include paths → pin paths; `Context::GetRawInstance()` → `GetInstance()` at 3 sites;
`include/X` → `src/X` header locations); 7 hunks are moot because the features they guard
(TCC scripting, CoreAudio) do not exist at the pin — and the pin's SDL-only audio *is*
HarkinianPad's iOS end-state. The mandatory link fix (fullscreen carve-outs) is included. Known
additional hunk StarshipPad must write itself: possibly bump `ios.cmake`'s SDL2 from
`release-2.28.1` if it fails to build under current Xcode SDKs (LUS PR #966 fixed exactly an
"outdated SDL2/CMake incompatibility" class of failure on newer LUS; whether 2.28.1 still builds
is **unknown** — resolved by Phase 0, and the fallback is a one-line `GIT_TAG release-2.32.10`
bump, the tag HarkinianPad shipped against).

**Option 3 — fork LUS and maintain a StarshipPad branch.** Identical engineering content to
option 2 plus repo mechanics, minus the patch-replay simplicity, plus permanent divergence
bookkeeping. Its only unique advantage (protection against `eaaf9d0` disappearing) is achievable
more cheaply — see mitigation below.

**Chosen: Option 2**, because Starship main compiles against `eaaf9d0` today (game-side churn:
zero), because the backport is modest and fully enumerated while the bump is a porting project
with no iOS payoff, and because it matches the repository model (§5.1). Two riders:
1. **Dangling-pin insurance (addresses C1):** StarshipPad's `patches/` will carry
   `lus-925-metal-prism.patch` = `git diff 09dfab5f..eaaf9d0` (`09dfab5f` is on `main` and can
   never be GC'd). `clone-sources.sh` fetches `eaaf9d0` by SHA and, on failure, reconstructs it
   by checking out `09dfab5f` and applying the stored patch. The build is then byte-identical
   either way.
2. **Bump later, not never:** if upstream Starship ever bumps its LUS submodule, StarshipPad
   revisits — the HarkinianPad patch already targets the PM layout, so a future bump makes the
   LUS side *easier*, not harder.

### 5.3 Asset extraction on device — Option 1: Torch in-process (chosen)

**Option 1 — Torch runs on device** (chosen). User cost: first launch needs the ROM placed in
the app's Files-visible folder and a few minutes of extraction (HarkinianPad's OoT extraction
measured ~257 s in an iPhone Simulator; SF64's ROM is 12 MiB vs 32 MiB and Torch is a lighter
pipeline — expect less, **estimate** 1–3 min; measure at Phase 4). Engineering cost: Torch
itself needs ~nothing (§3.3); the work is Starship-side flow restructuring (Phase 4) because the
current extraction blocks the boot thread before a window exists — that must not survive
contact with the iOS watchdog. This option preserves the developer's established
bring-your-own-assets, no-desktop-required pattern and matches what desktop Starship users
already do.

**Option 2 — generate `sf64.o2r` on a Mac, import through Files.** User cost: requires a Mac
and a working Starship desktop build — a regression from the established pattern, as the brief
notes. It is **not chosen as the product**, but it *is* the Phase 3 stepping stone (boot the
game on iOS with desktop-generated archives before on-device extraction exists), and it remains
a permanent documented fallback for unsupported-hash ROMs. Zero additional engineering (archive
discovery through `LocateFileAcrossAppDirs`/`GetPathRelativeToAppDirectory` already finds files
dropped into Documents).

**Option 3 — hybrid: ship Torch but defer the UI (headless auto-extract on launch when a ROM
named per C7 exists).** Rejected as the end state (silent multi-minute boot with no progress UI
is exactly the watchdog/UX failure mode), though it is effectively what Starship's current
`__IOS__` stub does and may briefly exist mid-Phase 4.

### 5.4 Touch controls — port the component, redesign for Star Fox, upgrade to analog

**What HarkinianPad's overlay actually is (answering C):** implemented entirely game-side
(`HP:patches/shipwright-ios-touch-controls.patch` → `soh/ios/HarkinianPadTouchControls.mm`), a
UIKit view layer that posts SDL keyboard events (`SDL_PushEvent` of `SDL_KEYDOWN/UP`) matching
LUS's default keyboard bindings, with an 8-way stick, pass-through hit-testing, safe-area-aware
layout, a persistent menu button, and menu-visibility coordination via one hook call in LUS
`Gui::DrawMenu`. The *mechanism* is a generic N64-controller overlay (nothing reads Ocarina
state); the *layout, binding table, symbol names, and CVar* are Ocarina-shaped. Classification:
**Portable, not solved** — the component ports; the design does not.

**SF64 mapping (from §3.1 ground truth) onto the overlay:**

| Touch element | N64 input | In-game meaning | Carries over from HP? |
|---|---|---|---|
| Analog stick (left thumb) | stick | fly/aim (full analog) | Component yes; **8-way fidelity is the gap** (below) |
| A (large, right cluster) | A | fire / hold to charge | yes (rebind) |
| B (right cluster) | B | smart bomb | yes (rebind) |
| BOOST pill (right rail) | C-Left | boost; +stick-down = somersault | new label/position |
| BRAKE pill (right rail) | C-Down | brake; +stick-down = U-turn (all-range) | new label/position |
| Z pill (left shoulder) | Z | bank/roll left; double-tap = barrel roll | yes |
| R pill (right shoulder) | R | bank/roll right; double-tap = barrel roll | yes |
| VIEW (small) | C-Up | cockpit/view toggle; map screen | new |
| TALK (small, reachable mid-flight) | C-Right | answer wingman calls; supplies in all-range | new — must not be buried |
| Start | Start | pause | yes |
| Menu `•••` (persistent) | — | ImGui menu | yes verbatim |
| D-pad | D-pad | no gameplay use found (Q5) | **dropped** pending Q5 |

Somersault and U-turn need no dedicated buttons — they are boost/brake + stick-down inside a
5-frame window, which two-thumb touch play performs naturally; the acceptance tests must verify
the window is hittable through the SDL event path (Phase 6). Double-tap Z/R barrel rolls work
as-is. The Ocarina overlay's 16 buttons reduce to ~10 for SF64 v1, freeing screen space —
important because SF64 is aim-centric and the screen center must stay clean.

**The analog problem.** HarkinianPad's stick emits WASD scancodes → 8 directions at full
deflection. Acceptable for OoT menus-and-walking; poor for SF64, where aiming precision *is*
the game. Two-stage plan:
- **Stage 1 (Phase 6):** port the overlay as-is with SF64 bindings via LUS keyboard defaults
  (identical at the pin: A→`X`, B→`C`, Z→`Z`, R→`R`, Start→`Space`, C-buttons→arrows,
  stick→WASD; `LUSpin:src/controller/.../ControllerDefaultMappings.cpp:53-84` — Starship passes
  empty keyboard maps so LUS defaults apply, `S:src/port/Engine.cpp:132-136`; verify the
  empty-map fallback behavior at the pin, expected but not yet read). This is the proven,
  low-risk slice that makes a clean install playable.
- **Stage 2 (Phase 7):** replace key-event emission with an **SDL virtual game controller**
  (`SDL_JoystickAttachVirtual` + `SDL_JoystickSetVirtualAxis/Button` — available since SDL
  2.0.14, present in 2.28.1): the overlay becomes a real `SDL_GameController` to LUS, the stick
  posts continuous axis values, and Starship's existing SDL gamepad defaults
  (`S:src/port/Engine.cpp:138-159`) bind it with zero LUS changes. Deadzone/response tuning then
  happens against the game's own ±16/±60 processing (`S:src/sys/sys_joybus.c:13-49`).
  Risk: unproven in this stack (nobody in the LUS mobile ecosystem has shipped it); fallback is
  staying on stage 1.

The overlay's LUS-side hook (`Gui::DrawMenu` menu-visibility call) is renamed to a StarshipPad
symbol (`StarshipPad_SetTouchControlsMenuVisible`) in the backported LUS patch — same one-line
wart HarkinianPad accepted, documented as such.

### 5.5 Audio — SDL backend, 32 kHz, HarkinianPad lifecycle semantics (chosen)

At the pin there is nothing to exclude: SDL is the only non-Windows backend (§3.2). Keep
Starship's 32 kHz producer exactly as-is (it is backend-agnostic), backport `SetPaused` +
`SDL_HINT_AUDIO_CATEGORY` + the lifecycle pause/clear behavior, and inherit SDL's own
`AVAudioSession` interruption handling (verified live by HarkinianPad: `SDLInterruptionListener`
breakpoint evidence, `HP:docs/remaining-work.md` M4a/M6d entry). Do not build a RemoteIO
backend. Carry HarkinianPad's **open silent-audio defect** as an explicit risk (R4) — same SDL
audio path, so assume it reproduces until a device says otherwise.

### 5.6 The four phantom bundle files — they belong in the game repo (decided)

HarkinianPad answered this for Shipwright: `Info.plist.in` + `Assets.xcassets` live in the
*game* tree (`soh/ios/`), not in LUS. The SpaghettiKart lineage converged on the same answer —
PR #694's first act was "move ios file in spaghettikart and use default lus", and upstream LUS
reviewers have pushed port-layer concerns out of core LUS since PR #491. StarshipPad therefore
creates `ios/Info.plist.in` and `ios/Assets.xcassets/` **inside the Starship source tree via the
StarshipPad game patch**, and repoints `IOS_DIR` from `libultraship/ios/` to
`${CMAKE_SOURCE_DIR}/ios/` (`S:CMakeLists.txt:169`). No storyboard: HarkinianPad shipped without
one (SDL creates the window; `UILaunchScreen` dict in the plist covers launch), and its bundle
passed Xcode validation (`HP:docs/remaining-work.md`, M2a). `PoweredBy.png` is not load-bearing
anywhere — dropped.

### 5.7 ROM ingestion — scan + identify + byteswap (chosen)

Replace the hardcoded `baserom.us.rev1.z64` with HarkinianPad's pattern: scan the Files-visible
Documents directory for `*.z64/*.n64/*.v64` (any filename), normalize byte order in memory
(magic-word detection: `80 37 12 40` native / `37 80 40 12` `.v64` / `40 12 37 80` `.n64` —
~20 lines, needed because neither Starship nor Torch handles swapped images, C7), then SHA-1
against the existing six-hash table. US hashes → base `sf64.o2r`; JP/EU/CN hashes → offer the
voice/mod archive flow. Never require a specific filename.

### 5.8 Deployment target and devices — iOS/iPadOS 14.0, landscape, iPhone+iPad (chosen)

Follow the entire proven HarkinianPad envelope: deployment target 14.0 (LUS CI's value; built
against current SDKs; ran on iPadOS 26 hardware), `TARGETED_DEVICE_FAMILY "1,2"`,
landscape-only, `UIRequiredDeviceCapabilities` arm64+metal, Files sharing enabled. iOS 14 floor
implies iPad Air 2/mini 4/iPad 5th-gen and later can install; the Metal backend's
`GPUFamilyApple4` check is a soft capability probe, not a floor. Extraction's estimated
~150–250 MB transient peak fits even 2 GB devices' foreground budget, run before game heaps
(same ordering argument as HarkinianPad's). Whether 14.0 is the *true* floor vs the metal-cpp
`macOS13_iOS16` tag remains HarkinianPad's open question Q10, inherited here (Q8) — it has never
blocked a build or a modern-device run.

### 5.9 Distribution, signing, licensing (chosen posture)

Source-first: clone → `build-ios.sh` → personally-signed install, exactly like HarkinianPad;
unsigned IPA as a reproducibility artifact; a downloadable IPA only after the release-checklist
gates (adapted from `HP:docs/RELEASE_CHECKLIST.md`), and it still requires
personal-signing/sideload (AltStore PAL / SideStore constraints noted in
`HP:docs/findings/05-priorart-licensing.md` §B4 apply unchanged). TestFlight/App Store: out of
scope; the ScummVM precedent is recorded there if ever revisited.

**GPL compliance: there is nothing to comply with — the chain contains no GPL/LGPL/AGPL
component.** Inventory: Starship **CC0-1.0** (`S:LICENSE.md` — materially *better* than
Shipwright, which has no top-level license at all); LUS MIT; Torch MIT; SDL2/tinyxml2 zlib;
libzip BSD-3; metal-cpp Apache-2.0; spdlog/nlohmann/yaml-cpp/ImGui/stb/thread-pool MIT; miniz
MIT; ogg/vorbis BSD-3. Verification step at Phase 9: dump the final link closure's license set
and commit it as `docs/LICENSES.md`. StarshipPad's own files: pick MIT at repo creation (the
release checklist's "owner has selected licensing terms" gate — resolved on day one here, which
HarkinianPad never did).

**No-ROM enforcement (explicit, as required):** (1) `.gitignore` + `check-repo-safety.sh`
tracked-file *and full-history* audit for `*.z64/n64/v64/rom/o2r/otr/mpq/ipa/…` (adapted
patterns: block `sf64*.o2r`, `baserom*`; allow only the ROM-free `starship.o2r` as a build
product, never tracked); (2) `generate-port-archive.sh` refuses a `starship.o2r` containing ROM
extensions or `sf64*.o2r` entries (and Q2 verifies the port archive's contents are genuinely
ROM-free — it is generated by CI upstream today from repo-owned assets, so the expectation is
strong); (3) `package-ios.sh` refuses any app/IPA containing forbidden files and re-audits the
bundled `starship.o2r`; (4) CI runs all three gates on every push plus the REQUIRE_SIGNED
negative test. ROMs live only in git-ignored `ref/` locally and in the user's app container on
device.

### 5.10 Deliberately deferred

- **Four-player versus**: code ships (it is compiled in and all ports always read plugged); no
  StarshipPad work beyond "does it crash" smoke testing until after 1.0. Touch provides player 1
  only; players 2–4 require physical controllers. QA state: unknown (Q4).
- **Touch haptics for rumble** (`gControllerRumbleFlags` → CoreHaptics when the overlay is
  active): natural enhancement, after Phase 7. Physical-controller rumble comes free via
  SDL → GameController framework (iOS 14+) and is verified, not built, in Phase 7.
- **ProMotion/120 Hz**: Starship has frame interpolation and a match-refresh-rate option
  (`S:src/port/Engine.cpp:520,537-546`); default stays 60 fps; high-refresh experiments are
  post-1.0 (R7 notes the pacing mechanism).
- **JP/EU/CN voice-pack flow on iOS** (second extraction pass writing `mods/sf64xx.o2r`):
  supported by the same machinery; UI exposure deferred to Phase 8.
- **Upstreaming**: all changes stay in StarshipPad (repository rule). If upstream Starship
  revives and wants the work, the patch series is the offer; coordination with coco875's LUS
  #1083 is read-only monitoring, exactly as HarkinianPad practiced.
- **App Store / TestFlight**: out of scope entirely.

---

## 6. Phased plan

Phases are strictly ordered; each ends with an acceptance gate that must pass before the next
begins (HarkinianPad's "smallest maintainable change for the first reproducible failure, then
replay the gate" discipline). Efforts are **estimates**: S ≈ hours-to-a-day, M ≈ days,
L ≈ 1–2 weeks, for one engineer who knows CMake/iOS.

### Phase 0 — Prove the toolchain: pinned bootstrap + unpatched LUS iOS library (S)

*The smallest thing that proves the approach*: Starship's pinned, dangling-commit LUS builds as
an iOS static library on this machine, with zero StarshipPad patches.

Repo work (StarshipPad repo, adapted from HP): `scripts/clone-sources.sh` (clone
HarbourMasters/Starship, checkout pin `6202c443`; `git submodule update --init libultraship
tools/Torch` — fetches `eaaf9d0` and `cd92cc0f` by SHA; set all push URLs to
`disabled://starshippad-upstream-input`; verify all three SHAs; **also** store/verify the C1
insurance patch: `git -C libultraship diff 09dfab5f..eaaf9d0 > patches/lus-925-metal-prism.patch`
on first run, with the reconstruction fallback path coded in), `.gitignore` (sources/, build*/,
`*.z64/n64/v64/o2r/otr/ipa`…), `scripts/check-repo-safety.sh` (adapted patterns).

Build:
```sh
scripts/clone-sources.sh
cmake -S sources/Starship/libultraship -B build-ios-lus -GXcode \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_SYSTEM_VERSION=14.0 -DDEPLOYMENT_TARGET=14.0 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_BUILD_TYPE:STRING=Release
cmake --build build-ios-lus --config Release
```
(Both `DEPLOYMENT_TARGET` and `CMAKE_OSX_DEPLOYMENT_TARGET` are required — the fetched
ios-cmake toolchain consumes the former; HarkinianPad reproduced an silent-iOS-13 project when
only the latter was passed, `HP:docs/remaining-work.md` M1a.)

Acceptance: `libultraship.a` exists for iphoneos, `lipo -info` reports arm64. Expected failure
mode: SDL `release-2.28.1` fetch/compile breaks under the current SDK → resolution is decided
here (bump to `release-2.32.10` becomes hunk #1 of the LUS patch; that exact tag is
HarkinianPad-proven on device). Everything learned lands in the evidence ledger
(`docs/remaining-work.md`, HarkinianPad format).

### Phase 1 — StarshipPad LUS patch, part 1: make it link (S–M)

Create `patches/libultraship-ios.patch` against `eaaf9d0`, containing only what Phase 2 needs:
1. Fullscreen carve-outs: `#if defined(__APPLE__) && !defined(__IOS__)` at
   `src/graphic/Fast3D/backends/gfx_sdl2.cpp:231-236` and `:614-620` (+ the `macUtils.h`
   include at `:22-25`). **Mandatory link fix.**
2. `cmake/ios-toolchain-populate.cmake`: `if(NOT DEFINED PLATFORM)` guard (Starship sets
   `PLATFORM OS64` first; without this the populate file stomps it to OS64COMBINED).
3. `src/Context.cpp:408-411`: delete the `__IOS__` `GetAppBundlePath` Documents override
   (falls through to `FolderManager::getMainBundlePath()` — required by Phase 4, harmless now).
4. If Phase 0 demanded it: `cmake/dependencies/ios.cmake` SDL2 tag bump.

Verify: patch applies with `git apply --check` to a clean pin checkout; Phase 0's LUS build
replays green with the patch applied; `git diff --check` clean.

### Phase 2 — Full Starship app configures, compiles, links for iOS (M–L)

Create `patches/starship-ios.patch` (game side). Exact changes:
- `CMakeLists.txt:58-66`: drop `YOUR_TEAM_ID` (accept `-DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM`
  from the configure script instead) and replace `PROJECT_ID "dev.net64.game"` with a
  `BUNDLE_ID` cache option defaulting to `com.example.starshippad`; keep `PLATFORM OS64`
  overridable (`SIMULATORARM64` path mirrors `HP:scripts/configure-ios.sh`).
- `CMakeLists.txt:28`: iOS branch for the deployment target (`14.0` via `DEPLOYMENT_TARGET`),
  mirroring the HarkinianPad `CMAKE_SYSTEM_VERSION` handling hunk.
- `CMakeLists.txt:168-190`: `IOS_DIR` → `${CMAKE_CURRENT_SOURCE_DIR}/ios`; drop
  storyboard/PoweredBy; add **new files** `ios/Info.plist.in` (HarkinianPad's 63-line template:
  `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`, landscape-only both families,
  `GCSupportedGameControllers` ExtendedGamepad, `UIRequiredDeviceCapabilities` arm64+metal,
  `UIRequiresFullScreen`, `UIStatusBarHidden`, `UILaunchScreen` dict) and
  `ios/Assets.xcassets/AppIcon.appiconset/` (icon TBD; wiring per
  `HP:patches/shipwright-ios-app-icon.patch`); `OUTPUT_NAME "StarshipPad"`,
  `XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"`.
- New `cmake/ios-deps.cmake`, included for iOS before the platform-deps if-chain: FetchContent
  **Ogg `v1.3.6`** + **Vorbis `v1.3.7`** with `OVERRIDE_FIND_PACKAGE` and alias targets, modeled
  line-for-line on `HP:patches/shipwright-ios.patch`'s `CMake/ios.cmake` (minus opus/opusfile/
  libpng, which Starship does not use — verify libpng absence at configure, Q6).
- `CMakeLists.txt:326-368`: add an `elseif(CMAKE_SYSTEM_NAME STREQUAL "iOS")` arm:
  `ADDITIONAL_LIBRARY_DEPENDENCIES = SDL2::SDL2-static SDL2::SDL2main Ogg::ogg Vorbis::vorbis
  Vorbis::vorbisenc Vorbis::vorbisfile Threads::Threads`.
- `CMakeLists.txt:607-641`: exclude `TorchExternal`/`ExtractAssets`/`GeneratePortO2R` and CPack
  from iOS configures (host-only targets); pin `gamecontrollerdb.txt` to a commit+SHA-256 and
  fail on mismatch (HarkinianPad's exact hunk, which also fixed a real Invalid-RWops bug);
  POST_BUILD: copy `starship.o2r`, `config.yml`, `assets/` (yaml tree), `gamecontrollerdb.txt`
  into the bundle (`$<TARGET_FILE_DIR:Starship>` resolves inside the `.app` for bundle targets —
  confirm at first build; the existing `:600-605` copy may already do config/assets).
- `src/port/Game.cpp:33-38`: `#if defined(_WIN32) || defined(__IOS__) int SDL_main(...)` —
  replace the `extern "C" main` wart; SDL2main provides the UIKit `main`.
- Game-target compile definitions for iOS: add `__IOS__` (LUS defines it only for its own
  target; Starship game code and the new `.mm` files need it — HarkinianPad did the same for
  soh).
- No changes needed for: compile-flag branches (iOS already lands in the `Darwin|iOS` branch at
  `S:CMakeLists.txt:489`; `-mcpu=native` and `-Wl,-export-dynamic` are in the non-Apple `else()`
  and never apply), `enable_language(OBJCXX)` (already `if(APPLE)` at `:23`), Torch options
  (already correct), networking (already off).

Commands (wrapped in `scripts/configure-ios.sh` / `scripts/build-ios.sh`, HarkinianPad
signatures):
```sh
scripts/clone-sources.sh && scripts/apply-source-patches.sh
cmake -S sources/Starship -B build-ios -GXcode -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_SYSTEM_VERSION=14.0 -DDEPLOYMENT_TARGET=14.0 -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DPLATFORM=OS64 -DBUNDLE_ID=com.example.starshippad \
  -DCMAKE_BUILD_TYPE:STRING=Release
cmake --build build-ios --target Starship --config Release -- \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -destination generic/platform=iOS
```
Acceptance: `StarshipPad.app` with an arm64 Mach-O; `vtool -show-build` reports platform IOS,
minos 14.0; Xcode bundle validation clean; expected `find_package(spdlog)` resolution via LUS's
`OVERRIDE_FIND_PACKAGE` confirmed in the CMake configure log (if not: add spdlog to
`ios-deps.cmake` — S). Zero forbidden files in the bundle (`package audit` dry run).

### Phase 3 — Renders a frame in Simulator with desktop-generated archives (S–M)

Host side (Mac): build desktop Starship once; `cmake --build build-host --target GeneratePortO2R`
for `starship.o2r`; `--target ExtractAssets` with a legally-owned ROM at `sources/Starship/
baserom.z64` (ROM lives in git-ignored `ref/`, copied in transiently) for `sf64.o2r`. Build the
`SIMULATORARM64` app (`IOS_PLATFORM=SIMULATORARM64 scripts/configure-ios.sh`), install via
`simctl`, push `sf64.o2r` into the app container Documents (`starship.o2r` rides in the
bundle), launch.

Acceptance: the game boots to the title screen through Metal in an iPad Simulator; a capture
is recorded in the evidence ledger; the SDL audio device initializes (log line). This is the
first whole-stack proof (renderer, F3DEX interpreter path, resource system, filesystem seam) —
equivalent to HarkinianPad's M2. Known watch-item: extraction is skipped in this phase, so the
boot-blocking flow is not yet hit.

### Phase 4 — On-device extraction: Files import → Torch → gameplay (M–L)

The one structurally new game-side build. Changes (extend `starship-ios.patch` or a second
focused patch, mirroring HarkinianPad's base+first-run split):
- **Restructure boot**: on iOS, do not run `GenAssetFile` inside the `GameEngine` constructor
  pre-window (`S:src/port/Engine.cpp:82-101`). Order becomes: create context + window first,
  then, if `sf64.o2r` is absent, enter a windowed first-run loop (ImGui popups rendered through
  the existing LUS Gui) that: explains the Files step ("copy your ROM into On My iPad ▸
  StarshipPad"), offers **Rescan**, scans Documents per §5.7 (any name, three extensions,
  byteswap, SHA-1 identify against `GameExtractor.cpp:12-24`), runs
  `GameExtractor::GenerateOTR()` on a worker `std::thread` with a progress modal (indeterminate
  first; Torch `d0042dc` progress backport optional later), and on success loads the archive and
  proceeds — no `exit()` anywhere in the normal flow (HarkinianPad M5c rules: Continue / Rescan /
  Try Again). SDL message boxes (`ShowYesNoBox`) are acceptable on iOS (UIKit alerts) for
  fatal-only paths.
- `GameExtractor::GetRoms`-equivalent scan + byteswap (~40 lines) replacing the hardcoded
  `baserom.us.rev1.z64` at `GameExtractor.cpp:35-37`.
- Bundle-path correctness: with Phase 1's `GetAppBundlePath` fix, Torch reads
  `config.yml` + `assets/yaml/**` from the app bundle and writes `sf64.o2r` +
  `torch.hash.yml` to Documents (`GameExtractor.cpp:57-70` needs no change for paths).
- JP/EU/CN hash detected → route to the voice-pack flow (write under `mods/`), deferred UI
  polish to Phase 8.

Acceptance (HarkinianPad M5 standard): clean Simulator install with an empty container →
in-app guidance → ROM moved into the Files-visible folder (any filename; test `.z64` and a
byteswapped `.v64`) → Rescan → extraction completes with the app responsive → title screen →
relaunch skips extraction. Measure and record wall-clock and peak RSS (ledger). Then replay on
physical hardware including a real Files move. Verify `torch.hash.yml` and `sf64.o2r` land in
Documents and never in the repo/bundle.

### Phase 5 — Lifecycle, audio pause, persistence (M)

Extend the LUS patch with HarkinianPad's remaining Shared hunks (rows 4–6, 8, 10–14 of §4):
`SDL_APP_*` handling + synchronous config flush, `SetPaused` chain +
`SDL_HINT_AUDIO_CATEGORY`, `mIsBackgrounded`/`IsFrameReady`, `GetPixelDepth` guards,
`WindowIsFrameReady()` bridge, ImGui iOS scaling, overlay scale. Game side: the loop gate —

```c
while (WindowIsRunning()) {
#ifdef __IOS__
    if (!WindowIsFrameReady()) { continue; }
#endif
    push_frame();
}
```
(`S:src/port/Game.cpp:45`). Also audit Starship's audio producer for pause behavior while
backgrounded (the `WindowIsFrameReady` gate stops `push_frame`, which stops
`StartAudioFrame`/`EndAudioFrame` — confirm the producer blocks on its condition variable
rather than spinning: `S:src/port/Engine.cpp:362-414`).

Acceptance (HarkinianPad M6a standard): three consecutive background/foreground cycles in
Simulator on one PID with no crash; game log stalls while backgrounded (no simulation advance)
while the config file's mtime advances at background time; `sf64.o2r`/save/config hashes stable
across cycles; save survives background-then-kill. Replay the depth-read crash scenario
(HarkinianPad found a real `GetPixelDepth` stale-texture SIGSEGV here — the guard must be in
before this gate).

### Phase 6 — Touch controls, stage 1 (M)

New files `ios/StarshipTouchControls.{h,mm}` adapted from
`HP:patches/shipwright-ios-touch-controls.patch` (component identical: button view posting SDL
scancodes, stick view, pass-through hit test, persistent `•••`, menu-visibility hook — renamed
symbols), with the §5.4 SF64 layout: stick low-left; Z pill left shoulder; R pill right
shoulder; A (large) + B right cluster; BOOST/BRAKE pills right rail; VIEW + TALK small buttons;
Start; no D-pad. Bindings via LUS keyboard defaults (stick WASD, A→X, B→C, Z→Z, R→R,
Start→Space, C-buttons→arrows). CVar `gSettings.TouchControls` + Settings→Controls toggle
(Starship's ImGui menu, `S:src/port/ui/ImguiUI.cpp`), LUS `Gui::DrawMenu` hook from the Phase 5
patch. Keep HarkinianPad's Start=Space+Enter and decide the iOS mouse-defaults question (row 16)
here.

Acceptance: clean install → title reachable and navigable by touch alone; in Corneria: fire,
charge shot, bomb, boost, brake, bank both ways, double-tap barrel roll, **somersault (boost +
stick-down) and, in an all-range section, U-turn (brake + stick-down)** all executable by
touch; wingman call answered with TALK during a mission; menu open/close hides/restores the
overlay; toggle works without restart; overlay absent from screenshots when disabled. Package
audit unchanged.

### Phase 7 — Analog stick (stage 2) + physical-controller matrix (M, riskier)

Implement the SDL virtual-controller overlay backend (§5.4 stage 2) behind a CVar
(`TouchAnalog`, default on, fallback to stage 1). Physical-controller pass (HarkinianPad M4
checklist, `HP:docs/BUILDING.md`): MFi/Xbox/PS pairing, gameplay, disconnect/reconnect, and
**rumble verification** — expected free through `SDLRumbleMapping` → SDL → GameController
haptics on iOS 14+; record supported/unsupported per model. Gyro: SF64 has no gyro consumer —
nothing to do.

Acceptance: measurably finer aim than 8-way (record input-viewer or hit-rate evidence);
controller checklist recorded per model; rumble state recorded (works / stubbed per
controller). If virtual-controller registration misbehaves in ControlDeck, ship stage 1 and
file the analog path as a known limitation — do not block the release train on it.

### Phase 8 — Menus, scaling, per-file iOS decisions, first-run polish (S–M)

Starship-side equivalents of HarkinianPad's item-10 sweep: hide the DX11-only "Render
parallelization" toggle on iOS (`S:src/port/ui/ImguiUI.cpp:465`); backend picker shows Metal
only; `ResolutionEditor` gets the console-style stretch option if applicable
(`S:src/port/ui/ResolutionEditor.cpp`); verify ImGui readability on iPhone-class (compact) and
iPad displays with the Phase 5 scale rule; JP/EU/CN voice-pack import exposed in settings;
first-run copy checked on both form factors; `gInvertYAxis` surfaced prominently (flight game).

Acceptance: HarkinianPad M3-style visual audit on iPad + iPhone Simulators; no desktop-only
controls visible on iOS; settings persist.

### Phase 9 — CI, packaging, docs, release gates (S–M)

Adapt wholesale from HarkinianPad: `.github/workflows/ios-build.yml` (repo-safety job +
macos-15 full unsigned build + `package-ios.sh` audit + REQUIRE_SIGNED negative test);
`package-ios.sh` with §5.9 patterns; `generate-port-archive.sh` for `starship.o2r` (host
`GeneratePortO2R` + content audit); `docs/BUILDING.md` (device + Simulator + signing +
controller/touch test protocol); `docs/RELEASE_CHECKLIST.md`; `docs/LICENSES.md` (link-closure
license dump); MIT license for StarshipPad-owned files.

Acceptance: a clean-machine replay (HarkinianPad's public-proof standard: fresh checkout with
only the repo + a ROM under ignored `ref/` → `build-ios.sh --device` → audited unsigned IPA;
`REQUIRE_SIGNED=1` rejects it), then a signed physical-device install exercising the full
first-run and lifecycle matrix, all recorded in the evidence ledger.

---

## 7. Risks

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | **LUS pin `eaaf9d0` is a dangling object** — GitHub could GC it, breaking every fresh clone (upstream Starship included) | Low-medium (it has survived ~4 months unreferenced; GitHub GC of fetched-by-SHA objects is rare but real) | High if unmitigated (bootstrap fails) | Phase 0's insurance: `patches/lus-925-metal-prism.patch` = `diff 09dfab5f..eaaf9d0`; `clone-sources.sh` reconstructs the tree from the always-fetchable `09dfab5f` on fetch failure. Byte-identical result either way |
| R2 | **SDL `release-2.28.1` fails to build under current Xcode/iOS SDKs** (the exact failure class LUS PR #966 fixed on newer branches) | Medium | Low (contained) | Phase 0 detects it on day one; fallback is a one-line bump to `release-2.32.10`, the tag HarkinianPad shipped and device-tested |
| R3 | **Boot-time extraction vs the iOS watchdog** — Starship's current flow blocks pre-window for minutes | Certain if unaddressed | High (app killed at first launch) | Phase 4 restructures the flow window-first, worker-threaded, with progress UI; Phase 3 sidesteps it entirely while the rest of the stack is proven |
| R4 | **Silent device audio** — HarkinianPad's open defect (SDL device inits 2ch/32kHz, no audible output on its physical iPad) may reproduce on the same SDL path | Medium (unresolved upstream of us; root cause unknown) | Medium (game playable but mute) | Track HarkinianPad's resolution before Phase 5 hardware testing; test audio on hardware at Phase 3/4, not Phase 9; if needed, the pin's SDL is bumpable independently; SDL's `SDLInterruptionListener` behavior is already evidence-verified in HP |
| R5 | **Upstream decay**: sonicdcer account gone (with the sf64 decomp root), Starship main quiet since 2026-06-15, README links dead, `/releases` API oddity | Medium (already partially realized) | Low for the build (everything is pinned and push-disabled); medium for long-term rebasing | Patch-replay model assumes zero upstream availability; decomp knowledge survives in KiritoDv/inspectredc forks (C8); no plan dependency on any upstream action |
| R6 | **Touch analog quality** — stage 2 (virtual controller) is unproven in this ecosystem; stage 1's 8-way stick may make rails aiming feel bad | Medium | Medium (product quality, not shippability) | Two-stage plan with stage 1 as the shippable floor; the game's own deadzone/clamp (±16/±60) actually narrows the analog dynamic range, softening the 8-way penalty; measure at Phase 7 |
| R7 | **Frame pacing/ProMotion**: nanosleep pacing + SDL vsync, no CADisplayLink; 120 Hz panels and Stage Manager resizing are untested territory | Medium likelihood of minor jitter; low impact | Low | Default 60 fps; interpolation and match-refresh options exist in Starship already; treat CADisplayLink adoption as a post-1.0 upstreamable improvement (HarkinianPad reached device-stable without it) |
| R8 | **Nintendo climate**: the official "Star Fox" Switch 2 remake released 2026-06-25; historical enforcement correlates with asset/ROM distribution, not engine code (`HP:docs/findings/05-priorart-licensing.md` §B4) | Unknowable | High if the asset posture slips; low otherwise | The §5.9 enforcement stack (no ROM, no `sf64*.o2r`, no extracted assets — in repo, app, IPA, or CI artifacts, ever); hash-verified user-supplied-ROM-only extraction; no-piracy copy in the first-run UI. Noted without editorializing, as instructed |
| R9 | **Extraction memory on 2 GB devices** (~150–250 MB transient, estimate, unmeasured) | Low | Low-medium (jetsam during first run) | Runs before game heaps by construction after the Phase 4 restructure; measure there; document a device floor if needed; desktop-generated-o2r import remains the escape hatch |
| R10 | **`config.yml`/yaml drift**: extraction inputs ship in the bundle; a mismatch between bundled yamls and the pinned Torch/Starship revisions breaks extraction invisibly | Low (everything is pinned together from one Starship checkout) | Medium | Bundle contents come from the same pinned tree the binary was built from (POST_BUILD copy); `torch.hash.yml` output is checked in acceptance |
| R11 | **Four-player versus expectations** — all four slots always read plugged, so the versus menu is enterable with no way for touch to drive P2–P4 | Certain (cosmetic) | Low | Documented limitation; deferred (§5.10); consider hiding versus behind controller-count detection post-1.0 |

---

## 8. Open questions

| # | Question | What resolves it |
|---|---|---|
| Q1 | Does SDL `release-2.28.1` build under the current Xcode/iOS SDK? | Phase 0 build. Fallback pre-decided (R2) |
| Q2 | Is `starship.o2r` (the port archive) verifiably free of Nintendo-derived content? (Expected yes — built by upstream CI from repo-owned `assets/` via `torch pack port`, publicly distributed today) | Enumerate its entries at Phase 3 (`unzip -l`-equivalent for o2r/zip); encode the check into `generate-port-archive.sh` |
| Q3 | What does `izzy2lost/Starship` (Android, shipped APKs) do for touch controls and extraction? Directly reusable design intelligence for Phases 4/6 | Read that repo before Phase 4 (it was identified but not examined in this investigation) |
| Q4 | Runtime QA state of 4-player versus in Starship generally | Community/issue-tracker check; smoke test post-1.0. Not load-bearing (deferred) |
| Q5 | Does any SF64 gameplay/menu path require the D-pad? (None found in `fox_play.c`/menu greps; not exhaustive) | `grep -rn 'DPAD\|BTN_D' src/engine src/overlays` sweep at Phase 6; add a compact D-pad to the overlay only if something needs it |
| Q6 | Does anything in the iOS link closure need libpng? (Expected no: Torch uses stb; SoH needed it only for ZAPD. The Brewfile lists it for desktop) | Phase 2 configure/link |
| Q7 | Does Starship's audio producer sleep correctly while `push_frame` is gated off (no busy-spin, no queue starvation on resume)? | Phase 5 instrumentation on the condvar path (`S:src/port/Engine.cpp:362-414`) |
| Q8 | Is iOS 14.0 the real floor given metal-cpp's `macOS13_iOS16` tag, or is 16.0? (Inherited from HarkinianPad Q10; has never failed a build or modern-device run) | Attempt an install on an iOS 14/15 device or lower the question's priority permanently by raising the target to 16 — decide at Phase 9 |
| Q9 | Is `eaaf9d0`'s tree byte-identical to `09dfab5f` + main's `d1bbd53e` (#925) content? (Assumed materially yes; insurance patch makes it moot for builds) | `git diff` the two trees once; record in the ledger |
| Q10 | Can Torch main's progress-reporting split (`d0042dc`) be cleanly backported to pinned Torch `cd92cc0f` for a real extraction progress bar? | Try the cherry-pick at Phase 4; indeterminate spinner is the fallback |
| Q11 | Do LUS keyboard defaults actually apply when Starship passes empty mapping containers to `ControllerDefaultMappings`? (Expected yes — empty-map fallback pattern; overlay stage 1 depends on it) | One read of the pin's `ControllerDefaultMappings` ctor at Phase 6, or observed behavior at Phase 3 (keyboard works in Simulator) |
| Q12 | Will HarkinianPad's silent-audio defect reproduce here, and what was its root cause? | HarkinianPad's own M3/M6 hardware investigation; StarshipPad tests device audio early (Phase 3/4) either way |
| Q13 | Starship maintainers' posture toward an iOS port (upstreaming interest, naming/branding sensitivities)? Not a plan dependency — StarshipPad publishes independently like HarkinianPad did | Optional outreach once Phase 3 shows a demo; read-only monitoring of LUS #1083 / SpaghettiKart #694 regardless |

---

*Prepared for the StarshipPad project. This document is research and planning only; no code,
branches, or PRs were created. All upstream repositories referenced are treated as read-only
pinned inputs, per the repository rules established by HarkinianPad and adopted here.*
