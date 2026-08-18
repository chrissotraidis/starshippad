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
- Keep engine-layer, application-layer, and build-tool corrections separate
  in maintained patches.
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
| 7 | Analog touch and physical controller matrix | Complete on Simulator; hardware matrix open | CVar fallback, aim evidence, per-model controller/rumble results |
| 8 | iOS menus, scaling, and first-run polish | Complete on Simulator; hardware gate open | iPad+iPhone visual audit and persistent settings |
| 9 | CI, packaging, docs, and clean replay | Local gate complete; CI externally blocked | Fresh-checkout audited unsigned IPA and signed refusal passed; GitHub Actions did not start because of account billing/spending policy |
| Post-9 | Low-grip iPad touch and public README parity | Local gate complete | HarkinianPad geometry parity, two-orientation iPad Simulator interaction, unsigned device link, audited IPA |

## Active gate

**Phase 9 — CI blocked before runner allocation.**

Local clean-replay, packaging, and publication evidence has passed. GitHub
Actions is the remaining gate, but the service currently refuses to allocate
even the Ubuntu safety runner because of the account's billing/spending state.

Required external action: resolve the GitHub account billing/payment or Actions
spending-limit condition, then rerun workflow
`StarshipPad iOS build` at the current `main`. A green repository-safety job
and green macOS unsigned build/package job are still required to pass Phase 9.

No signed install, physical-device, physical-controller, rumble, or audible
speaker result may be inferred from the unsigned package or Simulator matrix.
Those hardware gates remain explicitly open on this machine.

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
- This early product used a placeholder bundle identifier and inherited
  Starship's 2.0.0 version. Preview 2 supersedes both with the deliberate
  StarshipPad identifier and 0.1.0 release metadata. The early build also
  proved iPhone+iPad device families, landscape-only orientations,
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
- Runtime target: iPad Pro 11-inch (M4), iOS 18.5 Simulator. After
  uninstall/install, the
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
- Runtime target: iPad Pro 11-inch (M4), iOS 18.5 Simulator. Three consecutive
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
- Runtime target: iPad Pro 11-inch (M4), iOS 18.5 Simulator. The final
  accessibility tree exposed
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

### 2026-07-27 — Phase 7 analog touch passed on Simulator; hardware matrix recorded open

- The touch overlay now attaches an SDL virtual game controller when both
  `gSettings.TouchControls` and the new default-on
  `gSettings.TouchAnalog` CVar are enabled. The stick writes continuous
  left-X/left-Y values; Fire, Bomb, banks, Pause, Boost, Brake, View/Talk,
  and D-pad controls write standard controller buttons or axes. Menu remains
  on the proven F1 keyboard path. Any attach/open/write failure and an
  explicit Analog Touch disable both preserve the complete Phase 6
  keyboard-event fallback.
- The diagnostics-free runtime attached the virtual controller on iPad Pro
  11-inch (M4), iOS 18.5 Simulator. Touch Start advanced the title to the main
  menu; virtual D-pad Down plus A selected and entered Training. This proves
  the virtual device was consumed by LibUltraShip's ControlDeck rather than
  merely registered with SDL.
- A temporary diagnostic was placed at LibUltraShip's actual
  `SDL_GameControllerGetAxis` read boundary. Three touch-stick test
  deflections produced left-X values `8192`, `16384`, and `32767`, exactly
  25%, 50%, and 100% of the positive SDL range. The condensed evidence log
  `/tmp/starshippad-phase7-analog-distinct.log` has SHA-256
  `0e55ad1ca5b47b589b155060881d45c07651ecf489aca70beea63c97138b5e3d`.
  Because ControlDeck received three distinct magnitudes from one direction,
  this is measurably finer than the Stage-1 eight-way/full-deflection input.
  The diagnostic code and its temporary accessibility actions were removed
  before the maintained patch and final products were generated.
- Settings → Controller → Analog Touch disabled the CVar live, detached the
  virtual controller, and left the Stage-1 keyboard path operational: touch
  Start and A still advanced the title and selected a game path. Re-enabling
  it live attached a new controller instance. The detach/reattach log
  `/tmp/starshippad-phase7-toggle.log` has SHA-256
  `5b7151aefb71a33f12fef7e5fba2bcbab165cf27ca7a2d023d8a3457a76c5def`.
  The restored config persisted both `TouchAnalog: 1` and
  `TouchControls: 1`. The temporary settings capture has SHA-256
  `452fd3401926d79348af1e00e16cab59813eafefd2b8cfe1365b1dfd43831979`.
- The final diagnostics-free Simulator process, PID `20589`, logged only
  `StarshipPad analog touch controller attached: instance=2`; no diagnostic
  marker remained. Final Simulator binary SHA-256:
  `020595171292f8589b0a16fb98a4e95647f427643b6e56a978a3bbac4f20d0e4`.
  `lipo` reports arm64; `vtool` reports platform IOSSIMULATOR, minimum 14.0,
  SDK 26.5.
- Physical-controller checklist on this machine:

  | Model class | Pair/detect | Gameplay | Disconnect/reconnect | Rumble |
  |---|---|---|---|---|
  | MFi | Not available | Not tested | Not tested | Not tested |
  | Xbox | Not available | Not tested | Not tested | Not tested |
  | PlayStation | Not available | Not tested | Not tested | Not tested |

  `xcrun xctrace list devices` reports only the local M1 Mac as a physical
  device and no connected iPhone or iPad. Bluetooth/USB inventory SHA-256 is
  `d42ce8f9660f2cff075767683152939c6d15013deaf2f42d113b907840721c2a`;
  the GameController I/O Registry query was empty (SHA-256
  `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`).
  The compiled path still contains LUS `SDLRumbleMapping` through SDL and
  GameController/CoreHaptics, but no physical model exists here to claim
  pairing, reconnect, or rumble. SF64 has no gyro consumer, so no gyro work
  was added.
- The final Starship patch reverse-applies and has SHA-256
  `4a4a2e770020d1092c81eac4a0849a13a8120431752b5ed6f7e736cb3edfd606`;
  the unchanged LUS patch is
  `0957d740b035f55fe4ce9a7f8d68cd385d196ffc594387ec3bbb638b096358b8`.
  Disposable clones at exact Starship/LUS pins accepted both patches,
  `git diff --check`, and reverse-apply, and contained the analog CVar and
  virtual-controller source after apply.
- `scripts/build-ios.sh --device` configured SDL 2.32.10 with
  `SDL_VIRTUAL_JOYSTICK=ON`, kept `ENABLE_SCRIPTING=OFF`, and ended
  `** BUILD SUCCEEDED **`. Final unsigned device binary SHA-256:
  `88edac9cee7c03ccd8f3dca31fa84f22dbd2a9385873228bfad6cf457f3a2b37`.
  `lipo` reports arm64; `vtool` reports platform IOS, minimum 14.0, SDK 26.5.
  Device app audit and repository safety passed.
- Boundary: this closes the analog-touch, CVar, fallback, patch, Simulator,
  and unsigned-device compile gates. It does not claim physical-controller
  detection or gameplay, disconnect/reconnect, rumble, physical-device
  thumb feel, audio, signing, IPA packaging, or CI. Those hardware results
  remain open exactly because no relevant hardware is available. Execution
  proceeds to Phase 8.

### 2026-07-27 — Phase 8 iOS polish and Metal teardown regression passed on Simulator

- The iOS menu slice now presents Metal as the fixed renderer, hides the
  DX11-only render-parallelization toggle, constrains the resolution editor to
  the available display, exposes the console-style stretch option, and
  offsets the menu by the UIKit safe area. Desktop behavior remains unchanged
  outside the iOS guards.
- The first-run instructions use the correct Files location for either
  iPhone or iPad and explain that JP/EU/CN inputs use the Voice Pack path.
  Settings exposes that short Voice Pack label and presents Invert Flight Y
  Axis prominently under Controller > Flight Controls.
- Visual targets were iPhone 16 and iPad Pro 11-inch (M4), both on the iOS
  18.5 Simulator. The iPhone first-run view, safe-area menu, Controller view,
  persisted invert-Y view, and final Metal renderer view were captured under
  `/tmp`; their SHA-256 values are respectively
  `7e4cd7bff8554588113431b6517a50f4dc39ac76a2e7094f2c0920e906f1794d`,
  `36ae270f6e40878217c4f4b84782619391800f0b0d03d07841647015a3f6709f`,
  `4c02577e8294ca08ac92318d07c52fb2d62bdc8705c4804461832660d91cee21`,
  `8162b508894fd0842b95ea8124cf822f262a0bfe350ab7028af54d7d383ebcc3`,
  and
  `21e987f311fb673673651d1604e95f6de662a6e8ccdb9609750f566d281ee097`.
  The iPad Voice Pack view has SHA-256
  `47a48d08aed4babbec2c0b8c639b0cde12301be566240659155d50890b5f1a52`.
  The responsive iPad resolution editor and advanced-settings toggle were
  also inspected live. The stretch option is present in the iOS source path,
  but its individual control was not isolated in a final capture.
- Toggling Invert Flight Y Axis wrote `gInvertYAxis: 1` to the app
  configuration. A terminate and cold relaunch retained the value and showed
  the setting checked, proving persistence rather than only an in-process
  state change.
- Closing the first final iPhone build exposed a real crash instead of a
  visual-only defect. User report SHA-256
  `0599e1e59a0501e67c7626bfd5a0bdf5abdfd9856f313bf7f3ea084174edc460`
  and system report
  `StarshipPad-2026-07-27-200528.ips` SHA-256
  `4e697e144cde6bbf1420021ff50a4c6778e58f4ae522fb3dfb3c474bc817cef1`
  show `EXC_BAD_ACCESS` during `CAMetalDrawable` deallocation at the
  autorelease-pool drain.
- The first reproducible cause was pinned LibUltraShip manually releasing
  `tex.texture` returned from `CAMetalDrawable`; CoreAnimation owns that
  texture. Upstream LibUltraShip commit
  `8ffa903c703ac0f48c15a3e2fdc31e58e11c31e4` fixes the same macOS Metal
  resize/teardown race by deleting those exact three release lines.
  StarshipPad backported only that deletion.
- The fixed iPad build was closed and observed for 40 seconds without a new
  StarshipPad crash report. A fresh launch then completed three
  background/foreground cycles on one PID, `37347`, with no crash or PID
  replacement. This is a focused teardown/lifecycle regression replay; the
  stronger simulation-stall, config-flush, and save evidence remains the
  Phase 5 record.
- Final maintained patch SHA-256 values are
  `patches/libultraship-ios.patch`
  `8c2b624fde1066fbb0f9262fbfb9aef7a2bd006226c0afb8ca44fee501a4708e`
  and `patches/starship-ios.patch`
  `a5250d06fa9fa31360625a5e055858e37457dc633084fc8fe2f43920f71af27d`.
  Disposable checkouts at the exact pins accepted both patches, passed
  `git diff --check`, matched the maintained source deltas, and accepted
  reverse-apply checks.
- Final arm64 Simulator binary SHA-256:
  `5071b2e4c8134b5119be72ba307e6d1c59f0ff6bf1c51a866099c700019b66e2`.
  Final unsigned arm64 iPhoneOS binary SHA-256:
  `e200bd2c5da09f2114cd7ef4f407ad67f4548d69ea9db1ad81461ca4b07632f2`.
  The full unsigned device build ended `** BUILD SUCCEEDED **`, the device
  app audit passed, and repository safety passed before the gate commit.
- Boundary: Phase 8 proves iPhone/iPad Simulator layout, menu availability,
  setting persistence, and the focused Metal teardown repair, plus an
  unsigned device build and audit. No physical iPhone/iPad visual audit,
  Stage Manager behavior, real-device Metal teardown, signing, controller,
  rumble, or speaker-audio result is claimed. Those hardware gates remain
  open. Execution proceeds to Phase 9.

### 2026-07-27 — Phase 9 local clean replay and audited unsigned IPA passed

- Release tooling now includes `scripts/package-ios.sh`,
  `.github/workflows/ios-build.yml`, MIT project licensing, third-party
  license inventory, clean-checkout build instructions, a release checklist,
  and a visitor-facing README. Packaging re-audits the device app and nested
  archive, requires the audited ROM-free `starship.o2r`, refuses forbidden
  files or stale signing material, and emits only under ignored
  `artifacts/`.
- Q8 is resolved conservatively: StarshipPad's supported deployment floor is
  iOS/iPadOS 16.0. No iOS 14 or 15 hardware is available for install
  evidence, and the pinned `metal-cpp` package itself targets iOS 16.
  Configure, audit, workflow, and documentation now agree on 16.0. This is an
  explicit supported-floor decision, not a claim that older binaries could
  never run.
- The pinned Starship source referenced moving `sse2neon` `master`. The
  maintained application patch freezes it to upstream commit
  `3b70b3727edc9a151c113814129258c3423a771c`, with expected archive SHA-256
  `fab5e1be1994596f28a71f1c991036db280b8d61a1f75895e8a3101dcde6df38`.
- The first fresh-checkout replay failed in host `GeneratePortO2R`: pinned
  Torch fetched spdlog 1.14.1 and Xcode 26 reproduced the Phase 0
  `consteval` compiler failure. A previously warm Torch checkout had masked
  that host-build dependency. The smallest correction is the separate
  `patches/torch-ios.patch`, changing only Torch's spdlog pin to v1.16.0.
  The patch has SHA-256
  `262f05a9e4c16169af942f4a951f20d586f13dd16cd6eb1fb09bb0e7707739e1`;
  no Torch runtime or extraction behavior was changed.
- The authoritative clean replay used temporary candidate commit
  `8c5de59ce0b90eadaa60f3c06c6740d4307f8c1c`, tree
  `8a72de7d8f8a89fcd03e1c82ee32521659e031bb`, in clean checkout
  `/tmp/starshippad-phase9-replay.YPc02C/starshippad`. Its only untracked
  input was an ignored, legally acquired ROM at `ref/clean-replay.v64`.
  Repository safety passed before and after the build.
- Bootstrap resolved the exact Starship, LibUltraShip, and Torch pins; all
  three push URLs were `disabled://starshippad-upstream-input`. The LUS,
  Starship, and Torch patches applied cleanly, their resulting source trees
  passed `git diff --check`, and each patch accepted a reverse-apply check.
- Host `GeneratePortO2R` produced the exact audited 13-entry, ROM-free
  manifest. Clean iPhoneOS configure used target triple
  `arm64-apple-ios16.0`, SDK 26.5, and correctly reported `memcpy_s` absent.
  The full device build ended `** BUILD SUCCEEDED **` and included Xcode
  bundle validation. Build log SHA-256:
  `41812ba6c2d5cad6d6938da63f3d962ec3a0a5474ce8f6032761fa4c1bdb63fc`.
  Measured wall time was 1,768 seconds (29 minutes 28 seconds).
- Clean product evidence: unsigned arm64 app binary SHA-256
  `092268fa79abc36f448437997089d612df28ae9cdf64debae669c92c7665082d`;
  bundled audited `starship.o2r` SHA-256
  `fd44eb50120fb016e66cf90ea04c3541614420b7ba43e4e3eaee9ecc652ffa13`;
  final ignored
  `artifacts/StarshipPad-2.0.0-unsigned.ipa` SHA-256
  `3d8a461ae8e9c418fd286c243300ef498fa8384d2ab190ed950e88de7b23b6ad`.
  ZIP integrity passed across 125 entries.
- `REQUIRE_SIGNED=1` rejected that unsigned product with exit status 1; its
  log SHA-256 is
  `6974259358c68853127045030ca8f78ed7258e188daef49a49814bc0a732ca7c`.
  This is the required negative test, not a signed-package result.
- Final maintained patch SHA-256 values at this local gate are LUS
  `8c2b624fde1066fbb0f9262fbfb9aef7a2bd006226c0afb8ca44fee501a4708e`,
  Torch
  `262f05a9e4c16169af942f4a951f20d586f13dd16cd6eb1fb09bb0e7707739e1`,
  and Starship
  `264e1484ddac6f70019be92970cbc5f6037bafeb66053d008f54a0c635340b77`.
- Boundary: the clean local build, package, signed refusal, patch
  reversibility, and safety gates are proven. At the time of this local
  replay the tree was not yet published; the following entry records its
  publication and remote result. The IPA is unsigned and is not installable
  through the standard device path. No physical
  iPhone/iPad install, signing-team, controller, rumble, real-speaker audio,
  or hardware performance result is claimed.

### 2026-07-27 — Phase 9 published; remote CI blocked before execution

- Commit `a1914a1961e050de975203c23a799911807e1447` was pushed to
  `origin/main`; local `main`, its upstream-tracking ref, and GitHub's remote
  ref matched.
- GitHub Actions run
  `30331244577` for that exact head SHA concluded failure at 2026-07-28
  05:18:24 UTC. The `Repository safety` job
  (`90186668410`) contains zero steps and one pre-run annotation; the
  dependent `Full app (unsigned iPhoneOS)` job was skipped.
- The GitHub annotation states that the job did not start because recent
  account payments failed or the Actions spending limit must be increased,
  and directs the account owner to Billing & plans. This is an external
  runner-allocation block, not a repository-safety, workflow-step, compiler,
  test, or package failure. There is no runner log because no runner started.
- Run URL:
  `https://github.com/chrissotraidis/starshippad/actions/runs/30331244577`.
  Phase 9 is not marked complete and CI is not represented as green.
- Boundary: resolving GitHub account billing or spending policy is outside
  this repository and requires account-owner authority. After that external
  change, rerun the published workflow; no source correction is justified by
  this pre-start failure. Physical-device, signing, controller, rumble,
  real-speaker audio, and hardware performance gates also remain open.

### 2026-07-28 — Post-Phase 9 low-grip iPad touch and README gate passed locally

- The maintained Starship touch component was compared directly with the
  local-only HarkinianPad reference before editing. StarshipPad already
  preserved the reference mechanism: UIKit controls inject SDL keyboard
  events, touch cancellation releases inputs, the overlay passes through
  uncovered touches, menu visibility owns overlay visibility, and a
  persistent Menu control remains available. StarshipPad's analog
  SDL virtual-controller stage and CVar fallback remain intact.
- The layout now follows HarkinianPad's low-grip side rails instead of placing
  Z, R, and Start on the top edge. The left rail contains Z, a four-way
  D-pad, and the stick; the right rail contains R, Pause, the A/B/Z face
  cluster, and the four C directions. Every discrete touch target is at least
  44 points. The C buttons use N64-style directional symbols while their
  accessibility labels retain Star Fox semantics: Boost, Brake, View, and
  Talk.
- Accessibility actions are semantic rather than generic. Fire, bank, boost,
  brake, and D-pad controls expose Hold where a chord is meaningful. Only the
  Z and R bank controls expose Double Tap. Pause, Bomb, View, Talk, and Menu
  expose neither action. The ordinary rapid-retap path now completes a
  pending minimum-duration release before accepting the second down event,
  removing the prior 80 ms double-tap race.
- The complete arm64 iPad Simulator rebuild ended `** BUILD SUCCEEDED **`,
  passed Xcode bundle validation, and produced binary SHA-256
  `262382fcb0e7d35b4adbf06fda5eb0fafd1d224c0e5066740efe3c64212dafc6`.
  `lipo` reports arm64; `vtool` reports `IOSSIMULATOR`, minimum 16.0,
  SDK 26.5.
- The exact product was installed and launched on iPad Pro 11-inch (M4),
  iOS 18.5 Simulator. Both landscape orientations retained safe-area
  placement and the same 15 touch elements: persistent Menu, two Z
  placements, R, Pause, A, B, four D-pad directions, four C directions, and
  the control stick. Menu hid all gameplay controls and a second tap restored
  the complete semantic tree.
- Coordinate-level touch replay advanced Start from the title screen, moved
  native menu selection with D-pad Down, selected Training with Fire, booted
  the training stage, and issued a rapid two-click bank input on the Z
  shoulder. Evidence-capture SHA-256 values are respectively
  `fabcd5f72024c83f84f455d67b650f90f3fd42ad7e2d6c5a8138366ba7db7cfe`,
  `74acfdc35b869f201fb33f7f696f0527906d070ad18b00637f8aef9bcc739d2c`,
  `0fa4e07b9e6c4451124e0c65ab3a2d9afbb0bb9237bf770bfbdbbba30ca700c5`,
  and
  `006067ae3db7634f9344c5b31877d9f81738ce95ed13cb3d7bd01b6d9c5d9b74`.
  The opposite-landscape title capture SHA-256 is
  `82c29afd251afa046b968932fe1540681aa4dbc09b4ea6c983309a829b591112`.
  Captures remain temporary because they contain game content and are not
  repository or release artifacts.
- The separate 13-inch M4 Simulator boot exposed an Apple system-process
  watchdog report, not a StarshipPad crash. The report names
  `WidgetRenderer_Default`, identifier
  `com.apple.chrono.WidgetRenderer-Default`, in the 13-inch Simulator
  coalition and contains no StarshipPad binary or stack frame. FrontBoard
  killed it after a 10-second scene-update watchdog timeout while its stack
  was in dyld and Accessibility monitoring. Report SHA-256:
  `ec5df626de84f055ad0a6a15fa401af144f75b41e001b9f55fb6dcb9f061c391`.
  A separate 13-inch M5 runtime reached SpringBoard, but its app-install
  service did not respond within the bounded replay. Therefore no 13-inch
  StarshipPad runtime result is claimed.
- The incremental unsigned iPhoneOS build compiled the same touch source,
  linked, and ended `** BUILD SUCCEEDED **`. Device binary SHA-256:
  `d164991b4df71cfbf1055a33482e3473e0ec35e23ce09df4a62a95dab4535f65`;
  `lipo` reports arm64 and `vtool` reports `IOS`, minimum 16.0, SDK 26.5.
  The app audit and repository safety check passed. Packaging produced ignored
  `artifacts/StarshipPad-2.0.0-unsigned.ipa`, SHA-256
  `5736f438dc35d6167c54bc5c3ed59645af9fa66b5b1361c69ebd3f8534950975`;
  `REQUIRE_SIGNED=1` correctly rejected it.
- Maintained `patches/starship-ios.patch` SHA-256 is
  `8221e2310cd8466675a7ae376aba5a4e733134e64347ba9324663bd4602bc919`.
  It matches the complete pinned-source delta byte-for-byte. A disposable
  checkout at `6202c443` passed apply-check, apply, `git diff --check`, and
  reverse-apply-check. The ROM-free README hero SVG is valid XML with SHA-256
  `c0663a1dd64a3a8eebdf3b148e4698c57429de1c9d867de2939cde3fcd0412d2`;
  all new local Markdown links resolve.
- Boundary: this gate proves the low-grip layout, semantic tree, basic
  coordinate interaction through Training, both landscape orientations on an
  11-inch iPad Simulator, an unsigned arm64 device link, package audit, and
  signed-package refusal. It does not prove 13-inch runtime behavior,
  physical thumb comfort, glass friction, multi-finger feel, Stage Manager,
  signing, real-device Metal/audio/performance, controller, or rumble.
  GitHub Actions remains externally blocked before runner allocation by the
  existing account billing/spending condition.

### 2026-07-28 — Post-Phase 9 README visual-polish gate passed locally

- The current StarshipPad and HarkinianPad repository pages were captured at
  full-page scale before editing. The comparison confirmed structural parity
  but also showed that StarshipPad's technical touch-layout diagram did not
  provide HarkinianPad's immediate product-level visual hierarchy.
- The opening now uses original 1672×941 project artwork created specifically
  for StarshipPad's landscape iPad flight deck. It contains no game
  screenshot, extracted asset, logo, character, written mark, or ROM-derived
  material. The prior handcrafted layout SVG was removed rather than
  presented as gameplay. PNG SHA-256:
  `effaef35cdefc10127dbc838b1da387b62c79bc847efe73d7dd59bb6d1f95075`;
  size: 1,637,019 bytes.
- The README retains HarkinianPad's direct status/build/first-launch/touch
  sequence while adding a compact navigation row, a three-part native /
  touch-complete / reproducible summary, and explicit disclosure that the
  hero is original ROM-free artwork. It also records why locally supplied
  gameplay captures remain outside Git and release artifacts. README
  SHA-256:
  `ec97a7c6debd4dfc9e7090bbfe8daaad74ef15d6539f023668982c06bf21f6a3`.
- GitHub's authenticated Markdown API accepted and rendered the complete GFM
  document. All repository-relative Markdown and HTML image/link targets
  resolve locally, `git diff --check` passes, and the repository safety audit
  passes with the new binary asset.
- The pushed branch was then inspected in GitHub's authenticated repository
  view. The hero loaded at its intended 16:9 ratio, the disclosure and quick
  links remained readable, the three summary cells stayed aligned, and the
  install-status table followed without a broken asset or layout overflow.
  A same-state top-of-page comparison against HarkinianPad confirmed matching
  visual rhythm without copying its Nintendo-derived screenshots. Temporary
  live-render capture SHA-256:
  `b8c98a4f7185cb36378b3234b29ca02b8beac6705e2dbf66c2c0602ed4573070`;
  temporary comparison SHA-256:
  `0b026f2f2c302cadc5949c336a36459d3da6a2f924060e44ab1bd144617b2d14`.
- Boundary: this is a documentation and visual-identity gate. It does not add
  or extend any Simulator, device, signing, audio, performance, controller,
  rumble, or touch-runtime claim. The generated hero is illustrative and is
  labeled as such; it is not runtime evidence.

### 2026-07-28 — README runtime screenshot set captured

- The current Simulator app was launched on an iPad Pro 13-inch (M5) running
  iOS 26.5 with the existing local archive. On-screen Start, D-pad, and Fire
  input reached Training mode; the persistent menu opened
  **Settings → Controller** with Touch Controls and Analog Touch enabled.
- A clean install of the same app on an iPad Pro 11-inch (M5) running iOS 26.5
  displayed the ROM-free first-run setup screen without importing game data.
- Three curated README images were captured and reduced to a maximum
  1,800-pixel edge:
  `docs/readme/starshippad-gameplay.jpg`, 342,821 bytes, SHA-256
  `7a6b74617b4a8f8bb8450477cfbdb547f3e173e72e8b48b0cb9c30a831d1aced`;
  `docs/readme/starshippad-first-run.png`, 169,853 bytes, SHA-256
  `1e5cb20d286488adb315bf507c79cf7dd4d4a704c76553dc51fcb7acec499d5c`;
  and `docs/readme/starshippad-controller.jpg`, 333,058 bytes, SHA-256
  `60df23de256df9cef9f882b45fef105136816610114a89b788cc2cab1495d41c`.
- This supersedes the earlier README-only decision to keep every gameplay
  capture out of Git, but only for these three curated documentation images.
  No ROM, generated game archive, extracted game asset, log, or local filename
  is included. The images are Simulator evidence, not physical-device,
  signing, audio, performance, controller-model, rumble, or thumb-feel proof.

### 2026-07-28 — README real-gameplay hero and copy pass

- Replaced the generated opening illustration with the user-supplied current
  iPad Simulator gameplay capture showing the complete touch flight deck. The
  2732×2048 source was published as an 1800×1349 JPEG (322,895 bytes; SHA-256
  `3cbd8142c85a1e89582be14926ccad1e9ea210a91ae88c71d2e7fa593500fe73`).
- Tightened the README around the build → import → fly path, made the summary
  cards benefit-led, added direct setup and future-work navigation, and removed
  the duplicate lower gameplay image. The replaced generated hero and
  redundant gameplay capture remain recoverable from Git history.
- Boundary: this is a real Simulator screenshot using locally supplied game
  data. It includes no ROM, archive, or extracted game asset and is not
  physical-device proof.

### 2026-07-30 — Physical-iPad gameplay gallery

- Replaced the README's first-run setup panel with current in-game action
  while retaining the Controller settings panel and its **Tune it while
  running** explanation. Two additional physical-iPad captures now show the
  touch deck during vehicle and all-range missions.
- The three user-supplied 2732×2048 PNG captures were published as
  1600×1199 JPEGs:
  `docs/readme/starshippad-action-sunset.jpg`, 227,360 bytes, SHA-256
  `a6e24e4f1a88c1557be9ce9c59959a60683cbb53962d1e1a0e17c1b6ca9214fd`;
  `docs/readme/starshippad-action-landmaster.jpg`, 267,876 bytes, SHA-256
  `b22e46c53594efd35889161bb607c96faa057651536c6960cca90e04bb49d749`;
  and `docs/readme/starshippad-action-battle.jpg`, 277,353 bytes, SHA-256
  `280c124a73d7dc9df948a5a905c33e0437873f29de78e89f3fdbb7b1fa8f7581`.
- Boundary: these images document rendered gameplay on the attached physical
  iPad and contain no ROM, generated archive, or extracted asset file. They
  do not establish sustained performance, audio, or control-feel acceptance.

### 2026-07-30 — Public-release hardening and Preview 2 package

- `v0.1.0-preview.1` and commit
  `4d38f6a2c511fd23971dad96d54addf48cde6020` remain the pre-hardening rollback
  point.
- The Starship, LibUltraShip, and Torch patches were regenerated from their
  exact pinned inputs, fresh-replayed, and reverse-checked. All iOS
  FetchContent inputs and GitHub Actions now use full commit SHAs; a clean
  dependency fetch confirmed every requested revision.
- The clean device build ended `** BUILD SUCCEEDED **` with Xcode 26.6 and
  the iPhoneOS 26.5 SDK, targeting arm64 and iOS 16.0 or newer.
- Processed metadata reports `com.chrissotraidis.starshippad`, version 0.1.0,
  and build 2. The executable contains no `/Users`, `/private/tmp`, or
  `/var/folders` build path.
- `THIRD_PARTY_NOTICES.md` and the complete Apache 2.0 text are in the app.
  The inventory includes the controller database and SDL's linked HIDAPI and
  yuv2rgb code.
- ROM loading now rejects inputs outside 1–64 MiB before allocation, requires
  a complete bounded read, and catches cartridge-validation exceptions. The
  clean device compile verifies this path without using or publishing a ROM.
- The ROM-free unsigned IPA passed the app and package audits; the signed-only
  gate rejected it as required. Its SHA-256 is
  `779d40f29f950023b36db6206f5e1ed4639a7252d5df2ae1e57a8a23b4f827a8`.
- Boundary: this establishes source/package readiness for Preview 2 without
  changing accepted touch geometry or bindings. It does not replace open
  physical controller, audio-route, thermal, or sustained-performance gates.

### 2026-08-18 — SDL2 controller reconciliation and Preview 4

- Backend ownership is LibUltraShip's SDL2 `ConnectedPhysicalDeviceManager`
  under the engine-managed ControlDeck; Apple GameController supplies iOS
  devices through SDL, and StarshipPad's analog touch stick is an SDL virtual
  controller. StarshipPad does not own a PaperPad-style app-level handle.
- The pinned manager relied on add/remove events, kept unchecked
  `SDL_GameController*` values, did not close replaced handles, performed no
  foreground reconciliation, and routed every newly seen controller to
  Player 1. A missed sleep/background removal could therefore leave stale
  ownership until another event happened.
- The targeted patch reconciles the existing manager against current SDL
  enumeration and `SDL_GameControllerGetAttached()`, preserves valid
  instance/port ownership, closes stale handles, clears buffered held input,
  assigns physical devices to the first free port, and keeps StarshipPad's
  virtual-touch takeover behavior. Reconciliation runs at startup,
  add/remove/remap, foreground resume, and once per active second.
- `scripts/test-controller-reconnect.sh` deterministically passes missed
  removal with a held button and axis, neutral input afterward, sole-controller
  Player 1 reclaim, additional-controller Player 2 assignment, stable Player 1
  while Player 2 changes, virtual-touch overlap, and foreground recovery.
- Clean patch replay/reverse-check, repository safety, all 11 route cases, the
  ROM-free unsigned arm64 iPhoneOS Release build, package audit, and the strict
  signed arm64 device build pass at version `0.1.0` build `4`. The clean
  Simulator sources compile, but Xcode 26.6 currently links an iPhoneOS
  CoreVideo path into the Simulator target; that pre-existing build-system
  failure remains separate from the controller repair.
- The signed build was installed in place as
  `com.chrissotraidis.starshippad` on the attached 12.9-inch iPad Pro. PID 612
  reached the title/menu state and heartbeats through frame 900. One
  background/foreground cycle stayed on PID 612, paused at frame 2015, resumed
  at the same frame, and logged `controller_reconciled=true`.
- Pre/post readback hashes match for the user ROM, generated `sf64.o2r`, Torch
  hash, save, touch layout, and preferences plist. `starship.cfg.json` changed
  only by additive default SDL mappings for the newly usable secondary player
  ports; every pre-existing configuration value remained identical.
- No physical controller was connected. Bluetooth reconnect, wired reconnect,
  natural sleep/wake, held-input release on hardware, full mapping, rumble,
  touch-overlay transitions with hardware, and two-controller ownership remain
  explicit physical acceptance gates.
- Release artifact: `StarshipPad-v0.1.0-preview.4-unsigned.ipa` (ROM-free,
  unsigned, self-signing required). SHA-256 is recorded in the Preview 4 GitHub
  release and its adjacent checksum asset.

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
| Q8 true iOS floor | 9 | Resolved | Explicit supported floor raised to iOS/iPadOS 16.0; clean binary reports minos 16.0; no older-device install claim |
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
