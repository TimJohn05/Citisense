import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/settings_button.dart';
import '../complaint_detail_screen.dart';
import 'report_issue_screen.dart';

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user!;
    final myComplaints = appState.myComplaints;
    final recent = myComplaints.take(3).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => appState.refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SettingsButton(),
                const LogoutButton(),
              ],
            ),
            const SizedBox(height: 16),
            _ReportCta(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _MiniStat(
                  label: 'My reports',
                  value: '${myComplaints.length}',
                  color: AppColors.primary,
                  icon: Icons.article_outlined,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: 'Pending',
                  value: '${myComplaints.where((c) => c.status == ComplaintStatus.pending || c.status == ComplaintStatus.inReview).length}',
                  color: AppColors.warning,
                  icon: Icons.schedule,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: 'Resolved',
                  value: '${myComplaints.where((c) => c.status == ComplaintStatus.resolved).length}',
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (myComplaints.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      context.read<ValueNotifier<int>>().value = 2;
                    },
                    child: const Text('View all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Text(
                  'You have not filed any reports yet. Tap the button above to report an issue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
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

class _ReportCta extends StatelessWidget {
  final VoidCallback onTap;

  const _ReportCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF1D7BB8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report an issue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Take a photo and pin the location',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
