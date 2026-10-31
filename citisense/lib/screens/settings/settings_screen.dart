import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeStyle>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeStyle.system,
                        label: Text(
                          'System',
                          style: TextStyle(fontSize: 12),
                        ),
                        icon: Icon(Icons.brightness_auto_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeStyle.light,
                        label: Text(
                          'Light',
                          style: TextStyle(fontSize: 12),
                        ),
                        icon: Icon(Icons.light_mode_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeStyle.dark,
                        label: Text(
                          'Dark',
                          style: TextStyle(fontSize: 12),
                        ),
                        icon: Icon(Icons.dark_mode_outlined, size: 16),
                      ),
                    ],
                    selected: {
                      if (appState.themeStyle == ThemeStyle.highContrast)
                        ThemeStyle.system
                      else
                        appState.themeStyle,
                    },
                    onSelectionChanged: (selection) =>
                        appState.setThemeStyle(selection.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'High contrast',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Stronger text, darker borders and bolder colors.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: appState.highContrast,
                    onChanged: appState.setHighContrast,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Push notifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Receive status updates for your complaints.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enabled',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Get notified when your complaint status changes.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: appState.notificationsEnabled,
                    onChanged: appState.setNotificationsEnabled,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CitiSense',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Barangay Feedback & Resolution Platform, a Software Engineering 2 project.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: const Text('Privacy Policy'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
