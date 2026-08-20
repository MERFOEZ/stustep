/// SAIE — AnswerQualityEvaluator
///
/// The central scoring engine for student answers.
/// Computes a 9-dimension [AnswerScore] for every accepted answer.
/// Reads exclusively from pre-extracted [AnswerFeatures].
library;

import 'package:stustep/features/saie/analysis/answer_features.dart';
import 'package:stustep/features/saie/analysis/answer_score.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnswerQualityEvaluator
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless evaluator that computes the [AnswerScore] for a student answer.
///
/// Scoring is multi-dimensional:
/// - Relevance: answer addresses the question topic.
/// - Completeness: answer covers all aspects of the question.
/// - Specificity: answer is concrete and non-vague.
/// - Consistency: answer aligns with existing profile evidence.
/// - Confidence: engine's certainty about the answer interpretation.
/// - EvidenceStrength: usable signal for profile update.
/// - ReasoningDepth: depth of justification provided.
/// - InformationDensity: information content per word.
/// - ContextAwareness: answer references conversation context.
final class AnswerQualityEvaluator {
  const AnswerQualityEvaluator();

  /// Evaluates an answer and returns a fully computed [AnswerScore].
  AnswerScore evaluate({
    required String rawAnswer,
    required AnswerFeatures features,
    required Question question,
    required StudentCognitiveProfile profile,
    required List<String> recentAnswerTexts,
    bool contradictionDetected = false,
  }) {
    final now = DateTime.now().toUtc();

    // ── Hard rejection checks ──
    if (features.isEmpty || features.looksRandom) {
      return _zeroScore(
        questionId: question.id,
        answerText: rawAnswer,
        reason: features.isEmpty
            ? 'Answer is empty.'
            : 'Answer appears to be random text.',
        scoredAt: now,
      );
    }

    // ── 1. Relevance ──
    final relevance = _scoreRelevance(features, question);

    // ── 2. Completeness ──
    final completeness = _scoreCompleteness(features, question);

    // ── 3. Specificity ──
    final specificity = _scoreSpecificity(features);

    // ── 4. Consistency ──
    final consistency = _scoreConsistency(
      features: features,
      profile: profile,
      contradictionDetected: contradictionDetected,
    );

    // ── 5. Confidence ──
    final confidence = _scoreConfidence(features, question);

    // ── 6. Evidence Strength ──
    final evidenceStrength = _scoreEvidenceStrength(features, question);

    // ── 7. Reasoning Depth ──
    final reasoningDepth = _scoreReasoningDepth(features);

    // ── 8. Information Density ──
    final informationDensity = _scoreInformationDensity(features);

    // ── 9. Context Awareness ──
    final contextAwareness = _scoreContextAwareness(features);

    // ── Weighted composite total ──
    final total = _computeTotal(
      relevance: relevance,
      completeness: completeness,
      specificity: specificity,
      consistency: consistency,
      confidence: confidence,
      evidenceStrength: evidenceStrength,
      reasoningDepth: reasoningDepth,
      informationDensity: informationDensity,
      contextAwareness: contextAwareness,
    );

    final band = ScoreBandX.fromTotal(total);

    return AnswerScore(
      questionId: question.id,
      answerText: rawAnswer,
      relevance: relevance,
      completeness: completeness,
      specificity: specificity,
      consistency: consistency,
      confidence: confidence,
      evidenceStrength: evidenceStrength,
      reasoningDepth: reasoningDepth,
      informationDensity: informationDensity,
      contextAwareness: contextAwareness,
      total: total,
      band: band,
      scoringReason: _buildReason(
        band: band,
        total: total,
        features: features,
        contradictionDetected: contradictionDetected,
      ),
      scoredAt: now,
    );
  }

  // ─── Sub-dimension scorers ────────────────────────────────────────────────

  int _scoreRelevance(AnswerFeatures features, Question question) {
    int score = 40; // base — assume the student is answering

    // Very short answers are rarely fully relevant.
    if (features.isVeryShort) score -= 20;

    // Single word may still be a valid Likert / MC answer.
    if (features.isSingleWord && question.type == QuestionType.likertScale) {
      score += 30;
    }

    // Random-looking text kills relevance.
    if (features.looksRandom) return 0;

    // Repetition reduces relevance (already answered this).
    if (features.isRepetition) score -= 25;

    // Numeric answer for Likert is highly relevant.
    if (features.containsNumeric &&
        (question.type == QuestionType.likertScale ||
            question.type == QuestionType.ranking)) {
      score += 20;
    }

    return score.clamp(0, 100);
  }

  int _scoreCompleteness(AnswerFeatures features, Question question) {
    int score = 30;

    // Open-ended questions require more words to be complete.
    if (question.type == QuestionType.openEnded) {
      if (features.wordCount >= 20) {
        score += 50;
      } else if (features.wordCount >= 10) {
        score += 30;
      } else if (features.wordCount >= 5) {
        score += 15;
      }
    } else {
      // MC/Likert/Ranking — brevity is expected.
      score += 50;
    }

    if (features.sentenceCount >= 2) score += 10;
    if (features.isVeryShort && question.type == QuestionType.openEnded) score -= 20;

    return score.clamp(0, 100);
  }

  int _scoreSpecificity(AnswerFeatures features) {
    int score = 30;

    if (features.containsPersonalExperience) score += 25;
    if (features.containsExamples) score += 20;
    if (features.lexicalDiversity > 0.7) score += 15;
    if (features.avgWordLength > 4.5) score += 10;
    if (features.isVeryShort) score -= 15;
    if (features.isSingleWord) score -= 20;

    return score.clamp(0, 100);
  }

  int _scoreConsistency({
    required AnswerFeatures features,
    required StudentCognitiveProfile profile,
    required bool contradictionDetected,
  }) {
    if (contradictionDetected) return 10;
    int score = 70; // default — assume consistent

    // Negation can be consistent (e.g., "I don't like maths" on a maths question).
    if (features.containsNegation && !features.containsAffirmation) score -= 10;

    return score.clamp(0, 100);
  }

  int _scoreConfidence(AnswerFeatures features, Question question) {
    int score = 50;

    if (features.containsReasoning) score += 20;
    if (features.containsPersonalExperience) score += 15;
    if (features.lexicalDiversity > 0.65) score += 10;
    if (features.looksRandom) return 0;
    if (features.isSingleWord && question.type == QuestionType.openEnded) score -= 30;

    return score.clamp(0, 100);
  }

  int _scoreEvidenceStrength(AnswerFeatures features, Question question) {
    int score = 35;

    // Open-ended questions with good depth are highest-value.
    if (question.type == QuestionType.openEnded) {
      if (features.wordCount >= 15 && features.containsReasoning) {
        score += 40;
      } else if (features.wordCount >= 8) {
        score += 20;
      }
    } else {
      // MC/Likert — direct signal, moderate strength.
      score += 30;
    }

    if (features.containsPersonalExperience) score += 15;
    if (features.isRepetition) score -= 30;
    if (features.looksRandom) return 0;

    return score.clamp(0, 100);
  }

  int _scoreReasoningDepth(AnswerFeatures features) {
    int score = 20;

    if (features.containsReasoning) score += 40;
    if (features.sentenceCount >= 3) score += 20;
    if (features.containsPersonalExperience) score += 10;
    if (features.wordCount >= 25) score += 10;
    if (features.isVeryShort) score = (score * 0.3).round();

    return score.clamp(0, 100);
  }

  int _scoreInformationDensity(AnswerFeatures features) {
    if (features.wordCount == 0) return 0;

    int score = 30;

    // Lexical diversity is the best proxy for information density.
    score += (features.lexicalDiversity * 40).round();

    // Longer average word length = more technical vocabulary.
    if (features.avgWordLength > 5.0) {
      score += 15;
    } else if (features.avgWordLength > 3.5) {
      score += 8;
    }

    if (features.isVeryShort) score -= 20;

    return score.clamp(0, 100);
  }

  int _scoreContextAwareness(AnswerFeatures features) {
    int score = 20;

    if (features.referencesContext) score += 50;
    if (features.containsPersonalExperience) score += 20;
    if (features.referencesContext && features.containsReasoning) score += 10;

    return score.clamp(0, 100);
  }

  // ─── Weighted composite ───────────────────────────────────────────────────

  int _computeTotal({
    required int relevance,
    required int completeness,
    required int specificity,
    required int consistency,
    required int confidence,
    required int evidenceStrength,
    required int reasoningDepth,
    required int informationDensity,
    required int contextAwareness,
  }) {
    // Weights sum to 1.0.
    const weights = {
      'relevance': 0.20,
      'completeness': 0.12,
      'specificity': 0.12,
      'consistency': 0.10,
      'confidence': 0.10,
      'evidenceStrength': 0.15,
      'reasoningDepth': 0.10,
      'informationDensity': 0.06,
      'contextAwareness': 0.05,
    };

    final weighted =
        relevance * weights['relevance']! +
        completeness * weights['completeness']! +
        specificity * weights['specificity']! +
        consistency * weights['consistency']! +
        confidence * weights['confidence']! +
        evidenceStrength * weights['evidenceStrength']! +
        reasoningDepth * weights['reasoningDepth']! +
        informationDensity * weights['informationDensity']! +
        contextAwareness * weights['contextAwareness']!;

    return weighted.round().clamp(0, 100);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  AnswerScore _zeroScore({
    required String questionId,
    required String answerText,
    required String reason,
    required DateTime scoredAt,
  }) => AnswerScore(
    questionId: questionId,
    answerText: answerText,
    relevance: 0,
    completeness: 0,
    specificity: 0,
    consistency: 0,
    confidence: 0,
    evidenceStrength: 0,
    reasoningDepth: 0,
    informationDensity: 0,
    contextAwareness: 0,
    total: 0,
    band: ScoreBand.invalid,
    scoringReason: reason,
    scoredAt: scoredAt,
  );

  String _buildReason({
    required ScoreBand band,
    required int total,
    required AnswerFeatures features,
    required bool contradictionDetected,
  }) {
    final parts = <String>[];
    if (features.containsReasoning) parts.add('has reasoning');
    if (features.containsPersonalExperience) parts.add('personal experience');
    if (features.containsExamples) parts.add('examples');
    if (features.isRepetition) parts.add('REPEATED');
    if (contradictionDetected) parts.add('CONTRADICTION');
    if (features.looksRandom) parts.add('RANDOM');
    return '${band.label} ($total/100): ${parts.isEmpty ? "standard answer" : parts.join(", ")}';
  }
}
