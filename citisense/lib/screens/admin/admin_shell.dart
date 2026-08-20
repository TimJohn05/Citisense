import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListenableProvider<ValueNotifier<int>>(
      create: (_) => ValueNotifier<int>(_index),
      child: Builder(
        builder: (context) {
          return ValueListenableBuilder<int>(
            valueListenable: context.watch<ValueNotifier<int>>(),
            builder: (context, index, _) {
              _index = index;
              return Scaffold(
                body: IndexedStack(
                  index: index,
                  children: const [
                    AdminDashboardScreen(),
                    AdminUsersScreen(),
                    AdminComplaintsScreen(),
                    AdminLogsScreen(),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      context.read<ValueNotifier<int>>().value = value,
                  destinations: const [
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
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
