import 'package:flutter/material.dart';

import '../transport/state_transport.dart';
import '../metrics/metrics_collector.dart';

class MetricsWidget extends StatelessWidget {
  final StateTransport<MetricsData> transport;
  const MetricsWidget({super.key, required this.transport});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MetricsData>>(
      valueListenable: transport.state,
      builder: (context, state, _) {
        return ListView(
          children: state
              .map((data) => ListTile(
                    title: Text('CPU: '
                        '${data.cpuUsage != null ? '${data.cpuUsage!.toStringAsFixed(2)}%' : 'N/A'}'),
                    subtitle: Text('Memory: ${data.memoryUsage} bytes'),
                    trailing: Text('${data.timestamp}'),
                  ))
              .toList(),
        );
      },
    );
  }
}
