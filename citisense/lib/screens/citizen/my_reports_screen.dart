import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/date_preset.dart';
import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/date_filter_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/location_filter_button.dart';
import '../../widgets/settings_button.dart';
import '../../widgets/skeleton.dart';
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
  String? _location;
  String _searchQuery = '';
  final _searchController = TextEditingController();

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
    // Load saved search query after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.savedSearchQuery.isNotEmpty) {
        _searchController.text = appState.savedSearchQuery;
        _searchQuery = appState.savedSearchQuery;
      }
    });
  }

  void _onExternalFilter() {
    if (mounted) {
      setState(() => _filter = widget.filterNotifier?.value);
    }
  }

  @override
  void dispose() {
    widget.filterNotifier?.removeListener(_onExternalFilter);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.isRestoringSession) {
      return const MyReportsSkeleton();
    }
    final complaints = (_filter == null
            ? appState.myComplaints
            : appState.myComplaints
                .where((c) => _filter!.contains(c.status))
                .toList())
        .where((c) => _date.matches(c.createdAt))
        .where((c) => c.matchesLocation(_location))
        .where((c) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return c.id.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q) ||
              c.category.label.toLowerCase().contains(q);
        })
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
              clipBehavior: Clip.none,
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                final trimmed = val.trim();
                setState(() => _searchQuery = trimmed);
                context.read<AppState>().setSavedSearchQuery(trimmed);
              },
              decoration: InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          context.read<AppState>().setSavedSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceMuted,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            child: Row(
              children: [
                Text(
                  '${complaints.length} shown',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const Spacer(),
                LocationFilterButton(
                  value: _location,
                  onChanged: (loc) => setState(() => _location = loc),
                ),
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
                    title: 'No reports found',
                    message: _searchQuery.isNotEmpty
                        ? 'No reports match your search. Try different keywords or clear the search.'
                        : _filter != null || _date != DatePreset.allTime || _location != null
                            ? 'No reports match your filters. Try clearing filters or adjusting date/location.'
                            : 'You haven\'t submitted any reports yet. Tap the + button to report an issue.',
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
          HapticFeedback.lightImpact();
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
