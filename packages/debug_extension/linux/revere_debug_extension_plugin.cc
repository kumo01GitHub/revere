#include "include/revere_debug_extension_plugin/revere_debug_extension_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

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
    // メモリ使用量取得
    long memory = 0;
    FILE* statm = fopen("/proc/self/statm", "r");
    if (statm) {
      long size, resident;
      if (fscanf(statm, "%ld %ld", &size, &resident) == 2) {
        long page_size = sysconf(_SC_PAGESIZE);
        memory = resident * page_size;
      }
      fclose(statm);
    }

    // CPU使用率（簡易）
    static long long last_total_time = 0;
    static long long last_clock = 0;
    double cpu_percent = 0.0;
    FILE* stat = fopen("/proc/self/stat", "r");
    if (stat) {
      long long utime = 0, stime = 0;
      int skip = 0;
      char comm[256], state;
      fscanf(stat, "%d %s %c", &skip, comm, &state); // pid, comm, state
      for (int i = 0; i < 11; ++i) fscanf(stat, "%*s"); // skip to utime
      fscanf(stat, "%lld %lld", &utime, &stime);
      fclose(stat);
      long long total_time = utime + stime;
      long long now_clock = (long long)clock();
      if (last_clock != 0 && now_clock > last_clock) {
        long long diff_time = total_time - last_total_time;
        long long diff_clock = now_clock - last_clock;
        cpu_percent = 100.0 * ((double)diff_time / (double)sysconf(_SC_CLK_TCK)) / ((double)diff_clock / (double)CLOCKS_PER_SEC);
        if (cpu_percent < 0) cpu_percent = 0.0;
      }
      last_total_time = total_time;
      last_clock = now_clock;
    }

    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set(result, fl_value_new_string("cpu"), fl_value_new_float(cpu_percent));
    fl_value_set(result, fl_value_new_string("memory"), fl_value_new_int(memory));
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
                            "revere_debug_extension_plugin",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
