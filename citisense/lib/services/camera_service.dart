import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_compress/video_compress.dart';

class VideoTooLongException implements Exception {}

class VideoTooLargeException implements Exception {}

class CameraService {
  final ImagePicker _picker = ImagePicker();

  static const int maxVideoSizeBytes = 50 * 1024 * 1024;
  static const double maxVideoDimensionPx = 1280;
  static const Duration maxVideoDuration = Duration(minutes: 2);

  /// permission_handler has no desktop implementation; on preview-only
  /// desktop targets the permission request throws MissingPluginException,
  /// so treat the camera as acceptable without asking (gallery is not
  /// permission-gated anyway).
  Future<bool> _hasCameraAccess() async {
    try {
      return await Permission.camera.request().isGranted;
    } on MissingPluginException {
      return true;
    }
  }

  Future<File?> capturePhoto() async {
    if (!await _hasCameraAccess()) {
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
        maxWidth: maxVideoDimensionPx,
        maxHeight: maxVideoDimensionPx,
        imageQuality: 85,
      );
      if (file == null) return null;
      return File(file.path);
    } catch (_) {
      if (kIsWeb) return null;
      rethrow;
    }
  }

  Future<File?> captureVideo() async {
    if (!await _hasCameraAccess()) {
      return null;
    }
    return _pickVideo(ImageSource.camera);
  }

  Future<File?> pickVideoFromGallery() async {
    return _pickVideo(ImageSource.gallery);
  }

  Future<File?> _pickVideo(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: source,
        maxDuration: maxVideoDuration,
      );
      if (file == null) return null;
      return File(file.path);
    } catch (_) {
      if (kIsWeb) return null;
      rethrow;
    }
  }

  Future<MediaInfo?> probeVideo(File file) async {
    try {
      final info = await VideoCompress.getMediaInfo(file.path);
      return info;
    } catch (_) {
      return null;
    }
  }

  Future<File> ensureVideoWithinLimits(File file) async {
    final info = await probeVideo(file);
    if (info == null) return file;

    final durOver = info.duration != null &&
        info.duration! > maxVideoDuration.inMilliseconds;
    if (durOver) throw VideoTooLongException();

    final processed = needsCompression(info, file.lengthSync())
        ? await _compress(file)
        : file;
    if (processed.lengthSync() > maxVideoSizeBytes) {
      throw VideoTooLargeException();
    }
    return processed;
  }

  static bool needsCompression(MediaInfo info, int fileSizeBytes) {
    final atOrBelow720p = info.width != null &&
        info.height != null &&
        info.width! <= maxVideoDimensionPx &&
        info.height! <= maxVideoDimensionPx;
    return !atOrBelow720p || fileSizeBytes > maxVideoSizeBytes;
  }

  Future<File> _compress(File file) async {
    try {
      final result = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      if (result == null || result.path == null) return file;
      final out = File(result.path!);
      if (out.existsSync()) return out;
    } catch (_) {
      // Compression unavailable — keep original.
    }
    return file;
  }
}