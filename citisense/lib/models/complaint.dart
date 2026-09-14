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
    this.evidencePhotos = const [],
    this.evidenceVideos = const [],
    this.proofPhotos = const [],
    this.proofVideos = const [],
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

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