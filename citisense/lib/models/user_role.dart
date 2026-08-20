import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum UserRole { citizen, officer, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.officer:
        return 'Barangay Official';
      case UserRole.admin:
        return 'System Admin';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen';
      case UserRole.officer:
        return 'Official';
      case UserRole.admin:
        return 'Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.citizen:
        return Icons.person_outline;
      case UserRole.officer:
        return Icons.shield_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  Color get color {
    switch (this) {
      case UserRole.citizen:
        return AppColors.primary;
      case UserRole.officer:
        return AppColors.officer;
      case UserRole.admin:
        return AppColors.admin;
    }
  }

  Color get containerColor {
    switch (this) {
      case UserRole.citizen:
        return AppColors.primaryContainer;
      case UserRole.officer:
        return const Color(0xFFD5F0EE);
      case UserRole.admin:
        return const Color(0xFFEBDCFC);
    }
  }
}
