import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../models/complaint.dart';
import 'chips.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final VoidCallback onTap;

  const ComplaintCard({super.key, required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryChip(category: complaint.category),
                  const Spacer(),
                  StatusChip(status: complaint.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SentimentBadge(sentiment: complaint.sentiment),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, yyyy').format(complaint.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              if (complaint.hasLocation) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 14, color: AppColors.textMuted, semanticLabel: 'Location'),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${complaint.latitude!.toStringAsFixed(5)}, '
                        '${complaint.longitude!.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (complaint.evidenceVideos.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.videocam_outlined,
                        size: 14, color: AppColors.textMuted, semanticLabel: 'Video evidence'),
                    const SizedBox(width: 4),
                    Text(
                      '${complaint.evidenceVideos.length} video${complaint.evidenceVideos.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
