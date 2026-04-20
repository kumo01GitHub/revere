// Template for metrics display screen
import 'package:flutter/material.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metrics')),
      body: const Center(child: Text('Metrics data will be shown here.')),
    );
  }
}
