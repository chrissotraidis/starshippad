#include "src/port/extractor/GameExtractorRoutes.h"

#include <array>
#include <iostream>
#include <string_view>

using StarshipPad::GetRomArchiveRelativePath;
using StarshipPad::GetRomArchiveRoute;
using StarshipPad::RomArchiveRoute;

struct RouteCase {
    std::string_view hash;
    RomArchiveRoute route;
    std::string_view path;
};

constexpr std::array<RouteCase, 12> kCases = {{
    { "d8b1088520f7c5f81433292a9258c1184afa1457", RomArchiveRoute::Main, "sf64.o2r" },
    { "63b69f0ef36306257481afc250f9bc304c7162b2", RomArchiveRoute::Main, "sf64.o2r" },
    { "09f0d105f476b00efa5303a3ebc42e60a7753b7a", RomArchiveRoute::Main, "sf64.o2r" },
    { "f7475fb11e7e6830f82883412638e8390791ab87", RomArchiveRoute::Main, "sf64.o2r" },
    { "9bd71afbecf4d0a43146e4e7a893395e19bf3220", RomArchiveRoute::JapaneseVoice, "mods/sf64jp.o2r" },
    { "d064229a32cc05ab85e2381ce07744eb3ffaf530", RomArchiveRoute::JapaneseVoice, "mods/sf64jp.o2r" },
    { "05b307b8804f992af1a1e2fbafbd588501fdf799", RomArchiveRoute::EuropeanVoice, "mods/sf64eu.o2r" },
    { "09f5d5c14219fc77a36c5a6ad5e63f7abd8b3385", RomArchiveRoute::EuropeanVoice, "mods/sf64eu.o2r" },
    { "e6dad7523ff8f83fad6fbdb59d472b4f76340c2b", RomArchiveRoute::EuropeanVoice, "mods/sf64eu.o2r" },
    { "c8a10699dea52f4bb2e2311935c1376dfb352e7a", RomArchiveRoute::ChineseVoice, "mods/sf64cn.o2r" },
    { "3a05aba5549fa71e8b16a0c6e2c8481b070818a9", RomArchiveRoute::ChineseVoice, "mods/sf64cn.o2r" },
    { "0000000000000000000000000000000000000000", RomArchiveRoute::Unsupported, "" },
}};

int main() {
    for (const auto& test : kCases) {
        const auto route = GetRomArchiveRoute(test.hash);
        const auto path = GetRomArchiveRelativePath(route);
        if (route != test.route || path != test.path) {
            std::cerr << "route mismatch for " << test.hash << '\n';
            return 1;
        }
    }

    std::cout << "PASS: all 11 supported ROM hashes route to the expected main or voice archive; "
                 "unknown hashes remain unsupported\n";
    return 0;
}
