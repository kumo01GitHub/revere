#include "revere_debug_extension_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace revere_debug_extension_plugin {

// static
void RevereDebugExtensionPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "revere_debug_extension_plugin",
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
    // メモリ取得
    SIZE_T memory = 0;
    PROCESS_MEMORY_COUNTERS pmc;
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
      memory = pmc.WorkingSetSize;
    }
    // CPU使用率（簡易）
    static FILETIME last_sys_kernel = {0}, last_sys_user = {0}, last_proc_kernel = {0}, last_proc_user = {0};
    static ULONGLONG last_time = 0;
    double cpu_percent = 0.0;
    FILETIME sys_idle, sys_kernel, sys_user, proc_kernel, proc_user, dummy;
    if (GetSystemTimes(&sys_idle, &sys_kernel, &sys_user) &&
        GetProcessTimes(GetCurrentProcess(), &dummy, &dummy, &proc_kernel, &proc_user)) {
      ULONGLONG sys_kernel64 = (((ULONGLONG)sys_kernel.dwHighDateTime) << 32) | sys_kernel.dwLowDateTime;
      ULONGLONG sys_user64 = (((ULONGLONG)sys_user.dwHighDateTime) << 32) | sys_user.dwLowDateTime;
      ULONGLONG proc_kernel64 = (((ULONGLONG)proc_kernel.dwHighDateTime) << 32) | proc_kernel.dwLowDateTime;
      ULONGLONG proc_user64 = (((ULONGLONG)proc_user.dwHighDateTime) << 32) | proc_user.dwLowDateTime;
      ULONGLONG sys_total = (sys_kernel64 - last_sys_kernel.dwLowDateTime - ((ULONGLONG)last_sys_kernel.dwHighDateTime << 32)) +
                           (sys_user64 - last_sys_user.dwLowDateTime - ((ULONGLONG)last_sys_user.dwHighDateTime << 32));
      ULONGLONG proc_total = (proc_kernel64 - last_proc_kernel.dwLowDateTime - ((ULONGLONG)last_proc_kernel.dwHighDateTime << 32)) +
                            (proc_user64 - last_proc_user.dwLowDateTime - ((ULONGLONG)last_proc_user.dwHighDateTime << 32));
      if (last_time != 0 && sys_total > 0) {
        cpu_percent = 100.0 * (double)proc_total / (double)sys_total;
        if (cpu_percent < 0) cpu_percent = 0.0;
      }
      last_sys_kernel = sys_kernel;
      last_sys_user = sys_user;
      last_proc_kernel = proc_kernel;
      last_proc_user = proc_user;
      last_time = GetTickCount64();
    }
    flutter::EncodableMap result_map = {
      {flutter::EncodableValue("cpu"), flutter::EncodableValue(cpu_percent)},
      {flutter::EncodableValue("memory"), flutter::EncodableValue(static_cast<int64_t>(memory))}
    };
    result->Success(flutter::EncodableValue(result_map));
  } else {
    result->NotImplemented();
  }
}

}  // namespace revere_debug_extension_plugin
