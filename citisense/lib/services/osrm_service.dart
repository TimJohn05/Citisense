import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OSRMStep {
  final String maneuverType;
  final String? modifier;
  final String name;
  final double distance;

  const OSRMStep({
    required this.maneuverType,
    this.modifier,
    required this.name,
    required this.distance,
  });

  String get instruction => OSRMService.instructionFor(this, maneuverType == 'arrive');
}

class OSRMRoute {
  final List<LatLng> geometry;
  final double distanceMeters;
  final double durationSeconds;
  final List<OSRMStep> steps;

  const OSRMRoute({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });
}

class OSRMService {
  static const _endpoint = 'https://router.project-osrm.org/route/v1/driving';

  // Offline cache: last successfully fetched route keyed by "from,to" coordinates.
  OSRMRoute? _cachedRoute;
  String? _cachedRouteKey;
  bool _lastResultWasCached = false;

  /// Whether the most recent fetchRoute result came from the offline cache.
  bool get lastResultWasCached => _lastResultWasCached;

  String _routeKey(LatLng from, LatLng to) =>
      '${from.latitude},${from.longitude}|${to.latitude},${to.longitude}';

  /// Fetches a route from OSRM. When the request fails (offline), returns the
  /// last successfully cached route for the same origin/destination pair, if any.
  Future<OSRMRoute?> fetchRoute(LatLng from, LatLng to) async {
    final key = _routeKey(from, to);
    final uri = Uri.parse(
      '$_endpoint/${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson&steps=true',
    );
    final client = http.Client();
    try {
      final response = await client.get(uri).timeout(
            const Duration(seconds: 15),
          );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final route = _parseRoute(data);
          _cachedRoute = route;
          _cachedRouteKey = key;
          _lastResultWasCached = false;
          return route;
        }
      }
    } catch (_) {
      // fall through to cache fallback
    } finally {
      client.close();
    }

    // Offline fallback: return cached route if it matches this origin/destination.
    if (_cachedRoute != null && _cachedRouteKey == key) {
      _lastResultWasCached = true;
      return _cachedRoute;
    }
    _lastResultWasCached = false;
    return null;
  }

  OSRMRoute _parseRoute(Map<String, dynamic> data) {
    final route = (data['routes'] as List).first;
    final coords = (route['geometry']['coordinates'] as List)
        .map((c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ))
        .toList();
    final steps = <OSRMStep>[];
    for (final leg in route['legs'] as List) {
      for (final s in leg['steps'] as List) {
        final maneuver = s['maneuver'] as Map<String, dynamic>? ?? const {};
        final rawName = (s['name'] ?? '') as String;
        final ref = (s['ref'] ?? '') as String;
        steps.add(
          OSRMStep(
            maneuverType: (maneuver['type'] ?? 'continue') as String,
            modifier: maneuver['modifier'] as String?,
            name: rawName.isNotEmpty ? rawName : ref,
            distance: ((s['distance'] as num?) ?? 0).toDouble(),
          ),
        );
      }
    }
    return OSRMRoute(
      geometry: coords,
      distanceMeters: ((route['distance'] as num?) ?? 0).toDouble(),
      durationSeconds: ((route['duration'] as num?) ?? 0).toDouble(),
      steps: steps,
    );
  }

  static String instructionFor(OSRMStep step, bool isArrive) {
    if (isArrive) return 'Arrive at the destination';
    final name = step.name;
    final mod = step.modifier ?? '';
    switch (step.maneuverType) {
      case 'depart':
        return 'Start following the route toward the destination';
      case 'turn':
        return _withName('Turn $mod', name);
      case 'continue':
        return _withName('Continue', name);
      case 'new name':
        return _withName('Continue onto', name);
      case 'merge':
        return _withName('Merge $mod onto', name);
      case 'on ramp':
        return _withName('Take the ramp onto', name);
      case 'off ramp':
        return _withName('Exit onto', name);
      case 'fork':
        return _withName('Keep $mod at the fork onto', name);
      case 'end of road':
        return _withName('Turn $mod at the end of the road onto', name);
      case 'roundabout':
        return _withName('At the roundabout turn $mod onto', name);
      case 'rotary':
        return _withName('At the rotary turn $mod onto', name);
      case 'roundabout turn':
        return _withName('Turn $mod at the roundabout onto', name);
      case 'uturn':
        return 'Make a U-turn${name.isEmpty ? '' : ' onto $name'}';
      case 'arrive':
        return 'Arrive at the destination';
      default:
        return name.isEmpty ? 'Continue along the route' : 'Follow $name';
    }
  }

  static String _withName(String prefix, String name) {
    if (name.isEmpty) return prefix;
    return '$prefix $name';
  }
}