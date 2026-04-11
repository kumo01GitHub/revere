#include "include/revere_debug_extension/revere_debug_extension_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <memory>
#include <map>
#include <variant>

class RevereDebugExtensionPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  RevereDebugExtensionPlugin();
  virtual ~RevereDebugExtensionPlugin();

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<std::string> &method_call,
      std::unique_ptr<flutter::MethodResult<std::variant<std::monostate, int, double, std::string, std::vector<uint8_t>, std::map<std::string, std::variant<std::monostate, int, double, std::string, std::vector<uint8_t>>>>>> result);
};

void RevereDebugExtensionPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<
      std::string>>(registrar->messenger(), "revere_debug_extension",
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
  if (method_call.method_name().compare("getMetrics") == 0) {
    // Windows: Use GetProcessMemoryInfo for memory, GetSystemTimes for CPU
    // Windows: GetProcessMemoryInfo for process memory (RSS)
    int memory = 0;
    PROCESS_MEMORY_COUNTERS pmc;
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
      memory = static_cast<int>(pmc.WorkingSetSize);
    }
    // CPU usage: not available as instant value via API
    std::map<std::string, std::variant<std::monostate, int, double, std::string, std::vector<uint8_t>>> metrics;
    metrics["cpu"] = nullptr;
    metrics["memory"] = memory;
    result->Success(metrics);
  } else {
    result->NotImplemented();
  }
}
