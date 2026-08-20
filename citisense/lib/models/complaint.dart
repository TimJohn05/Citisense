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
  final String? evidenceImage;
  final String? proofImage;
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
    this.evidenceImage,
    this.proofImage,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

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
    String? evidenceImage,
    String? proofImage,
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
      evidenceImage: evidenceImage ?? this.evidenceImage,
      proofImage: proofImage ?? this.proofImage,
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
      'evidenceImage': evidenceImage,
      'proofImage': proofImage,
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
      evidenceImage: map['evidenceImage'] as String?,
      proofImage: map['proofImage'] as String?,
      resolvedBy: map['resolvedBy'] as String?,
      resolvedAt: DateTime.tryParse(map['resolvedAt'] as String? ?? ''),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
