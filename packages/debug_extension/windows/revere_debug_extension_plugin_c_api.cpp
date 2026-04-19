#include "include/revere_debug_extension/revere_debug_extension_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "revere_debug_extension_plugin.h"

void RevereDebugExtensionPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  revere_debug_extension::RevereDebugExtensionPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
