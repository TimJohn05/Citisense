import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../widgets/attention_panel.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/report_summary_sheet.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_chart.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/skeleton.dart';
import '../complaint_detail_screen.dart';

class OfficerDashboardScreen extends StatelessWidget {
  final ValueNotifier<ComplaintStatus?>? complaintFilter;

  const OfficerDashboardScreen({super.key, this.complaintFilter});

  void _openComplaints(BuildContext context, ComplaintStatus? status) {
    complaintFilter?.value = status;
    context.read<ValueNotifier<int>>().value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isRestoringSession) {
      return const OfficerDashboardSkeleton();
    }
    final attention = appState.needsAttention;
    final recent = appState.complaints.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          const SettingsButton(),
          const LogoutButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.officer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14, color: AppColors.officer),
                      SizedBox(width: 6),
                      Text(
                        'BARANGAY OFFICIAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.officer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${appState.complaints.length} reports',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total reports',
                    value: '${appState.totalComplaints}',
                    icon: Icons.inbox_outlined,
                    color: AppColors.primary,
                    onTap: () => _openComplaints(context, null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Pending',
                    value: '${appState.pendingCount}',
                    icon: Icons.schedule,
                    color: AppColors.warning,
                    onTap: () =>
                        _openComplaints(context, ComplaintStatus.pending),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Under review',
                    value: '${appState.inReviewCount}',
                    icon: Icons.visibility_outlined,
                    color: AppColors.primary,
                    onTap: () =>
                        _openComplaints(context, ComplaintStatus.inReview),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Resolved',
                    value: '${appState.resolvedCount}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                    onTap: () =>
                        _openComplaints(context, ComplaintStatus.resolved),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Rejected',
                    value: '${appState.rejectedCount}',
                    icon: Icons.cancel_outlined,
                    color: AppColors.danger,
                    onTap: () =>
                        _openComplaints(context, ComplaintStatus.rejected),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (attention.isNotEmpty) ...[
              AttentionPanel(complaints: attention),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showReportSummary(context, appState),
                icon: const Icon(Icons.summarize_outlined, size: 18),
                label: const Text('Generate report summary'),
              ),
            ),
            const SizedBox(height: 16),
            StatusChart(
              appState: appState,
              onStatusTap: (status) => _openComplaints(context, status),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(child: _CategoryChart(complaints: appState.complaints)),
            const SizedBox(height: 24),
            Text(
              'Recent Complaints',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'No complaints yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              )
            else
              for (final Complaint complaint in recent) ...[
                ComplaintCard(
                  complaint: complaint,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ComplaintDetailScreen(
                        complaintId: complaint.id,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final List<Complaint> complaints;

  const _CategoryChart({required this.complaints});

  @override
  Widget build(BuildContext context) {
    final categories = ComplaintCategory.values;
    final data = [
      for (final category in categories)
        (
          category,
          complaints.where((c) => c.category == category).length.toDouble(),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports by category',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            for (final (category, count) in data) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(category.icon, size: 16, color: category.color),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: Text(
                        category.shortLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: complaints.isEmpty
                              ? 0
                              : count / complaints.length,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceMuted,
                          color: category.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${count.toInt()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
