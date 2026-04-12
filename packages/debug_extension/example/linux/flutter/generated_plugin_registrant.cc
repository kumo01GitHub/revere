//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <revere_debug_extension/revere_debug_extension_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) revere_debug_extension_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "RevereDebugExtensionPlugin");
  revere_debug_extension_plugin_register_with_registrar(revere_debug_extension_registrar);
}
