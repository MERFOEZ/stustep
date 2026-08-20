/// SAIE — IntentClassifier
///
/// The multi-signal intent classifier. Runs all detectors in parallel,
/// collects their [IntentScore] candidates, and assembles a final
/// [DecisionConfidence] distribution. The highest-scoring intent wins.
/// Context-free keyword matching is strictly forbidden.
library;

import 'package:stustep/features/saie/decision/answer_detector.dart';
import 'package:stustep/features/saie/decision/continuation_detector.dart';
import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/decision_confidence.dart';
import 'package:stustep/features/saie/decision/discussion_detector.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';
import 'package:stustep/features/saie/decision/question_detector.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IntentClassifier
// ─────────────────────────────────────────────────────────────────────────────

/// Runs all sub-detectors and assembles the final [DecisionConfidence].
///
/// Sub-detectors:
/// - [AnswerDetector] → [SupportedIntent.answerCurrentQuestion]
/// - [QuestionDetector] → [SupportedIntent.askAcademicQuestion],
///                        [SupportedIntent.requestExplanation]
/// - [DiscussionDetector] → greeting, discussion, skip, restart,
///                           recommendation, offTopic
///
/// Each detector produces a weighted score. All candidates are sorted
/// descending. The winner must exceed [DecisionConfidence.minimumThreshold]
/// to execute without clarification.
final class IntentClassifier {
  final AnswerDetector _answerDetector;
  final QuestionDetector _questionDetector;
  final DiscussionDetector _discussionDetector;
  final ContinuationDetector _continuationDetector;

  const IntentClassifier({
    AnswerDetector answerDetector = const AnswerDetector(),
    QuestionDetector questionDetector = const QuestionDetector(),
    DiscussionDetector discussionDetector = const DiscussionDetector(),
    ContinuationDetector continuationDetector = const ContinuationDetector(),
  })  : _answerDetector = answerDetector,
        _questionDetector = questionDetector,
        _discussionDetector = discussionDetector,
        _continuationDetector = continuationDetector;

  /// Classifies a student message and returns the full [DecisionConfidence].
  DecisionConfidence classify(
    MessageAnalysis analysis,
    ConversationContext context,
  ) {
    // Collect all candidate scores.
    final candidates = <IntentScore>[
      _answerDetector.score(analysis, context),
      // ── Continuation (context-primary) — must run before answer/discussion. ──
      _continuationDetector.scoreStart(analysis, context),
      _continuationDetector.scoreContinue(analysis, context),
      // ── Standard detectors ────────────────────────────────────────────────
      _questionDetector.scoreAcademic(analysis, context),
      _questionDetector.scoreExplanation(analysis, context),
      _discussionDetector.scoreGreeting(analysis, context),
      _discussionDetector.scoreDiscussion(analysis, context),
      _discussionDetector.scoreSkip(analysis, context),
      _discussionDetector.scoreRestart(analysis, context),
      _discussionDetector.scoreRecommendation(analysis, context),
      _discussionDetector.scoreOffTopic(analysis, context),
      // ── Question Understanding Layer detectors ────────────────────────────
      _questionDetector.scoreWordMeaning(analysis, context),
      _questionDetector.scoreUncertainty(analysis, context),
      _questionDetector.scoreWhyThisQuestion(analysis, context),
      _questionDetector.scoreAlternativeQuestion(analysis, context),
      _questionDetector.scoreExamples(analysis, context),
      // Unknown always has a base score; wins only when everything else is low.
      _unknownScore(candidates: []),
    ];

    // Re-inject unknown with context of other scores so it can self-adjust.
    final adjusted = _adjustUnknown(candidates);

    // Sort descending by score.
    adjusted.sort((a, b) => b.score.compareTo(a.score));

    return DecisionConfidence(
      candidates: adjusted,
      minimumThreshold: 0.65,
    );
  }

  /// The [SupportedIntent.unknown] score is the inverse of the max observed
  /// candidate score — i.e., it wins only when nothing else does.
  IntentScore _unknownScore({required List<IntentScore> candidates}) =>
      IntentScore(
        intent: SupportedIntent.unknown,
        score: 0.05,
        signals: const {'baseline': 0.05},
      );

  /// After all scores are computed, adjust [unknown] so it wins only when all
  /// other intents score below 0.40.
  List<IntentScore> _adjustUnknown(List<IntentScore> candidates) {
    final knownCandidates =
        candidates.where((c) => c.intent != SupportedIntent.unknown).toList();

    final maxOther = knownCandidates.isEmpty
        ? 0.0
        : knownCandidates.map((c) => c.score).reduce((a, b) => a > b ? a : b);

    // Unknown wins only when everything else is very weak.
    final unknownScore = maxOther < 0.30 ? 0.50 : 0.05;

    return [
      ...knownCandidates,
      IntentScore(
        intent: SupportedIntent.unknown,
        score: unknownScore,
        signals: {'max_other_score': maxOther},
      ),
    ];
  }
}
