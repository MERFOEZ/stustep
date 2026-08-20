/// SAIE — StudentEvidence
///
/// Every piece of information the engine collects from the student is stored
/// as a [StudentEvidence] record. Evidence is the atomic input to every
/// cognitive dimension update — nothing changes in the profile without evidence.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EvidenceSource
// ─────────────────────────────────────────────────────────────────────────────

/// The origin of a piece of evidence.
enum EvidenceSource {
  /// Derived from a structured assessment question answer.
  questionAnswer,

  /// Derived from a free-text message the student typed.
  freeTextMessage,

  /// Derived from a Likert-scale rating response.
  likertRating,

  /// Derived from a ranking of choices.
  ranking,

  /// Derived from a multi-select answer.
  multiSelect,

  /// Inferred cross-dimensionally by the engine from other evidence.
  engineInference,

  /// Provided explicitly during student onboarding intake.
  onboardingIntake,
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentEvidence
// ─────────────────────────────────────────────────────────────────────────────

/// An atomic, immutable evidence record produced by a student interaction.
///
/// One question answer can produce multiple [StudentEvidence] records,
/// each targeting a different cognitive dimension.
final class StudentEvidence extends Equatable {
  /// Unique identifier for this evidence record (UUID v4).
  final String id;

  /// ID of the question that generated this evidence (if applicable).
  final String? questionId;

  /// ID of the conversation message that generated this evidence.
  final String? messageId;

  /// The raw value the student provided (e.g., option key, Likert score text).
  final String rawValue;

  /// UTC timestamp when this evidence was collected.
  final DateTime timestamp;

  /// Signal strength in [0.0, 1.0] — how strongly this evidence supports
  /// the affected dimensions.
  final double weight;

  /// Engine confidence in interpreting this evidence, in [0.0, 1.0].
  final double confidence;

  /// The origin of this evidence.
  final EvidenceSource source;

  /// Map from dimension key to the signed delta this evidence applies.
  /// Positive = increases dimension score; negative = decreases.
  /// Values in [-1.0, 1.0].
  final Map<String, double> affectedDimensions;

  /// Human-readable explanation of why this evidence was created.
  final String reason;

  /// Optional tags for grouping evidence during analysis.
  final List<String> tags;

  const StudentEvidence({
    required this.id,
    required this.rawValue,
    required this.timestamp,
    required this.weight,
    required this.confidence,
    required this.source,
    required this.affectedDimensions,
    required this.reason,
    this.questionId,
    this.messageId,
    this.tags = const [],
  })  : assert(weight >= 0.0 && weight <= 1.0, 'weight must be in [0.0, 1.0]'),
        assert(
          confidence >= 0.0 && confidence <= 1.0,
          'confidence must be in [0.0, 1.0]',
        );

  factory StudentEvidence.fromJson(Map<String, dynamic> json) =>
      StudentEvidence(
        id: json['id'] as String,
        questionId: json['question_id'] as String?,
        messageId: json['message_id'] as String?,
        rawValue: json['raw_value'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        weight: (json['weight'] as num).toDouble(),
        confidence: (json['confidence'] as num).toDouble(),
        source: EvidenceSource.values.byName(json['source'] as String),
        affectedDimensions:
            (json['affected_dimensions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        reason: json['reason'] as String,
        tags:
            (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    if (questionId != null) 'question_id': questionId,
    if (messageId != null) 'message_id': messageId,
    'raw_value': rawValue,
    'timestamp': timestamp.toIso8601String(),
    'weight': weight,
    'confidence': confidence,
    'source': source.name,
    'affected_dimensions': affectedDimensions,
    'reason': reason,
    if (tags.isNotEmpty) 'tags': tags,
  };

  StudentEvidence copyWith({
    String? id,
    String? questionId,
    String? messageId,
    String? rawValue,
    DateTime? timestamp,
    double? weight,
    double? confidence,
    EvidenceSource? source,
    Map<String, double>? affectedDimensions,
    String? reason,
    List<String>? tags,
  }) => StudentEvidence(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    messageId: messageId ?? this.messageId,
    rawValue: rawValue ?? this.rawValue,
    timestamp: timestamp ?? this.timestamp,
    weight: weight ?? this.weight,
    confidence: confidence ?? this.confidence,
    source: source ?? this.source,
    affectedDimensions: affectedDimensions ?? this.affectedDimensions,
    reason: reason ?? this.reason,
    tags: tags ?? this.tags,
  );

  /// Total signed impact across all affected dimensions.
  double get totalImpact =>
      affectedDimensions.values.fold(0.0, (sum, v) => sum + v.abs());

  /// Returns `true` if this evidence affects [dimensionKey].
  bool affects(String dimensionKey) =>
      affectedDimensions.containsKey(dimensionKey);

  @override
  List<Object?> get props =>
      [id, questionId, weight, confidence, source, timestamp];

  @override
  String toString() =>
      'StudentEvidence(id: $id, source: ${source.name}, '
      'weight: ${weight.toStringAsFixed(2)}, '
      'dims: ${affectedDimensions.keys.join(",")})';
}
