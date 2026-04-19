#include <flutter_linux/flutter_linux.h>

#include "include/revere_debug_extension/revere_debug_extension_plugin.h"

// This file exposes some plugin internals for unit testing. See
// https://github.com/flutter/flutter/issues/88724 for current limitations
// in the unit-testable API.

// Handles the collect method call.
FlMethodResponse *collect();
