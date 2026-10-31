import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import 'officer_complaints_screen.dart';
import 'officer_dashboard_screen.dart';

class OfficerShell extends StatefulWidget {
  const OfficerShell({super.key});

  @override
  State<OfficerShell> createState() => _OfficerShellState();
}

class _OfficerShellState extends State<OfficerShell> {
  int _index = 0;
  final ValueNotifier<ComplaintStatus?> _complaintFilter =
      ValueNotifier<ComplaintStatus?>(null);

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.inbox_outlined),
      selectedIcon: Icon(Icons.inbox),
      label: 'Complaints',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inbox_outlined),
      selectedIcon: Icon(Icons.inbox),
      label: Text('Complaints'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    return ListenableProvider<ValueNotifier<int>>(
      create: (_) => ValueNotifier<int>(_index),
      child: Builder(
        builder: (context) {
          return ValueListenableBuilder<int>(
            valueListenable: context.watch<ValueNotifier<int>>(),
            builder: (context, index, _) {
              _index = index;
              final body = IndexedStack(
                index: index,
                children: [
                  OfficerDashboardScreen(complaintFilter: _complaintFilter),
                  OfficerComplaintsScreen(filterNotifier: _complaintFilter),
                ],
              );
              return PopScope(
                canPop: _index == 0,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop && _index != 0) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.read<ValueNotifier<int>>().value = 0;
                    });
                  }
                },
                child: Scaffold(
                  body: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: isWide
                          ? Row(
                              children: [
                                NavigationRail(
                                  selectedIndex: index,
                                  onDestinationSelected: (value) =>
                                      context
                                          .read<ValueNotifier<int>>()
                                          .value = value,
                                  labelType: NavigationRailLabelType.all,
                                  destinations: _railDestinations,
                                ),
                                const VerticalDivider(thickness: 1, width: 1),
                                Expanded(child: body),
                              ],
                            )
                          : body,
                    ),
                  ),
                  bottomNavigationBar: isWide
                      ? null
                      : NavigationBar(
                          selectedIndex: index,
                          onDestinationSelected: (value) =>
                              context
                                  .read<ValueNotifier<int>>()
                                  .value = value,
                          destinations: _destinations,
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
