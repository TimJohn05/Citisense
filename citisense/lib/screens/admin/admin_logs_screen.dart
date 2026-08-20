import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/system_log.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/settings_button.dart';

class AdminLogsScreen extends StatelessWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final logs = appState.logs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          const SettingsButton(),
          const LogoutButton(),
        ],
      ),
      body: logs.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No logs yet',
              message: 'System activity will be recorded here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final SystemLog log = logs[index];
                return _LogTile(log: log);
              },
            ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final SystemLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: log.isSuccess
                    ? AppColors.successContainer
                    : AppColors.dangerContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                log.isSuccess
                    ? Icons.check_rounded
                    : Icons.error_outline,
                size: 18,
                color: log.isSuccess ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.action,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.detail,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MMM d, yyyy h:mm a').format(log.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
