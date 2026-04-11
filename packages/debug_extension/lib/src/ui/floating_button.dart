import 'package:flutter/material.dart';
import 'metrics_widget.dart';

import '../transport/state_transport.dart';
import '../metrics/metrics_collector.dart';

class FloatingMetricsButton extends StatefulWidget {
  final StateTransport<MetricsData> transport;
  const FloatingMetricsButton({super.key, required this.transport});

  @override
  State<FloatingMetricsButton> createState() => _FloatingMetricsButtonState();
}

class _FloatingMetricsButtonState extends State<FloatingMetricsButton> {
  bool _showMetrics = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showMetrics)
          Positioned(
            right: 16,
            bottom: 80,
            child: SizedBox(
              width: 300,
              height: 400,
              child: Card(
                child: MetricsWidget(transport: widget.transport),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => setState(() => _showMetrics = !_showMetrics),
            child: Icon(_showMetrics ? Icons.close : Icons.bar_chart),
          ),
        ),
      ],
    );
  }
}
