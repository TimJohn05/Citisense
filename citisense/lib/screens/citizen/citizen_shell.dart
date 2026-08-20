import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'citizen_home_screen.dart';
import 'my_reports_screen.dart';
import 'report_issue_screen.dart';

class CitizenShell extends StatefulWidget {
  const CitizenShell({super.key});

  @override
  State<CitizenShell> createState() => _CitizenShellState();
}

class _CitizenShellState extends State<CitizenShell> {
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
                    CitizenHomeScreen(),
                    ReportIssueScreen(),
                    MyReportsScreen(),
                  ],
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      context.read<ValueNotifier<int>>().value = value,
                  destinations: const [
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
