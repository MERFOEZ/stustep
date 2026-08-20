/// SAIE — StudentStrength & StudentWeakness
///
/// Represents academically significant strengths and weaknesses detected
/// in the student's profile. Both are evidence-backed and dynamically updated.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AcademicArea
// ─────────────────────────────────────────────────────────────────────────────

/// The academic subject area or domain a strength/weakness belongs to.
enum AcademicArea {
  mathematics,
  physics,
  chemistry,
  biology,
  computerScience,
  programming,
  logic,
  language,
  literature,
  history,
  geography,
  economics,
  business,
  law,
  psychology,
  design,
  art,
  music,
  engineering,
  research,
  writing,
  communication,
  leadership,
  teamwork,
  creativity,
  analytics,
  other,
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentStrength
// ─────────────────────────────────────────────────────────────────────────────

/// An academic or cognitive strength detected in the student.
final class StudentStrength extends Equatable {
  /// Unique key for this strength (e.g., `"strength_math"`).
  final String key;

  /// Human-readable label.
  final String label;

  /// The academic area this strength belongs to.
  final AcademicArea area;

  /// Whether this was self-reported by the student.
  final bool isSelfReported;

  /// The tracked dimension for this strength.
  final CognitiveDimension dimension;

  /// UTC timestamp when this strength was first detected.
  final DateTime detectedAt;

  const StudentStrength({
    required this.key,
    required this.label,
    required this.area,
    required this.dimension,
    required this.detectedAt,
    this.isSelfReported = false,
  });

  factory StudentStrength.initial({
    required String key,
    required String label,
    required AcademicArea area,
    bool isSelfReported = false,
    double initialScore = 0.5,
  }) => StudentStrength(
    key: key,
    label: label,
    area: area,
    isSelfReported: isSelfReported,
    dimension: CognitiveDimension.initial(key: key, label: label)
        .copyWith(score: initialScore),
    detectedAt: DateTime.now().toUtc(),
  );

  factory StudentStrength.fromJson(Map<String, dynamic> json) =>
      StudentStrength(
        key: json['key'] as String,
        label: json['label'] as String,
        area: AcademicArea.values.byName(json['area'] as String),
        isSelfReported: json['is_self_reported'] as bool? ?? false,
        dimension: CognitiveDimension.fromJson(
          json['dimension'] as Map<String, dynamic>,
        ),
        detectedAt: DateTime.parse(json['detected_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'area': area.name,
    'is_self_reported': isSelfReported,
    'dimension': dimension.toJson(),
    'detected_at': detectedAt.toIso8601String(),
  };

  StudentStrength copyWith({
    String? key,
    String? label,
    AcademicArea? area,
    bool? isSelfReported,
    CognitiveDimension? dimension,
    DateTime? detectedAt,
  }) => StudentStrength(
    key: key ?? this.key,
    label: label ?? this.label,
    area: area ?? this.area,
    isSelfReported: isSelfReported ?? this.isSelfReported,
    dimension: dimension ?? this.dimension,
    detectedAt: detectedAt ?? this.detectedAt,
  );

  double get score => dimension.score;
  double get confidence => dimension.confidence;

  @override
  List<Object?> get props => [key, area, dimension.score];

  @override
  String toString() =>
      'StudentStrength(key: $key, area: ${area.name}, '
      'score: ${score.toStringAsFixed(2)})';
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentWeakness
// ─────────────────────────────────────────────────────────────────────────────

/// An academic or cognitive weakness or gap detected in the student.
final class StudentWeakness extends Equatable {
  /// Unique key for this weakness (e.g., `"weakness_algebra"`).
  final String key;

  /// Human-readable label.
  final String label;

  /// The academic area this weakness belongs to.
  final AcademicArea area;

  /// Whether this was self-reported by the student.
  final bool isSelfReported;

  /// Severity of the weakness — the higher the score, the more severe.
  final CognitiveDimension dimension;

  /// Optional suggested bridge skills or resources.
  final List<String> suggestedBridgeSkillIds;

  /// UTC timestamp when this weakness was first detected.
  final DateTime detectedAt;

  const StudentWeakness({
    required this.key,
    required this.label,
    required this.area,
    required this.dimension,
    required this.detectedAt,
    this.isSelfReported = false,
    this.suggestedBridgeSkillIds = const [],
  });

  factory StudentWeakness.initial({
    required String key,
    required String label,
    required AcademicArea area,
    bool isSelfReported = false,
    double initialSeverity = 0.5,
    List<String> suggestedBridgeSkillIds = const [],
  }) => StudentWeakness(
    key: key,
    label: label,
    area: area,
    isSelfReported: isSelfReported,
    dimension: CognitiveDimension.initial(key: key, label: label)
        .copyWith(score: initialSeverity),
    detectedAt: DateTime.now().toUtc(),
    suggestedBridgeSkillIds: suggestedBridgeSkillIds,
  );

  factory StudentWeakness.fromJson(Map<String, dynamic> json) =>
      StudentWeakness(
        key: json['key'] as String,
        label: json['label'] as String,
        area: AcademicArea.values.byName(json['area'] as String),
        isSelfReported: json['is_self_reported'] as bool? ?? false,
        dimension: CognitiveDimension.fromJson(
          json['dimension'] as Map<String, dynamic>,
        ),
        detectedAt: DateTime.parse(json['detected_at'] as String),
        suggestedBridgeSkillIds:
            (json['suggested_bridge_skill_ids'] as List<dynamic>?)
                    ?.cast<String>() ??
                const [],
      );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'area': area.name,
    'is_self_reported': isSelfReported,
    'dimension': dimension.toJson(),
    'detected_at': detectedAt.toIso8601String(),
    if (suggestedBridgeSkillIds.isNotEmpty)
      'suggested_bridge_skill_ids': suggestedBridgeSkillIds,
  };

  StudentWeakness copyWith({
    String? key,
    String? label,
    AcademicArea? area,
    bool? isSelfReported,
    CognitiveDimension? dimension,
    DateTime? detectedAt,
    List<String>? suggestedBridgeSkillIds,
  }) => StudentWeakness(
    key: key ?? this.key,
    label: label ?? this.label,
    area: area ?? this.area,
    isSelfReported: isSelfReported ?? this.isSelfReported,
    dimension: dimension ?? this.dimension,
    detectedAt: detectedAt ?? this.detectedAt,
    suggestedBridgeSkillIds:
        suggestedBridgeSkillIds ?? this.suggestedBridgeSkillIds,
  );

  /// Severity score — higher = more severe weakness.
  double get severity => dimension.score;
  double get confidence => dimension.confidence;

  /// Returns `true` if this weakness is severe enough to affect recommendations.
  bool get isCritical => severity >= 0.7 && confidence >= 0.5;

  @override
  List<Object?> get props => [key, area, dimension.score];

  @override
  String toString() =>
      'StudentWeakness(key: $key, area: ${area.name}, '
      'severity: ${severity.toStringAsFixed(2)})';
}
