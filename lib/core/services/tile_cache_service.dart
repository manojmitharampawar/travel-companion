import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lightweight offline tile cache for flutter_map.
///
/// - Downloads tiles on first access and serves from disk afterwards
/// - Pre-downloads tiles for a journey route corridor at zoom levels 10-16
/// - Reports cache size and allows clearing
class TileCacheService {
  TileCacheService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    responseType: ResponseType.bytes,
    headers: {
      'User-Agent': 'TravelCompanionApp/1.0 (contact@travelcompanion.app)',
    },
  ));

  static String? _cacheDir;

  /// Gets (or creates) the tile cache directory.
  static Future<String> get cacheDir async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationCacheDirectory();
    final dir = Directory(p.join(appDir.path, 'map_tiles'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir.path;
    return _cacheDir!;
  }

  /// Constructs the local file path for a tile.
  static Future<String> tilePath(int z, int x, int y) async {
    final dir = await cacheDir;
    return p.join(dir, '$z', '$x', '$y.png');
  }

  /// Gets a cached tile file, or null if not cached.
  static Future<File?> getCachedTile(int z, int x, int y) async {
    final path = await tilePath(z, x, y);
    final file = File(path);
    if (await file.exists()) return file;
    return null;
  }

  /// Downloads a single tile and saves to disk. Returns the file.
  static Future<File?> downloadTile(String urlTemplate, int z, int x, int y) async {
    try {
      final path = await tilePath(z, x, y);
      final file = File(path);

      // Already cached
      if (await file.exists()) return file;

      // Build URL from template
      final url = urlTemplate
          .replaceAll('{z}', z.toString())
          .replaceAll('{x}', x.toString())
          .replaceAll('{y}', y.toString());

      final resp = await _dio.get<List<int>>(url);
      if (resp.data != null && resp.data!.isNotEmpty) {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(resp.data!);
        return file;
      }
    } catch (e) {
      dev.log('TileCacheService: failed to download tile $z/$x/$y: $e',
          name: 'TileCache');
    }
    return null;
  }

  /// Pre-downloads all tiles along a route corridor for offline use.
  ///
  /// [routePoints] - the polyline points of the route (from OSRM).
  /// [minZoom] / [maxZoom] - zoom range to cache (default 10-15).
  /// [corridorPadding] - extra tiles around the route to cache.
  /// [onProgress] - callback with (downloaded, total) counts.
  ///
  /// Returns the number of tiles downloaded.
  static Future<int> preDownloadRoute({
    required List<LatLng> routePoints,
    String urlTemplate =
        'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
    int minZoom = 10,
    int maxZoom = 15,
    int corridorPadding = 1,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    if (routePoints.isEmpty) return 0;

    // Collect all unique tile coordinates across zoom levels
    final tileSet = <String, _TileCoord>{};

    for (int z = minZoom; z <= maxZoom; z++) {
      for (final point in routePoints) {
        final tx = _lngToTileX(point.longitude, z);
        final ty = _latToTileY(point.latitude, z);

        // Add tile + padding around it
        for (int dx = -corridorPadding; dx <= corridorPadding; dx++) {
          for (int dy = -corridorPadding; dy <= corridorPadding; dy++) {
            final x = tx + dx;
            final y = ty + dy;
            final maxTile = (1 << z) - 1;
            if (x < 0 || y < 0 || x > maxTile || y > maxTile) continue;
            final key = '$z/$x/$y';
            tileSet[key] = _TileCoord(z, x, y);
          }
        }
      }
    }

    final tiles = tileSet.values.toList();
    int downloaded = 0;
    int skipped = 0;

    dev.log('TileCacheService: pre-downloading ${tiles.length} tiles for route',
        name: 'TileCache');

    // Download in batches of 6 concurrent requests
    const batchSize = 6;
    for (int i = 0; i < tiles.length; i += batchSize) {
      final batch = tiles.skip(i).take(batchSize);
      await Future.wait(batch.map((t) async {
        // Check if already cached
        final cached = await getCachedTile(t.z, t.x, t.y);
        if (cached != null) {
          skipped++;
        } else {
          await downloadTile(urlTemplate, t.z, t.x, t.y);
          downloaded++;
        }
      }));
      onProgress?.call(downloaded + skipped, tiles.length);
      // Yield to UI thread between batches
      await Future.delayed(Duration.zero);
    }

    dev.log(
      'TileCacheService: done. Downloaded: $downloaded, Already cached: $skipped',
      name: 'TileCache',
    );
    return downloaded;
  }

  /// Pre-downloads tiles for origin and destination points (city-level zoom).
  static Future<int> preDownloadPoints({
    required List<LatLng> points,
    String urlTemplate =
        'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
    int minZoom = 12,
    int maxZoom = 16,
    int padding = 2,
    void Function(int downloaded, int total)? onProgress,
  }) async {
    if (points.isEmpty) return 0;

    final tileSet = <String, _TileCoord>{};

    for (int z = minZoom; z <= maxZoom; z++) {
      for (final point in points) {
        final tx = _lngToTileX(point.longitude, z);
        final ty = _latToTileY(point.latitude, z);

        for (int dx = -padding; dx <= padding; dx++) {
          for (int dy = -padding; dy <= padding; dy++) {
            final x = tx + dx;
            final y = ty + dy;
            final maxTile = (1 << z) - 1;
            if (x < 0 || y < 0 || x > maxTile || y > maxTile) continue;
            tileSet['$z/$x/$y'] = _TileCoord(z, x, y);
          }
        }
      }
    }

    final tiles = tileSet.values.toList();
    int done = 0;

    const batchSize = 6;
    for (int i = 0; i < tiles.length; i += batchSize) {
      final batch = tiles.skip(i).take(batchSize);
      await Future.wait(batch.map((t) async {
        final cached = await getCachedTile(t.z, t.x, t.y);
        if (cached == null) {
          await downloadTile(urlTemplate, t.z, t.x, t.y);
        }
        done++;
      }));
      onProgress?.call(done, tiles.length);
      // Yield to UI thread between batches
      await Future.delayed(Duration.zero);
    }

    return done;
  }

  /// Returns total cache size in bytes.
  static Future<int> getCacheSize() async {
    final dir = Directory(await cacheDir);
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Returns human-readable cache size string.
  static Future<String> getCacheSizeText() async {
    final bytes = await getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Clears all cached tiles.
  static Future<void> clearCache() async {
    final dir = Directory(await cacheDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
    dev.log('TileCacheService: cache cleared', name: 'TileCache');
  }

  // ── Tile math helpers ─────────────────────

  static int _lngToTileX(double lng, int zoom) {
    return ((lng + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  static int _latToTileY(double lat, int zoom) {
    final latRad = lat * pi / 180.0;
    return ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0 * (1 << zoom))
        .floor();
  }
}

class _TileCoord {
  final int z, x, y;
  const _TileCoord(this.z, this.x, this.y);
}

/// Custom [TileProvider] that serves tiles from disk cache, falling back to network.
class CachedTileProvider extends TileProvider {
  final String urlTemplate;

  CachedTileProvider({
    required this.urlTemplate,
    super.headers,
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedTileImageProvider(
      z: coordinates.z.toInt(),
      x: coordinates.x.toInt(),
      y: coordinates.y.toInt(),
      urlTemplate: urlTemplate,
    );
  }
}

/// ImageProvider that checks disk cache first, then downloads.
class CachedTileImageProvider extends ImageProvider<CachedTileImageProvider> {
  final int z, x, y;
  final String urlTemplate;

  const CachedTileImageProvider({
    required this.z,
    required this.x,
    required this.y,
    required this.urlTemplate,
  });

  @override
  ImageStreamCompleter loadImage(
    CachedTileImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadTile(decode),
      scale: 1.0,
    );
  }

  // Minimal valid 1x1 transparent PNG (67 bytes)
  static const _kTransparentPng = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
    0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
    0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  Future<ui.Codec> _loadTile(ImageDecoderCallback decode) async {
    try {
      // Try disk cache first
      final cached = await TileCacheService.getCachedTile(z, x, y);
      if (cached != null) {
        final bytes = await cached.readAsBytes();
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      }

      // Download and cache
      final file = await TileCacheService.downloadTile(urlTemplate, z, x, y);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      }

      // Fallback: try network directly (no caching)
      final url = urlTemplate
          .replaceAll('{z}', z.toString())
          .replaceAll('{x}', x.toString())
          .replaceAll('{y}', y.toString());
      final resp = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        Uint8List.fromList(resp.data!),
      );
      return decode(buffer);
    } catch (e) {
      dev.log('CachedTileImageProvider: failed to load tile $z/$x/$y: $e',
          name: 'TileCache');
      // Return a transparent 1x1 pixel PNG to avoid crashing the widget tree
      final bytes = Uint8List.fromList(_kTransparentPng);
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    }
  }

  @override
  Future<CachedTileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedTileImageProvider &&
        other.z == z &&
        other.x == x &&
        other.y == y &&
        other.urlTemplate == urlTemplate;
  }

  @override
  int get hashCode => Object.hash(z, x, y, urlTemplate);
}
