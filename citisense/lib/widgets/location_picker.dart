import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../services/location_service.dart';
import '../widgets/offline_first_tile_provider.dart';

class LocationPicker extends StatefulWidget {
  final LatLng? initialPosition;
  final ValueChanged<LatLng> onChanged;

  const LocationPicker({
    super.key,
    this.initialPosition,
    required this.onChanged,
  });

  static const LatLng defaultPosition = LatLng(14.1956, 121.1469);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  late LatLng _selected;
  bool _locating = false;

  static const double _zoom = 15.5;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialPosition ?? LocationPicker.defaultPosition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onChanged(_selected);
    });
  }

  void _updateSelection(LatLng position) {
    setState(() => _selected = position);
    widget.onChanged(position);
  }

  void _placePinAtMapCenter() {
    _updateSelection(_mapController.camera.center);
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final permission = await _locationService.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is permanently denied. '
              'Enable it in device settings.',
            ),
          ),
        );
      }
      if (mounted) setState(() => _locating = false);
      return;
    }
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      _mapController.move(position, _zoom);
      _updateSelection(position);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location unavailable. Check permission and try again.'),
        ),
      );
    }
    if (mounted) setState(() => _locating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selected,
                    initialZoom: _zoom,
                    minZoom: 12.0,
                    maxZoom: 18.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.citisense',
                      tileProvider: offlineFirstTileProvider,
                      maxNativeZoom: 16,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selected,
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_pin,
                            size: 40,
                            color: AppColors.markerColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Center(
                  child: IgnorePointer(
                    child: _CrosshairIndicator(color: AppColors.primary),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'place-pin',
                        backgroundColor: AppColors.surface,
                        tooltip: 'Place pin at map center',
                        onPressed: _placePinAtMapCenter,
                        child: Icon(
                          Icons.push_pin_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'my-location',
                        backgroundColor: AppColors.surface,
                        onPressed: _locating ? null : _useMyLocation,
                        child: _locating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.my_location, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${_selected.latitude.toStringAsFixed(6)}, '
                '${_selected.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Center the crosshair on the spot, then tap the pin button to place '
          'the marker. Use the crosshair for your precise GPS location.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CrosshairIndicator extends StatelessWidget {
  final Color color;

  const _CrosshairIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85),
              border: Border.all(color: color, width: 2),
            ),
          ),
          Align(
            alignment: const Alignment(0, -1),
            child: Container(width: 2, height: 9, color: color),
          ),
          Align(
            alignment: const Alignment(0, 1),
            child: Container(width: 2, height: 9, color: color),
          ),
          Align(
            alignment: const Alignment(-1, 0),
            child: Container(width: 9, height: 2, color: color),
          ),
          Align(
            alignment: const Alignment(1, 0),
            child: Container(width: 9, height: 2, color: color),
          ),
        ],
      ),
    );
  }
}
