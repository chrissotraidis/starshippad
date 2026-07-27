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
| 4 | Files import and on-device Torch extraction | Complete on Simulator; hardware gate open | `.z64` and byteswapped `.v64`, responsive extraction, boot/relaunch, voice route, time/RSS |
| 5 | Lifecycle, audio pause, and persistence | Complete on Simulator; hardware gate open | Three cycles on one PID, config flush, simulation stall, save replay |
| 6 | Stage-1 touch controls | Complete on Simulator; hardware grip gate open | Every required Star Fox action executable by touch alone |
| 7 | Analog touch and physical controller matrix | In progress | CVar fallback, aim evidence, per-model controller/rumble results |
| 8 | iOS menus, scaling, and first-run polish | Pending | iPad+iPhone visual audit and persistent settings |
| 9 | CI, packaging, docs, and clean replay | Pending | Fresh-checkout audited unsigned IPA, signed refusal, CI result |

## Active gate

**Phase 7 — Analog touch and physical controller matrix.**

Expected:

1. Add the analog virtual-controller stage behind its own CVar while keeping
   the complete Phase 6 keyboard-event overlay as the default fallback.
2. Prove analog steering and aiming on Simulator without regressing every
   Stage-1 touch action.
3. Record physical-controller detection, gameplay, reconnect, and rumble per
   available model; leave every unavailable hardware result explicitly open.

No physical-controller, rumble, signing, package, or physical-device claim may
be inferred from Simulator touch evidence. Phase 6 remains complete only for
the Stage-1 Simulator gate and unsigned-device compilation.

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

### 2026-07-27 — Phase 4 Files import and extraction passed on Simulator

- Q3 resolved before extraction changes. The local read-only clone of
  `izzy2lost/Starship` was inspected at
  `f2794c26dd0bab87a5f5d755150fb8f025c77379`. Its Android layer persists a
  Storage Access Framework tree URI, copies a prebuilt `sf64.o2r` in 8 KiB
  chunks followed by stream flush and file-descriptor sync, synchronizes
  mods, downloads a separate Torch executable, restarts after import, and
  drives direct touch axes. It does not run Torch in-process: its native
  extractor still requires a hardcoded baserom and the Android flow imports
  an archive produced elsewhere. StarshipPad reused only the relevant
  storage/axis design knowledge; its window-first in-process extraction and
  no-restart transition remain distinct.
- Q10 resolved with the plan's approved fallback. The exact progress commit
  `d0042dc6bfa12a6bee5702aa6b67f9a65873509c` is fetchable in the pinned Torch
  repository, but a focused no-commit cherry-pick conflicts in both
  `src/Companion.cpp` and `src/main.cpp`. The Companion conflict is a
  700-plus-line parser/export restructure against the pinned revision, not a
  small progress callback backport. The attempt was discarded; Torch remains
  pinned and the first-run UI uses an indeterminate spinner.
- The maintained LUS patch adds only the proven renderer-only setup loop
  needed to draw first-run ImGui before game resources exist. The maintained
  Starship patch now scans Files-visible Documents for any case-insensitive
  `.z64`, `.n64`, or `.v64` filename, normalizes all three N64 byte orders in
  memory, validates the existing SHA-1 table, and maps US inputs to
  `Documents/sf64.o2r` and JP/EU/CN inputs to their `Documents/mods/`
  voice-pack archives. It creates the window first, runs one asynchronous
  Torch worker while rendering setup frames, records measured wall time and
  peak RSS, mounts a successful main archive dynamically, and contains no
  normal-flow iOS `exit()`.
- The arm64 iPad Simulator replay built successfully. The app bundle contains
  the audited ROM-free `starship.o2r`, 103 YAML inputs, and no ROM,
  `sf64*.o2r`, `.otr`, or `.ipa`. The current maintained patches both
  reverse-apply cleanly:
  `patches/libultraship-ios.patch` SHA-256
  `460d61e19c3977b82c9e9069fa5153c4bd594f86c8d93ee7088130127cc20b1f`;
  `patches/starship-ios.patch` SHA-256
  `70367f049f8bfcfdf7f1eb6640c160558656ab915ef45227dc7664590f47d59f`.
  This regeneration also corrected a clean-checkout defect found during the
  Phase 4 audit: the earlier patch referenced, but did not contain, the new
  `cmake/ios-deps.cmake`, plist, and asset-catalog JSON files. All five new
  iOS text files and the pure ROM-route header are now patch entries; the
  repository-owned icon remains installed by `apply-source-patches.sh`.
  A disposable checkout at the exact Starship pin accepted the complete
  patch, contained every new iOS text file, passed `git diff --check`, and
  accepted the reverse-apply check.
- Clean-container `.v64` case: the ignored legal US 1.1 ROM was copied to
  Documents as `flight-test.v64`. Rescan logged `format=v64`, normalized and
  identified it as `Star Fox 64 (U) (V1.1)`, and began one worker. The setup
  renderer logged responsive-frame evidence every roughly 30 seconds from
  1,800 through 23,400 frames. Torch reported `Done! Took 394070ms`; the app
  recorded `success=true`, wall time `394073` ms, and peak RSS
  `303202304` bytes.
- That worker produced `Documents/sf64.o2r`, 14,559,161 bytes, SHA-256
  `0f6f6b574161d3da36ef577438d4662553027cc5a70c8837c61b0136e6432c73`,
  and `Documents/torch.hash.yml`, 8,560 bytes, SHA-256
  `f67f74aab580a5e26e78c47a88a849d0f7ada691b5fed01bedc61aa9444d36ce`.
  ZIP integrity passed. The same PID mounted the archive and rendered the game
  intro without restart. Temporary boot capture
  `/tmp/starshippad-phase4-v64-boot.png` has SHA-256
  `ffcc6abcab1a664800ef3837cc1fad5c23f04e8e9291e79ab4a4aa22a45b1509`
  and remains outside Git.
- A terminate/relaunch reused the same archive. Its size, SHA-256, and mtime
  `1785186632` remained unchanged; the app rendered the Nintendo 64 intro
  without a second extraction start. Temporary relaunch capture
  `/tmp/starshippad-phase4-v64-relaunch.png` has SHA-256
  `6da2cac998c733413a49e7ce9911207dfb1b9a099933b81b6255256e796498c3`.
- Clean-container `.z64` case: pairwise normalization
  produced a temporary 12,582,912-byte file with native magic
  `80 37 12 40` and expected SHA-1
  `09f0d105f476b00efa5303a3ebc42e60a7753b7a`. The Files app visibly exposed
  it at `On My iPad/StarshipPad/fox-flight-training.z64`; temporary Files
  capture `/tmp/starshippad-phase4-files-z64.png` has SHA-256
  `3380eb92ecd8bd71c0f990fd6b1eb093edf3bbdf1903b5772a8f49bbe4537ceb`.
  Rescan logged `format=z64`, identified US 1.1, and started the responsive
  extraction worker. The setup renderer remained responsive through 39,600
  logged frames. Torch reported `Done! Took 690828ms`; the app recorded
  `success=true`, wall time `690827` ms, and peak RSS `322617344` bytes.
- The `.z64` worker produced `Documents/sf64.o2r`, 14,559,161 bytes,
  SHA-256
  `22348a12d4706180b507a65d65363e309649ffd7bf2e403df75d721e60ec5b45`,
  plus the same 8,560-byte `torch.hash.yml` content as the `.v64` run. ZIP
  integrity passed. The same PID mounted the archive and rendered the game
  intro. Temporary boot capture
  `/tmp/starshippad-phase4-z64-boot.png` has SHA-256
  `5f9bf54dc68c30044622930b1f537c3f18bdc1dfbc3a0232623bffa1873fda7a`.
- Terminate/relaunch preserved the `.z64` archive's size, SHA-256, and mtime
  `1785187724`. The log still contained exactly one extraction-start marker
  and the relaunched app rendered the game. Temporary relaunch capture
  `/tmp/starshippad-phase4-z64-relaunch.png` has SHA-256
  `1c780fa8fc2ebe4a2c74968eccf82006240ee556aa45e1ec0b8cf671b810acaf`.
- The regional route seam is now a pure compile-time mapping used by the
  runtime extractor, with `Unsupported` explicit instead of defaulting an
  unknown hash to Europe. `scripts/verify-phase4-voice-routes.sh` compiles and
  runs the focused test with the active macOS SDK. It passed all 11 supported
  ROM hashes: four US hashes route to `sf64.o2r`, both JP hashes route to
  `mods/sf64jp.o2r`, all three EU/Spanish hashes route to
  `mods/sf64eu.o2r`, both CN hashes route to `mods/sf64cn.o2r`, and an
  unknown hash remains unsupported. Script SHA-256:
  `f3aadd7efa5d08453c30b9380736506ce202154d6e2b27cbf25448123307be43`;
  focused test SHA-256:
  `624977511a7d7cd23c7ed57f90770596edb93b08e4ddfd2ddcf8cbc7fdf702bb`.
  No legal JP/EU ROM is present under local `ref/`, so this is deterministic
  route proof, not a fabricated end-to-end regional extraction claim.
- `xcrun xctrace list devices` reports only the local M1 Mac under Devices;
  every iOS/iPadOS target listed is a Simulator. No physical iPhone or iPad
  is connected, so a real-device Files move, extraction, RSS, and audibility
  replay is unavailable on this machine and remains an explicit hardware
  gate.
- Final code rebuilt for both arm64 Simulator and unsigned arm64 iPhoneOS;
  both ended `** BUILD SUCCEEDED **`. The final device binary has SHA-256
  `cbd92270cf2f8c3886b078a1fef2f86fa82024d366bbcc158876ddbe80dbedb9`.
  `scripts/audit-ios-app.sh` passed the device bundle, the forbidden-file
  search returned empty, and repository safety passed.
- Boundary: all ROMs, derived archives, extraction hashes, logs, and captures
  remain in `ref/`, Simulator containers, or `/tmp`, never the repository or
  app bundle. Phase 4's reproducible Simulator gate is complete for `.z64`,
  byteswapped `.v64`, Files visibility, Rescan, responsiveness, dynamic boot,
  relaunch, measurements, and deterministic regional routing. This is not a
  physical-device extraction claim. End-to-end JP/EU extraction remains
  untested because no lawful regional input is present; physical-device Files
  move, extraction, RSS, and audio remain open hardware gates. Per the stated
  no-device boundary, the audited unsigned device build plus Simulator matrix
  is the deliverable and execution proceeds to Phase 5.

### 2026-07-27 — Phase 5 lifecycle, audio pause, and persistence passed on Simulator

- The maintained LUS patch now contains the focused shared lifecycle slice:
  all SDL iOS application events, synchronous config flush, a null-safe audio
  pause chain with queued-audio clearing, the playback audio category,
  background frame availability, pixel-depth guards, the public
  `WindowIsFrameReady()` bridge, and adaptive ImGui/overlay scaling. The
  Starship patch gates `push_frame()` before simulation while the window is
  unavailable. The implementation follows the proven HarkinianPad structure
  without adding a second UIKit lifecycle observer.
- Both maintained patches reverse-apply cleanly. Final Phase 5 SHA-256 values:
  `patches/libultraship-ios.patch`
  `4435c0ba7df840a95b9d86397c39323c28e28ad03b69c7f8ff42c1c23f8ecf02`;
  `patches/starship-ios.patch`
  `de754ed17f2e00c9413a64be15998d08a037842e4c7c5f3bd089fbf3ac772ea3`.
  The final arm64 Simulator and unsigned arm64 iPhoneOS builds both ended
  `** BUILD SUCCEEDED **`.
- Runtime target: iPad Pro 11-inch (M4), iOS 18.5 Simulator, UDID
  `08636791-2675-4675-8335-EF72EF954DCF`. Three consecutive
  background/foreground cycles ran on the same PID, `96084`, without a crash.
  The exact pause/resume simulation-frame pairs were `365/365`, `917/917`,
  and `1221/1221`. The first background dwell was 20 seconds and produced no
  intervening game-console output. This directly proves the game simulation
  did not advance while backgrounded.
- Every background transition logged
  `config_flushed=true audio_paused=true`; every foreground transition logged
  `audio_paused=false`. The config mtime advanced at each background:
  `2026-07-27T16:51:28-0500`,
  `2026-07-27T16:52:38-0500`, and
  `2026-07-27T16:53:11-0500`. After the first durable window-state flush, the
  config content remained stable at 12,550 bytes and SHA-256
  `e2ccc3eef6bab8e0debd0f6e32f21ff7a66605ce0b0f162609b3167a29c9a3e8`
  through the remaining cycles and relaunch.
- Integrity across the replay: `Documents/sf64.o2r` remained 14,559,161 bytes
  with SHA-256
  `22348a12d4706180b507a65d65363e309649ffd7bf2e403df75d721e60ec5b45`;
  `Documents/default.sav` remained 512 bytes with SHA-256
  `d29a2c96802e416491746959bd51e4caed84013e7054beafada6280ecd089a6b`.
  For the explicit background-then-kill test, the save had that hash before
  termination and the identical hash, size, and mtime after cold relaunch on
  new PID `96395`. The relaunched title sequence rendered normally.
- The HarkinianPad stale-depth crash scenario was replayed by the repeated
  active-title background transitions after the depth-read guards were in
  place. No StarshipPad crash report newer than the test start was present in
  either the host or Simulator crash-report locations.
- Q7 is resolved. `GameEngine::HandleAudioThread()` waits on
  `audio.cv_to_thread` while `audio.processing` is false; the background game
  gate stops the only `StartAudioFrame()` producer. A one-second process stack
  sample during a later 20-second background dwell captured all 770 samples of
  `GameEngine::HandleAudioThread()` in
  `std::condition_variable::wait` → `_pthread_cond_wait` →
  `__psynch_cvwait`, while the main thread spent 758 of 770 samples in the
  bridge's 16 ms sleep. This proves the audio worker blocks rather than
  spinning when simulation is gated.
- Final Simulator binary SHA-256:
  `5e1594a27d9398f5d47c019da8cd6d5d5ae9cfd6d3ca2ac75e5c7afdeace5c5c`;
  `vtool` reports `platform IOSSIMULATOR`, minimum iOS `14.0`, SDK `26.5`.
  Final unsigned device binary SHA-256:
  `4bcac1d850093b7864c83a04960fdc079f6eeabac8426eaf213f5b9a732dad62`;
  `file`/`lipo` report arm64 and `vtool` reports `platform IOS`, minimum iOS
  `14.0`, SDK `26.5`. `scripts/audit-ios-app.sh` passed the device bundle,
  whose ROM-free `starship.o2r` hashes to
  `b0c6c70d8e0df89381fac0e72e04221e508d8a12cd924c3b114441d9aa45705e`.
  The app is intentionally unsigned and repository safety passed.
- Boundary: this is Simulator lifecycle, simulation, persistence, and
  audio-worker blocking evidence plus a build/audit of the unsigned device
  product. No physical iPhone or iPad is connected, so real-device lifecycle,
  interruption behavior, background suspension, speaker audibility, and
  save persistence remain open hardware gates. Touch, physical controller,
  rumble, signing, package, and CI gates are not claimed. Execution proceeds
  to Phase 6.

### 2026-07-27 — Phase 6 Stage-1 touch controls passed on Simulator

- The maintained Starship patch now carries the complete iOS-only
  `StarshipTouchControls.h` and 646-line Objective-C++ implementation. It
  preserves HarkinianPad's proven UIKit overlay, SDL keyboard-event delivery,
  safe-area layout, empty-space pass-through, independent menu button,
  menu-visibility cancellation, and live CVar toggle. Short taps are held for
  at least 80 ms so one-frame game polling cannot lose them. Buttons expose
  one-second Hold and timed Double Tap accessibility actions; the stick
  exposes Hold Up/Down/Left/Right while retaining ordinary eight-way drag.
- Final bindings follow the game source: WASD stick; X Fire; C Bomb; Z/R
  left/right bank; Space Pause; arrow-left Boost; arrow-down Brake; arrow-up
  View; arrow-right Talk/C-Right; and T/G/F/H D-pad. The persistent `•••`
  button uses F1. The plan inherited Escape from HarkinianPad, but Starship's
  `GuiMenuBar` actually toggles on F1; the observed source contradicted the
  plan, so the binding was corrected here rather than silently drifting.
- Q5 is resolved. An exhaustive `U_JPAD`, `D_JPAD`, `L_JPAD`, and `R_JPAD`
  source sweep found executable D-pad paths in `fox_effect.c`, `fox_hud.c`,
  `fox_turret.c`, `fox_map.c`, `fox_option.c`, and `sys_main.c`. The Stage-1
  overlay therefore includes all four D-pad directions instead of omitting
  them as the plan's provisional table suggested.
- Q11 is resolved. `SetDefaultKeyboardKeyToButtonMappings()` and
  `SetDefaultKeyboardKeyToAxisDirectionMappings()` populate the built-in
  Starship keyboard mappings only when caller-supplied maps are empty. The
  live clean configuration accepted those mappings. Return was added as a
  second Start default alongside Space; existing non-empty user mappings are
  unchanged. Mouse-button defaults were deliberately not added because touch
  already uses the established keyboard path and an incidental secondary
  click would trigger a bomb.
- Runtime target: iPad Pro 11-inch (M4), iOS 18.5 Simulator, UDID
  `08636791-2675-4675-8335-EF72EF954DCF`. The final accessibility tree exposed
  Fire, Bomb, both banks, Pause, Menu, Boost, Brake, View, Talk, four D-pad
  directions, and the directional stick actions. Touch alone moved from title
  through menu and mission selection into gameplay. Settings → Controller →
  Touch Controls removed and restored the gameplay overlay immediately, and
  Menu removed all gameplay controls while preserving the independent Menu
  button, then restored them on close.
- Fire produced visible lasers; a one-second Fire hold produced the blue
  charged shot; Bomb reduced the HUD count from three to two. Boost and Brake
  each drove their visible meter/effect. One-second left and right bank holds
  moved and banked the Arwing; the left-bank Double Tap action produced the
  complete barrel-roll rotation. Pause stopped gameplay and resumed it with a
  second tap. Talk was activated while Peppy's wingman-answer prompt was
  visible and the prompt cleared into continued play.
- The required chords were replayed through two concurrent accessibility
  actions, not a keyboard or controller shortcut. Boost Hold plus Control
  Stick Hold Down produced the somersault camera pull-back and Arwing loop.
  In Training all-range mode, Brake Hold plus Control Stick Hold Down produced
  the U-turn climb/rotation. The U-turn setup itself was reached through touch
  gameplay; no debug warp or non-touch setup input was used.
- The temporary Nintendo-content captures remain only under `/tmp`. Aggregate
  SHA-256 values over sorted per-frame SHA-256 manifests are: Fire 16 frames
  `3e22051366789488c4473f107b51f19991953ddd326862407b13ae921fd651a4`;
  charge 24 frames
  `89b69511b9019457db4705b6f9ac14ad5f900ddd4702c474386ebd7e878f48a0`;
  Boost 18 frames
  `4357d85d2a8a6ceb235583a93bb7cbb53e7d04ff72fa0cc41ca5b14b38e69251`;
  Brake 16 frames
  `014167b68f8ebce48cd9a3e8955ff45dd1e74cbb8dcbe037927968fad043de85`;
  left/right bank 14/10 frames
  `d45d567a24c06e4755a0862e7bbbc7860abbd5b6d517020b97bb1c09fd37c2e2` /
  `588b226952c43f63f82601ea1141d92168e7f6eafd76d874fb1cbedaa5ba8fa5`;
  barrel roll 18 frames
  `8778c3639fc1e3cec405fd54729c51c9ed6890bf014f27a9e42f8b1b2c7c5999`;
  Talk 16 frames
  `32e8a4a3c2ebe81a2238f8ba2b26904d4bda1da049317457c9743c5b2be2492b`;
  somersault 36 frames
  `8ab6c48448f131911516f8a0498b5fb5b683b8028bd100f4d881c16dacd6757a`;
  and all-range U-turn 32 frames
  `a4f4ab7421324a8604656d92ba1f024826c235e39675250792e05c8af67d58a7`.
- The clean-patch audit caught and fixed one reproducibility defect before the
  gate closed: CMake references to the two new touch files were present while
  those untracked upstream-worktree files were initially absent from the
  maintained diff. The final patch includes both files and reverse-applies
  cleanly. Disposable clones at the exact Starship and LUS pins accepted
  apply, `git diff --check`, and reverse-apply; the Starship clone contained
  both touch files after apply. Final patch SHA-256 values are
  `patches/starship-ios.patch`
  `69b0848fabbb33fba8a7fab34f1d42d3c5f4a4471d0864af844a7f0b0b5e73d4`
  and `patches/libultraship-ios.patch`
  `0957d740b035f55fe4ce9a7f8d68cd385d196ffc594387ec3bbb638b096358b8`.
- `scripts/build-ios.sh --device` replayed the pinned bootstrap, both complete
  maintained patches, explicit `ENABLE_SCRIPTING=OFF`, OS64 arm64, and iOS
  14.0, then ended `** BUILD SUCCEEDED **`. The final unsigned device binary
  is SHA-256
  `ec0c81b4d14eb710736eb995f4f0d181855418ed17dd488328bda416d618c023`;
  `lipo` reports arm64 and `vtool` reports platform IOS, minimum 14.0, SDK
  26.5. The bundled ROM-free `starship.o2r` remains
  `b0c6c70d8e0df89381fac0e72e04221e508d8a12cd924c3b114441d9aa45705e`.
  App audit, forbidden-file audit, patch reverse checks, `git diff --check`,
  and repository safety all passed.
- Boundary: this closes Stage-1 touch behavior on Simulator and compilation
  of the same source for unsigned iPhoneOS. It does not prove physical thumb
  comfort, simultaneous-touch feel on glass, physical-device rendering or
  audio, a physical controller, reconnect, rumble, signing, IPA packaging, or
  CI. No physical iPhone, iPad, or controller is connected. Those hardware
  results remain open, and execution proceeds to Phase 7.

## Open-question resolution ledger

| Question | Resolution phase | State | Evidence |
|---|---|---|---|
| Q1 SDL 2.28.1 under current SDK | 0 | Resolved | Fails at configure under CMake 4.4; SDL 2.32.10 passes after one further spdlog 1.16.0 compiler correction |
| Q2 `starship.o2r` content audit | 3 | Resolved | Exact 13-file tracked manifest and byte equality; no ROM-derived content |
| Q3 izzy2lost Android techniques | 4 | Resolved | Android imports a prebuilt archive and restarts; only SAF storage and direct-axis ideas transfer |
| Q4 four-player versus state | Post-1.0 | Deferred | Not load-bearing |
| Q5 D-pad use | 6 | Resolved | D-pad is executable in HUD/effects, turret, map, options, and system code; all four directions are included |
| Q6 libpng in iOS closure | 2 | Resolved | Configure and final link closure contain no libpng |
| Q7 audio producer sleep | 5 | Resolved | Source gate plus background stack sample captured the worker in `__psynch_cvwait` for all 770 samples |
| Q8 true iOS floor | 9 | Open | Device/install evidence or explicit floor decision |
| Q9 LUS pin versus upstream squash | 0 | Resolved | Identical stable patch ID `b08ae8b1`; different parent trees documented |
| Q10 Torch progress backport | 4 | Resolved | Exact commit conflicts across a large Companion rewrite; approved indeterminate spinner fallback used |
| Q11 empty keyboard defaults | 6 | Resolved | Empty maps populate built-ins; clean live config used them; Return added as a second Start default |
| Q12 silent-audio reproduction | 3/4 | Open | Simulator SDL init passed at 32000 Hz stereo/1024; physical-device audibility remains open |
| Q13 upstream posture | Optional | Deferred | Not a plan dependency |

## External constraints

- Simulator proof will not be represented as physical-device proof.
- If no connected device or signing team is available, the unsigned device
  build plus Simulator matrix is the deliverable and all hardware gates stay
  open.
