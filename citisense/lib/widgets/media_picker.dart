import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/media_item.dart';
import '../services/camera_service.dart';

class MediaPicker extends StatefulWidget {
  final String label;
  final List<String> initialPhotoUrls;
  final List<String> initialVideoUrls;
  final ValueChanged<List<MediaItem>> onChanged;

  const MediaPicker({
    super.key,
    this.label = 'Add photos and videos',
    this.initialPhotoUrls = const [],
    this.initialVideoUrls = const [],
    required this.onChanged,
  });

  @override
  State<MediaPicker> createState() => _MediaPickerState();
}

class _MediaPickerState extends State<MediaPicker> {
  final CameraService _cameraService = CameraService();
  final List<MediaItem> _items = [];

  @override
  void initState() {
    super.initState();
    _items.addAll([
      for (final url in widget.initialPhotoUrls) MediaItem(url: url, isVideo: false),
      for (final url in widget.initialVideoUrls) MediaItem(url: url, isVideo: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _items.length; i++) _buildThumb(_items[i], i),
            _buildAddTile(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Photos and short video clips (max 2 min / 50 MB each). '
          'Media is compressed to 720p before upload.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildThumb(MediaItem item, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 92,
            height: 92,
            child: _preview(item),
          ),
        ),
        if (item.isVideo)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Video',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                setState(() => _items.removeAt(index));
                widget.onChanged(List.unmodifiable(_items));
              },
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _preview(MediaItem item) {
    final path = item.displayPath;
    if (item.isVideo) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline,
            color: Colors.white, size: 34),
      );
    }
    if (path != null && path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    if (path != null && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: AppColors.textMuted),
    );
  }

  Widget _buildAddTile() {
    return InkWell(
      onTap: _showSourceSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 26, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              'Add media',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSourceSheet() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: const Text('Take Photo'),
                subtitle: const Text('Opens the camera'),
                onTap: () => Navigator.pop(context, 'photoCamera'),
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose Photo from Gallery'),
                subtitle: const Text('Select existing photos'),
                onTap: () => Navigator.pop(context, 'photoGallery'),
              ),
              ListTile(
                leading:
                    Icon(Icons.videocam_outlined, color: AppColors.primary),
                title: const Text('Record Video'),
                subtitle: const Text('Capture up to 2 minutes'),
                onTap: () => Navigator.pop(context, 'videoCamera'),
              ),
              ListTile(
                leading:
                    Icon(Icons.video_library_outlined, color: AppColors.primary),
                title: const Text('Choose Video from Gallery'),
                subtitle: const Text('Select a clip up to 2 minutes'),
                onTap: () => Navigator.pop(context, 'videoGallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    if (source == 'photoCamera' || source == 'photoGallery') {
      final file = source == 'photoCamera'
          ? await _cameraService.capturePhoto()
          : await _cameraService.pickFromGallery();
      if (file == null) {
        if (source == 'photoCamera' && mounted) _showCameraDenied();
        return;
      }
      if (mounted) _add(MediaItem(file: file, isVideo: false));
      return;
    }

    File? file;
    if (source == 'videoCamera') {
      file = await _cameraService.captureVideo();
      if (file == null && mounted) {
        _showCameraDenied();
        return;
      }
    } else {
      file = await _cameraService.pickVideoFromGallery();
    }
    if (file == null || !mounted) return;

    _showCompressingDialog();
    try {
      final safe = await _cameraService.ensureVideoWithinLimits(file);
      if (mounted) _closeCompressingDialog();
      if (safe.path != file.path) await unsafeCleanup(file);
      if (mounted) {
        _add(MediaItem(file: safe, isVideo: true));
      }
    } on VideoTooLongException {
      if (mounted) _closeCompressingDialog();
      await unsafeCleanup(file);
      if (mounted) _showVideoTooLong();
    } on VideoTooLargeException {
      if (mounted) _closeCompressingDialog();
      await unsafeCleanup(file);
      if (mounted) _showVideoTooLarge();
    } catch (_) {
      if (mounted) _closeCompressingDialog();
      await unsafeCleanup(file);
      if (mounted) _showVideoTooLarge();
    }
  }

  void _showCompressingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _CompressingDialog(),
    );
  }

  void _closeCompressingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> unsafeCleanup(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  void _add(MediaItem item) {
    setState(() => _items.add(item));
    widget.onChanged(List.unmodifiable(_items));
  }

  void _showCameraDenied() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera permission required'),
        content: const Text(
          'CitiSense needs camera access to capture evidence photos and videos. '
          'Please enable camera permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVideoTooLong() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video too long'),
        content: const Text(
          'Videos must be at most 2 minutes long. '
          'Please choose a shorter clip or record a shorter video.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVideoTooLarge() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video exceeds size limit'),
        content: const Text(
          'Even after compression the video is larger than 50 MB. '
          'Please choose a shorter or lower-resolution recording.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _CompressingDialog extends StatelessWidget {
  const _CompressingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Compressing video…',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}