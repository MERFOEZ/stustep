/// SAIE — ConversationRoute
///
/// Routes an incoming message to the correct handler.
/// This is the single decision authority for "what do we do with this message?"
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/conversation/conversation_context.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/decision/semantic_message_classifier.dart';
import 'package:stustep/features/saie/decision/supported_intent.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationRoute enum
// ─────────────────────────────────────────────────────────────────────────────

enum ConversationRoute {
  /// Student answered the active question → process through Assessment Engine.
  continueAssessment,

  /// Student asked an academic/domain question → answer then return.
  academicDiscussion,

  /// Student is asking about or discussing the recommendation output.
  recommendationDiscussion,

  /// Student asked for clarification of a term or concept.
  clarification,

  /// Student greeted the system.
  greeting,

  /// Student asked for help.
  help,

  /// Student wants to restart from the beginning.
  restartAssessment,

  /// Student wants to skip the current question.
  skipQuestion,

  /// Student said goodbye.
  goodbye,

  /// Student asks what a specific word/term in the question means.
  wordMeaning,

  /// Student expressed uncertainty — simplify and encourage.
  uncertainty,

  /// Student asked why this question is being asked.
  whyThisQuestion,

  /// Student wants a different question (same domain preferred).
  alternativeQuestion,

  /// Student requested examples relevant to the question.
  questionExamples,

  /// Cannot be classified.
  unknown,
}

extension ConversationRouteX on ConversationRoute {
  bool get resumesAssessment =>
      this == ConversationRoute.continueAssessment ||
      this == ConversationRoute.skipQuestion;
}

// ─────────────────────────────────────────────────────────────────────────────
// RouteDecision
// ─────────────────────────────────────────────────────────────────────────────

/// The output of the router: which route to take and why.
final class RouteDecision extends Equatable {
  final ConversationRoute route;
  final SupportedIntent sourceIntent;
  final String rationale;
  final bool pausedAssessment;
  final bool willReturnToAssessment;

  const RouteDecision({
    required this.route,
    required this.sourceIntent,
    required this.rationale,
    required this.pausedAssessment,
    required this.willReturnToAssessment,
  });

  factory RouteDecision.fromJson(Map<String, dynamic> json) => RouteDecision(
    route: ConversationRoute.values.byName(json['route'] as String),
    sourceIntent:
        SupportedIntent.values.byName(json['source_intent'] as String),
    rationale: json['rationale'] as String,
    pausedAssessment: json['paused_assessment'] as bool,
    willReturnToAssessment: json['will_return_to_assessment'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'route': route.name,
    'source_intent': sourceIntent.name,
    'rationale': rationale,
    'paused_assessment': pausedAssessment,
    'will_return_to_assessment': willReturnToAssessment,
  };

  RouteDecision copyWith({
    ConversationRoute? route,
    SupportedIntent? sourceIntent,
    String? rationale,
    bool? pausedAssessment,
    bool? willReturnToAssessment,
  }) => RouteDecision(
    route: route ?? this.route,
    sourceIntent: sourceIntent ?? this.sourceIntent,
    rationale: rationale ?? this.rationale,
    pausedAssessment: pausedAssessment ?? this.pausedAssessment,
    willReturnToAssessment:
        willReturnToAssessment ?? this.willReturnToAssessment,
  );

  @override
  List<Object?> get props => [route, sourceIntent];
}

// ─────────────────────────────────────────────────────────────────────────────
// ConversationRouter
// ─────────────────────────────────────────────────────────────────────────────

/// Maps every [SupportedIntent] → [ConversationRoute] based on context.
final class ConversationRouter {
  const ConversationRouter();

  /// Routes the message and returns a [RouteDecision].
  RouteDecision route(ConversationContext ctx) {
    // ══════════════════════════════════════════════════════════════════════════
    // PHASE 1: SEMANTIC MESSAGE TYPE CHECK (Message Understanding Layer)
    // ══════════════════════════════════════════════════════════════════════════
    //
    // The SemanticMessageType is the authoritative understanding of the
    // student's message. It is computed in MessageAnalyzerService BEFORE any
    // scoring and reflects the true intent.
    //
    // GUARANTEE: If semanticType.blocksAssessmentAdvancement == true, this
    // router MUST NOT route to ConversationRoute.continueAssessment.
    // This prevents clarification requests from advancing the assessment.
    //
    final semanticType = ctx.decision.messageAnalysis?.semanticType;
    if (semanticType != null && semanticType != SemanticMessageType.unknown) {
      final semanticRoute = _routeBySemanticType(semanticType, ctx);
      if (semanticRoute != null) return semanticRoute;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // PHASE 2: INTENT-SCORE BASED ROUTING (legacy fallback)
    // ══════════════════════════════════════════════════════════════════════════
    //
    // Only reached when semantic type is unknown or unroutable.
    // The intent system is a secondary signal, not the primary authority.
    //
    final intent = ctx.decision.detectedIntent;
    final phase = ctx.phase;

    return switch (intent) {
      SupportedIntent.answerCurrentQuestion =>
        _answerRoute(ctx),
      // ── Continuation intents: directly trigger assessment pipeline ──────────
      SupportedIntent.startAssessment =>
        RouteDecision(
          route: ConversationRoute.continueAssessment,
          sourceIntent: intent,
          rationale:
              'Student wants to start the assessment — routing to assessment pipeline.',
          pausedAssessment: false,
          willReturnToAssessment: true,
        ),
      SupportedIntent.continueAssessment =>
        RouteDecision(
          route: ConversationRoute.continueAssessment,
          sourceIntent: intent,
          rationale:
              'Student wants to continue the assessment — routing to next question.',
          pausedAssessment: false,
          willReturnToAssessment: true,
        ),
      // ── Standard intents ────────────────────────────────────────────────────
      SupportedIntent.askAcademicQuestion =>
        _academicDiscussionRoute(ctx),
      SupportedIntent.requestExplanation =>
        _clarificationRoute(ctx),
      SupportedIntent.greeting =>
        RouteDecision(
          route: ConversationRoute.greeting,
          sourceIntent: intent,
          rationale: 'Student sent a greeting.',
          pausedAssessment: false,
          willReturnToAssessment: phase.stage.canReceiveAnswer,
        ),
      SupportedIntent.generalDiscussion =>
        _generalDiscussionRoute(ctx),
      SupportedIntent.skipQuestion =>
        RouteDecision(
          route: ConversationRoute.skipQuestion,
          sourceIntent: intent,
          rationale: 'Student wants to skip the current question.',
          pausedAssessment: false,
          willReturnToAssessment: true,
        ),
      SupportedIntent.restartAssessment =>
        RouteDecision(
          route: ConversationRoute.restartAssessment,
          sourceIntent: intent,
          rationale: 'Student requested assessment restart.',
          pausedAssessment: false,
          willReturnToAssessment: true,
        ),
      SupportedIntent.requestRecommendation =>
        RouteDecision(
          route: ctx.hasRecommendation
              ? ConversationRoute.recommendationDiscussion
              : ConversationRoute.continueAssessment,
          sourceIntent: intent,
          rationale: ctx.hasRecommendation
              ? 'Student is discussing the existing recommendation.'
              : 'Student requested a recommendation — assessment must complete first.',
          pausedAssessment: ctx.hasRecommendation,
          willReturnToAssessment: !ctx.hasRecommendation,
        ),
      SupportedIntent.offTopic =>
        RouteDecision(
          route: ConversationRoute.unknown,
          sourceIntent: intent,
          rationale: 'Off-topic message — politely redirect.',
          pausedAssessment: false,
          willReturnToAssessment: phase.stage.canReceiveAnswer,
        ),
      // ── Question Understanding Layer intents ─────────────────────────────
      SupportedIntent.askWordMeaning =>
        _qulRoute(intent, ConversationRoute.wordMeaning,
            'Student asking word meaning — explain then repeat question.', ctx),
      SupportedIntent.expressUncertainty =>
        _qulRoute(intent, ConversationRoute.uncertainty,
            'Student uncertain — simplify and encourage.', ctx),
      SupportedIntent.askWhyThisQuestion =>
        _qulRoute(intent, ConversationRoute.whyThisQuestion,
            'Student asks why this question — explain purpose then repeat.', ctx),
      SupportedIntent.requestAlternativeQuestion =>
        _alternativeQuestionRoute(ctx),
      SupportedIntent.requestExamples =>
        _qulRoute(intent, ConversationRoute.questionExamples,
            'Student requests examples — provide then repeat question.', ctx),
      SupportedIntent.unknown =>
        RouteDecision(
          route: ConversationRoute.unknown,
          sourceIntent: intent,
          rationale: 'Intent unknown — ask for clarification.',
          pausedAssessment: false,
          willReturnToAssessment: phase.stage.canReceiveAnswer,
        ),
    };
  }

  // ─── Semantic-type-first routing (Message Understanding Layer) ─────────────

  /// Maps [SemanticMessageType] → [RouteDecision].
  /// Returns null only for [SemanticMessageType.unknown] (falls through to
  /// intent-score routing).
  RouteDecision? _routeBySemanticType(
    SemanticMessageType type,
    ConversationContext ctx,
  ) {
    return switch (type) {
      SemanticMessageType.answer =>
        // Only route as answer if question is active.
        ctx.hasActiveQuestion ? _answerRoute(ctx) : null,

      SemanticMessageType.optionsRequest ||
      SemanticMessageType.exampleRequest =>
        _qulRoute(
          SupportedIntent.requestExamples,
          ConversationRoute.questionExamples,
          'Student wants options/examples — show them then repeat question.',
          ctx,
        ),

      SemanticMessageType.definitionRequest =>
        _qulRoute(
          SupportedIntent.askWordMeaning,
          ConversationRoute.wordMeaning,
          'Student asking word/term meaning — explain then repeat question.',
          ctx,
        ),

      SemanticMessageType.clarificationRequest ||
      SemanticMessageType.simplificationRequest =>
        _clarificationRoute(ctx),

      SemanticMessageType.whyRequest =>
        _qulRoute(
          SupportedIntent.askWhyThisQuestion,
          ConversationRoute.whyThisQuestion,
          'Student asks why this question — explain purpose then repeat.',
          ctx,
        ),

      SemanticMessageType.uncertaintyExpression =>
        _qulRoute(
          SupportedIntent.expressUncertainty,
          ConversationRoute.uncertainty,
          'Student uncertain — simplify and encourage.',
          ctx,
        ),

      SemanticMessageType.academicQuestion =>
        _academicDiscussionRoute(ctx),

      SemanticMessageType.greeting =>
        RouteDecision(
          route: ConversationRoute.greeting,
          sourceIntent: SupportedIntent.greeting,
          rationale: 'Student sent a greeting.',
          pausedAssessment: false,
          willReturnToAssessment: ctx.phase.stage.canReceiveAnswer,
        ),

      SemanticMessageType.skipRequest =>
        RouteDecision(
          route: ConversationRoute.skipQuestion,
          sourceIntent: SupportedIntent.skipQuestion,
          rationale: 'Student wants to skip the current question.',
          pausedAssessment: false,
          willReturnToAssessment: true,
        ),

      SemanticMessageType.restartRequest =>
        RouteDecision(
          route: ConversationRoute.restartAssessment,
          sourceIntent: SupportedIntent.restartAssessment,
          rationale: 'Student requested assessment restart.',
          pausedAssessment: false,
          willReturnToAssessment: true,
        ),

      SemanticMessageType.recommendationRequest =>
        RouteDecision(
          route: ctx.hasRecommendation
              ? ConversationRoute.recommendationDiscussion
              : ConversationRoute.continueAssessment,
          sourceIntent: SupportedIntent.requestRecommendation,
          rationale: ctx.hasRecommendation
              ? 'Student is discussing the existing recommendation.'
              : 'Student requested a recommendation — assessment must complete first.',
          pausedAssessment: ctx.hasRecommendation,
          willReturnToAssessment: !ctx.hasRecommendation,
        ),

      SemanticMessageType.farewell =>
        RouteDecision(
          route: ConversationRoute.goodbye,
          sourceIntent: SupportedIntent.unknown,
          rationale: 'Student said goodbye.',
          pausedAssessment: false,
          willReturnToAssessment: false,
        ),

      SemanticMessageType.unknown => null,
    };
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  RouteDecision _answerRoute(ConversationContext ctx) {
    if (!ctx.hasActiveQuestion) {
      // No active question → treat as general message.
      return RouteDecision(
        route: ConversationRoute.unknown,
        sourceIntent: SupportedIntent.answerCurrentQuestion,
        rationale: 'Answer detected but no active question exists.',
        pausedAssessment: false,
        willReturnToAssessment: false,
      );
    }
    return const RouteDecision(
      route: ConversationRoute.continueAssessment,
      sourceIntent: SupportedIntent.answerCurrentQuestion,
      rationale: 'Valid answer to active question.',
      pausedAssessment: false,
      willReturnToAssessment: true,
    );
  }

  RouteDecision _academicDiscussionRoute(ConversationContext ctx) {
    final willReturn = ctx.policy.autoReturnAfterDiscussion &&
        ctx.phase.stage.canReceiveAnswer;
    final exceedsDepth =
        ctx.phase.discussionDepth >= ctx.policy.maxDiscussionDepth;

    if (exceedsDepth) {
      return RouteDecision(
        route: ConversationRoute.continueAssessment,
        sourceIntent: SupportedIntent.askAcademicQuestion,
        rationale: 'Max discussion depth reached — returning to assessment.',
        pausedAssessment: false,
        willReturnToAssessment: true,
      );
    }

    return RouteDecision(
      route: ConversationRoute.academicDiscussion,
      sourceIntent: SupportedIntent.askAcademicQuestion,
      rationale: 'Academic question — answer then return to assessment.',
      pausedAssessment: true,
      willReturnToAssessment: willReturn,
    );
  }

  RouteDecision _clarificationRoute(ConversationContext ctx) => RouteDecision(
    route: ConversationRoute.clarification,
    sourceIntent: SupportedIntent.requestExplanation,
    rationale:
        'Clarification requested — explain, then repeat question.',
    pausedAssessment: false,
    willReturnToAssessment: ctx.policy.repeatQuestionAfterClarification,
  );

  RouteDecision _generalDiscussionRoute(ConversationContext ctx) {
    final exceedsInterruption =
        ctx.phase.interruptionCount >= ctx.policy.maxInterruptionCount;
    return RouteDecision(
      route: exceedsInterruption
          ? ConversationRoute.continueAssessment
          : ConversationRoute.academicDiscussion,
      sourceIntent: SupportedIntent.generalDiscussion,
      rationale: exceedsInterruption
          ? 'Max interruptions reached — returning to assessment.'
          : 'General discussion — brief response then return.',
      pausedAssessment: !exceedsInterruption,
      willReturnToAssessment: true,
    );
  }

  /// Generic route for all Question Understanding Layer intents.
  /// All five QUL routes share the same properties:
  ///  - never pause the assessment
  ///  - always return to the same question
  RouteDecision _qulRoute(
    SupportedIntent intent,
    ConversationRoute route,
    String rationale,
    ConversationContext ctx,
  ) {
    if (!ctx.hasActiveQuestion) {
      // No question active — cannot explain/encourage anything specific.
      return RouteDecision(
        route: ConversationRoute.unknown,
        sourceIntent: intent,
        rationale: 'QUL intent but no active question — redirecting.',
        pausedAssessment: false,
        willReturnToAssessment: false,
      );
    }
    return RouteDecision(
      route: route,
      sourceIntent: intent,
      rationale: rationale,
      pausedAssessment: false,
      willReturnToAssessment: true,
    );
  }

  /// Routes requestAlternativeQuestion — delegates to skip path.
  RouteDecision _alternativeQuestionRoute(ConversationContext ctx) {
    if (!ctx.hasActiveQuestion) {
      return RouteDecision(
        route: ConversationRoute.unknown,
        sourceIntent: SupportedIntent.requestAlternativeQuestion,
        rationale: 'Alternative question requested but no active question.',
        pausedAssessment: false,
        willReturnToAssessment: false,
      );
    }
    return const RouteDecision(
      route: ConversationRoute.alternativeQuestion,
      sourceIntent: SupportedIntent.requestAlternativeQuestion,
      rationale:
          'Student wants different question — same domain preferred via engine.',
      pausedAssessment: false,
      willReturnToAssessment: true,
    );
  }
}
