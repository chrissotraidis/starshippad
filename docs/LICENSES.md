# StarshipPad iOS link-closure licenses

This inventory records the permissive-license closure for the pinned unsigned
iPhoneOS build. It was checked against the exact CMake inputs, fetched license
files under `build-ios/_deps`, pinned upstream trees, and the Release
`OTHER_LDFLAGS` in the generated Xcode project.

No GPL, LGPL, or AGPL component appears in this closure. Nintendo-owned ROM
data and extracted assets are not dependencies and are never distributed.

| Component | Pinned input | License | iOS build role |
|---|---|---|---|
| Starship | `6202c44356fee70dd23e80a16933b211863d3e2d` | CC0-1.0 | Game port |
| StarshipPad-owned files | This repository | MIT | iOS build, UI, scripts, packaging |
| LibUltraShip | `eaaf9d0fc91e2c400f49ef2a1f8547a691ce4d3c` | MIT | Engine and platform layer |
| Torch | `cd92cc0f161c5e79e36f5dda0d0029edd3fc8d50` | MIT | On-device SF64 extraction |
| SDL2 | `release-2.32.10` | zlib | Window, audio, touch/controller input |
| Dear ImGui | `v1.91.9b-docking` | MIT | Runtime menus and setup UI |
| single-header-metal-cpp | `macOS13_iOS16` | Apache-2.0 | Metal C++ interface |
| libzip | `v1.10.1` | BSD-3-Clause | `.o2r` ZIP access |
| zlib | iPhoneOS SDK | zlib | libzip compression |
| bzip2 | iPhoneOS SDK | bzip2 | libzip compression |
| Ogg | `v1.3.6` | BSD-3-Clause | Audio container |
| Vorbis | `v1.3.7` | BSD-3-Clause | Audio decode |
| yaml-cpp | `2f86d13775d119edbb69af52e5f566fd65c6953b` | MIT | Torch manifests |
| spdlog and bundled fmt | `v1.16.0` | MIT | Logging and formatting |
| tinyxml2 | `10.0.0` | zlib | XML parsing |
| nlohmann-json | `v3.11.3` | MIT | Header-only JSON |
| prism-processor | `bbcbc7e3f890a5806b579361e7aa0336acd547e7` | MIT | Shader preprocessing |
| BS thread pool | `v4.1.0` | MIT | Engine worker pool |
| stb_image | `0bc88af4de5fb022db643c2d8e549a0927749354` | MIT or public domain | Image decode |
| dr_libs | `da35f9d6c7374a95353fd1df1d394d44ab66cf01` | MIT-0 or public domain | Audio helpers |
| sse2neon | `3b70b3727edc9a151c113814129258c3423a771c` | MIT | ARM SIMD compatibility header |

The generated Release link line also uses Apple system frameworks and system
libraries supplied by the iPhoneOS SDK: AudioToolbox, AVFoundation,
CoreAudio, CoreBluetooth, CoreGraphics, CoreHaptics (weak), CoreMotion,
CoreVideo, Foundation, GameController (weak), Metal, OpenGLES, QuartzCore,
UIKit, `libm`, `libobjc`, and pthreads. They are governed by Apple's SDK terms,
not vendored or redistributed by StarshipPad.

StormLib is present in the Torch source input but disabled by Starship's iOS
configuration (`BUILD_STORMLIB=OFF`) and absent from the final link line.
Host-only archive-generation dependencies and Xcode/CMake tooling are not
part of the shipped binary closure.
