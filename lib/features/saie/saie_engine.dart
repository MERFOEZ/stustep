/// SAIE — SAIEEngine
///
/// The ONLY public entry point for the entire SAIE AI system.
///
/// The Flutter UI layer MUST communicate exclusively through this class.
/// It coordinates:
///   - ConversationEngine     (student message pipeline)
///   - CognitiveDecisionEngine (intent + language detection)
///   - AdaptiveAssessmentEngine (question sequencing)
///   - MajorMatchingEngine    (vector similarity ranking)
///   - RecommendationEngine   (structured recommendation)
///   - ExplainableAIEngine    (decision reasoning)
///   - SessionManager         (persist / restore state)
///
/// Pure Dart. No Flutter. No Widgets. No HTTP. No OpenAI. No Network.
library;

import 'package:stustep/features/saie/analysis/answer_intelligence_engine.dart';
import 'package:stustep/features/saie/assessment/adaptive_assessment_engine.dart';
import 'package:stustep/features/saie/assessment/assessment_controller.dart';
import 'package:stustep/features/saie/assessment/assessment_progress.dart';
import 'package:stustep/features/saie/conversation/conversation_engine.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/decision/cognitive_decision_engine.dart';
import 'package:stustep/features/saie/decision/decision_confidence.dart';
import 'package:stustep/features/saie/engine_configuration.dart';
import 'package:stustep/features/saie/engine_events.dart';
import 'package:stustep/features/saie/engine_exceptions.dart';
import 'package:stustep/features/saie/engine_result.dart';
import 'package:stustep/features/saie/engine_state.dart';
import 'package:stustep/features/saie/explainable/explainable_ai_engine.dart';
import 'package:stustep/features/saie/llm/llm_factory.dart';
import 'package:stustep/features/saie/llm/llm_service.dart';
import 'package:stustep/features/saie/matching/major_matching_engine.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/recommendation/recommendation_engine.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';
import 'package:stustep/features/saie/session_manager.dart';
import 'package:stustep/features/saie/session_snapshot.dart';
import 'package:stustep/features/gemini_config.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SAIEEngine
// ─────────────────────────────────────────────────────────────────────────────

/// The single public facade of the SAIE system.
///
/// All Flutter UI code goes through this API exclusively.
final class SAIEEngine {
  // ── Wiring ─────────────────────────────────────────────────────────────────
  final EngineConfiguration _config;
  final SessionManager _sessionManager;

  // Internal engines — constructed lazily after initialization.
  late final ConversationEngine _conversationEngine;
  late final List<Major> _allMajors;
  late final List<Question> _allQuestions;

  // ── Mutable state (always replaced atomically) ──────────────────────────────
  EngineState _state;

  // ── Event log ───────────────────────────────────────────────────────────────
  final List<EngineEvent> _events = [];

  static const _uuid = Uuid();

  // ── Constructor ─────────────────────────────────────────────────────────────

  /// Creates a [SAIEEngine].
  ///
  /// [majors] and [questions] are the pre-loaded knowledge base lists.
  /// Inject a [SessionPersistenceAdapter] via [sessionManager] to enable
  /// cross-session persistence. Defaults to in-memory only.
  SAIEEngine({
    required EngineConfiguration config,
    required List<Major> majors,
    required List<Question> questions,
    SessionManager? sessionManager,
  })  : _config = config,
        _sessionManager = sessionManager ?? SessionManager(),
        _allMajors = majors,
        _allQuestions = questions,
        _state = EngineState.initial(
          sessionId:
              config.sessionId.isEmpty ? const Uuid().v4() : config.sessionId,
          studentId: config.studentId,
        );

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Initialise all internal engines and transition to [EngineStatus.ready].
  ///
  /// Must be called once before any other method.
  Future<void> initialize() async {
    _assertNotStatus(EngineStatus.initialising);

    _state = _state.copyWith(status: EngineStatus.initialising);

    try {
      _conversationEngine = ConversationEngine.create(
        decisionEngine: const CognitiveDecisionEngine(),
        answerEngine: const AnswerIntelligenceEngine(),
        assessmentEngine: const AdaptiveAssessmentEngine(),
        assessmentController: const AssessmentController(),
        matchingEngine: const MajorMatchingEngine(),
        recommendationEngine: const RecommendationEngine(),
        explainableEngine: const ExplainableAIEngine(),
        // Use Gemini if configured, otherwise run offline
        llmService: GeminiConfig.isConfigured
            ? const LlmFactory().create(GeminiConfig.config)
            : LlmService.disabled(),
        allMajors: _allMajors,
        allQuestions: _allQuestions,
        policy: _config.conversationPolicy,
      );

      _state = _state.copyWith(status: EngineStatus.ready);

      _emit(EngineEventType.engineInitialised);
    } catch (e, st) {
      throw KnowledgeBaseLoadException(
        'Engine initialization failed: $e',
        st,
      );
    }
  }

  /// Start a new assessment session. Returns an [EngineResult] containing
  /// the greeting and first question.
  Future<EngineResult> startAssessment() async {
    _assertInitialised();

    _state = _state.copyWith(
      status: EngineStatus.assessing,
      lastActivityAt: DateTime.now().toUtc(),
    );

    const greeting = 'مرحباً! أنا مستشارك الأكاديمي الذكي. لنبدأ تقييمك الأكاديمي الآن.';

    _emit(EngineEventType.assessmentStarted);

    return _buildResult(
      response: greeting,
      event: _events.last,
    );
  }

  /// Process one student message.
  ///
  /// This is the primary interaction method.
  Future<EngineResult> processMessage(String message) async {
    _assertInitialised();
    _assertSessionStarted();
    _validateMessage(message);

    final output = await _conversationEngine.process(
      studentMessage: message,
      studentId: _state.studentId,
      memory: _state.memory,
      phase: _state.phase,
      profile: _state.profile,
      language: _state.language,
    );

    // ── Atomically update engine state ─────────────────────────────────────
    final newState = _state.copyWith(
      memory: output.updatedMemory,
      phase: output.updatedPhase,
      language: output.updatedLanguage,
      profile: output.updatedProfile,
      assessmentProgress:
          output.updatedMemory.assessmentState?.progress ??
          _state.assessmentProgress,
      assessmentState: output.updatedMemory.assessmentState,
      activeQuestion:
          output.updatedMemory.assessmentState?.activeQuestion,
      recommendationReport:
          output.updatedMemory.recommendationReport ??
          _state.recommendationReport,
      recommendationAvailable: output.recommendationGenerated ||
          _state.recommendationAvailable,
      status: output.recommendationGenerated
          ? EngineStatus.recommending
          : EngineStatus.assessing,
      lastActivityAt: DateTime.now().toUtc(),
    );

    _state = newState;

    // ── Emit events ────────────────────────────────────────────────────────
    if (output.assessmentAdvanced) {
      _emit(EngineEventType.answerAccepted,
          question: _state.activeQuestion,
          progress: _state.assessmentProgress);
    }
    if (output.recommendationGenerated) {
      _emit(EngineEventType.recommendationGenerated,
          recommendation: _state.recommendationReport);
    }

    // ── Auto-persist if configured ────────────────────────────────────────
    if (_config.autoPersist) {
      await _persistCurrentState();
    }

    return _buildResult(
      response: output.response,
      event: _events.isNotEmpty ? _events.last : null,
    );
  }

  /// Continue a discussion about the existing recommendation or academic topics.
  /// Delegates to [processMessage] — the ConversationRouter handles intent.
  Future<EngineResult> continueDiscussion(String message) async =>
      processMessage(message);

  /// Returns the [RecommendationReport] when ready.
  ///
  /// Throws [RecommendationNotReadyException] if the assessment is incomplete.
  Future<RecommendationReport> getRecommendation() async {
    _assertInitialised();
    final report = _state.recommendationReport;
    if (report == null || !_state.recommendationAvailable) {
      throw const RecommendationNotReadyException();
    }
    return report;
  }

  /// Returns the current [StudentCognitiveProfile].
  Future<StudentCognitiveProfile> getCurrentProfile() async {
    _assertInitialised();
    return _state.profile;
  }

  /// Returns the current [AssessmentProgress].
  Future<AssessmentProgress> getAssessmentProgress() async {
    _assertInitialised();
    return _state.assessmentProgress;
  }

  /// Persists the current session state.
  Future<void> saveSession() async {
    _assertInitialised();
    await _persistCurrentState();
    _emit(EngineEventType.sessionSaved);
  }

  /// Restores a previously saved session for the configured [studentId].
  ///
  /// After loading, the engine resumes from the exact saved state.
  Future<void> loadSession() async {
    _assertInitialised();

    final snapshot = await _sessionManager.load(_state.sessionId);
    if (snapshot == null) return;

    _state = _state.copyWith(
      profile: snapshot.profile,
      memory: snapshot.memory,
      phase: snapshot.phase,
      language: snapshot.language,
      assessmentState: snapshot.assessmentState,
      assessmentProgress: snapshot.assessmentState?.progress ??
          AssessmentProgress.initial(),
      activeQuestion: snapshot.assessmentState?.activeQuestion,
      recommendationReport: snapshot.recommendationReport,
      recommendationAvailable: snapshot.recommendationAvailable,
      status: snapshot.assessmentState != null
          ? EngineStatus.assessing
          : EngineStatus.ready,
      lastActivityAt: snapshot.savedAt,
    );

    _emit(EngineEventType.sessionRestored);
  }

  /// Resets the engine to its initial state.
  /// Does NOT delete persisted snapshots — call [saveSession] with reset state first.
  Future<void> reset() async {
    _state = EngineState.initial(
      sessionId: _uuid.v4(),
      studentId: _config.studentId,
    ).copyWith(status: EngineStatus.ready);
    _events.clear();
    _emit(EngineEventType.engineReset);
  }

  // ── Read-only accessors ─────────────────────────────────────────────────────

  /// The current [EngineState]. Read-only view for diagnostics.
  EngineState get currentState => _state;

  /// All events emitted this session.
  List<EngineEvent> get events => List.unmodifiable(_events);

  /// Current session ID.
  String get sessionId => _state.sessionId;

  /// True if the engine has been initialised.
  bool get isInitialised => _state.status != EngineStatus.uninitialised &&
      _state.status != EngineStatus.initialising;

  // ── Private helpers ─────────────────────────────────────────────────────────

  EngineResult _buildResult({
    required String response,
    EngineEvent? event,
  }) {
    final state = _state;
    return EngineResult(
      assistantResponse: response,
      currentPhase: state.phase.stage,
      assessmentProgress: state.assessmentProgress,
      confidence: _buildConfidence(),
      recommendationAvailable: state.recommendationAvailable,
      currentQuestion: state.activeQuestion,
      currentLanguage: state.language,
      studentSnapshot: EngineStudentSnapshot.fromProfile(state.profile),
      event: event,
      recommendationReport: state.recommendationReport,
    );
  }

  /// Builds an empty-but-valid [DecisionConfidence] for the current turn.
  ///
  /// The ConversationEngine internally uses its own full confidence; this
  /// provides a lightweight read-only summary at the EngineResult boundary.
  DecisionConfidence _buildConfidence() => const DecisionConfidence(
    candidates: [],
    minimumThreshold: 0.65,
  );

  Future<void> _persistCurrentState() async {
    final snapshot = SessionSnapshot(
      sessionId: _state.sessionId,
      studentId: _state.studentId,
      profile: _state.profile,
      memory: _state.memory,
      phase: _state.phase,
      language: _state.language,
      assessmentState: _state.assessmentState,
      recommendationReport: _state.recommendationReport,
      recommendationAvailable: _state.recommendationAvailable,
      savedAt: DateTime.now().toUtc(),
    );
    await _sessionManager.save(snapshot);
  }

  void _emit(
    EngineEventType type, {
    Question? question,
    RecommendationReport? recommendation,
    AssessmentProgress? progress,
    ConversationStage? stage,
    String? payload,
  }) {
    _events.add(EngineEvent(
      eventId: _uuid.v4(),
      type: type,
      occurredAt: DateTime.now().toUtc(),
      question: question,
      recommendation: recommendation,
      progress: progress,
      stage: stage,
      payload: payload,
    ));
  }

  void _assertInitialised() {
    if (!isInitialised) throw const EngineNotInitializedException();
  }

  void _assertSessionStarted() {
    if (_state.status == EngineStatus.uninitialised ||
        (_state.status == EngineStatus.ready &&
            _state.memory.history.turns.isEmpty)) {
      throw const SessionNotStartedException();
    }
  }

  void _assertNotStatus(EngineStatus status) {
    if (_state.status == status) {
      throw SAIEEngineStateException(
          'Engine is already in status: ${status.name}');
    }
  }

  void _validateMessage(String message) {
    if (message.trim().isEmpty) {
      throw const InvalidMessageException('Message must not be empty.');
    }
  }
}
