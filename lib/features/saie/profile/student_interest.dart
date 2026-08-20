/// SAIE — StudentInterest
///
/// Represents a specific academic or career interest detected in a student.
/// Interests are evidence-backed and carry their own confidence trajectory.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';

// ─────────────────────────────────────────────────────────────────────────────
// InterestCategory
// ─────────────────────────────────────────────────────────────────────────────

/// The broad category an interest belongs to.
enum InterestCategory {
  academic,
  vocational,
  extracurricular,
  creative,
  social,
  technological,
  entrepreneurial,
  scientific,
  literary,
  physical,
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentInterest
// ─────────────────────────────────────────────────────────────────────────────

/// A single student interest, fully tracked and evidence-backed.
final class StudentInterest extends Equatable {
  /// Unique key for this interest (e.g., `"interest_programming"`).
  final String key;

  /// Human-readable label.
  final String label;

  /// Broad category this interest belongs to.
  final InterestCategory category;

  /// IDs of majors or careers this interest maps to.
  final List<String> relatedDomainIds;

  /// The underlying tracked dimension for scoring this interest.
  final CognitiveDimension dimension;

  /// UTC timestamp when this interest was first detected.
  final DateTime discoveredAt;

  const StudentInterest({
    required this.key,
    required this.label,
    required this.category,
    required this.dimension,
    required this.discoveredAt,
    this.relatedDomainIds = const [],
  });

  factory StudentInterest.initial({
    required String key,
    required String label,
    required InterestCategory category,
    List<String> relatedDomainIds = const [],
  }) => StudentInterest(
    key: key,
    label: label,
    category: category,
    dimension: CognitiveDimension.initial(key: key, label: label),
    discoveredAt: DateTime.now().toUtc(),
    relatedDomainIds: relatedDomainIds,
  );

  factory StudentInterest.fromJson(Map<String, dynamic> json) =>
      StudentInterest(
        key: json['key'] as String,
        label: json['label'] as String,
        category: InterestCategory.values.byName(json['category'] as String),
        dimension: CognitiveDimension.fromJson(
          json['dimension'] as Map<String, dynamic>,
        ),
        discoveredAt: DateTime.parse(json['discovered_at'] as String),
        relatedDomainIds: (json['related_domain_ids'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'category': category.name,
    'dimension': dimension.toJson(),
    'discovered_at': discoveredAt.toIso8601String(),
    if (relatedDomainIds.isNotEmpty) 'related_domain_ids': relatedDomainIds,
  };

  StudentInterest copyWith({
    String? key,
    String? label,
    InterestCategory? category,
    CognitiveDimension? dimension,
    DateTime? discoveredAt,
    List<String>? relatedDomainIds,
  }) => StudentInterest(
    key: key ?? this.key,
    label: label ?? this.label,
    category: category ?? this.category,
    dimension: dimension ?? this.dimension,
    discoveredAt: discoveredAt ?? this.discoveredAt,
    relatedDomainIds: relatedDomainIds ?? this.relatedDomainIds,
  );

  double get score => dimension.score;
  double get confidence => dimension.confidence;
  bool get isStrong => dimension.score >= 0.65 && dimension.confidence >= 0.5;

  @override
  List<Object?> get props => [key, category, dimension.score];

  @override
  String toString() =>
      'StudentInterest(key: $key, score: ${score.toStringAsFixed(2)})';
}
