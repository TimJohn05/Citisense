import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../services/compass_math.dart';
import '../../services/location_service.dart';
import '../../services/osrm_service.dart';
import '../../widgets/offline_first_tile_provider.dart';

class NavigationScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;

  const NavigationScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = 'Complaint location',
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const _routeColor = Color(0xFF1A73E8);
  static const _arrivalMeters = 40.0;
  static const _rerouteThresholdMeters = 40.0;

  final _mapController = MapController();
  final _osrm = OSRMService();

  LatLng? _position;
  LatLng? _routeOrigin;
  OSRMRoute? _route;
  bool _usingCachedRoute = false;
  double _heading = 0.0;
  bool _loading = true;
  bool _mapReady = false;
  bool _arrived = false;
  String? _error;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _rerouteTimer;

  LatLng get _dest => LatLng(widget.latitude, widget.longitude);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _compassSub?.cancel();
    _rerouteTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final service = LocationService();
    final pos = await service.getCurrentPosition();
    final permission = await service.checkPermission();
    if (!mounted) return;
    if (pos != null) _position = pos;
    if (pos != null && (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always)) {
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen(
        (p) {
          if (!mounted) return;
          final newPos = LatLng(p.latitude, p.longitude);
          double newHeading = _heading;
          if (p.heading > 0 && p.headingAccuracy > 0) {
            newHeading = p.heading;
          } else if (_position != null &&
              CompassMath.distanceMeters(_position!, newPos) > 1.5) {
            newHeading = CompassMath.bearing(_position!, newPos);
          }
          setState(() {
            _position = newPos;
            _heading = newHeading;
          });
          _maybeReroute();
        },
        onError: (_) {},
      );
    }

    // Start compass stream for device heading (works even when stationary)
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      if (event.heading != null && event.heading! > 0) {
        // Use compass heading when GPS heading is unavailable or inaccurate
        setState(() {
          _heading = event.heading!;
        });
      }
    });

    await _fetchRoute();
  }

  void _maybeReroute() {
    if (_arrived || _loading) return;
    final origin = _routeOrigin;
    final pos = _position;
    if (pos == null || origin == null) return;
    if (CompassMath.distanceMeters(origin, pos) < _rerouteThresholdMeters) {
      return;
    }
    _rerouteTimer?.cancel();
    _rerouteTimer = Timer(const Duration(milliseconds: 900), _fetchRoute);
  }

  double _calculateHeadingFromRoute(LatLng from, List<LatLng> geometry) {
    for (final pt in geometry) {
      if (CompassMath.distanceMeters(from, pt) > 8.0) {
        return CompassMath.bearing(from, pt);
      }
    }
    return geometry.length > 1
        ? CompassMath.bearing(geometry.first, geometry[1])
        : CompassMath.bearing(from, _dest);
  }

  Future<void> _fetchRoute() async {
    final from = _position;
    if (from == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Position unavailable.';
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final route = await _osrm.fetchRoute(from, _dest);
    if (!mounted) return;
    _usingCachedRoute = _osrm.lastResultWasCached;
    setState(() {
      _loading = false;
      if (route == null) {
        _error = 'Could not fetch a route. Check your connection and try again.';
        return;
      }
      _route = route;
      _routeOrigin = from;
      _arrived =
          CompassMath.distanceMeters(from, _dest) < _arrivalMeters;
      if (_heading == 0.0 && route.geometry.isNotEmpty) {
        _heading = _calculateHeadingFromRoute(from, route.geometry);
      }
    });
    _fitRoute();
  }

  void _fitRoute() {
    if (!_mapReady) return;
    final route = _route;
    final pos = _position;
    final points = <LatLng>[];
    if (route != null) points.addAll(route.geometry);
    points.add(_dest);
    if (pos != null) points.add(pos);
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(36, 90, 36, 260),
          maxZoom: 16,
        ),
      );
    } catch (_) {}
  }

  Future<void> _openInGoogleMaps() async {
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${widget.latitude},${widget.longitude}&travelmode=driving';
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Google Maps.'),
        ),
      );
    }
  }

  OSRMStep? get _nextStep {
    final route = _route;
    if (route == null || route.steps.isEmpty || _arrived) return null;
    for (final s in route.steps) {
      if (s.maneuverType == 'depart' || s.maneuverType == 'arrive') continue;
      if (s.distance > 1) return s;
    }
    return route.steps.last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route guidance'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _dest,
              initialZoom: 13,
              minZoom: 12.0,
              maxZoom: 18.5,
              onMapReady: () {
                _mapReady = true;
                _fitRoute();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.citisense',
                tileProvider: offlineFirstTileProvider,
                maxNativeZoom: 16,
              ),
              if (_route != null && _route!.geometry.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route!.geometry,
                      strokeWidth: 9,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                    Polyline(
                      points: _route!.geometry,
                      strokeWidth: 5,
                      color: _routeColor,
                    ),
                  ],
                ),
              if (_position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _position!,
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      child: _OfficerLocationMarker(heading: _heading),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _dest,
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.location_pin,
                      size: 44,
                      color: AppColors.markerColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel() {
    final route = _route;
    final pos = _position;
    final panelChildren = <Widget>[];

    panelChildren.add(
      Row(
        children: [
          if (_loading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Calculating route...',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ] else if (_error != null) ...[
            Icon(Icons.error_outline, size: 18, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_error!, style: const TextStyle(fontSize: 13)),
            ),
            TextButton(onPressed: _fetchRoute, child: const Text('Retry')),
          ] else if (_arrived) ...[
            Icon(Icons.flag_rounded, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$_arrivalIn, ${_formatDistance(_remainingMeters)} from the '
                'reported location.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
          ] else if (route != null) ...[
            Icon(Icons.directions_car_filled,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatEta(route.durationSeconds)} '
                    '(${_formatDistance(route.distanceMeters)})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_usingCachedRoute)
                    Text(
                      'Cached route (offline)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (!_loading && route != null && !_arrived)
            IconButton(
              onPressed: _openInGoogleMaps,
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open in Google Maps navigation',
              color: AppColors.primary,
            ),
        ],
      ),
    );

    if (route != null && pos != null && !_arrived && _error == null) {
      if (route.steps.isEmpty) {
        panelChildren.add(const SizedBox(height: 8));
        panelChildren.add(
          const Text(
            'You are close. Follow the blue path to the '
            'pinned location.',
            style: TextStyle(fontSize: 13),
          ),
        );
      } else {
        final next = _nextStep;
        if (next != null) {
          panelChildren.add(const SizedBox(height: 10));
          panelChildren.add(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(_maneuverIcon(next),
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      next.instruction,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatDistance(next.distance),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        const divider = SizedBox(height: 10);
        panelChildren.add(divider);
        panelChildren.add(
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 130),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: route.steps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final step = route.steps[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(_maneuverIcon(step),
                          size: 16, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.instruction,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDistance(step.distance),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      }
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: panelChildren,
          ),
        ),
      ),
    );
  }

  double get _remainingMeters {
    final pos = _position;
    if (pos == null) return 0;
    return CompassMath.distanceMeters(pos, _dest);
  }

  String get _arrivalIn => 'You have arrived';

  String _formatEta(double seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 1) return 'Less than a minute away';
    return '~$minutes min away';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  IconData _maneuverIcon(OSRMStep step) {
    final type = step.maneuverType;
    final mod = step.modifier;
    if (type == 'turn' || type == 'end of road') {
      if (mod != null && mod.contains('right')) return Icons.turn_right;
      if (mod != null && mod.contains('left')) return Icons.turn_left;
      return Icons.straight;
    }
    if (type == 'uturn') return Icons.u_turn_left;
    if (type == 'merge' || type == 'fork') return Icons.merge_type;
    if (type == 'roundabout' ||
        type == 'rotary' ||
        type == 'roundabout turn') {
      return Icons.rotate_right;
    }
    if (type == 'on ramp' || type == 'off ramp') return Icons.ramp_right;
    if (type == 'arrive') return Icons.flag_rounded;
    return Icons.arrow_forward;
  }
}

class _OfficerLocationMarker extends StatelessWidget {
  final double heading;

  const _OfficerLocationMarker({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: heading * math.pi / 180.0,
              child: CustomPaint(
                size: const Size(80, 80),
                painter: _DirectionConePainter(
                  color: AppColors.primary,
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionConePainter extends CustomPainter {
  final Color color;

  const _DirectionConePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 38.0;
    const sweepAngle = 55.0 * math.pi / 180.0;
    const startAngle = -math.pi / 2 - (sweepAngle / 2);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          color.withValues(alpha: 0.50),
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
        [0.0, 0.65, 1.0],
      )
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, startAngle, sweepAngle, false)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DirectionConePainter oldDelegate) =>
      oldDelegate.color != color;
}