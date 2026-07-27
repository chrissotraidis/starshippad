# StarshipPad remaining work

This is the authoritative execution queue and proof log for the goal in
[`starshippad-implementation-plan.md`](starshippad-implementation-plan.md).
The research in that plan and the local-only `ref/harkinianpad/` reference
remain the technical baseline; this file records current state, tested
evidence, and the next reproducible gate.

## Goal

Deliver a reproducible native iOS/iPadOS port of Star Fox 64 through
HarbourMasters/Starship, with touch input and the established physical
controller path, from pinned upstream inputs through an audited package. A
passing intermediate build or runtime gate is progress, not completion.

## Invariants

- User-supplied, legally acquired ROM only.
- Never commit or distribute ROMs, ROM-derived `sf64*.o2r` archives,
  extracted Nintendo assets, or local reference material. The ROM-free
  `starship.o2r` may be bundled only as an ignored build product.
- `chrissotraidis/starshippad` is the sole owned project and publication
  repository. Starship, libultraship, Torch, their forks, and their pull
  requests are read-only inputs.
- Upstream source inputs are pinned, disposable, and push-disabled.
- Keep `ENABLE_SCRIPTING` off. Never adopt a runtime-codegen path.
- Keep engine-layer and application-layer changes separate in maintained
  patches.
- Treat local, CI, Simulator, physical-device, signing, audio, touch, and
  controller evidence as separate gates.
- Make the smallest maintainable change for the first reproducible failure,
  then replay that gate.
- Run `scripts/check-repo-safety.sh` before every commit.

## Repository and source boundary

| Tree | Role | Revision |
|---|---|---|
| `chrissotraidis/starshippad` | Sole owned project and publication repository | `795c7fd` baseline |
| `HarbourMasters/Starship` | Pinned upstream source input | `6202c443` |
| `Kenix3/libultraship` | Pinned upstream source input | `eaaf9d0fc91e2c400f49ef2a1f8547a691ce4d3c` |
| `HarbourMasters/Torch` | Pinned upstream source input | `cd92cc0f` |

`scripts/clone-sources.sh` resolves these revisions under ignored `sources/`,
disables every upstream push URL, and maintains the LUS dangling-pin
reconstruction patch. Durable implementation, scripts, patches, docs, and
evidence belong to StarshipPad.

## Milestone queue

| Phase | Gate | State | Required evidence |
|---|---|---|---|
| 0 | Pinned bootstrap and minimally corrected LUS iOS library | Complete | Three verified pins, insurance patch, iphoneos `libultraship.a`, arm64 `lipo` |
| 1 | Focused LUS link patch | Complete | Clean apply/reverse-apply and replayed LUS build |
| 2 | Full Starship iOS app compiles and links | Complete | arm64 app, iOS 14.0 load command, bundle validation, forbidden-file audit |
| 3 | Metal title screen in iPad Simulator | Complete | Capture, runtime log, SDL audio-init line |
| 4 | Files import and on-device Torch extraction | In progress | `.z64` and byteswapped `.v64`, responsive extraction, boot/relaunch, voice route, time/RSS |
| 5 | Lifecycle, audio pause, and persistence | Pending | Three cycles on one PID, config flush, simulation stall, save replay |
| 6 | Stage-1 touch controls | Pending | Every required Star Fox action executable by touch alone |
| 7 | Analog touch and physical controller matrix | Pending | CVar fallback, aim evidence, per-model controller/rumble results |
| 8 | iOS menus, scaling, and first-run polish | Pending | iPad+iPhone visual audit and persistent settings |
| 9 | CI, packaging, docs, and clean replay | Pending | Fresh-checkout audited unsigned IPA, signed refusal, CI result |

## Active gate

**Phase 4 — Files import and on-device Torch extraction.**

Expected:

1. Read and record the load-bearing techniques in the izzy2lost Android
   implementation before changing extraction.
2. A clean app container imports both a `.z64` and byteswapped `.v64` with
   arbitrary filenames through Files, provides Rescan, keeps the UI
   responsive while extraction runs off the main thread, and boots the
   extracted game.
3. A relaunch reuses `sf64.o2r` without extraction. A JP or EU input routes
   to the voice-pack path instead of failing as the main game.
4. Record wall-clock time and peak resident memory for the on-device
   extraction path. Estimates do not count as evidence.

No physical-device extraction result may be inferred from Simulator evidence.
Lifecycle, touch, controller, signing, and package claims remain outside this
gate.

## Evidence log

### 2026-07-27 — Phase 0 baseline and reference review recorded

- Checkout: clean `main` at
  `795c7fd` (`Add StarshipPad implementation plan and repository ignore
  rules`), equal to `origin/main` before Phase 0 work.
- Authoritative plan:
  `docs/starshippad-implementation-plan.md`, SHA-256
  `00f403b6e93f0f2d87c926c998549992ce93ae0d0ebea13230a4f14beda8733c`,
  read in full before implementation.
- Reference review: the HarkinianPad evidence ledger, build/release docs,
  five findings reports, seven scripts, six maintained patches, and exact
  522-line UIKit touch component were reviewed before implementation.
  Reference ledger SHA-256:
  `82383d8c5f4f56da6b56a9df2e245ed60ab4d809b54bc8ed954d4b577afe4bc3`;
  LUS patch SHA-256:
  `e4de4ee9814138bf5ad87849b6742166d427c79afae66cbecae499f9fd2ec648`;
  touch patch SHA-256:
  `2836294d07a37bdcbcd3fbd3d8f07af40fa7f53a1e9f77a932f7bee6080cd9c4`.
- Local toolchain: Xcode 26.6 (`17F113`), iPhoneOS SDK 26.5, CMake 4.4.0,
  Git 2.36.1.
- Local-only ROM input: ignored `ref/Starfox 64 1.1 (U).v64`, 12,582,912
  bytes, SHA-256
  `599e604c59db55a64c5a5bedef1e22bf0a776a43526c5745d80d24a1cb45727e`.
  It is not a Phase 0 compile input and is not present in Git.
- Boundary: no source bootstrap or build result is claimed yet. The active
  gate remains the unpatched LUS iPhoneOS build.

### 2026-07-27 — Phase 0 pinned bootstrap and LUS iPhoneOS library passed

- `scripts/clone-sources.sh` resolved and verified:
  Starship `6202c44356fee70dd23e80a16933b211863d3e2d`,
  libultraship `eaaf9d0fc91e2c400f49ef2a1f8547a691ce4d3c`,
  and Torch `cd92cc0f161c5e79e36f5dda0d0029edd3fc8d50`.
  Starship's two gitlinks match those LUS and Torch revisions. All three
  `origin` push URLs are `disabled://starshippad-upstream-input`.
- The dangling-pin insurance patch is exactly
  `git diff 09dfab5fb2a9a047a6e268dc9db2daad9b2ce5f0..eaaf9d0fc91e2c400f49ef2a1f8547a691ce4d3c`.
  Its SHA-256 is
  `c6817eeb41068e6e7b6a18614a6b8112a9202959d19b1d992840e8b2ba7133ec`;
  applying it to the base produces tree
  `1e27f25eeecab5b262dd274fab4ebeeb9e8cb2e4`, exactly the pinned LUS
  tree. The bootstrap contains the tested direct-fetch and reconstruction
  paths.
- The unmodified pin did not configure under CMake 4.4.0: SDL
  `release-2.28.1` stops at its `CMakeLists.txt:3190` because compatibility
  with CMake before 3.5 has been removed. Per the plan's pre-approved Q1
  fallback, the maintained patch changes only that tag to
  `release-2.32.10`.
- With only the SDL correction, compilation reached LUS and then failed in
  `src/utils/stox.cpp`: spdlog 1.14.1's bundled fmt emitted
  `call to consteval function ... is not a constant expression` under the
  Xcode 26.6 C++20 compiler. Upstream LUS mobile commit `e8fe0b7d` resolves
  the same dependency set by moving spdlog to 1.16.0. StarshipPad adopted
  only that additional pin change, not the unrelated nlohmann-json,
  tinyxml2, or libzip bumps. This is a measured correction to the plan's
  assumption that spdlog 1.14.1 would build.
- Reconfigure then reported SDL
  `SDL-release-2.32.10-0-g5d2495703`, spdlog 1.16.0, iPhoneOS SDK 26.5,
  and minimum deployment version 14.0. The incremental replay ended
  `** BUILD SUCCEEDED **`.
- Artifact:
  `build-ios-lus/src/Release-iphoneos/libultraship.a`, 4,112,936 bytes,
  SHA-256
  `8434998d908fab28504819488c5b9d855a029962901a8dd669b60595bafc01a8`.
  `xcrun lipo -info` reports `architecture: arm64`. Extracted member
  `Context.o` is `Mach-O 64-bit object arm64`; `xcrun vtool -show-build`
  reports `platform IOS`, `minos 14.0`, and `sdk 26.5`.
- Q9: `eaaf9d0` and upstream squash `d1bbd53e` have the same one-file,
  two-line Metal/Prism change and the same stable patch ID
  `b08ae8b107af207a61c9f7e2e6b7e37d59053418`. Their full repository trees
  differ because they have different parents; applying the identical patch
  to `09dfab5f` produces the pinned tree, which is the property the
  reconstruction path requires.
- Environment boundary: the first build attempt inside the filesystem
  sandbox could not write Xcode/CoreSimulator caches; the approved Xcode
  replay reached the compiler and produced the evidence above. No Starship
  app, Simulator boot, physical-device run, signing, touch, ROM extraction,
  or package result is claimed by Phase 0.

### 2026-07-27 — Phase 1 focused LUS link patch passed

- `patches/libultraship-ios.patch` contains exactly four files and only:
  the Phase 0 SDL/spdlog corrections; the `PLATFORM` preservation guard;
  deletion of the iOS Documents override from `GetAppBundlePath`; and
  macOS-only guards around the `macUtils` include and two fullscreen call
  sites. SHA-256:
  `ce81e8a23d2d6a60548a908622e940125238d17cd8b710f4bb9b2a950dae9a8a`.
- A fresh local clone detached at
  `eaaf9d0fc91e2c400f49ef2a1f8547a691ce4d3c` accepted
  `git apply --check`, applied with a clean `git diff --check`, and accepted
  `git apply --reverse --check`. Its resulting diff SHA-256 is the same
  `ce81e8a...`, proving the tracked patch is the exact source delta.
- `scripts/apply-source-patches.sh` applies the LUS patch idempotently and is
  ready to layer the Phase 2 Starship patch when it exists.
- Reconfigure with explicit `-DPLATFORM=OS64` reported
  `Configuring iphoneos build for platform: OS64, architecture(s): arm64`,
  target triple `arm64-apple-ios14.0`, and minimum deployment 14.0. This
  proves the new guard no longer overwrites Starship's device platform with
  `OS64COMBINED`.
- The patched replay ended `** BUILD SUCCEEDED **`. Artifact
  `build-ios-lus/src/Release-iphoneos/libultraship.a` is 4,113,552 bytes,
  SHA-256
  `8ebf93353de0dc57bac9beac2f7900392dd929b7241b1e3a719e13508106b4b6`.
  `lipo` reports arm64; extracted `Context.o` reports `platform IOS`,
  `minos 14.0`, `sdk 26.5`. Undefined-symbol inspection finds neither
  `isNativeMacOSFullscreenActive` nor `toggleNativeMacOSFullscreen`.
- Boundary: no full Starship application has configured or linked yet, so no
  app bundle, Simulator, device, signing, touch, extraction, or package claim
  is made.

### 2026-07-27 — Phase 2 full unsigned StarshipPad app link passed

- `patches/starship-ios.patch` applies to pinned Starship
  `6202c44356fee70dd23e80a16933b211863d3e2d`, adds six text files/deltas,
  reverse-applies cleanly, and has SHA-256
  `720ffb137c755cffeb7da1da0311cbfff396083cd60ab56f61d4205a5b42766d`.
  The patch supplies `ios/Info.plist.in`, the asset-catalog metadata,
  `cmake/ios-deps.cmake`, the native bundle and SDL2main wiring, and the
  iOS-only dependency/link slice. The original StarshipPad-owned icon is
  tracked separately, matching HarkinianPad's asset-copy pattern:
  `ios-assets/AppIcon.svg` SHA-256
  `c06c18cf33dba898b9d62bcd98f08488c1ae081a15286b809d9ee871fa878080`;
  opaque 1024x1024 `AppIcon.png` SHA-256
  `77be15423fd37e9d6c4f0bebd500a6d89272e8d55da4965e2a751c36f5bffc22`.
- Clean configure: OS64, arm64, target triple
  `arm64-apple-ios14.0`, iPhoneOS SDK 26.5, spdlog 1.16.0, Ogg 1.3.6,
  Vorbis 1.3.7, and Threads found. The configure reported no libpng
  dependency or target. Host-only `TorchExternal`, `ExtractAssets`, and
  `GeneratePortO2R` are excluded from the iOS project; the in-process Torch
  library remains in the link.
- First reproducible compile failure: two redundant global
  `libultraship/src/config` include paths caused libzip's C source to resolve
  its `"config.h"` include to LUS's C++ header and fail on `<vector>`. No
  Starship source outside LUS includes a bare config header, so the two
  redundant paths were removed. The replay then reached libzip itself.
- Second reproducible compile failure: Starship's vendored iOS toolchain used
  static-library `try_compile` checks, falsely setting `HAVE_MEMCPY_S=1`
  without linking. That produced an undeclared `memcpy_s` call on iOS. The
  patch enables the toolchain's documented `ENABLE_STRICT_TRY_COMPILE`
  option. A new clean configure then reported `Looking for memcpy_s - not
  found`; no hard-coded libzip workaround or unrelated dependency bump was
  needed.
- Full build command used unsigned generic-device settings and ended
  `** BUILD SUCCEEDED **`. Xcode ran
  `builtin-validationUtility ... StarshipPad.app -shallow-bundle` without
  diagnostics.
- Product:
  `build-ios/Release-iphoneos/StarshipPad.app/StarshipPad`, 8,291,952 bytes,
  SHA-256
  `0beebf3ecfb712e5d7e929732aff96b8d89fcca94e67e2a5b37d869365592e2f`.
  `file` and `lipo` report arm64; `vtool` reports `platform IOS`,
  `minos 14.0`, `sdk 26.5`. The app is intentionally unsigned.
- Processed bundle metadata proves identifier `com.example.starshippad`,
  version 2.0.0, iPhone+iPad device families, landscape-only orientations,
  Files sharing/open-in-place, arm64+Metal requirements, full-screen/status
  bar behavior, ExtendedGamepad support, launch-screen dictionary, and a
  compiled app icon. The 10,526,720-byte bundle has 111 files, including 103
  YAML inputs, `config.yml`, `Assets.car`, and the pinned controller database
  with expected SHA-256
  `eb002773dc8a16aa96f9ee2609798e231a9deb60c45e21fbdd4e221c9e8b7d77`.
- `scripts/audit-ios-app.sh` passed: arm64/iPhoneOS/iOS-14 metadata, required
  resource presence, clean plist, no ROM, ROM-derived archive, unexpected
  `.o2r`, `.otr`, `.mpq`, or stale signing material.
- Q6 resolved: the complete link command contains no libpng. Torch links
  without it; only Ogg and Vorbis were added for Starship audio.
- Boundary: Phase 2 deliberately links without `starship.o2r`; Phase 3 is the
  first gate that generates and audits that ROM-free archive, generates the
  local-only `sf64.o2r`, and attempts a Simulator boot. No title-screen,
  audio-init, physical-device, touch, extraction, lifecycle, signing, or IPA
  claim is made here.

### 2026-07-27 — Phase 3 Metal iPad Simulator boot passed

- `scripts/generate-port-archive.sh` performs the pinned host build and audits
  `starship.o2r` before it can be bundled. It requires the archive manifest to
  equal `git ls-files port` exactly, compares every archived byte with its
  tracked source file, and rejects ROM/archive names. Script SHA-256:
  `a941c674ddbbe9757913ce39fcf728b6c700a210a4da08b93580b95c141f2e5c`.
- First clean host failure: Torch's standalone spdlog 1.12 snapshot fails under
  Xcode 26.6 in bundled fmt with the same constant-expression class seen in
  Phase 0. The Starship patch moves only standalone Torch to spdlog 1.16.0.
  Its external build then exposed that the default multi-game factories pull
  unrelated format code into the SF64 tool. The host external project now
  explicitly disables SM64, MK64, F-Zero, and Mario Artist while keeping SF64
  and NAudio enabled. NAudio cannot be disabled because Torch's Companion
  unconditionally owns its audio manager. This is a build-scope correction,
  not a Torch revision change; Torch remains pinned at `cd92cc0f`.
- The replay built `GeneratePortO2R`. The resulting ROM-free
  `sources/Starship/starship.o2r` is 10,536 bytes, has SHA-256
  `b0c6c70d8e0df89381fac0e72e04221e508d8a12cd924c3b114441d9aa45705e`,
  and contains exactly 13 tracked `port/` files: nine HUD-arrow assets plus
  four tracked Metal, OpenGL, and DirectX shader files. ZIP integrity, exact
  manifest equality, byte equality, and repository safety all passed.
- Q2 resolved: `starship.o2r` contains only the 13 repository-owned files
  above. It contains no ROM bytes, extracted game assets, `sf64.o2r`, or other
  untracked input.
- Phase 3's local boot fixture stayed outside the repository. Torch correctly
  rejected the raw byteswapped `.v64`, whose SHA-256 is recorded in the
  Phase 0 entry. A temporary pairwise byte swap produced a supported US 1.1
  `.z64` with SHA-1
  `09f0d105f476b00efa5303a3ebc42e60a7753b7a` and SHA-256
  `385bcf1901ed12fb1152f3c227d1968cc54ae41e8566da66695df71af40a573f`.
  Host Torch generated `/tmp/starshippad-phase3-runtime.FKKYZ0/sf64.o2r`,
  14,559,161 bytes, SHA-256
  `4233ea3755b554020db8fbe76e212e270d383ab973de9f8003c81e4fe6bb2444`;
  `unzip -tq` passed. Torch reported `Done! Took 950839ms`. This is host-fixture
  timing only and is not the Phase 4 on-device wall-clock or memory result.
- First Simulator link failure: libzip's Zlib and BZip2 discovery leaked
  absolute iPhoneOS SDK paths into an arm64 simulator link. The focused LUS
  patch now derives both paths from `CMAKE_OSX_SYSROOT`. Reconfigure reported
  both libraries in `iPhoneSimulator26.5.sdk`, and the exact link replay ended
  `** BUILD SUCCEEDED **`.
- The final simulator app binary is 8,353,656 bytes, SHA-256
  `d958d3be2becac240638a60e00c7c3e5a61c6446d1999fd634b3e445c1661416`.
  `file` and `lipo` report arm64; `vtool` reports `platform IOSSIMULATOR`,
  `minos 14.0`, and `sdk 26.5`. The bundle carries the audited
  `starship.o2r` with the same SHA-256 and no `sf64.o2r`.
- Runtime target: iPad Pro 11-inch (M4), iOS 18.5,
  UDID `08636791-2675-4675-8335-EF72EF954DCF`. After uninstall/install, the
  clean data container received only the temporary derived `sf64.o2r`.
  Runtime logs prove both the Documents archive and bundled
  `StarshipPad.app/starship.o2r` were opened.
- The successful SDL device-open path previously logged only failures. One
  success log was added at that existing boundary. The final run recorded:
  `SDL audio initialized: 32000 Hz, 2 channels, 1024 samples`.
- The same final binary reached the Star Fox 64 title screen through the
  Metal-capable simulator build. Temporary capture
  `/tmp/starshippad-phase3-seq-1.png` is 1668x2420 and has SHA-256
  `51cefde9574fb2563d8a52ac2fe4d04587caabef4ff8495fe6d786e903f20282`.
  It remains outside Git because it depicts Nintendo-owned game content.
  The headless Simulator LCD was portrait while the landscape-only game
  surface was rotated within it; the complete title frame is visible.
- Current maintained patch SHA-256 values after the Phase 3 corrections:
  `patches/libultraship-ios.patch`
  `7b149c6982efd43d53f19c9ee5300c7a64994c8d0096fb87ed0a9e8dc65ab6e8`;
  `patches/starship-ios.patch`
  `86922148433fe81726df52dd1fc58f6a64786ba377f995ec61f98aebe5735b46`.
- Boundary: this is Simulator Metal/title and successful SDL initialization
  evidence only. It is not physical-device audio, speaker audibility,
  on-device extraction, Files-import, lifecycle, touch, controller, signing,
  or package evidence. The raw ROM, normalized ROM, `sf64.o2r`, screenshots,
  source checkouts, and build directories remain ignored or under `/tmp` and
  are not commit inputs.

## Open-question resolution ledger

| Question | Resolution phase | State | Evidence |
|---|---|---|---|
| Q1 SDL 2.28.1 under current SDK | 0 | Resolved | Fails at configure under CMake 4.4; SDL 2.32.10 passes after one further spdlog 1.16.0 compiler correction |
| Q2 `starship.o2r` content audit | 3 | Resolved | Exact 13-file tracked manifest and byte equality; no ROM-derived content |
| Q3 izzy2lost Android techniques | 4 | Open | Read before Phase 4 |
| Q4 four-player versus state | Post-1.0 | Deferred | Not load-bearing |
| Q5 D-pad use | 6 | Open | Exhaustive source sweep |
| Q6 libpng in iOS closure | 2 | Resolved | Configure and final link closure contain no libpng |
| Q7 audio producer sleep | 5 | Open | Condvar instrumentation |
| Q8 true iOS floor | 9 | Open | Device/install evidence or explicit floor decision |
| Q9 LUS pin versus upstream squash | 0 | Resolved | Identical stable patch ID `b08ae8b1`; different parent trees documented |
| Q10 Torch progress backport | 4 | Open | Focused cherry-pick attempt |
| Q11 empty keyboard defaults | 6 | Open | Source read + observed input |
| Q12 silent-audio reproduction | 3/4 | Open | Simulator SDL init passed at 32000 Hz stereo/1024; physical-device audibility remains open |
| Q13 upstream posture | Optional | Deferred | Not a plan dependency |

## External constraints

- Simulator proof will not be represented as physical-device proof.
- If no connected device or signing team is available, the unsigned device
  build plus Simulator matrix is the deliverable and all hardware gates stay
  open.
