import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../core/theme/app_colors.dart';
import '../models/complaint.dart';
import '../models/enums.dart';
import '../models/media_item.dart';
import '../models/user_role.dart';
import '../screens/officer/navigation_screen.dart';
import '../services/firebase_repository.dart';
import '../state/app_state.dart';
import '../utils/text_validators.dart';
import '../widgets/app_image.dart';
import '../widgets/chips.dart';
import '../widgets/media_picker.dart';
import '../widgets/settings_button.dart';
import '../widgets/static_map_preview.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  Complaint? _complaint;
  UserRole? _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    final matches = appState.complaints.where((c) => c.id == widget.complaintId).toList();
    _complaint = matches.isEmpty ? null : matches.first;
    _role = appState.user?.role;
  }

  @override
  Widget build(BuildContext context) {
    final complaint = _complaint;
    if (complaint == null) {
      return const Scaffold(body: Center(child: Text('Complaint not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        actions: [const SettingsButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
          _buildTimeline(complaint),
          const SizedBox(height: 20),
          Text(
            complaint.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildMetaSection(complaint),
          if (complaint.evidencePhotos.isNotEmpty ||
              complaint.evidenceVideos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Evidence'),
            const SizedBox(height: 8),
            _EvidenceGallery(complaint: complaint),
          ],
          if (complaint.hasLocation) ...[
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Reported location'),
            const SizedBox(height: 8),
            StaticMapPreview(
              latitude: complaint.latitude!,
              longitude: complaint.longitude!,
            ),
            const SizedBox(height: 8),
            Text(
              '${complaint.latitude!.toStringAsFixed(6)}, '
              '${complaint.longitude!.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (_role == UserRole.officer && complaint.hasLocation) ...[
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Navigation'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NavigationScreen(
                        latitude: complaint.latitude!,
                        longitude: complaint.longitude!,
                        title: complaint.description,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.directions_outlined, semanticLabel: 'Get directions'),
                label: const Text('Get directions, follow the route'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
          if (complaint.officerNotes != null &&
              complaint.officerNotes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Official notes'),
            const SizedBox(height: 8),
            _NotesBox(notes: complaint.officerNotes!),
          ],
          if (complaint.rejectReason != null) ...[
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Reason for rejection'),
            const SizedBox(height: 8),
            _NotesBox(
              notes: complaint.rejectReason!,
              color: AppColors.danger,
            ),
          ],
          if (complaint.proofPhotos.isNotEmpty ||
            complaint.proofVideos.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionLabel(label: 'Resolution proof'),
            const SizedBox(height: 8),
            _ProofGallery(complaint: complaint),
          ],
          if (complaint.status == ComplaintStatus.resolved) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.task_alt,
                    size: 14, color: AppColors.success, semanticLabel: 'Resolved'),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Resolved by ${complaint.resolvedBy ?? 'an official'} '
                    'on ${DateFormat('MMM d, yyyy').format(complaint.resolvedAt ?? complaint.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          if (_role == UserRole.officer) _buildOfficerActions(complaint),
          if (_role == UserRole.admin) _buildAdminActions(complaint),
          const SizedBox(height: 24),
],
      ),
    ),
  );
  }

  Widget _buildMetaSection(Complaint complaint) {
    return Row(
      children: [
        CategoryChip(category: complaint.category),
        const SizedBox(width: 8),
        SentimentBadge(sentiment: complaint.sentiment),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('MMM d, yyyy').format(complaint.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'By ${complaint.citizenName}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildTimeline(Complaint complaint) {
    final steps = [
      (label: 'Submitted', done: true, icon: Icons.file_upload_outlined),
      (
        label: 'Under Review',
        done: complaint.status.index >= ComplaintStatus.inReview.index,
        icon: Icons.visibility_outlined,
      ),
      (
        label: 'Resolved',
        done: complaint.status == ComplaintStatus.resolved,
        icon: Icons.check_circle_outline,
      ),
    ];

    if (complaint.status == ComplaintStatus.rejected) {
      steps[2] = (
        label: 'Rejected',
        done: true,
        icon: Icons.cancel_outlined,
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      children.add(
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: steps[i].done
                    ? (complaint.status == ComplaintStatus.rejected && i == 2
                        ? AppColors.danger
                        : AppColors.success)
                    : AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                steps[i].icon,
                size: 16,
                color: steps[i].done ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              steps[i].label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: steps[i].done
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
      if (i < steps.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Container(
              width: 2,
              height: 20,
              color: steps[i + 1].done
                  ? AppColors.success
                  : AppColors.border,
            ),
          ),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildOfficerActions(Complaint complaint) {
    final isOpen =
        complaint.status == ComplaintStatus.pending ||
        complaint.status == ComplaintStatus.inReview;

    if (!isOpen) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (complaint.status == ComplaintStatus.pending) ...[
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAcknowledgeSheet(complaint);
            },
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Acknowledge & Under Review'),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showResolveSheet(complaint);
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark as Resolved with Proof'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showRejectSheet(complaint);
          },
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Reject Report'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: BorderSide(color: AppColors.danger),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActions(Complaint complaint) {
    return OutlinedButton.icon(
      onPressed: () => _confirmDelete(complaint),
      icon: Icon(Icons.delete_outline, color: AppColors.danger, semanticLabel: 'Delete complaint'),
      label: Text('Remove Complaint'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.danger,
        side: BorderSide(color: AppColors.danger),
      ),
    );
  }

  void _showAcknowledgeSheet(Complaint complaint) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acknowledge Complaint',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirm the report is being reviewed by your office.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Review notes (optional)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final notes = controller.text.trim();
                if (notes.isNotEmpty && looksLikeGibberish(notes)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'You cannot submit gibberish text. Please enter clear review notes.'),
                    ),
                  );
                  return;
                }
                final appState = context.read<AppState>();
                appState.acknowledgeComplaint(complaint, notes);
                Navigator.pop(context);
              },
              child: const Text('Acknowledge'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResolveSheet(Complaint complaint) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ResolveSheet(complaint: complaint),
    );
  }

  void _showRejectSheet(Complaint complaint) {
    final controller = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reject Report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide a reason why this report is being rejected.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Reason for rejection',
                  errorText: errorText,
                ),
                onChanged: (_) {
                  if (errorText != null) {
                    setSheetState(() => errorText = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        final reason = controller.text.trim();
                        ScaffoldMessenger.of(context).clearSnackBars();
                        if (reason.isEmpty) {
                          setSheetState(() {
                            errorText = 'Please provide a rejection reason';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please provide a rejection reason'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        if (looksLikeGibberish(reason)) {
                          setSheetState(() {
                            errorText =
                                'You cannot submit gibberish text. Please provide a clear rejection reason.';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'You cannot submit gibberish text. Please provide a clear rejection reason.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        setSheetState(() => isSubmitting = true);
                        final appState = context.read<AppState>();
                        appState.rejectComplaint(complaint, reason);
                        Navigator.pop(context);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Reject Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Complaint complaint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove complaint?'),
        content: Text(
          'This will permanently remove the complaint "${complaint.description.substring(0, complaint.description.length.clamp(0, 40))}..."',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AppState>().deleteComplaint(complaint);
      Navigator.pop(context);
    }
  }
}

class _ResolveSheet extends StatefulWidget {
  final Complaint complaint;

  const _ResolveSheet({required this.complaint});

  @override
  State<_ResolveSheet> createState() => _ResolveSheetState();
}

class _ResolveSheetState extends State<_ResolveSheet> {
  final _notesController = TextEditingController();
  List<MediaItem> _proof = [];
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mark as Resolved',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirm the issue has been fixed. Capture or attach photos and videos as proof that the reported problem is cleared.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resolution notes',
                hintText: 'e.g. Cleanup crew cleared the garbage pile',
              ),
            ),
            const SizedBox(height: 16),
            MediaPicker(
              label: 'Proof photos & videos',
              onChanged: (items) => _proof = items,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _resolve,
              child: _submitting
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text('Confirm Resolution'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolve() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add resolution notes')),
      );
      return;
    }
    if (looksLikeGibberish(notes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You cannot submit gibberish text. Please provide clear resolution notes.'),
        ),
      );
      return;
    }
    if (_proof.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'At least one proof photo or video is required to resolve the complaint'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    await context.read<AppState>().resolveComplaint(
          widget.complaint,
          notes: notes,
          proof: _proof,
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint marked as resolved')),
      );
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _NotesBox extends StatelessWidget {
  final String notes;
  final Color? color;

  const _NotesBox({required this.notes, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Text(
        notes,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _EvidenceGallery extends StatelessWidget {
  final Complaint complaint;

  const _EvidenceGallery({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (complaint.evidenceVideos.isNotEmpty) ...[
          _MediaTileRow(
            videos: complaint.evidenceVideos,
            label: 'Video evidence',
          ),
          const SizedBox(height: 12),
        ],
        for (final photo in complaint.evidencePhotos) ...[
          TapToZoomImage(path: photo),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ProofGallery extends StatelessWidget {
  final Complaint complaint;

  const _ProofGallery({required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (complaint.proofVideos.isNotEmpty) ...[
          _MediaTileRow(
            videos: complaint.proofVideos,
            label: 'Video proof',
          ),
          const SizedBox(height: 12),
        ],
        for (final photo in complaint.proofPhotos) ...[
          TapToZoomImage(path: photo),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MediaTileRow extends StatelessWidget {
  final List<String> videos;
  final String label;

  const _MediaTileRow({required this.videos, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _ComplaintVideoPlayer(
              path: videos[index],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComplaintVideoPlayer extends StatefulWidget {
  final String path;

  const _ComplaintVideoPlayer({required this.path});

  @override
  State<_ComplaintVideoPlayer> createState() => _ComplaintVideoPlayerState();
}

class _ComplaintVideoPlayerState extends State<_ComplaintVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _playing = false;
  int _retryCount = 0;
  static const _maxRetries = 3;

  @override
  void dispose() {
    _controller?.removeListener(_onStatus);
    _controller?.dispose();
    super.dispose();
  }

  void _onStatus() {
    if (!mounted) return;
    final c = _controller;
    if (c != null && c.value.isInitialized) {
      // When playback finishes, reset to start and show play button.
      if (c.value.position >= c.value.duration && c.value.duration > Duration.zero) {
        c.seekTo(Duration.zero);
        c.pause();
        if (mounted) setState(() => _playing = false);
        return;
      }
      // Handle error state
      if (c.value.hasError && !_hasError) {
        if (mounted) setState(() => _hasError = true);
      }
    }
    setState(() {});
  }

  Future<void> _init() async {
    if (_controller != null) return;
    String videoPath = widget.path;
    // Convert Cloudinary URLs to signed URLs for security
    if (videoPath.startsWith('https://res.cloudinary.com/')) {
      videoPath = FirebaseRepository.getSignedVideoUrl(videoPath) ?? videoPath;
    }
    final controller = videoPath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(videoPath))
        : VideoPlayerController.file(File(videoPath));
    _controller = controller;
    controller.addListener(_onStatus);
    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _initialized = true;
          _hasError = false;
          _retryCount = 0;
        });
      }
    } on TimeoutException {
      if (mounted) {
        _handleInitError('Video load timeout');
      }
    } catch (_) {
      if (mounted) {
        _handleInitError('Failed to load video');
      }
    }
  }

  Future<void> _handleInitError(String message) async {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      _controller?.dispose();
      _controller = null;
      // Exponential backoff: 2s, 4s, 8s
      await Future.delayed(Duration(seconds: 1 << _retryCount));
      if (mounted) {
        _init();
      }
    } else {
      setState(() {
        _initialized = true;
        _hasError = true;
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final position = controller?.value.position ?? Duration.zero;
    final duration = controller?.value.duration ?? Duration.zero;
    final progress = (duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    // Show error state if video failed to load
    if (_hasError) {
      return SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 260 * 9 / 16,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Failed to load video',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        if (mounted) {
                          setState(() {
                            _hasError = false;
                            _initialized = false;
                          });
                        }
                        await _init();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: const Text(
                'The video could not be loaded. Check your connection or try again.',
                style: TextStyle(color: Colors.white60, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
],
      ),
  );
    }

    return SizedBox(
      width: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: (controller != null && controller.value.isInitialized)
                  ? controller.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black),
                  if (_initialized && controller != null)
                    VideoPlayer(controller)
                  else
                    const Center(
                      child: Icon(Icons.videocam, color: Colors.white54, size: 40),
                    ),
                  if (_initialized && controller != null && !_playing)
                    Center(
                      child: IconButton(
                        onPressed: () async {
                          await controller.play();
                          if (mounted) setState(() => _playing = true);
                        },
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Seek bar + time + play/pause
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  iconSize: 24,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () async {
                    if (!_initialized) await _init();
                    if (_playing) {
                      await controller?.pause();
                      if (mounted) setState(() => _playing = false);
                    } else {
                      // Replay from start if at end
                      if (controller != null &&
                          controller.value.position >= controller.value.duration) {
                        await controller.seekTo(Duration.zero);
                      }
                      await controller?.play();
                      if (mounted) setState(() => _playing = true);
                    }
                  },
                  icon: Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (v) {
                        if (controller != null && controller.value.isInitialized) {
                          final pos = Duration(
                            milliseconds: (v * duration.inMilliseconds).round(),
                          );
                          controller.seekTo(pos);
                        }
                      },
                    ),
                  ),
                ),
                Text(
                  '${_formatDuration(position)} / ${_formatDuration(duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
