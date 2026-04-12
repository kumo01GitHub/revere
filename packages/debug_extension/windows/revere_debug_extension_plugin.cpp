
#include "include/revere_debug_extension/revere_debug_extension_plugin.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>
#include <psapi.h>
#include <memory>
#include <map>
#include <variant>




void RevereDebugExtensionPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<std::string>>(
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
    const flutter::MethodCall<std::string> &method_call,
    std::unique_ptr<flutter::MethodResult<std::variant<std::monostate, int, double, std::string, std::vector<uint8_t>, std::map<std::string, std::variant<std::monostate, int, double, std::string, std::vector<uint8_t>>>>>> result) {
  if (method_call.method_name().compare("collect") == 0) {
    int memory = 0;
    PROCESS_MEMORY_COUNTERS pmc;
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
      memory = static_cast<int>(pmc.WorkingSetSize);
    }
    std::map<std::string, std::variant<std::monostate, int, double, std::string, std::vector<uint8_t>>> metrics;
    metrics["cpu"] = nullptr;
    metrics["memory"] = memory;
    result->Success(metrics);
  } else {
    result->NotImplemented();
  }
}
