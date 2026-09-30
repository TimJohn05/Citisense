import 'package:flutter_test/flutter_test.dart';

import 'package:citisense/services/camera_service.dart';
import 'package:video_compress/video_compress.dart';

void main() {
  group('CameraService media compression', () {
    test('1080p landscape video is compressed even when small', () {
      final info = MediaInfo(path: 'a.mp4', width: 1920, height: 1080);
      expect(CameraService.needsCompression(info, 1024 * 1024), isTrue);
    });

    test('portrait phone video above 720p is compressed', () {
      final info = MediaInfo(path: 'a.mp4', width: 1080, height: 1920);
      expect(CameraService.needsCompression(info, 5 * 1024 * 1024), isTrue);
    });

    test('720p video is kept when within the size limit', () {
      final info = MediaInfo(path: 'a.mp4', width: 1280, height: 720);
      expect(CameraService.needsCompression(info, 10 * 1024 * 1024), isFalse);
    });

    test('sub-720p video is kept when within the size limit', () {
      final info = MediaInfo(path: 'a.mp4', width: 640, height: 480);
      expect(CameraService.needsCompression(info, 10 * 1024 * 1024), isFalse);
    });

    test('oversized video is compressed even at 720p', () {
      final info = MediaInfo(path: 'a.mp4', width: 1280, height: 720);
      expect(CameraService.needsCompression(info, 60 * 1024 * 1024), isTrue);
    });

    test('video with unknown dimensions is compressed to be safe', () {
      final info = MediaInfo(path: 'a.mp4');
      expect(CameraService.needsCompression(info, 1024 * 1024), isTrue);
    });
  });
}