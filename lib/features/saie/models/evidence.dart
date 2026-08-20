/// SAIE — Evidence Model
///
/// Represents a single atomic piece of evidence collected during a session.
/// Evidence is the primary raw material the reasoning engine uses to produce
/// [Confidence] values and [Recommendation] objects.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EvidenceType
// ─────────────────────────────────────────────────────────────────────────────

/// Classifies what kind of signal an [Evidence] record represents.
enum EvidenceType {
  /// Derived from a direct answer to an assessment question.
  questionResponse,

  /// Derived from a free-text interest statement.
  interestDeclaration,

  /// Derived from a self-reported academic strength or subject.
  academicStrength,

  /// Derived from a self-reported academic weakness.
  academicWeakness,

  /// Derived from a self-reported career aspiration or goal.
  careerAspiration,

  /// Derived from a personality or learning-style signal.
  personalitySignal,

  /// Derived from a reported extracurricular activity.
  extracurricularActivity,

  /// Inferred by the engine via cross-signal reasoning (not directly stated).
  engineInference,
}

// ─────────────────────────────────────────────────────────────────────────────
// Evidence
// ─────────────────────────────────────────────────────────────────────────────

/// An atomic evidence signal linking a student action to an academic domain.
///
/// Each [Evidence] record has:
/// - A [type] classifying its source.
/// - A [domainId] pointing to the major/career/skill it supports.
/// - A [weight] in [0.0, 1.0] representing its strength.
/// - An [answerQuality] if derived from a question response.
/// - A [timestamp] marking when it was collected.
final class Evidence extends Equatable {
  /// Unique identifier for this evidence record.
  final String id;

  /// The type of signal this evidence represents.
  final EvidenceType type;

  /// The ID of the academic domain (major, career, or skill) this supports.
  final String domainId;

  /// Human-readable description of what was observed.
  final String observation;

  /// Signal strength in [0.0, 1.0].
  final double weight;

  /// Quality of the originating answer, if from a question response.
  final AnswerQuality? answerQuality;

  /// ID of the question that generated this evidence, if applicable.
  final String? sourceQuestionId;

  /// UTC timestamp when this evidence was collected.
  final DateTime timestamp;

  const Evidence({
    required this.id,
    required this.type,
    required this.domainId,
    required this.observation,
    required this.weight,
    required this.timestamp,
    this.answerQuality,
    this.sourceQuestionId,
  }) : assert(
         weight >= 0.0 && weight <= 1.0,
         'Evidence weight must be in [0.0, 1.0]',
       );

  /// Creates an [Evidence] from a decoded JSON map.
  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: json['id'] as String,
    type: EvidenceType.values.byName(json['type'] as String),
    domainId: json['domain_id'] as String,
    observation: json['observation'] as String,
    weight: (json['weight'] as num).toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    answerQuality: json['answer_quality'] != null
        ? AnswerQuality.values.byName(json['answer_quality'] as String)
        : null,
    sourceQuestionId: json['source_question_id'] as String?,
  );

  /// Serializes this [Evidence] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'domain_id': domainId,
    'observation': observation,
    'weight': weight,
    'timestamp': timestamp.toIso8601String(),
    if (answerQuality != null) 'answer_quality': answerQuality!.name,
    if (sourceQuestionId != null) 'source_question_id': sourceQuestionId,
  };

  /// Returns a copy of this [Evidence] with specified fields replaced.
  Evidence copyWith({
    String? id,
    EvidenceType? type,
    String? domainId,
    String? observation,
    double? weight,
    DateTime? timestamp,
    AnswerQuality? answerQuality,
    String? sourceQuestionId,
  }) => Evidence(
    id: id ?? this.id,
    type: type ?? this.type,
    domainId: domainId ?? this.domainId,
    observation: observation ?? this.observation,
    weight: weight ?? this.weight,
    timestamp: timestamp ?? this.timestamp,
    answerQuality: answerQuality ?? this.answerQuality,
    sourceQuestionId: sourceQuestionId ?? this.sourceQuestionId,
  );

  @override
  List<Object?> get props => [id, type, domainId, weight, timestamp];

  @override
  String toString() =>
      'Evidence(id: $id, type: ${type.name}, domain: $domainId, '
      'weight: ${weight.toStringAsFixed(2)})';
}
