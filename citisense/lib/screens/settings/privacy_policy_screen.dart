import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'CitiSense Privacy Policy',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated: August 5, 2026',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const _Section(
            title: '1. Overview',
            body:
                'CitiSense is a barangay feedback and resolution platform for '
                'Calamba City, Laguna. This policy explains how the app handles '
                'your personal data when you use it to file a community report.',
          ),
          const _Section(
            title: '2. Permissions we request',
            body:
                'Camera: used only to capture an evidence photo when you file a '
                'report and a proof photo when an official resolves it. '
                'Photos are captured only when you tap the capture button.\n\n'
                'Location: used only to pin the exact location of the issue you '
                'are reporting on the map. You can drag the map to choose the pin '
                'manually, or press the crosshair button to use your device\'s '
                'current GPS position. Your location is never tracked in the '
                'background.',
          ),
          const _Section(
            title: '3. What we collect',
            body:
                'When you file a report we store: your account name and email, '
                'the report description and category, the map coordinates of the '
                'pin, the evidence photo you upload, and the resolution status. '
                'Barangay officials and system administrators can view reports '
                'to act on them.',
          ),
          const _Section(
            title: '4. How we use it',
            body:
                'Data is used only to receive, route and resolve community '
                'complaints: showing officials where the issue is, attaching '
                'visual evidence, and keeping a public audit trail of how '
                'reports were handled.',
          ),
          const _Section(
            title: '5. Where it is stored',
            body:
                'In the demonstration build, reports are stored only on your '
                'device. When the live backend is enabled, reports are stored in '
                'Google Firebase (Firestore and Storage), whose servers may be '
                'located outside the Philippines.',
          ),
          const _Section(
            title: '6. Sharing',
            body:
                'We do not sell or rent your personal data. Report information '
                'is visible to barangay officials and administrators of the '
                'system for the purpose of resolving reports.',
          ),
          const _Section(
            title: '7. Your choices',
            body:
                'You may decline any permission at any time. Without the camera '
                'and location permissions you can still read reports, but you '
                'cannot fully file a new report. You may sign out or delete the '
                'app at any time; reports you filed may remain on the backend '
                'for the barangay\'s records.',
          ),
          const _Section(
            title: '8. Contact',
            body:
                'For privacy questions, contact the barangay administrator '
                'through the local barangay hall or the project team behind '
                'CitiSense.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
