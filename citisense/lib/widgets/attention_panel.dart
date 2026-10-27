import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/complaint.dart';
import '../models/enums.dart';
import '../screens/complaint_detail_screen.dart';

class AttentionPanel extends StatelessWidget {
  final List<Complaint> complaints;

  const AttentionPanel({super.key, required this.complaints});

  @override
  Widget build(BuildContext context) {
    if (complaints.isEmpty) {
      return const SizedBox.shrink();
    }
    final visible = complaints.take(3).toList();

    return Card(
      color: AppColors.warning.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Urgent alerts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${complaints.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'High-risk or open for more than 3 days',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            for (final complaint in visible)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ComplaintDetailScreen(complaintId: complaint.id),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(complaint.category.icon,
                          size: 16, color: complaint.category.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          complaint.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _ageLabel(complaint),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ),
              ),
            if (complaints.length > visible.length)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Text(
                  '+${complaints.length - visible.length} more need attention',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _ageLabel(Complaint complaint) {
    final days = DateTime.now().difference(complaint.createdAt).inDays;
    if (days <= 0) {
      return 'Today';
    }
    if (days == 1) {
      return '1 day open';
    }
    return '$days days open';
  }
}
