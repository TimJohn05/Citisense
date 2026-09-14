import 'dart:io';

class MediaItem {
  final File? file;
  final String? url;
  final bool isVideo;

  const MediaItem({this.file, this.url, required this.isVideo});

  String? get displayPath => url ?? file?.path;

  Map<String, dynamic> toJson() => {
        'url': url,
        'path': file?.path,
        'isVideo': isVideo,
      };
}