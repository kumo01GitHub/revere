import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidMetricsCollector implements PlatformMetricsCollector {
  static const MethodChannel _channel = MethodChannel('revere_debug_extension');
  @override
  Future<MetricsData> collect() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMetrics');
      return MetricsData(
        cpuUsage: (result?['cpu'] as num?)?.toDouble(),
        memoryUsage: (result?['memory'] as int?) ?? 0,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return MetricsData(
          cpuUsage: null, memoryUsage: 0, timestamp: DateTime.now());
    }
  }
}

class MetricsData {
  final double? cpuUsage;
  final int memoryUsage;
  final DateTime timestamp;

  MetricsData({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.timestamp,
  });
}

abstract class PlatformMetricsCollector {
  Future<MetricsData> collect();
}

class MetricsCollector {
  final _controller = StreamController<MetricsData>.broadcast();
  Timer? _timer;
  late final PlatformMetricsCollector _platformCollector;

  MetricsCollector() {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported');
    } else if (Platform.isAndroid) {
      _platformCollector = AndroidMetricsCollector();
    } else if (Platform.isIOS) {
      _platformCollector = IOSMetricsCollector();
    } else if (Platform.isMacOS) {
      _platformCollector = MacOSMetricsCollector();
    } else if (Platform.isLinux) {
      _platformCollector = LinuxMetricsCollector();
    } else if (Platform.isWindows) {
      _platformCollector = WindowsMetricsCollector();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  Stream<MetricsData> get metricsStream => _controller.stream;

  void start({Duration interval = const Duration(seconds: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      final metrics = await _platformCollector.collect();
      _controller.add(metrics);
    });
  }

  void stop() {
    _timer?.cancel();
  }
}

class IOSMetricsCollector implements PlatformMetricsCollector {
  static const MethodChannel _channel = MethodChannel('revere_debug_extension');
  @override
  Future<MetricsData> collect() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMetrics');
      return MetricsData(
        cpuUsage: (result?['cpu'] as num?)?.toDouble(),
        memoryUsage: (result?['memory'] as int?) ?? 0,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return MetricsData(
          cpuUsage: null, memoryUsage: 0, timestamp: DateTime.now());
    }
  }
}

class MacOSMetricsCollector implements PlatformMetricsCollector {
  static const MethodChannel _channel = MethodChannel('revere_debug_extension');
  @override
  Future<MetricsData> collect() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMetrics');
      return MetricsData(
        cpuUsage: (result?['cpu'] as num?)?.toDouble(),
        memoryUsage: (result?['memory'] as int?) ?? 0,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return MetricsData(
          cpuUsage: null, memoryUsage: 0, timestamp: DateTime.now());
    }
  }
}

class LinuxMetricsCollector implements PlatformMetricsCollector {
  static const MethodChannel _channel = MethodChannel('revere_debug_extension');
  @override
  Future<MetricsData> collect() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMetrics');
      return MetricsData(
        cpuUsage: (result?['cpu'] as num?)?.toDouble(),
        memoryUsage: (result?['memory'] as int?) ?? 0,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return MetricsData(
          cpuUsage: null, memoryUsage: 0, timestamp: DateTime.now());
    }
  }
}

class WindowsMetricsCollector implements PlatformMetricsCollector {
  static const MethodChannel _channel = MethodChannel('revere_debug_extension');
  @override
  Future<MetricsData> collect() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMetrics');
      return MetricsData(
        cpuUsage: (result?['cpu'] as num?)?.toDouble(),
        memoryUsage: (result?['memory'] as int?) ?? 0,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return MetricsData(
          cpuUsage: null, memoryUsage: 0, timestamp: DateTime.now());
    }
  }
}
