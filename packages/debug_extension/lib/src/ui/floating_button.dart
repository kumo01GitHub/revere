import 'package:flutter/material.dart';
import 'package:revere/core.dart';
import './debug_widget.dart';

class FloatingMetricsButton extends StatefulWidget {
  final List<Logger> loggers;
  final List<String>? tabNames;
  final int maxLength;
  const FloatingMetricsButton({
    super.key,
    required this.loggers,
    this.tabNames,
    this.maxLength = 100,
  });

  @override
  State<FloatingMetricsButton> createState() => _FloatingMetricsButtonState();
}

class _FloatingMetricsButtonState extends State<FloatingMetricsButton> {
  bool _showDebug = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showDebug)
          Positioned(
            right: 16,
            top: 80,
            bottom: 80, // ボタンの上までで制約
            child: SizedBox(
              width: 400,
              child: Card(
                child: DebugWidget(
                  loggers: widget.loggers,
                  tabNames: widget.tabNames,
                  maxLength: widget.maxLength,
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _showDebug = !_showDebug;
              });
            },
            child: const Icon(Icons.bug_report),
          ),
        ),
      ],
    );
  }
}
