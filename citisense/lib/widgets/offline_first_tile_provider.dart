import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

/// Shared provider instance so [TileLayer] instances stay stable across
/// rebuilds (avoids tile-layer churn on setState).
final OfflineFirstTileProvider offlineFirstTileProvider =
    OfflineFirstTileProvider();

class OfflineFirstTileProvider extends TileProvider {
  OfflineFirstTileProvider({
    super.headers,
    this.assetsBasePath = 'assets/tiles',
  });

  final String assetsBasePath;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final networkUrl = getTileUrl(coordinates, options);
    return _OfflineOrNetworkImage(
      assetPath: '$assetsBasePath/${coordinates.z}_${coordinates.x}_${coordinates.y}.png',
      networkUrl: networkUrl,
      headers: headers,
    );
  }
}

class _OfflineOrNetworkImage
    extends ImageProvider<_OfflineOrNetworkImage> {
  _OfflineOrNetworkImage({
    required this.assetPath,
    required this.networkUrl,
    required this.headers,
  });

  final String assetPath;
  final String networkUrl;
  final Map<String, String> headers;

  @override
  Future<_OfflineOrNetworkImage> obtainKey(ImageConfiguration config) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
    _OfflineOrNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(decode),
      scale: 1.0,
      debugLabel: assetPath,
    );
  }

  Future<ui.Codec> _loadCodec(ImageDecoderCallback decode) async {
    Uint8List bytes;
    final asset = await _tryLoadAsset();
    if (asset != null) {
      bytes = asset;
    } else {
      bytes = await _fetchNetwork();
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  Future<Uint8List?> _tryLoadAsset() async {
    try {
      final data = await rootBundle.load(assetPath);
      if (data.lengthInBytes == 0) return null;
      return data.buffer.asUint8List();
    } on Exception {
      return null;
    }
  }

  Future<Uint8List> _fetchNetwork() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(networkUrl));
      headers.forEach(request.headers.set);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Tile fetch failed: ${response.statusCode} for $networkUrl',
        );
      }
      final completer = Completer<Uint8List>();
      final bytes = <int>[];
      response.listen(
        bytes.addAll,
        onDone: () => completer.complete(Uint8List.fromList(bytes)),
        onError: completer.completeError,
      );
      return await completer.future;
    } finally {
      client.close(force: true);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _OfflineOrNetworkImage &&
      other.assetPath == assetPath &&
      other.networkUrl == networkUrl;

  @override
  int get hashCode => Object.hash(assetPath, networkUrl);
}