import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> capturePhoto() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return null;
    }
    return _pick(ImageSource.camera);
  }

  Future<File?> pickFromGallery() async {
    return _pick(ImageSource.gallery);
  }

  Future<File?> _pick(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 85,
      );
      if (file == null) return null;
      return File(file.path);
    } catch (_) {
      if (kIsWeb) return null;
      rethrow;
    }
  }
}
