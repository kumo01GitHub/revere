#include "revere_debug_extension_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For PROCESS_MEMORY_COUNTERS, GetProcessMemoryInfo
#include <psapi.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace revere_debug_extension {

// static
void RevereDebugExtensionPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "revere_debug_extension",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<RevereDebugExtensionPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

RevereDebugExtensionPlugin::RevereDebugExtensionPlugin() {}

RevereDebugExtensionPlugin::~RevereDebugExtensionPlugin() {}

void RevereDebugExtensionPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("collect") == 0) {
    // CPU usage (process)
    FILETIME ftCreation, ftExit, ftKernel, ftUser;
    ULARGE_INTEGER lastKernel, lastUser;
    double cpuUsagePercent = 0.0;
    if (!GetProcessTimes(GetCurrentProcess(), &ftCreation, &ftExit, &ftKernel, &ftUser)) {
      result->Error("GetProcessTimesError", "GetProcessTimes failed", nullptr);
      return;
    }
    lastKernel.LowPart = ftKernel.dwLowDateTime;
    lastKernel.HighPart = ftKernel.dwHighDateTime;
    lastUser.LowPart = ftUser.dwLowDateTime;
    lastUser.HighPart = ftUser.dwHighDateTime;
    double kernelTime = lastKernel.QuadPart / 10000000.0;
    double userTime = lastUser.QuadPart / 10000000.0;
    cpuUsagePercent = (kernelTime + userTime);

    PROCESS_MEMORY_COUNTERS pmc;
    SIZE_T memRss = 0;
    if (!GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
      result->Error("GetProcessMemoryInfoError", "GetProcessMemoryInfo failed", nullptr);
      return;
    }
    memRss = pmc.WorkingSetSize;

    flutter::EncodableMap result_map = {
      {flutter::EncodableValue("cpu"), flutter::EncodableValue(cpuUsagePercent)},
      {flutter::EncodableValue("memory"), flutter::EncodableValue(static_cast<int64_t>(memRss))}
    };
    result->Success(flutter::EncodableValue(result_map));
  } else {
    result->NotImplemented();
  }
}

}  // namespace revere_debug_extension
