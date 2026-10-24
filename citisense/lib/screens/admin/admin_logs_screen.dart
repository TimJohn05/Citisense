import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/system_log.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/settings_button.dart';

enum _LogGroup { login, logout, signup, complaint, user, system }

class _GroupSpec {
  final _LogGroup group;
  final String label;
  final IconData icon;
  final Color color;

  const _GroupSpec(this.group, this.label, this.icon, this.color);
}

const _groupSpecs = [
  _GroupSpec(_LogGroup.login, 'Logins', Icons.login, Color(0xFF1565C0)),
  _GroupSpec(_LogGroup.logout, 'Logouts', Icons.logout, Color(0xFF6A1B9A)),
  _GroupSpec(_LogGroup.signup, 'Signups', Icons.person_add_outlined,
      Color(0xFF00695C)),
  _GroupSpec(_LogGroup.complaint, 'Reports', Icons.report_outlined,
      Color(0xFFE65100)),
  _GroupSpec(_LogGroup.user, 'User Access', Icons.admin_panel_settings_outlined,
      Color(0xFF283593)),
  _GroupSpec(_LogGroup.system, 'System', Icons.memory, Color(0xFF455A64)),
];

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  _LogGroup? _filter;
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allLogs = [...appState.logs]..sort((a, b) {
        final diff = a.timestamp.compareTo(b.timestamp);
        return _ascending ? diff : -diff;
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          const SettingsButton(),
          const LogoutButton(),
        ],
      ),
      body: allLogs.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No logs yet',
              message: 'System activity will be recorded here.',
            )
          : Column(
              children: [
                _buildFilterBar(allLogs),
                const Divider(height: 1),
                Expanded(child: _buildLogList(allLogs)),
              ],
            ),
    );
  }

  Widget _buildFilterBar(List<SystemLog> logs) {
    final chips = <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 16),
        child: ChoiceChip(
          label: const Text('All'),
          selected: _filter == null,
          onSelected: (_) => setState(() => _filter = null),
        ),
      ),
      for (final spec in _groupSpecs)
        ChoiceChip(
          label: Text(spec.label),
          selected: _filter == spec.group,
          onSelected: (_) => setState(() => _filter = spec.group),
        ),
    ];
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              children: chips,
            ),
          ),
          if (logs.isNotEmpty)
            IconButton(
              tooltip: _ascending ? 'Oldest first' : 'Newest first',
              onPressed: () => setState(() => _ascending = !_ascending),
              icon: Icon(
                _ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 20,
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildLogList(List<SystemLog> logs) {
    if (_filter != null) {
      final spec =
          _groupSpecs.firstWhere((s) => s.group == _filter);
      final groupLogs =
          logs.where((l) => _groupFor(l.action) == _filter).toList();
      if (groupLogs.isEmpty) {
        return Center(
          child: Text(
            'No ${spec.label.toLowerCase()} recorded yet',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GroupHeader(spec: spec, count: groupLogs.length),
          const SizedBox(height: 4),
          for (final log in groupLogs) _LogTile(log: log),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        for (final log in logs) _LogTile(log: log),
      ],
    );
  }
}

_LogGroup _groupFor(String action) {
  switch (action) {
    case 'Login':
      return _LogGroup.login;
    case 'Logout':
      return _LogGroup.logout;
    case 'Signup':
      return _LogGroup.signup;
    case 'Complaint Filed':
    case 'Complaint Updated':
    case 'Complaint Removed':
      return _LogGroup.complaint;
    case 'Officer Created':
    case 'Access Restored':
    case 'Access Revoked':
      return _LogGroup.user;
    default:
      return _LogGroup.system;
  }
}

class _GroupHeader extends StatelessWidget {
  final _GroupSpec spec;
  final int count;

  const _GroupHeader({required this.spec, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6, left: 4),
      child: Row(
        children: [
          Icon(spec.icon, size: 18, color: spec.color),
          const SizedBox(width: 8),
          Text(
            spec.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: spec.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final SystemLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final spec = _groupSpecs.firstWhere((s) => s.group == _groupFor(log.action));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: log.isSuccess
                    ? spec.color.withValues(alpha: 0.14)
                    : AppColors.dangerContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                log.isSuccess ? spec.icon : Icons.error_outline,
                size: 19,
                color: log.isSuccess ? spec.color : AppColors.danger,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.action,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, h:mm a').format(log.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}