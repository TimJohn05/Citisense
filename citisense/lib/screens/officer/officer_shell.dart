import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'officer_complaints_screen.dart';
import 'officer_dashboard_screen.dart';

class OfficerShell extends StatefulWidget {
  const OfficerShell({super.key});

  @override
  State<OfficerShell> createState() => _OfficerShellState();
}

class _OfficerShellState extends State<OfficerShell> {
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
                    OfficerDashboardScreen(),
                    OfficerComplaintsScreen(),
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
                      icon: Icon(Icons.inbox_outlined),
                      selectedIcon: Icon(Icons.inbox),
                      label: 'Complaints',
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
