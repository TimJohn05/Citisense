import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../state/app_state.dart';
import '../../widgets/complaint_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/settings_button.dart';
import '../complaint_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  ComplaintStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final complaints = _filter == null
        ? appState.myComplaints
        : appState.myComplaints
            .where((c) => c.status == _filter)
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
                _filterChip(null, 'All'),
                for (final status in ComplaintStatus.values)
                  _filterChip(status, status.label),
              ],
            ),
          ),
        ),
      ),
      body: complaints.isEmpty
          ? EmptyState(
              icon: Icons.article_outlined,
              title: 'No reports yet',
              message: 'Reports you file will appear here so you can track them.',
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
    );
  }

  Widget _filterChip(ComplaintStatus? status, String label) {
    final selected = _filter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
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
