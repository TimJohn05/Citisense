import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class CompassMath {
  static const double _degToRad = math.pi / 180.0;
  static const double _radToDeg = 180.0 / math.pi;

  static double bearing(LatLng from, LatLng to) {
    final phi1 = from.latitude * _degToRad;
    final phi2 = to.latitude * _degToRad;
    final dLambda = (to.longitude - from.longitude) * _degToRad;
    final x = math.sin(dLambda) * math.cos(phi2);
    final y = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);
    return (math.atan2(x, y) * _radToDeg + 360) % 360;
  }

  static double distanceMeters(LatLng a, LatLng b) {
    const R = 6371000.0;
    final phi1 = a.latitude * _degToRad;
    final phi2 = b.latitude * _degToRad;
    final dPhi = (b.latitude - a.latitude) * _degToRad;
    final dLambda = (b.longitude - a.longitude) * _degToRad;
    final h = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    return 2 * R * math.asin(math.sqrt(h));
  }

  static double normalizedDiff(double a, double b) {
    return (a - b + 540) % 360 - 180;
  }

  static String cardinal(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return dirs[(deg % 360 / 45).round()];
  }
}