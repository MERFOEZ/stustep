/// SAIE — Question Model
///
/// Represents a single assessment question in the adaptive question bank.
/// Questions are loaded exclusively from JSON asset files under
/// `assets/knowledge/questions/`. No question is ever hardcoded in Dart.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/core/enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuestionOption
// ─────────────────────────────────────────────────────────────────────────────

/// A single selectable option within a [Question].
final class QuestionOption extends Equatable {
  /// Unique key for this option within its question (e.g., `"a"`, `"b"`).
  final String key;

  /// Display text shown to the student.
  final String label;

  /// IDs of academic domains this option signals affinity toward.
  final List<String> targetDomainIds;

  /// Evidence weight this option contributes when selected, in [0.0, 1.0].
  final double evidenceWeight;

  /// Semantic direction this option signals when selected.
  ///
  /// Allowed values: `"positive"`, `"negative"`, `"neutral"`.
  ///
  /// IMPORTANT: `null` means direction is unspecified — selecting this option
  /// produces NO cognitive evidence. A missing direction does NOT default to
  /// positive. All structured-question options MUST declare direction
  /// explicitly in the knowledge base.
  final String? direction;

  const QuestionOption({
    required this.key,
    required this.label,
    required this.targetDomainIds,
    required this.evidenceWeight,
    this.direction,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
    key: json['key'] as String,
    label: json['label'] as String,
    targetDomainIds: (json['target_domain_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    evidenceWeight: (json['evidence_weight'] as num?)?.toDouble() ?? 0.5,
    // direction is nullable — absent in JSON produces null, not a silent default.
    direction: json['direction'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'target_domain_ids': targetDomainIds,
    'evidence_weight': evidenceWeight,
    if (direction != null) 'direction': direction,
  };

  QuestionOption copyWith({
    String? key,
    String? label,
    List<String>? targetDomainIds,
    double? evidenceWeight,
    Object? direction = _sentinel,
  }) => QuestionOption(
    key: key ?? this.key,
    label: label ?? this.label,
    targetDomainIds: targetDomainIds ?? this.targetDomainIds,
    evidenceWeight: evidenceWeight ?? this.evidenceWeight,
    direction: direction == _sentinel ? this.direction : direction as String?,
  );

  @override
  List<Object?> get props => [key, label, evidenceWeight, direction];
}

// Sentinel for nullable copyWith fields.
const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Question
// ─────────────────────────────────────────────────────────────────────────────

/// A single assessment question with adaptive metadata.
///
/// Questions are loaded from JSON and never constructed in Dart code directly.
/// The engine selects questions dynamically based on:
/// - Current [AssessmentPhase]
/// - Student's existing [Evidence] profile
/// - Question [difficulty] relative to student performance
final class Question extends Equatable {
  /// Unique identifier (e.g., `"q_stem_001"`).
  final String id;

  /// The question text displayed to the student.
  final String text;

  /// An optional elaboration or context hint for the student.
  final String? hint;

  /// The format type of this question.
  final QuestionType type;

  /// The relative difficulty of this question.
  final QuestionDifficulty difficulty;

  /// The assessment phase this question is intended for.
  final AssessmentPhase targetPhase;

  /// IDs of academic domains this question is relevant to.
  final List<String> targetDomainIds;

  /// Selectable options (for [QuestionType.multipleChoice], etc.).
  final List<QuestionOption> options;

  /// Minimum score on Likert scale (for [QuestionType.likertScale]).
  final int? likertMin;

  /// Maximum score on Likert scale (for [QuestionType.likertScale]).
  final int? likertMax;

  /// For [QuestionType.likertScale]: whether the higher end of the scale is
  /// the positive cognitive pole.
  ///
  /// `true`  — higher value = stronger positive evidence (most common).
  /// `false` — higher value = stronger negative evidence (reverse-coded).
  /// `null`  — not configured. The [KnowledgeSemanticValidator] rejects Likert
  ///           questions that leave this unset, so `null` is never reached
  ///           during a live assessment session.
  final bool? likertPositiveOrientation;

  /// Tags for filtering questions by theme (e.g., `"math"`, `"social"`).
  final List<String> tags;

  /// Whether this question may be shown multiple times across sessions.
  final bool repeatable;

  const Question({
    required this.id,
    required this.text,
    required this.type,
    required this.difficulty,
    required this.targetPhase,
    required this.targetDomainIds,
    this.hint,
    this.options = const [],
    this.likertMin,
    this.likertMax,
    this.likertPositiveOrientation,
    this.tags = const [],
    this.repeatable = false,
  });

  /// Creates a [Question] from a decoded JSON map.
  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    text: json['text'] as String,
    hint: json['hint'] as String?,
    type: QuestionType.values.byName(json['type'] as String),
    difficulty: QuestionDifficulty.values.byName(json['difficulty'] as String),
    targetPhase: AssessmentPhase.values.byName(json['target_phase'] as String),
    targetDomainIds: (json['target_domain_ids'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    options: (json['options'] as List<dynamic>?)
            ?.map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
            .toList() ??
        const [],
    likertMin: json['likert_min'] as int?,
    likertMax: json['likert_max'] as int?,
    // Nullable: absent in JSON means unconfigured. Validator will catch this
    // for Likert questions before any session starts.
    likertPositiveOrientation: json['likert_positive_orientation'] as bool?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    repeatable: json['repeatable'] as bool? ?? false,
  );

  /// Serializes this [Question] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type.name,
    'difficulty': difficulty.name,
    'target_phase': targetPhase.name,
    'target_domain_ids': targetDomainIds,
    if (hint != null) 'hint': hint,
    if (options.isNotEmpty) 'options': options.map((o) => o.toJson()).toList(),
    if (likertMin != null) 'likert_min': likertMin,
    if (likertMax != null) 'likert_max': likertMax,
    if (likertPositiveOrientation != null)
      'likert_positive_orientation': likertPositiveOrientation,
    if (tags.isNotEmpty) 'tags': tags,
    'repeatable': repeatable,
  };

  /// Returns a copy of this [Question] with specified fields replaced.
  Question copyWith({
    String? id,
    String? text,
    String? hint,
    QuestionType? type,
    QuestionDifficulty? difficulty,
    AssessmentPhase? targetPhase,
    List<String>? targetDomainIds,
    List<QuestionOption>? options,
    int? likertMin,
    int? likertMax,
    Object? likertPositiveOrientation = _sentinel,
    List<String>? tags,
    bool? repeatable,
  }) => Question(
    id: id ?? this.id,
    text: text ?? this.text,
    hint: hint ?? this.hint,
    type: type ?? this.type,
    difficulty: difficulty ?? this.difficulty,
    targetPhase: targetPhase ?? this.targetPhase,
    targetDomainIds: targetDomainIds ?? this.targetDomainIds,
    options: options ?? this.options,
    likertMin: likertMin ?? this.likertMin,
    likertMax: likertMax ?? this.likertMax,
    likertPositiveOrientation: likertPositiveOrientation == _sentinel
        ? this.likertPositiveOrientation
        : likertPositiveOrientation as bool?,
    tags: tags ?? this.tags,
    repeatable: repeatable ?? this.repeatable,
  );

  @override
  List<Object?> get props => [id, text, type, difficulty, targetPhase];

  @override
  String toString() =>
      'Question(id: $id, type: ${type.name}, difficulty: ${difficulty.name})';
}
