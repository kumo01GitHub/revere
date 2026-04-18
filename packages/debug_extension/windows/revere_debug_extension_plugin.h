#ifndef FLUTTER_PLUGIN_REVERE_DEBUG_EXTENSION_PLUGIN_H_
#define FLUTTER_PLUGIN_REVERE_DEBUG_EXTENSION_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace revere_debug_extension_plugin {

class RevereDebugExtensionPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  RevereDebugExtensionPlugin();

  virtual ~RevereDebugExtensionPlugin();

  // Disallow copy and assign.
  RevereDebugExtensionPlugin(const RevereDebugExtensionPlugin&) = delete;
  RevereDebugExtensionPlugin& operator=(const RevereDebugExtensionPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace revere_debug_extension_plugin

#endif  // FLUTTER_PLUGIN_REVERE_DEBUG_EXTENSION_PLUGIN_H_
