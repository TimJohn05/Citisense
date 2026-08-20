import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/logout_button.dart';
import '../../widgets/settings_button.dart';
import '../complaint_detail_screen.dart';

class OfficerComplaintsScreen extends StatefulWidget {
  const OfficerComplaintsScreen({super.key});

  @override
  State<OfficerComplaintsScreen> createState() => _OfficerComplaintsScreenState();
}

class _OfficerComplaintsScreenState extends State<OfficerComplaintsScreen> {
  ComplaintStatus? _filter;
  ComplaintCategory? _category;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    var complaints = appState.complaints;
    if (_filter != null) {
      complaints = complaints.where((c) => c.status == _filter).toList();
    }
    if (_category != null) {
      complaints = complaints.where((c) => c.category == _category).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
        actions: [
          const SettingsButton(),
          const LogoutButton(),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _chip(null, 'All'),
                for (final status in ComplaintStatus.values)
                  _chip(status, status.label),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip(null, 'Any category'),
                for (final category in ComplaintCategory.values)
                  _categoryChip(category, category.shortLabel),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: complaints.isEmpty
                ? const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No complaints found',
                    message: 'Try adjusting your filters.',
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

  Widget _chip(ComplaintStatus? status, String label) {
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 10),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = status),
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryContainer,
        showCheckmark: false,
      ),
    );
  }

  Widget _categoryChip(ComplaintCategory? category, String label) {
    final selected = _category == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8),
      child: FilterChip(
        label: Text(label),
        avatar: category != null
            ? Icon(category.icon, size: 14, color: category.color)
            : null,
        selected: selected,
        onSelected: (_) => setState(() => _category = category),
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: AppColors.primaryContainer,
        showCheckmark: false,
      ),
    );
  }
}
