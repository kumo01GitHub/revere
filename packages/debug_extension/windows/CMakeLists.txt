cmake_minimum_required(VERSION 3.15)
project(revere_debug_extension_plugin LANGUAGES CXX)

set(PLUGIN_NAME "revere_debug_extension_plugin")

add_library(${PLUGIN_NAME} SHARED
  revere_debug_extension_plugin.cpp
)

target_include_directories(${PLUGIN_NAME} PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPLEMENTATION)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED YES
  POSITION_INDEPENDENT_CODE ON
)

# List the plugin as a dependency for the main app.
set(flutter_plugins ${flutter_plugins} PARENT_SCOPE)
