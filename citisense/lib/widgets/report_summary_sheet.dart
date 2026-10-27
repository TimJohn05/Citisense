import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/date_preset.dart';
import '../core/theme/app_colors.dart';
import '../models/complaint.dart';
import '../models/enums.dart';
import '../state/app_state.dart';

Future<void> showReportSummary(BuildContext context, AppState appState) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReportSummarySheet(appState: appState),
  );
}

class _ReportSummarySheet extends StatefulWidget {
  final AppState appState;

  const _ReportSummarySheet({required this.appState});

  @override
  State<_ReportSummarySheet> createState() => _ReportSummarySheetState();
}

class _ReportSummarySheetState extends State<_ReportSummarySheet> {
  DatePreset _preset = DatePreset.last30Days;

  List<Complaint> get _complaints => widget.appState.complaints
      .where((c) => _preset.matches(c.createdAt))
      .toList();

  int _statusCount(ComplaintStatus status) =>
      _complaints.where((c) => c.status == status).length;

  int get _resolutionRate {
    if (_complaints.isEmpty) {
      return 0;
    }
    return (_statusCount(ComplaintStatus.resolved) /
            _complaints.length *
            100)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    final complaints = _complaints;
    final categories = ComplaintCategory.values
        .map((category) => (
              category,
              complaints.where((c) => c.category == category).length,
            ))
        .where((entry) => entry.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Generated ${_formatDate(DateTime.now())}',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final preset in DatePreset.values)
                    ChoiceChip(
                      label: Text(preset.label),
                      selected: _preset == preset,
                      showCheckmark: false,
                      backgroundColor: AppColors.surfaceMuted,
                      selectedColor: AppColors.primaryContainer,
                      onSelected: (_) => setState(() => _preset = preset),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (complaints.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No reports in this period.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    _Metric(
                      label: 'Total reports',
                      value: '${complaints.length}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _Metric(
                      label: 'Resolved',
                      value: '${_statusCount(ComplaintStatus.resolved)}',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _Metric(
                      label: 'Resolution rate',
                      value: '$_resolutionRate%',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Metric(
                      label: 'Pending',
                      value: '${_statusCount(ComplaintStatus.pending)}',
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    _Metric(
                      label: 'Under review',
                      value: '${_statusCount(ComplaintStatus.inReview)}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _Metric(
                      label: 'Rejected',
                      value: '${_statusCount(ComplaintStatus.rejected)}',
                      color: AppColors.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle('Sentiment breakdown'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final sentiment in Sentiment.values) ...[
                      _Metric(
                        label: sentiment.label,
                        value:
                            '${complaints.where((c) => c.sentiment == sentiment).length}',
                        color: sentiment.color,
                      ),
                      if (sentiment != Sentiment.values.last)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle('Reports by category'),
                const SizedBox(height: 6),
                for (final (category, count) in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(category.icon, size: 16, color: category.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category.label,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
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
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _copy(complaints, categories),
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: const Text('Copy summary'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copy(
    List<Complaint> complaints,
    List<(ComplaintCategory, int)> categories,
  ) async {
    final buffer = StringBuffer()
      ..writeln('CitiSense report summary')
      ..writeln('Period: ${_preset.label}')
      ..writeln('Generated: ${_formatDate(DateTime.now())}')
      ..writeln()
      ..writeln('Total reports: ${complaints.length}')
      ..writeln('Pending: ${_statusCount(ComplaintStatus.pending)}')
      ..writeln('Under review: ${_statusCount(ComplaintStatus.inReview)}')
      ..writeln('Resolved: ${_statusCount(ComplaintStatus.resolved)}')
      ..writeln('Rejected: ${_statusCount(ComplaintStatus.rejected)}')
      ..writeln('Resolution rate: $_resolutionRate%')
      ..writeln()
      ..writeln('Sentiment:');
    for (final sentiment in Sentiment.values) {
      buffer.writeln(
        '${sentiment.label}: ${complaints.where((c) => c.sentiment == sentiment).length}',
      );
    }
    buffer
      ..writeln()
      ..writeln('By category:');
    for (final (category, count) in categories) {
      buffer.writeln('${category.label}: $count');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary copied to clipboard.')),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} '
        '$hour:$minute $period';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
