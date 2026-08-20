/// SAIE — RecommendationGenerator
///
/// Assembles all components into the final [RecommendationReport].
/// Called by [RecommendationEngine] after validation passes.
library;

import 'package:stustep/features/saie/assessment/assessment_statistics.dart';
import 'package:stustep/features/saie/matching/major_ranking.dart';
import 'package:stustep/features/saie/profile/learning_style.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_confidence.dart';
import 'package:stustep/features/saie/recommendation/recommendation_ranker.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationGenerator
// ─────────────────────────────────────────────────────────────────────────────

/// Assembles the full [RecommendationReport] from all engine outputs.
final class RecommendationGenerator {
  static const _uuid = Uuid();
  final RecommendationRanker _ranker;

  const RecommendationGenerator({
    RecommendationRanker ranker = const RecommendationRanker(),
  }) : _ranker = ranker;

  /// Generates the complete [RecommendationReport].
  RecommendationReport generate({
    required String studentId,
    required StudentCognitiveProfile profile,
    required MajorRanking ranking,
    required AssessmentStatistics stats,
    required String statusMessage,
  }) {
    final now = DateTime.now().toUtc();
    final profileStats = profile.computeStatistics();

    // Build ranked recommendations.
    final recommendations = _ranker.rank(
      ranking: ranking,
      profile: profile,
      stats: stats,
    );

    // Enrich career paths on each recommendation.
    final enriched = recommendations.map((rec) {
      return rec.copyWith(careerPaths: _careerPathsForMajor(rec.majorId));
    }).toList();

    // Overall confidence from the top pick.
    final overallConf = enriched.isEmpty
        ? RecommendationConfidence.compute(
            profileConfidence: profileStats.overallConfidence,
            evidenceCount: profile.evidenceCount,
            coverageRatio: profileStats.coverageRatio,
            matchSimilarityScore: 0,
          )
        : enriched.first.confidence;

    // Global strengths and weaknesses from profile stats.
    final strengths = profileStats.strongestDimensions
        .take(5)
        .map((d) => DimensionKeys.labels[d.key] ?? d.key)
        .toList();
    final weaknesses = profileStats.weakestDimensions
        .take(5)
        .map((d) => DimensionKeys.labels[d.key] ?? d.key)
        .toList();

    // Learning style.
    final learningStyle = _dominantLearningStyle(profile);

    // Personality.
    final personalityHighlights = _personalityHighlights(profile);

    // Improvement suggestions from gaps.
    final suggestions = _generateSuggestions(profile, enriched);

    return RecommendationReport(
      reportId: _uuid.v4(),
      studentId: studentId,
      status: enriched.isEmpty
          ? ReportStatus.noConfidentMatch
          : ReportStatus.ready,
      statusMessage: statusMessage,
      recommendations: enriched,
      overallConfidence: overallConf,
      globalStrengths: strengths,
      globalWeaknesses: weaknesses,
      dominantLearningStyle: learningStyle,
      personalityHighlights: personalityHighlights,
      assessmentStats: stats,
      improvementSuggestions: suggestions,
      sourceRanking: ranking,
      generatedAt: now,
    );
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  static const Map<String, List<String>> _careerPaths = {
    'major_cs': ['مطوّر برمجيات', 'مهندس أنظمة', 'مهندس أمن معلومات', 'باحث حوسبة'],
    'major_ai': ['مهندس ذكاء اصطناعي', 'باحث تعلم آلي', 'مهندس معالجة اللغة', 'مهندس روبوتيات'],
    'major_data_science': ['عالم بيانات', 'محلل بيانات', 'مهندس ذكاء أعمال', 'إحصائي'],
    'major_software_eng': ['مهندس برمجيات', 'مهندس DevOps', 'مدير منتج تقني', 'قائد فريق تقني'],
    'major_engineering': ['مهندس مدني', 'مهندس ميكانيكي', 'مهندس كهربائي', 'مهندس صناعي'],
    'major_medicine': ['طبيب عام', 'طبيب متخصص', 'جراح', 'باحث طبي'],
    'major_psychology': ['أخصائي نفسي', 'مستشار نفسي', 'معالج نفسي', 'باحث اجتماعي'],
    'major_business': ['مدير أعمال', 'رائد أعمال', 'مستشار استراتيجي', 'محلل مالي'],
    'major_law': ['محامٍ', 'قاضٍ', 'مستشار قانوني', 'مدّعٍ عام'],
    'major_architecture': ['مهندس معماري', 'مخطط عمراني', 'مصمم داخلي'],
    'major_media': ['صحفي', 'منتج محتوى', 'أخصائي علاقات عامة', 'مذيع'],
  };

  List<String> _careerPathsForMajor(String majorId) {
    return _careerPaths[majorId] ?? const [];
  }

  String _dominantLearningStyle(StudentCognitiveProfile profile) {
    final dominant = profile.learningStyle.dominantModality;
    if (dominant == null) return 'Multimodal';
    return _modalityLabel(dominant);
  }

  List<String> _personalityHighlights(StudentCognitiveProfile profile) {
    final axes = profile.personality.axes;
    if (axes.isEmpty) return const [];
    final sorted = axes.entries
        .where((e) => e.value.score.abs() >= 0.5)
        .toList()
      ..sort((a, b) => b.value.score.abs().compareTo(a.value.score.abs()));
    return sorted
        .take(3)
        .map((e) {
          final score = e.value.score;
          // Derive high/low label from the axis name and score direction.
          return score >= 0
              ? '${_capitalise(e.key)} (high)'
              : '${_capitalise(e.key)} (low)';
        })
        .toList();
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _modalityLabel(LearningModality m) => switch (m) {
    LearningModality.visual => 'Visual',
    LearningModality.readWrite => 'Read/Write',
    LearningModality.auditory => 'Auditory',
    LearningModality.kinesthetic => 'Kinesthetic',
  };

  List<ImprovementSuggestion> _generateSuggestions(
    StudentCognitiveProfile profile,
    List<MajorRecommendation> recommendations,
  ) {
    final suggestions = <ImprovementSuggestion>[];

    // Collect all weak areas from the top-3 recommendations.
    final weakKeys = <String>{};
    for (final rec in recommendations.take(3)) {
      weakKeys.addAll(rec.weakAreas);
      weakKeys.addAll(rec.missingSkills);
    }

    for (final key in weakKeys.take(8)) {
      final label = DimensionKeys.labels[key] ?? key;
      final score = profile.scoreFor(key);
      final conf = profile.confidenceFor(key);

      suggestions.add(ImprovementSuggestion(
        dimensionKey: key,
        title: 'Improve $label',
        suggestion: _suggestionTextFor(key, label),
        rationale:
            'Current score: ${(score * 100).toStringAsFixed(0)}%, '
            'confidence: ${(conf * 100).toStringAsFixed(0)}%. '
            'Your top recommended majors require stronger performance here.',
        priority: (1.0 - score).clamp(0.0, 1.0),
      ));
    }

    // Sort by priority descending.
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    return suggestions;
  }

  String _suggestionTextFor(String key, String label) {
    const templates = <String, String>{
      'programming': 'Practice coding daily with small projects or '
          'challenges on platforms like LeetCode or HackerRank.',
      'mathematics': 'Strengthen algebra and calculus foundations through '
          'structured problem sets and tutoring if needed.',
      'communication': 'Join a debate club, take public speaking courses, '
          'or practice writing daily journal entries.',
      'leadership': 'Take on team-lead roles in group projects or '
          'community activities to build confidence.',
      'creativity': 'Engage in creative hobbies — design, music, writing, '
          'or art — to develop lateral thinking.',
      'teamwork': 'Participate in collaborative projects, sports, or '
          'volunteer work that requires group coordination.',
      'research': 'Read academic papers in areas of interest and '
          'practice summarising findings concisely.',
      'business': 'Study basic economics, read case studies, and '
          'try small entrepreneurial projects.',
      'logic': 'Solve logic puzzles, study formal reasoning, '
          'or try competitive programming challenges.',
      'technology': 'Explore technology through online courses, '
          'build simple apps, or participate in hackathons.',
    };
    return templates[key] ??
        'Actively seek opportunities to develop and practise $label skills.';
  }
}
