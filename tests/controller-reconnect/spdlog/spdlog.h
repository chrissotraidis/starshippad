#pragma once

namespace fake_spdlog {
template <typename... Args> void Log(Args&&...) {
}
} // namespace fake_spdlog

#define SPDLOG_INFO(...) fake_spdlog::Log(__VA_ARGS__)
#define SPDLOG_WARN(...) fake_spdlog::Log(__VA_ARGS__)
#define SPDLOG_ERROR(...) fake_spdlog::Log(__VA_ARGS__)
