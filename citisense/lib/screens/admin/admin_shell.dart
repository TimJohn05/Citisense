import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import 'admin_complaints_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_logs_screen.dart';
import 'admin_users_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
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
      icon: Icon(Icons.group_outlined),
      selectedIcon: Icon(Icons.group),
      label: 'Users',
    ),
    NavigationDestination(
      icon: Icon(Icons.inbox_outlined),
      selectedIcon: Icon(Icons.inbox),
      label: 'Complaints',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Logs',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.group_outlined),
      selectedIcon: Icon(Icons.group),
      label: Text('Users'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.inbox_outlined),
      selectedIcon: Icon(Icons.inbox),
      label: Text('Complaints'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('Logs'),
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
                  AdminDashboardScreen(complaintFilter: _complaintFilter),
                  AdminUsersScreen(),
                  AdminComplaintsScreen(filterNotifier: _complaintFilter),
                  AdminLogsScreen(),
                ],
              );
              return Scaffold(
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
                                    context.read<ValueNotifier<int>>().value = value,
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
                            context.read<ValueNotifier<int>>().value = value,
                        destinations: _destinations,
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
