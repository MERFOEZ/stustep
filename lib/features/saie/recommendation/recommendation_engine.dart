/// SAIE — RecommendationEngine
///
/// The master orchestrator for the recommendation layer.
/// Validates → Generates → Returns [RecommendationReport].
/// NEVER guesses. NEVER calls external AI. Works completely offline.
library;

import 'package:stustep/features/saie/assessment/assessment_statistics.dart';
import 'package:stustep/features/saie/matching/major_ranking.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_generator.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';
import 'package:stustep/features/saie/recommendation/recommendation_validator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Entry point for the entire recommendation layer.
///
/// Pipeline:
/// 1. Validate that the profile + ranking have enough data.
/// 2. If not → return a [RecommendationReport] with status [needMoreAssessment].
/// 3. If valid → generate the full report.
final class RecommendationEngine {
  final RecommendationValidator _validator;
  final RecommendationGenerator _generator;

  const RecommendationEngine({
    RecommendationValidator validator = const RecommendationValidator(),
    RecommendationGenerator generator = const RecommendationGenerator(),
  })  : _validator = validator,
        _generator = generator;

  /// Produces a [RecommendationReport] from [ranking].
  ///
  /// This is the ONLY input path. The engine never receives raw answers.
  RecommendationReport produce({
    required String studentId,
    required StudentCognitiveProfile profile,
    required MajorRanking ranking,
    required AssessmentStatistics stats,
  }) {
    // ── Step 1: Validate ─────────────────────────────────────────────────
    final validation = _validator.validate(
      profile: profile,
      ranking: ranking,
      stats: stats,
    );

    if (!validation.isValid) {
      return _insufficientReport(
        studentId: studentId,
        profile: profile,
        ranking: ranking,
        stats: stats,
        validation: validation,
      );
    }

    // ── Step 2: Generate ─────────────────────────────────────────────────
    return _generator.generate(
      studentId: studentId,
      profile: profile,
      ranking: ranking,
      stats: stats,
      statusMessage: 'Recommendation generated successfully.',
    );
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  RecommendationReport _insufficientReport({
    required String studentId,
    required StudentCognitiveProfile profile,
    required MajorRanking ranking,
    required AssessmentStatistics stats,
    required RecommendationValidationResult validation,
  }) {
    final status = validation.outcome == ValidationOutcome.needMoreAssessment
        ? ReportStatus.needMoreAssessment
        : ReportStatus.noConfidentMatch;

    // Produce a skeletal report so the UI always has a consistent type.
    return _generator.generate(
      studentId: studentId,
      profile: profile,
      ranking: ranking,
      stats: stats,
      statusMessage: validation.message,
    ).copyWith(
      status: status,
      recommendations: const [],
    );
  }
}
