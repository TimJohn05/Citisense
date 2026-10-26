import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/settings_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Dashboard'),
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
                    color: AppColors.admin.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 14, color: AppColors.admin),
                      SizedBox(width: 6),
                      Text(
                        'SYSTEM ADMIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.admin,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${appState.users.length} users',
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
                    label: 'Total complaints',
                    value: '${appState.totalComplaints}',
                    icon: Icons.inbox_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Resolution rate',
                    value: '${appState.resolutionRate.toStringAsFixed(0)}%',
                    icon: Icons.verified_outlined,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Resolved',
                    value: '${appState.resolvedCount}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Pending / Review',
                    value: '${appState.pendingCount + appState.inReviewCount}',
                    icon: Icons.schedule,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StatusChart(appState: appState),
            const SizedBox(height: 16),
            RepaintBoundary(child: _CategoryChart(complaints: appState.complaints)),
            const SizedBox(height: 16),
            _SentimentChart(appState: appState),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatusChart extends StatelessWidget {
  final AppState appState;

  const _StatusChart({required this.appState});

  @override
  Widget build(BuildContext context) {
    final statuses = ComplaintStatus.values;
    final counts = [
      for (final status in statuses) appState.complaintsByStatus(status).length,
    ];
    final maxCount = counts.fold(1, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complaints by status',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
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
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= statuses.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              statuses[index].label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
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
                            color: statuses[i].color,
                            width: 26,
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
              'Complaints by category',
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

class _SentimentChart extends StatelessWidget {
  final AppState appState;

  const _SentimentChart({required this.appState});

  @override
  Widget build(BuildContext context) {
    final sentiments = Sentiment.values;
    final data = [
      (sentiments[0], appState.positiveCount),
      (sentiments[1], appState.neutralCount),
      (sentiments[2], appState.negativeCount),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: [
                      for (final (sentiment, count) in data)
                        PieChartSectionData(
                          value: count.toDouble(),
                          color: sentiment.color,
                          radius: 36,
                          showTitle: count > 0,
                          title: count > 0 ? '$count' : '',
                          titleStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: sentiment.color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (sentiment, count) in data)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: sentiment.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sentiment.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
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
