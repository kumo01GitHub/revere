#include "include/revere_debug_extension/revere_debug_extension_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/sysinfo.h>

// 正しいマクロ名に修正
#define REVERE_DEBUG_EXTENSION_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), revere_debug_extension_plugin_get_type(), \
                              RevereDebugExtensionPlugin))

struct _RevereDebugExtensionPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(RevereDebugExtensionPlugin, revere_debug_extension_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void revere_debug_extension_plugin_handle_method_call(
    RevereDebugExtensionPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "collect") == 0) {
    // Linux: Use sysinfo for memory, /proc/stat for CPU
    // Linux: /proc/self/statm for process memory (RSS)
    long memory = 0;
    FILE* f = fopen("/proc/self/statm", "r");
    if (f) {
      long size, resident;
      if (fscanf(f, "%ld %ld", &size, &resident) == 2) {
        long page_size = sysconf(_SC_PAGESIZE);
        memory = resident * page_size;
      }
      fclose(f);
    }
    // CPU usage: not available as instant value via API
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "cpu", fl_value_new_float(0.0));
    fl_value_set_string_take(result, "memory", fl_value_new_int(memory));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void revere_debug_extension_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(revere_debug_extension_plugin_parent_class)->dispose(object);
}

static void revere_debug_extension_plugin_class_init(RevereDebugExtensionPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = revere_debug_extension_plugin_dispose;
}

static void revere_debug_extension_plugin_init(RevereDebugExtensionPlugin* self) {}

extern "C" void revere_debug_extension_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  RevereDebugExtensionPlugin* plugin = REVERE_DEBUG_EXTENSION_PLUGIN(
    g_object_new(revere_debug_extension_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
    fl_plugin_registrar_get_messenger(registrar),
    "revere_debug_extension",
    FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, reinterpret_cast<FlMethodChannelMethodCallHandler>(revere_debug_extension_plugin_handle_method_call),
                      plugin,
                      nullptr);
  g_object_unref(plugin);
}
