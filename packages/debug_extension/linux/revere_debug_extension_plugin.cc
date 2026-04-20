#include "include/revere_debug_extension/revere_debug_extension_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <sys/resource.h> // for getrusage
#include <unistd.h>       // for sysconf

#include <cstring>

#include "revere_debug_extension_plugin_private.h"

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
    response = collect();
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

// Returns a map: {"cpu": double (seconds), "memory": int64 (bytes)}
FlMethodResponse* collect() {
  double cpu_time = 0.0;
  struct rusage usage;
  int rusage_ok = getrusage(RUSAGE_SELF, &usage);
  if (rusage_ok != 0) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("GetRusageError", "getrusage failed", nullptr));
  }
  cpu_time = usage.ru_utime.tv_sec + usage.ru_utime.tv_usec / 1e6;
  cpu_time += usage.ru_stime.tv_sec + usage.ru_stime.tv_usec / 1e6;

  long rss = 0;
  FILE* fp = fopen("/proc/self/statm", "r");
  if (!fp) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new("StatmOpenError", "Failed to open /proc/self/statm", nullptr));
  }
  long pages = 0;
  if (fscanf(fp, "%*s %ld", &pages) != 1) {
    fclose(fp);
    return FL_METHOD_RESPONSE(fl_method_error_response_new("StatmReadError", "Failed to read statm", nullptr));
  }
  rss = pages * sysconf(_SC_PAGESIZE);
  fclose(fp);

  g_autoptr(FlValue) result = fl_value_new_map();
  fl_value_set(result, fl_value_new_string("cpu"), fl_value_new_float(cpu_time));
  fl_value_set(result, fl_value_new_string("memory"), fl_value_new_int(rss));
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void revere_debug_extension_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(revere_debug_extension_plugin_parent_class)->dispose(object);
}

static void revere_debug_extension_plugin_class_init(RevereDebugExtensionPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = revere_debug_extension_plugin_dispose;
}

static void revere_debug_extension_plugin_init(RevereDebugExtensionPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  RevereDebugExtensionPlugin* plugin = REVERE_DEBUG_EXTENSION_PLUGIN(user_data);
  revere_debug_extension_plugin_handle_method_call(plugin, method_call);
}

void revere_debug_extension_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  RevereDebugExtensionPlugin* plugin = REVERE_DEBUG_EXTENSION_PLUGIN(
      g_object_new(revere_debug_extension_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "revere_debug_extension",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
