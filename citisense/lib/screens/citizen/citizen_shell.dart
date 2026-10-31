import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import 'citizen_home_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';
import 'report_issue_screen.dart';

class CitizenShell extends StatefulWidget {
  const CitizenShell({super.key});

  @override
  State<CitizenShell> createState() => _CitizenShellState();
}

class _CitizenShellState extends State<CitizenShell> {
  int _index = 0;
  final ValueNotifier<Set<ComplaintStatus>?> _reportFilter =
      ValueNotifier<Set<ComplaintStatus>?>(null);

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.add_circle_outline),
      selectedIcon: Icon(Icons.add_circle),
      label: 'Report',
    ),
    NavigationDestination(
      icon: Icon(Icons.article_outlined),
      selectedIcon: Icon(Icons.article),
      label: 'My Reports',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: 'Notifications',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.add_circle_outline),
      selectedIcon: Icon(Icons.add_circle),
      label: Text('Report'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.article_outlined),
      selectedIcon: Icon(Icons.article),
      label: Text('My Reports'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: Text('Notifications'),
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
                  CitizenHomeScreen(reportFilter: _reportFilter),
                  const ReportIssueScreen(),
                  MyReportsScreen(filterNotifier: _reportFilter),
                  const NotificationsScreen(),
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
