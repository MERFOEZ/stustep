/// SAIE — KnowledgeSemanticValidator
///
/// Release-safe validation of the knowledge base semantic layer.
///
/// This validator is called BEFORE an assessment session can start, inside
/// [LoadKnowledgeBaseUseCase.call()]. It checks that every identifier used
/// as a cognitive dimension key in the knowledge base actually maps to a
/// canonical [DimensionKeys] value.
///
/// DESIGN:
/// - Pure Dart. No Flutter. No assertions. Works identically in debug and
///   release builds.
/// - Returns a [KnowledgeSemanticFailure] listing ALL invalid identifiers
///   found, rather than stopping at the first. This allows a developer to
///   see the complete picture in one pass.
/// - On failure the engine startup is aborted before any student interaction.
///   The student sees a configuration error, not a silent bad recommendation.
///
/// WHAT IS VALIDATED:
/// 1. Every question-level [Question.targetDomainIds] entry must be a
///    canonical [DimensionKeys] value.
/// 2. Every [Major.requiredSkillIds] entry used as a dimension comparison
///    must be a canonical [DimensionKeys] value.
/// 3. Every [Major.preferredSkillIds] entry used as a dimension comparison
///    must be a canonical [DimensionKeys] value.
///
/// WHAT IS NOT VALIDATED HERE (deferred to Phase 2B):
/// - Option-level [QuestionOption.targetDomainIds] — not currently read by
///   [EvidenceExtractor]; validated when Phase 2B option evidence is added.
/// - Major tags — used only by [_interestAlignment], not as dimension keys.
/// - Question tags — supplementary dimension signals, not primary targets.
///   Tags that happen to match [DimensionKeys] are treated as bonuses; those
///   that do not are ignored, not errors.
library;

import 'package:stustep/features/saie/core/failures.dart';
import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KnowledgeSemanticFailure
// ─────────────────────────────────────────────────────────────────────────────

/// Returned when the knowledge base contains identifiers that are not
/// canonical [DimensionKeys] values in positions where they must be.
///
/// The engine MUST NOT start an assessment session if this failure is returned.
class KnowledgeSemanticFailure extends Failure {
  /// Every invalid identifier found, grouped by source.
  final List<SemanticViolation> violations;

  const KnowledgeSemanticFailure({
    required super.message,
    required this.violations,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, violations];
}

/// A single semantic integrity violation.
final class SemanticViolation {
  /// Human-readable source location (e.g., 'Question "q_001" targetDomainId').
  final String source;

  /// The invalid identifier found.
  final String invalidId;

  /// The context: what the identifier was being used as.
  final String role;

  const SemanticViolation({
    required this.source,
    required this.invalidId,
    required this.role,
  });

  @override
  String toString() =>
      '[$source] Invalid $role: "$invalidId" — not in DimensionKeys.all';
}

// ─────────────────────────────────────────────────────────────────────────────
// KnowledgeSemanticValidator
// ─────────────────────────────────────────────────────────────────────────────

/// Validates that all knowledge-base identifiers used as cognitive dimension
/// keys are canonical [DimensionKeys] values.
///
/// Release-safe: pure Dart, no assertions, identical behaviour in all build
/// modes. Returns a typed [KnowledgeSemanticFailure] on any violation.
///
/// Usage:
/// ```dart
/// final result = KnowledgeSemanticValidator.validate(
///   questions: loadedQuestions,
///   majors: loadedMajors,
/// );
/// if (result.isFailure) {
///   // Abort startup — report result.failure.message.
/// }
/// ```
final class KnowledgeSemanticValidator {
  const KnowledgeSemanticValidator._();

  /// Validates the semantic integrity of [questions] and [majors].
  ///
  /// Returns [Result.success] (value = `null`) if all identifiers are valid.
  /// Returns [Result.failure] with a [KnowledgeSemanticFailure] listing all
  /// violations if any invalid identifiers are found.
  ///
  /// IMPORTANT: This method collects ALL violations before returning, so the
  /// complete set of problems is visible in a single error report.
  static Result<void> validate({
    required List<Question> questions,
    required List<Major> majors,
  }) {
    final validKeys = DimensionKeys.all.toSet();
    final violations = <SemanticViolation>[];

    // ── 1. Validate question-level targetDomainIds ─────────────────────────
    for (final question in questions) {
      for (final id in question.targetDomainIds) {
        if (id.isEmpty) continue; // blank strings are ignored
        if (!validKeys.contains(id)) {
          violations.add(SemanticViolation(
            source: 'Question "${question.id}"',
            invalidId: id,
            role: 'targetDomainId (evidence dimension)',
          ));
        }
      }
    }

    // ── 2. Validate major requiredSkillIds ────────────────────────────────
    for (final major in majors) {
      for (final id in major.requiredSkillIds) {
        if (id.isEmpty) continue;
        if (!validKeys.contains(id)) {
          violations.add(SemanticViolation(
            source: 'Major "${major.id}"',
            invalidId: id,
            role: 'requiredSkillId (required cognitive dimension)',
          ));
        }
      }

      // ── 3. Validate major preferredSkillIds ──────────────────────────────
      for (final id in major.preferredSkillIds) {
        if (id.isEmpty) continue;
        if (!validKeys.contains(id)) {
          violations.add(SemanticViolation(
            source: 'Major "${major.id}"',
            invalidId: id,
            role: 'preferredSkillId (preferred cognitive dimension)',
          ));
        }
      }
    }

    if (violations.isEmpty) return Result.success(null);

    // Build a diagnostic summary listing every violation.
    final summary = StringBuffer();
    summary.writeln(
      'Knowledge base semantic validation failed. '
      '${violations.length} violation(s) found. '
      'The engine cannot start until all dimension identifiers are canonical '
      'DimensionKeys values.',
    );
    for (final v in violations) {
      summary.writeln('  • $v');
    }

    return Result.failure(KnowledgeSemanticFailure(
      message: summary.toString().trim(),
      violations: violations,
    ));
  }
}
