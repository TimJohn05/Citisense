import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:citisense/services/compass_math.dart';

void main() {
  group('CompassMath.bearing', () {
    test('due north target returns 0', () {
      final b = CompassMath.bearing(
        const LatLng(10, 121),
        const LatLng(10.01, 121),
      );
      expect(b, closeTo(0, 0.5));
    });

    test('due east target returns 90', () {
      final b = CompassMath.bearing(
        const LatLng(10, 121),
        const LatLng(10, 121.01),
      );
      expect(b, closeTo(90, 0.5));
    });

    test('due south target returns 180', () {
      final b = CompassMath.bearing(
        const LatLng(10, 121),
        const LatLng(9.99, 121),
      );
      expect(b, closeTo(180, 0.5));
    });

    test('due west target returns 270', () {
      final b = CompassMath.bearing(
        const LatLng(10, 121),
        const LatLng(10, 120.99),
      );
      expect(b, closeTo(270, 0.5));
    });
  });

  group('CompassMath.distanceMeters', () {
    test('zero distance', () {
      final d = CompassMath.distanceMeters(
        const LatLng(10, 121),
        const LatLng(10, 121),
      );
      expect(d, closeTo(0, 0.1));
    });

    test('one degree of latitude is ~111 km', () {
      final d = CompassMath.distanceMeters(
        const LatLng(10, 121),
        const LatLng(11, 121),
      );
      expect(d, closeTo(111195, 500));
    });
  });

  group('CompassMath.normalizedDiff', () {
    test('normal positive diff within range', () {
      expect(CompassMath.normalizedDiff(100, 80), closeTo(20, 1e-9));
    });

    test('wraps forward across north', () {
      expect(CompassMath.normalizedDiff(10, 350), closeTo(20, 1e-9));
    });

    test('wraps backward across north', () {
      expect(CompassMath.normalizedDiff(350, 10), closeTo(-20, 1e-9));
    });

    test('same heading is zero', () {
      expect(CompassMath.normalizedDiff(45, 45), closeTo(0, 1e-9));
    });
  });

  group('CompassMath.cardinal', () {
    test('maps bearings to cardinals', () {
      expect(CompassMath.cardinal(0), 'N');
      expect(CompassMath.cardinal(45), 'NE');
      expect(CompassMath.cardinal(90), 'E');
      expect(CompassMath.cardinal(200), 'S');
      expect(CompassMath.cardinal(292), 'W');
    });
  });
}