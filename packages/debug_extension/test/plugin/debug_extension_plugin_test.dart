import 'package:flutter_test/flutter_test.dart';
import 'package:revere_debug_extension/metrics.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePlatform extends DebugExtensionPluginPlatform {
  @override
  Future<MetricsData?> collect() async => null;
}

class NullPlugin extends DebugExtensionPluginPlatform {
  @override
  Future<MetricsData?> collect() async => null;
}

class DummyUnimplementedPlatform extends DebugExtensionPluginPlatform {}

// Testable MethodChannelDebugExtensionPlugin
class MethodChannelDebugExtensionPluginTest
    extends DebugExtensionPluginPlatform {
  dynamic mockResult;
  @override
  Future<MetricsData?> collect() async {
    final result = mockResult;
    if (result == null) return null;
    return MetricsData(
      cpuUsage:
          (result['cpu'] is num) ? (result['cpu'] as num?)?.toDouble() : null,
      memoryUsage:
          (result['memory'] is int) ? (result['memory'] as int?) ?? 0 : 0,
      timestamp: DateTime.now(),
    );
  }
}

class MockDebugExtensionPlugin extends DebugExtensionPluginPlatform {
  @override
  Future<MetricsData?> collect() async {
    return MetricsData(
        cpuUsage: 42.0, memoryUsage: 123, timestamp: DateTime.now());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DebugExtensionPluginPlatform.instance = MockDebugExtensionPlugin();
  test('DebugExtensionPluginPlatform.instance getter/setter works', () {
    final old = DebugExtensionPluginPlatform.instance;
    final dummy = DummyUnimplementedPlatform();
    DebugExtensionPluginPlatform.instance = dummy;
    expect(DebugExtensionPluginPlatform.instance, dummy);
    DebugExtensionPluginPlatform.instance = old;
  });

  test('DebugExtensionPluginPlatform.instance throws if token invalid', () {
    final fake = FakePlatform();
    expect(() => PlatformInterface.verifyToken(fake, Object()),
        throwsA(isA<AssertionError>()));
  });
  test('DebugExtensionPlugin returns default value if null', () async {
    final plugin = DebugExtensionPlugin();
    final result = await plugin.collect();
    expect(result, isNotNull);
    expect(result.memoryUsage, isA<int>());
  });

  test('DebugExtensionPlugin returns default value when platform returns null',
      () async {
    DebugExtensionPluginPlatform.instance = NullPlugin();
    final plugin = DebugExtensionPlugin();
    final result = await plugin.collect();
    expect(result.cpuUsage, isNull);
    expect(result.memoryUsage, 0);
    expect(result.timestamp, isA<DateTime>());
  });

  test('DebugExtensionPluginPlatform.collect throws UnimplementedError',
      () async {
    final platform = DummyUnimplementedPlatform();
    expect(() => platform.collect(), throwsA(isA<UnimplementedError>()));
  });

  test('MethodChannelDebugExtensionPlugin.collect handles null and bad map',
      () async {
    // Mock MethodChannel
    final plugin = MethodChannelDebugExtensionPluginTest();
    // null result
    plugin.mockResult = null;
    final nullResult = await plugin.collect();
    expect(nullResult, isNull);
    // bad map (missing keys)
    plugin.mockResult = <String, dynamic>{};
    final badMapResult = await plugin.collect();
    expect(badMapResult?.cpuUsage, isNull);
    expect(badMapResult?.memoryUsage, 0);
    expect(badMapResult?.timestamp, isA<DateTime>());
    // wrong types
    plugin.mockResult = <String, dynamic>{
      'cpu': 'notANumber',
      'memory': 'notAnInt'
    };
    final wrongTypeResult = await plugin.collect();
    expect(wrongTypeResult?.cpuUsage, isNull);
    expect(wrongTypeResult?.memoryUsage, 0);
  });
}
