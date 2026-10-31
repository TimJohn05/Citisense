import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/version_check_service.dart';

class UpdatePromptWrapper extends StatefulWidget {
  final Widget child;

  const UpdatePromptWrapper({super.key, required this.child});

  @override
  State<UpdatePromptWrapper> createState() => _UpdatePromptWrapperState();
}

class _UpdatePromptWrapperState extends State<UpdatePromptWrapper> {
  final VersionCheckService _versionService = VersionCheckService();
  bool _checked = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (_checked || _dismissed) return;
    try {
      final status = await _versionService.checkVersion();
      if (!mounted) return;
      if (status.shouldPromptUpdate) {
        _showUpdateDialog(status);
      }
    } catch (_) {
      // Silently ignore version check failures
    } finally {
      _checked = true;
    }
  }

  void _showUpdateDialog(VersionStatus status) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _UpdateDialog(
        status: status,
        onDismiss: () => _dismissed = true,
        onUpdate: () => _downloadAndInstall(status.updateUrl!),
      ),
    );
  }

  Future<void> _downloadAndInstall(String url) async {
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading update...'),
        duration: Duration(seconds: 30),
      ),
    );
    try {
      await _versionService.downloadAndInstallApk(url);
      // If successful, the installer will take over and app will be replaced
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e. Opening in browser...')),
      );
      // downloadAndInstallApk already falls back to browser
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _UpdateDialog extends StatelessWidget {
  final VersionStatus status;
  final VoidCallback onDismiss;
  final VoidCallback onUpdate;

  const _UpdateDialog({
    required this.status,
    required this.onDismiss,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final notes = status.updateNotes ?? '';
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          const Expanded(child: Text('Update Available')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A new version (${status.latestVersion}) is available. '
            'You are on ${status.currentVersion}.',
            style: const TextStyle(fontSize: 15),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'What\'s new:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(notes, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onDismiss();
            Navigator.of(context).pop();
          },
          child: const Text('Later'),
        ),
        FilledButton.icon(
          onPressed: onUpdate,
          icon: const Icon(Icons.download),
          label: const Text('Update Now'),
        ),
      ],
    );
  }
}