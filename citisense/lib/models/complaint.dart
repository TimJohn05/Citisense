import '../core/location_data.dart';
import 'enums.dart';

class Complaint {
  final String id;
  final String citizenId;
  final String citizenName;
  final ComplaintCategory category;
  final String description;
  final Sentiment sentiment;
  final String recommendation;
  final ComplaintStatus status;
  final String? officerNotes;
  final String? rejectReason;
  final double? latitude;
  final double? longitude;
  final String? barangay;
  final List<String> evidencePhotos;
  final List<String> evidenceVideos;
  final List<String> proofPhotos;
  final List<String> proofVideos;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const Complaint({
    required this.id,
    required this.citizenId,
    required this.citizenName,
    required this.category,
    required this.description,
    required this.sentiment,
    required this.recommendation,
    required this.status,
    this.officerNotes,
    this.rejectReason,
    this.latitude,
    this.longitude,
    this.barangay,
    this.evidencePhotos = const [],
    this.evidenceVideos = const [],
    this.proofPhotos = const [],
    this.proofVideos = const [],
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String get locationName {
    if (barangay != null && barangay!.trim().isNotEmpty) return barangay!.trim();
    final desc = description.toLowerCase();
    if (desc.contains('pansol')) return 'Pansol';
    if (desc.contains('halang')) return 'Halang';
    if (desc.contains('real')) return 'Real';
    if (desc.contains('canlubang')) return 'Canlubang';
    if (desc.contains('parian') || desc.contains('crossing')) return 'Parian';
    if (desc.contains('mabini') || desc.contains('block 5') || desc.contains('poblacion')) {
      return 'Barangay 1';
    }
    if (latitude != null && longitude != null) {
      if (latitude! > 14.208) return 'Real';
      if (latitude! > 14.203) return 'Parian';
      if (latitude! > 14.197) return 'Canlubang';
      if (latitude! > 14.193) return 'Barangay 1';
      if (latitude! > 14.188) return 'Halang';
      return 'Pansol';
    }
    return 'Calamba City';
  }

  bool matchesLocation(String? filterLocation) {
    if (filterLocation == null ||
        filterLocation.isEmpty ||
        filterLocation == 'All locations' ||
        filterLocation == 'All cities' ||
        filterLocation == 'All Cities') {
      return true;
    }
    final target = filterLocation.toLowerCase();

    // If filtering by city:
    final cityBarangays = LocationData.citiesAndBarangays[filterLocation];
    if (cityBarangays != null) {
      final loc = locationName.toLowerCase();
      if (loc.contains(target) ||
          target.contains(loc) ||
          description.toLowerCase().contains(target)) {
        return true;
      }
      for (final b in cityBarangays) {
        final bLower = b.toLowerCase();
        if (loc.contains(bLower) ||
            (barangay != null && barangay!.toLowerCase().contains(bLower)) ||
            description.toLowerCase().contains(bLower)) {
          return true;
        }
      }
      return false;
    }

    final loc = locationName.toLowerCase();
    return loc.contains(target) ||
        target.contains(loc) ||
        description.toLowerCase().contains(target);
  }

  bool get isOpen =>
      status == ComplaintStatus.pending || status == ComplaintStatus.inReview;

  static const Set<ComplaintCategory> highRiskCategories = {
    ComplaintCategory.electricalHazard,
    ComplaintCategory.peaceOrder,
    ComplaintCategory.floodDrainage,
    ComplaintCategory.healthSanitation,
  };

  static const Duration attentionThreshold = Duration(days: 3);

  bool get needsAttention =>
      isOpen &&
      (highRiskCategories.contains(category) ||
          DateTime.now().difference(createdAt) > attentionThreshold);

  String? get evidenceImage =>
      evidencePhotos.isEmpty ? null : evidencePhotos.first;

  String? get proofImage => proofPhotos.isEmpty ? null : proofPhotos.first;

  Complaint copyWith({
    String? id,
    String? citizenId,
    String? citizenName,
    ComplaintCategory? category,
    String? description,
    Sentiment? sentiment,
    String? recommendation,
    ComplaintStatus? status,
    String? officerNotes,
    String? rejectReason,
    double? latitude,
    double? longitude,
    String? barangay,
    List<String>? evidencePhotos,
    List<String>? evidenceVideos,
    List<String>? proofPhotos,
    List<String>? proofVideos,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      citizenId: citizenId ?? this.citizenId,
      citizenName: citizenName ?? this.citizenName,
      category: category ?? this.category,
      description: description ?? this.description,
      sentiment: sentiment ?? this.sentiment,
      recommendation: recommendation ?? this.recommendation,
      status: status ?? this.status,
      officerNotes: officerNotes ?? this.officerNotes,
      rejectReason: rejectReason ?? this.rejectReason,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      barangay: barangay ?? this.barangay,
      evidencePhotos: evidencePhotos ?? this.evidencePhotos,
      evidenceVideos: evidenceVideos ?? this.evidenceVideos,
      proofPhotos: proofPhotos ?? this.proofPhotos,
      proofVideos: proofVideos ?? this.proofVideos,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'citizenId': citizenId,
      'citizenName': citizenName,
      'category': category.name,
      'description': description,
      'sentiment': sentiment.name,
      'recommendation': recommendation,
      'status': status.name,
      'officerNotes': officerNotes,
      'rejectReason': rejectReason,
      'latitude': latitude,
      'longitude': longitude,
      'barangay': barangay,
      'evidencePhotos': evidencePhotos,
      'evidenceVideos': evidenceVideos,
      'proofPhotos': proofPhotos,
      'proofVideos': proofVideos,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'] as String,
      citizenId: map['citizenId'] as String,
      citizenName: map['citizenName'] as String,
      category: ComplaintCategoryX.fromString(map['category'] as String),
      description: map['description'] as String,
      sentiment: SentimentX.fromString(map['sentiment'] as String),
      recommendation: map['recommendation'] as String,
      status: ComplaintStatusX.fromString(map['status'] as String),
      officerNotes: map['officerNotes'] as String?,
      rejectReason: map['rejectReason'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      barangay: map['barangay'] as String?,
      evidencePhotos: _stringList(map['evidencePhotos'])
          .ifEmpty(_legacySingle(map['evidenceImage'])),
      evidenceVideos: _stringList(map['evidenceVideos']),
      proofPhotos: _stringList(map['proofPhotos'])
          .ifEmpty(_legacySingle(map['proofImage'])),
      proofVideos: _stringList(map['proofVideos']),
      resolvedBy: map['resolvedBy'] as String?,
      resolvedAt: DateTime.tryParse(map['resolvedAt'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  static List<String> _legacySingle(dynamic value) {
    if (value is String && value.isNotEmpty) return [value];
    return const [];
  }
}

extension _ListIsEmpty on List<String> {
  List<String> ifEmpty(List<String> fallback) => isEmpty ? fallback : this;
}