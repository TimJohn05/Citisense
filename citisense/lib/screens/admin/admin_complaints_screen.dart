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

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  ComplaintStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final complaints = _filter == null
        ? appState.complaints
        : appState.complaints.where((c) => c.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Complaints'),
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
}
