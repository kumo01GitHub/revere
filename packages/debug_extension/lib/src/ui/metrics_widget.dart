import 'package:flutter/material.dart';
import '../transport/metrics_transport.dart';

class MetricsWidget extends StatelessWidget {
  final MetricsTransport transport;
  const MetricsWidget({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: transport.state
          .map((data) => ListTile(
                title: Text('CPU: '
                    '${data.cpuUsage != null ? '${data.cpuUsage!.toStringAsFixed(2)}%' : 'N/A'}'),
                subtitle: Text('Memory: ${data.memoryUsage} bytes'),
                trailing: Text('${data.timestamp}'),
              ))
          .toList(),
    );
  }
}
