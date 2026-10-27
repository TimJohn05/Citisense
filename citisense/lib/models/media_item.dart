import 'dart:io';

class MediaItem {
  final File? file;
  final String? url;
  final bool isVideo;

  const MediaItem({this.file, this.url, required this.isVideo});

  String? get displayPath => url ?? file?.path;

  Map<String, dynamic> toMap() => {
        'url': url,
        'path': file?.path,
        'isVideo': isVideo,
      };

  static MediaItem fromMap(Map<String, dynamic> map) {
    return MediaItem(
      url: map['url'] as String?,
      file: map['path'] != null ? File(map['path'] as String) : null,
      isVideo: map['isVideo'] as bool? ?? false,
    );
  }
}