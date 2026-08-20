import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/camera_service.dart';

class PhotoPicker extends StatefulWidget {
  final String label;
  final File? initialImage;
  final ValueChanged<File?> onChanged;

  const PhotoPicker({
    super.key,
    this.label = 'Attach a photo',
    this.initialImage,
    required this.onChanged,
  });

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  final CameraService _cameraService = CameraService();
  File? _image;

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _image!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  setState(() => _image = null);
                  widget.onChanged(null);
                },
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _showSourceSheet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Take a photo or choose from gallery',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                leading: Icon(Icons.photo_camera_outlined,
                    color: AppColors.primary),
                title: const Text('Take Photo'),
                subtitle: const Text('Opens the camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    File? file;
    if (source == 'camera') {
      file = await _cameraService.capturePhoto();
      if (file == null && mounted) {
        _showPermissionDenied();
        return;
      }
    } else {
      file = await _cameraService.pickFromGallery();
    }

    if (file != null && mounted) {
      setState(() => _image = file);
      widget.onChanged(file);
    }
  }

  void _showPermissionDenied() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera permission required'),
        content: const Text(
          'CitiSense needs camera access to capture evidence photos. '
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
}
