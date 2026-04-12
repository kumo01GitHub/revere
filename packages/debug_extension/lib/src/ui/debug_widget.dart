import 'package:flutter/material.dart';
import 'package:revere/core.dart';
import '../transport/state_transport.dart';

/// DebugWidget: Switch and display the history of multiple Loggers in tabs.
class DebugWidget extends StatefulWidget {
  final List<Logger> loggers;
  final int maxLength;
  final List<String>? tabNames;
  const DebugWidget({
    super.key,
    required this.loggers,
    this.maxLength = 100,
    this.tabNames,
  });

  @override
  State<DebugWidget> createState() => _DebugWidgetState();
}

class _DebugWidgetState extends State<DebugWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final List<StateTransport<dynamic>> _transports;
  late final TabController _tabController;
  late final List<ScrollController> _scrollControllers;
  late final List<int> _prevLengths;

  @override
  void initState() {
    super.initState();
    _transports = widget.loggers.map((logger) {
      final t = StateTransport<dynamic>();
      logger.addTransport(t);
      // Add a listener to remove old elements when exceeding maxLength
      t.state.addListener(() {
        final maxLength = widget.maxLength;
        final list = t.state.value;
        if (maxLength > 0 && list.length > maxLength) {
          // Remove excess elements from the beginning
          t.state.value =
              List<dynamic>.from(list.skip(list.length - maxLength));
        }
      });
      return t;
    }).toList();
    _tabController = TabController(length: widget.loggers.length, vsync: this);
    _scrollControllers =
        List.generate(widget.loggers.length, (_) => ScrollController());
    _prevLengths = List.filled(widget.loggers.length, 0);
  }

  @override
  void dispose() {
    for (final c in _scrollControllers) {
      c.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tabNames = widget.tabNames ??
        List.generate(widget.loggers.length, (i) => 'Logger ${i + 1}');
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [for (final name in tabNames) Tab(text: name)],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (int tabIdx = 0; tabIdx < _transports.length; tabIdx++)
                ValueListenableBuilder<List<dynamic>>(
                  valueListenable: _transports[tabIdx].state,
                  builder: (context, state, _) {
                    final controller = _scrollControllers[tabIdx];
                    final prevLength = _prevLengths[tabIdx];
                    final atBottom = controller.hasClients
                        ? (controller.position.pixels >=
                            controller.position.maxScrollExtent - 50)
                        : true;
                    if (state.length > prevLength && atBottom) {
                      // Scroll after layout is completed
                      Future.delayed(Duration.zero, () {
                        if (controller.hasClients) {
                          controller.animateTo(
                            controller.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                    _prevLengths[tabIdx] = state.length;
                    return ListView.builder(
                      controller: controller,
                      itemCount: state.length,
                      itemBuilder: (context, i) {
                        final entry = state[i];
                        return ListTile(
                          title: Text(entry.toString()),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
