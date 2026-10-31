import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final double? height;
  final double? width;
  final Duration loadTimeout;

  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.loadTimeout = const Duration(seconds: 10),
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _placeholder();
    }
    if (path!.startsWith('data:image/')) {
      return _buildDataImage();
    }
    final isNetwork = path!.startsWith('http');
    if (isNetwork) {
      return _buildNetworkImage();
    }
    return _buildFileImage();
  }

  Widget _buildDataImage() {
    final payload = path!.substring(path!.indexOf(',') + 1);
    try {
      return Image.memory(
        base64Decode(payload),
        fit: fit,
        height: height,
        width: width,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: path!,
      fit: fit,
      height: height,
      width: width,
      maxWidthDiskCache: 800,
      memCacheWidth: 800,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      httpHeaders: const {'User-Agent': 'CitiSense/1.0'},
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _buildFileImage() {
    final file = File(path!);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        height: height,
        width: width,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: height ?? 140,
      width: width,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textMuted,
        size: 28,
      ),
    );
  }
}

class TapToZoomImage extends StatelessWidget {
  final String? path;

  const TapToZoomImage({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (path == null || path!.isEmpty) return;
        showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: AppImage(path: path, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AppImage(path: path, height: 180),
      ),
    );
  }
}
