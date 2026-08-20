/// SAIE — ImprovementSuggestions (Explainable Layer)
///
/// Generates a prioritised list of concrete improvement actions
/// based on the student's gap analysis and top recommendations.
library;

import 'package:stustep/features/saie/explainable/dimension_summary.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ImprovementSuggestionsEngine
// ─────────────────────────────────────────────────────────────────────────────

/// Generates [ImprovementSuggestion] objects from gap and recommendation data.
final class ImprovementSuggestionsEngine {
  const ImprovementSuggestionsEngine();

  /// Returns a sorted list of improvement suggestions.
  List<ImprovementSuggestion> generate({
    required StudentCognitiveProfile profile,
    required DimensionSummary dimensionSummary,
    required List<MajorRecommendation> topRecommendations,
  }) {
    final suggestions = <ImprovementSuggestion>[];
    final processedKeys = <String>{};

    // ── 1. Address missing skills across top recommendations ─────────────
    for (final rec in topRecommendations.take(3)) {
      for (final skill in rec.missingSkills.take(4)) {
        if (processedKeys.contains(skill)) continue;
        processedKeys.add(skill);
        suggestions.add(ImprovementSuggestion(
          dimensionKey: skill,
          title: 'Develop $skill',
          suggestion: _skillSuggestion(skill),
          rationale:
              'Required by "${rec.majorName}" (Rank ${rec.rank}). '
              'Gaining this skill will improve your match score significantly.',
          priority: 1.0,
        ));
      }
    }

    // ── 2. Address weak assessed dimensions ─────────────────────────────
    for (final dim in dimensionSummary.weaknesses) {
      if (processedKeys.contains(dim.key)) continue;
      processedKeys.add(dim.key);

      // Only suggest if it matters for at least one top recommendation.
      final isRelevant = topRecommendations.take(5).any((rec) =>
          rec.weakAreas.contains(dim.key) ||
          rec.missingSkills.contains(dim.key));
      if (!isRelevant && dim.status != DimensionStatus.weak) continue;

      suggestions.add(ImprovementSuggestion(
        dimensionKey: dim.key,
        title: 'Strengthen ${dim.label}',
        suggestion: _dimensionSuggestion(dim.key, dim.label),
        rationale:
            '${dim.label} is currently ${dim.status.label} '
            '(${(dim.score * 100).toStringAsFixed(0)}%). '
            'Improving it will broaden your major options.',
        priority: (1.0 - dim.score).clamp(0.0, 1.0),
      ));
    }

    // ── 3. Flag undiscovered dimensions ─────────────────────────────────
    for (final dim in dimensionSummary.undiscovered.take(3)) {
      if (processedKeys.contains(dim.key)) continue;
      processedKeys.add(dim.key);

      suggestions.add(ImprovementSuggestion(
        dimensionKey: dim.key,
        title: 'Explore ${dim.label}',
        suggestion:
            'Answer more questions about ${dim.label} to help the '
            'system understand your aptitude in this area.',
        rationale:
            '${dim.label} has not been assessed yet. More responses will '
            'improve the accuracy of your recommendation.',
        priority: 0.60,
      ));
    }

    // ── 4. Confidence boosting ───────────────────────────────────────────
    final lowConfDimensions = dimensionSummary.dimensions
        .where((d) => d.evidenceCount > 0 && d.confidence < 0.40)
        .toList()
      ..sort((a, b) => a.confidence.compareTo(b.confidence));

    for (final dim in lowConfDimensions.take(3)) {
      if (processedKeys.contains('confidence_${dim.key}')) continue;
      processedKeys.add('confidence_${dim.key}');

      suggestions.add(ImprovementSuggestion(
        dimensionKey: dim.key,
        title: 'Confirm your ${dim.label} level',
        suggestion:
            'Provide more specific examples or activities related to '
            '${dim.label} to help the system build confidence.',
        rationale:
            'Evidence for ${dim.label} exists but confidence is low '
            '(${(dim.confidence * 100).toStringAsFixed(0)}%). '
            'More consistent responses will sharpen this signal.',
        priority: 0.50,
      ));
    }

    // Sort by priority descending.
    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    return suggestions.take(10).toList();
  }

  // ─── Template lookup ─────────────────────────────────────────────────────

  String _skillSuggestion(String skill) {
    const templates = {
      'programming': 'Start with beginner projects using Python or Dart. '
          'Use platforms like Codecademy or freeCodeCamp.',
      'mathematics': 'Review algebra and calculus with Khan Academy. '
          'Practice problem sets daily for 30 minutes.',
      'english': 'Read one English article per day and write a short '
          'summary to improve comprehension and writing.',
      'communication': 'Join a debate club or take a public speaking course. '
          'Practice presenting ideas to others.',
      'leadership': 'Take on coordinator roles in group projects or '
          'community activities.',
      'design': 'Experiment with free design tools (Figma, Canva) and '
          'complete small design challenges online.',
      'research': 'Practice summarising academic papers in your own words. '
          'Start a reading log on topics you are curious about.',
      'statistics': 'Work through basic statistics exercises and use '
          'real datasets for practice (Kaggle, Google Dataset Search).',
    };
    return templates[skill.toLowerCase()] ??
        'Actively seek courses, workshops, or projects to practise and develop $skill.';
  }

  String _dimensionSuggestion(String key, String label) {
    const templates = {
      'creativity': 'Engage in creative hobbies such as writing, art, music, '
          'or design to build lateral thinking skills.',
      'teamwork': 'Participate in team sports, collaborative projects, or '
          'volunteer group work.',
      'logic': 'Solve logic puzzles and riddles daily. Explore resources '
          'like "The Art of Problem Solving".',
      'technology': 'Explore technology through MOOCs (Coursera, edX) and '
          'build small hobby projects.',
      'business': 'Read business case studies and explore concepts in '
          'entrepreneurship or economics.',
      'science': 'Engage with science documentaries and read beginner-level '
          'scientific literature.',
    };
    return templates[key] ??
        'Seek structured learning opportunities, mentorship, or '
        'hands-on experience in $label.';
  }
}
