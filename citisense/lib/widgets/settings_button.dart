import 'package:flutter/material.dart';

import '../screens/settings/settings_screen.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Settings',
    );
  }
}
