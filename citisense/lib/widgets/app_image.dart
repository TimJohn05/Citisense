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

  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _placeholder();
    }
    if (path!.startsWith('data:image/')) {
      final payload = path!.substring(path!.indexOf(',') + 1);
      return Image.memory(
        base64Decode(payload),
        fit: fit,
        height: height,
        width: width,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    final isNetwork = path!.startsWith('http');
    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: path!,
        fit: fit,
        height: height,
        width: width,
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _placeholder(),
      );
    }
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
