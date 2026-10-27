import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_preset.dart';
import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/date_filter_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/settings_button.dart';
import '../complaint_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  final ValueNotifier<Set<ComplaintStatus>?>? filterNotifier;

  const MyReportsScreen({super.key, this.filterNotifier});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  Set<ComplaintStatus>? _filter;
  DatePreset _date = DatePreset.allTime;

  static const List<(String, Set<ComplaintStatus>?)> _filters = [
    ('All', null),
    ('In progress', {ComplaintStatus.pending, ComplaintStatus.inReview}),
    ('Resolved', {ComplaintStatus.resolved}),
    ('Rejected', {ComplaintStatus.rejected}),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.filterNotifier?.value;
    widget.filterNotifier?.addListener(_onExternalFilter);
  }

  void _onExternalFilter() {
    if (mounted) {
      setState(() => _filter = widget.filterNotifier?.value);
    }
  }

  @override
  void dispose() {
    widget.filterNotifier?.removeListener(_onExternalFilter);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final complaints = (_filter == null
            ? appState.myComplaints
            : appState.myComplaints
                .where((c) => _filter!.contains(c.status))
                .toList())
        .where((c) => _date.matches(c.createdAt))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [const SettingsButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final (label, statuses) in _filters)
                  _filterChip(statuses, label),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                Text(
                  '${complaints.length} shown',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const Spacer(),
                DateFilterButton(
                  value: _date,
                  onChanged: (preset) => setState(() => _date = preset),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: complaints.isEmpty
                ? EmptyState(
                    icon: Icons.article_outlined,
                    title: 'No reports for these filters',
                    message: 'Adjust the status or date filter to see more.',
                  )
                : RefreshIndicator(
                    onRefresh: () => appState.refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: complaints.length,
                      itemBuilder: (context, index) {
                        final Complaint complaint = complaints[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ComplaintCard(
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
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(Set<ComplaintStatus>? statuses, String label) {
    final selected = statuses == null
        ? _filter == null
        : _filter != null &&
            _filter!.length == statuses.length &&
            _filter!.containsAll(statuses);
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = statuses);
          widget.filterNotifier?.value = statuses;
        },
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryContainer,
        showCheckmark: false,
      ),
    );
  }
}
