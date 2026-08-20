import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum ComplaintCategory {
  waste,
  road,
  water,
  lighting,
  peaceOrder,
  trafficObstruction,
  floodDrainage,
  healthSanitation,
  electricalHazard,
  publicFacilities,
  generalInquiry,
}

extension ComplaintCategoryX on ComplaintCategory {
  String get label {
    switch (this) {
      case ComplaintCategory.waste:
        return 'Waste Management';
      case ComplaintCategory.road:
        return 'Road & Infrastructure';
      case ComplaintCategory.water:
        return 'Water & Sanitation';
      case ComplaintCategory.lighting:
        return 'Lighting';
      case ComplaintCategory.peaceOrder:
        return 'Peace & Order';
      case ComplaintCategory.trafficObstruction:
        return 'Traffic & Obstruction';
      case ComplaintCategory.floodDrainage:
        return 'Flood & Drainage';
      case ComplaintCategory.healthSanitation:
        return 'Health & Sanitation';
      case ComplaintCategory.electricalHazard:
        return 'Electrical Hazard';
      case ComplaintCategory.publicFacilities:
        return 'Public Facilities';
      case ComplaintCategory.generalInquiry:
        return 'General Inquiry';
    }
  }

  String get shortLabel {
    switch (this) {
      case ComplaintCategory.waste:
        return 'Waste';
      case ComplaintCategory.road:
        return 'Road';
      case ComplaintCategory.water:
        return 'Water';
      case ComplaintCategory.lighting:
        return 'Lighting';
      case ComplaintCategory.peaceOrder:
        return 'Peace';
      case ComplaintCategory.trafficObstruction:
        return 'Traffic';
      case ComplaintCategory.floodDrainage:
        return 'Flooding';
      case ComplaintCategory.healthSanitation:
        return 'Health';
      case ComplaintCategory.electricalHazard:
        return 'Electrical';
      case ComplaintCategory.publicFacilities:
        return 'Facilities';
      case ComplaintCategory.generalInquiry:
        return 'Inquiry';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintCategory.waste:
        return Icons.recycling_outlined;
      case ComplaintCategory.road:
        return Icons.route_outlined;
      case ComplaintCategory.water:
        return Icons.water_drop_outlined;
      case ComplaintCategory.lighting:
        return Icons.lightbulb_outline;
      case ComplaintCategory.peaceOrder:
        return Icons.gavel_outlined;
      case ComplaintCategory.trafficObstruction:
        return Icons.traffic_outlined;
      case ComplaintCategory.floodDrainage:
        return Icons.flood_outlined;
      case ComplaintCategory.healthSanitation:
        return Icons.health_and_safety_outlined;
      case ComplaintCategory.electricalHazard:
        return Icons.electrical_services_outlined;
      case ComplaintCategory.publicFacilities:
        return Icons.park_outlined;
      case ComplaintCategory.generalInquiry:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintCategory.waste:
        return const Color(0xFF7A5AF8);
      case ComplaintCategory.road:
        return const Color(0xFF0F62A8);
      case ComplaintCategory.water:
        return const Color(0xFF0E7490);
      case ComplaintCategory.lighting:
        return const Color(0xFFD97706);
      case ComplaintCategory.peaceOrder:
        return const Color(0xFF9B2C2C);
      case ComplaintCategory.trafficObstruction:
        return const Color(0xFFE05D44);
      case ComplaintCategory.floodDrainage:
        return const Color(0xFF2563EB);
      case ComplaintCategory.healthSanitation:
        return const Color(0xFF059669);
      case ComplaintCategory.electricalHazard:
        return const Color(0xFFCA8A04);
      case ComplaintCategory.publicFacilities:
        return const Color(0xFF6D28D9);
      case ComplaintCategory.generalInquiry:
        return AppColors.neutral;
    }
  }

  String get mlKey {
    switch (this) {
      case ComplaintCategory.waste:
        return 'waste';
      case ComplaintCategory.road:
        return 'road';
      case ComplaintCategory.water:
        return 'water';
      case ComplaintCategory.lighting:
        return 'lighting';
      case ComplaintCategory.peaceOrder:
        return 'peace_order';
      case ComplaintCategory.trafficObstruction:
        return 'traffic_obstruction';
      case ComplaintCategory.floodDrainage:
        return 'flood_drainage';
      case ComplaintCategory.healthSanitation:
        return 'health_sanitation';
      case ComplaintCategory.electricalHazard:
        return 'electrical_hazard';
      case ComplaintCategory.publicFacilities:
        return 'public_facilities';
      case ComplaintCategory.generalInquiry:
        return 'general_inquiry';
    }
  }

  static final Map<String, ComplaintCategory> _mlLookup = {
    for (final c in ComplaintCategory.values) c.mlKey: c,
  };

  static ComplaintCategory fromString(String value) {
    return ComplaintCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => _mlLookup[value] ?? ComplaintCategory.generalInquiry,
    );
  }
}

enum ComplaintStatus { pending, inReview, resolved, rejected }

extension ComplaintStatusX on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.pending:
        return 'Pending';
      case ComplaintStatus.inReview:
        return 'Under Review';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintStatus.pending:
        return Icons.schedule;
      case ComplaintStatus.inReview:
        return Icons.visibility_outlined;
      case ComplaintStatus.resolved:
        return Icons.check_circle_outline;
      case ComplaintStatus.rejected:
        return Icons.cancel_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.pending:
        return AppColors.warning;
      case ComplaintStatus.inReview:
        return AppColors.primary;
      case ComplaintStatus.resolved:
        return AppColors.success;
      case ComplaintStatus.rejected:
        return AppColors.danger;
    }
  }

  Color get containerColor {
    switch (this) {
      case ComplaintStatus.pending:
        return AppColors.warningContainer;
      case ComplaintStatus.inReview:
        return AppColors.primaryContainer;
      case ComplaintStatus.resolved:
        return AppColors.successContainer;
      case ComplaintStatus.rejected:
        return AppColors.dangerContainer;
    }
  }

  static ComplaintStatus fromString(String value) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComplaintStatus.pending,
    );
  }
}

enum Sentiment { positive, neutral, negative }

extension SentimentX on Sentiment {
  String get label {
    switch (this) {
      case Sentiment.positive:
        return 'Positive';
      case Sentiment.neutral:
        return 'Neutral';
      case Sentiment.negative:
        return 'Negative';
    }
  }

  IconData get icon {
    switch (this) {
      case Sentiment.positive:
        return Icons.sentiment_satisfied_alt;
      case Sentiment.neutral:
        return Icons.sentiment_neutral;
      case Sentiment.negative:
        return Icons.sentiment_dissatisfied;
    }
  }

  Color get color {
    switch (this) {
      case Sentiment.positive:
        return AppColors.success;
      case Sentiment.neutral:
        return AppColors.neutral;
      case Sentiment.negative:
        return AppColors.danger;
    }
  }

  static Sentiment fromString(String value) {
    return Sentiment.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Sentiment.neutral,
    );
  }
}
