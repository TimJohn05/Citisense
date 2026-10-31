import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complaint.dart';
import '../../models/enums.dart';
import '../../models/media_item.dart';
import '../../state/app_state.dart';
import '../../utils/text_validators.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/media_picker.dart';
import '../../widgets/settings_button.dart';
import 'citizen_shell.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  ComplaintCategory? _category;
  final _descriptionController = TextEditingController();
  List<MediaItem> _evidence = [];
  LatLng? _location;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSubmitPressed() async {
    if (!_validate()) return;
    HapticFeedback.lightImpact();
    final confirmed = await _confirmSubmission();
    if (!confirmed || !mounted) return;
    await _submit();
  }

  bool _validate() {
    if (_category == null) {
      _showError('Please select a complaint category.');
      return false;
    }
    final description = _descriptionController.text.trim();
    if (description.length < 10) {
      _showError('Please describe the issue in at least 10 characters.');
      return false;
    }
    if (looksLikeGibberish(description)) {
      _showError(
          'You cannot submit gibberish text. Please describe the issue clearly.');
      return false;
    }
    if (_location == null) {
      _showError('Set the pin location on the map before submitting.');
      return false;
    }
    return true;
  }

  Future<bool> _confirmSubmission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Report?'),
        content: const Text(
          'Are you sure you want to submit this report? '
          'Once submitted, it cannot be changed.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    setState(() => _submitting = true);
    try {
      final complaint = await context.read<AppState>().submitComplaint(
            category: _category!,
            description: description,
            latitude: _location?.latitude,
            longitude: _location?.longitude,
            evidence: _evidence,
          );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _SubmissionResultScreen(complaint: complaint),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        _showError('Failed to submit the complaint. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
        actions: [const SettingsButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _submitting
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Describe the problem',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ComplaintCategory.values)
                ChoiceChip(
                  label: Text(category.label),
                  avatar: Icon(category.icon, size: 16),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Description',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            minLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Describe the issue. Include landmarks or other useful details...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Evidence (photos & videos)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          MediaPicker(
            label: 'Add evidence photos & videos',
            onChanged: (items) => _evidence = items,
          ),
          const SizedBox(height: 20),
          Text(
            'Location',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          LocationPicker(
            onChanged: (position) => _location = position,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _submitting ? null : _onSubmitPressed,
            child: _submitting
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Analyze & Submit Report'),
          ),
          const SizedBox(height: 8),
          Text(
            'Your report will be analyzed for sentiment and sent to barangay officials.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SubmissionResultScreen extends StatelessWidget {
  final Complaint complaint;

  const _SubmissionResultScreen({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final sentiment = complaint.sentiment;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Report Submitted'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 44,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Report received',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for helping improve your barangay. Your report has been dispatched to the officials.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUTO-ANALYSIS RESULT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          sentiment.icon,
                          color: sentiment.color,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Sentiment: ${sentiment.label} (Naive Bayes)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: sentiment.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Suggested action: ${complaint.recommendation}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    transitionDuration: Duration.zero,
                    pageBuilder: (_, _, _) => const CitizenShell(),
                  ),
                  (_) => false,
                );
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
