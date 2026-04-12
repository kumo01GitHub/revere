#ifndef FLUTTER_PLUGIN_REVERE_DEBUG_EXTENSION_PLUGIN_H_
#define FLUTTER_PLUGIN_REVERE_DEBUG_EXTENSION_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#define REVERE_DEBUG_EXTENSION_PLUGIN_TYPE \
  (revere_debug_extension_plugin_get_type())
G_DECLARE_FINAL_TYPE(RevereDebugExtensionPlugin, revere_debug_extension_plugin, \
                     REVERE, DEBUG_EXTENSION_PLUGIN, GObject)

G_END_DECLS

#endif  // FLUTTER_PLUGIN_REVERE_DEBUG_EXTENSION_PLUGIN_H_
