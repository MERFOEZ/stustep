/// SAIE — Recommendation Model
///
/// Represents a ranked academic recommendation produced by the SAIE engine.
/// Each recommendation carries evidence, confidence, and rationale.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/confidence.dart';
import 'package:stustep/features/saie/models/evidence.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationType
// ─────────────────────────────────────────────────────────────────────────────

/// The domain type of this recommendation.
enum RecommendationType {
  /// Recommending a specific academic major.
  major,

  /// Recommending a professional career path.
  career,

  /// Recommending a skill to develop.
  skill,
}

// ─────────────────────────────────────────────────────────────────────────────
// Recommendation
// ─────────────────────────────────────────────────────────────────────────────

/// A ranked recommendation produced by the SAIE reasoning engine.
///
/// A [Recommendation] is always:
/// - Backed by a non-empty list of [evidence] signals.
/// - Assigned a [confidence] value computed from those signals.
/// - Given a rank among all recommendations for the same session.
final class Recommendation extends Equatable {
  /// Unique identifier for this recommendation instance.
  final String id;

  /// ID of the recommended domain entity (major/career/skill ID).
  final String domainId;

  /// Display name of the recommended entity.
  final String domainName;

  /// The type of this recommendation.
  final RecommendationType type;

  /// Computed confidence for this recommendation.
  final Confidence confidence;

  /// Evidence signals that support this recommendation.
  final List<Evidence> evidence;

  /// Human-readable rationale explaining why this was recommended.
  final String rationale;

  /// Short summary suitable for display in a UI card.
  final String summary;

  /// Rank among all recommendations (1 = highest).
  final int rank;

  /// UTC timestamp when this recommendation was generated.
  final DateTime generatedAt;

  const Recommendation({
    required this.id,
    required this.domainId,
    required this.domainName,
    required this.type,
    required this.confidence,
    required this.evidence,
    required this.rationale,
    required this.summary,
    required this.rank,
    required this.generatedAt,
  });

  /// Creates a [Recommendation] from a decoded JSON map.
  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
    id: json['id'] as String,
    domainId: json['domain_id'] as String,
    domainName: json['domain_name'] as String,
    type: RecommendationType.values.byName(json['type'] as String),
    confidence: Confidence.fromJson(
      json['confidence'] as Map<String, dynamic>,
    ),
    evidence: (json['evidence'] as List<dynamic>)
        .map((e) => Evidence.fromJson(e as Map<String, dynamic>))
        .toList(),
    rationale: json['rationale'] as String,
    summary: json['summary'] as String,
    rank: json['rank'] as int,
    generatedAt: DateTime.parse(json['generated_at'] as String),
  );

  /// Serializes this [Recommendation] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'domain_id': domainId,
    'domain_name': domainName,
    'type': type.name,
    'confidence': confidence.toJson(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'rationale': rationale,
    'summary': summary,
    'rank': rank,
    'generated_at': generatedAt.toIso8601String(),
  };

  /// Returns a copy of this [Recommendation] with specified fields replaced.
  Recommendation copyWith({
    String? id,
    String? domainId,
    String? domainName,
    RecommendationType? type,
    Confidence? confidence,
    List<Evidence>? evidence,
    String? rationale,
    String? summary,
    int? rank,
    DateTime? generatedAt,
  }) => Recommendation(
    id: id ?? this.id,
    domainId: domainId ?? this.domainId,
    domainName: domainName ?? this.domainName,
    type: type ?? this.type,
    confidence: confidence ?? this.confidence,
    evidence: evidence ?? this.evidence,
    rationale: rationale ?? this.rationale,
    summary: summary ?? this.summary,
    rank: rank ?? this.rank,
    generatedAt: generatedAt ?? this.generatedAt,
  );

  /// The confidence level for this recommendation.
  ConfidenceLevel get confidenceLevel => confidence.level;

  /// Returns `true` if this is the top-ranked recommendation.
  bool get isPrimary => rank == 1;

  @override
  List<Object?> get props => [id, domainId, type, rank];

  @override
  String toString() =>
      'Recommendation(rank: $rank, domain: $domainName, '
      'type: ${type.name}, confidence: ${confidence.score.toStringAsFixed(2)})';
}
