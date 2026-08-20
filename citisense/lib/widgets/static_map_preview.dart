import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';

class StaticMapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;

  const StaticMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.citisense',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(latitude, longitude),
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
      ),
    );
  }
}
