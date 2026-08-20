import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class CsLogo extends StatelessWidget {
  final double size;

  const CsLogo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.location_city,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
