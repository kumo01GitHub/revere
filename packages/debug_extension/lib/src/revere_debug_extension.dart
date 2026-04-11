import 'logger/metrics_logger.dart';

class RevereDebugExtension {
  static void initialize() {
    MetricsLogger().start();
  }
}
