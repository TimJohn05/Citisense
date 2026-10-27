import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../models/citizen_notification.dart';
import '../models/enums.dart';
import '../screens/complaint_detail_screen.dart';

class OfficerActionBanner extends StatefulWidget {
  final List<CitizenNotification> notifications;
  final ValueChanged<String> onDismiss;

  const OfficerActionBanner({
    super.key,
    required this.notifications,
    required this.onDismiss,
  });

  @override
  State<OfficerActionBanner> createState() => _OfficerActionBannerState();
}

class _OfficerActionBannerState extends State<OfficerActionBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeIndex = _currentIndex.clamp(0, widget.notifications.length - 1);
    final notification = widget.notifications[safeIndex];

    final (color, icon, labelPrefix) = switch (notification.status) {
      ComplaintStatus.inReview => (
          AppColors.warning,
          Icons.visibility_outlined,
          'REPORT PLACED UNDER REVIEW',
        ),
      ComplaintStatus.resolved => (
          AppColors.success,
          Icons.check_circle_outline,
          'REPORT ACCEPTED & RESOLVED',
        ),
      ComplaintStatus.rejected => (
          AppColors.danger,
          Icons.cancel_outlined,
          'REPORT REJECTED',
        ),
      _ => (
          AppColors.primary,
          Icons.info_outline,
          'REPORT STATUS UPDATED',
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ComplaintDetailScreen(
                  complaintId: notification.complaintId,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Action Heading & Dismiss
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelPrefix,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${notification.category.label} • ${DateFormat('MMM d, h:mm a').format(notification.timestamp)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Dismiss update',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.textMuted,
                      onPressed: () => widget.onDismiss(notification.id),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom Box: Reason Why & Remarks from Barangay Officer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            notification.status == ComplaintStatus.rejected
                                ? Icons.help_outline
                                : Icons.speaker_notes_outlined,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            notification.status == ComplaintStatus.rejected
                                ? 'REASON FOR REJECTION'
                                : 'BARANGAY OFFICER REMARKS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.remarks,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Action hint & Multi-update indicator
                Row(
                  children: [
                    Text(
                      'Tap to view progress report',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const Spacer(),
                    if (widget.notifications.length > 1) ...[
                      InkWell(
                        onTap: () {
                          setState(() {
                            _currentIndex = (_currentIndex - 1 +
                                    widget.notifications.length) %
                                widget.notifications.length;
                          });
                        },
                        child: const Icon(Icons.chevron_left, size: 18),
                      ),
                      Text(
                        '${safeIndex + 1} of ${widget.notifications.length}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _currentIndex = (_currentIndex + 1) %
                                widget.notifications.length;
                          });
                        },
                        child: const Icon(Icons.chevron_right, size: 18),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
