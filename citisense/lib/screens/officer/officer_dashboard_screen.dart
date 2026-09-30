import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/settings_button.dart';
import '../complaint_detail_screen.dart';

class OfficerDashboardScreen extends StatelessWidget {
  const OfficerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
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
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  label: 'Total reports',
                  value: '${appState.totalComplaints}',
                  icon: Icons.inbox_outlined,
                  color: AppColors.primary,
                ),
                StatCard(
                  label: 'Pending',
                  value: '${appState.pendingCount}',
                  icon: Icons.schedule,
                  color: AppColors.warning,
                ),
                StatCard(
                  label: 'Under review',
                  value: '${appState.inReviewCount}',
                  icon: Icons.visibility_outlined,
                  color: AppColors.primary,
                ),
                StatCard(
                  label: 'Resolved',
                  value: '${appState.resolvedCount}',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _CategoryChart(complaints: appState.complaints),
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
    final counts = [
      for (final category in ComplaintCategory.values)
        complaints.where((c) => c.category == category).length,
    ];
    final maxCount = counts.fold(1, (a, b) => a > b ? a : b);

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
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: (maxCount + 1).toDouble(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= ComplaintCategory.values.length) {
                            return const SizedBox.shrink();
                          }
                          final category = ComplaintCategory.values[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Icon(
                              category.icon,
                              size: 18,
                              color: category.color,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < counts.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i].toDouble(),
                            color: ComplaintCategory.values[i].color,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
