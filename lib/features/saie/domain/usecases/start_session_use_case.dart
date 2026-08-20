/// SAIE — StartSessionUseCase
///
/// Initializes a new [ConversationState] for an existing student.
library;

import 'package:uuid/uuid.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/core/failures.dart';
import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/domain/repositories/i_session_repository.dart';
import 'package:stustep/features/saie/domain/repositories/i_student_repository.dart';
import 'package:stustep/features/saie/domain/usecases/use_case_base.dart';
import 'package:stustep/features/saie/models/assessment_goal.dart';
import 'package:stustep/features/saie/models/conversation_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Params
// ─────────────────────────────────────────────────────────────────────────────

/// Parameters required to start a new assessment session.
final class StartSessionParams {
  /// The student's unique ID.
  final String studentId;

  /// The goal for this session.
  final AssessmentGoal goal;

  const StartSessionParams({
    required this.studentId,
    required this.goal,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// UseCase
// ─────────────────────────────────────────────────────────────────────────────

/// Creates and persists a new [ConversationState] for the given student.
///
/// Validates:
/// - The student exists in storage.
/// - The student does not already have an active session.
final class StartSessionUseCase
    extends UseCase<StartSessionParams, ConversationState> {
  final IStudentRepository _studentRepository;
  final ISessionRepository _sessionRepository;
  final Uuid _uuid;

  StartSessionUseCase({
    required IStudentRepository studentRepository,
    required ISessionRepository sessionRepository,
    Uuid? uuid,
  }) : _studentRepository = studentRepository,
       _sessionRepository = sessionRepository,
       _uuid = uuid ?? const Uuid();

  @override
  Future<Result<ConversationState>> call(StartSessionParams params) async {
    // 1. Verify student exists.
    final twinResult = await _studentRepository.loadDigitalTwin(
      params.studentId,
    );
    if (twinResult.isFailure) return Result.failure(twinResult.failure);

    final twin = twinResult.value;

    // 2. Guard: only one active session at a time.
    if (twin.hasActiveSession) {
      return Result.failure(
        EngineStateFailure(
          message:
              'Student "${params.studentId}" already has an active session '
              '(${twin.activeSessionId}). Complete or abandon it first.',
        ),
      );
    }

    // 3. Build the initial conversation state.
    final now = DateTime.now().toUtc();
    final sessionId = _uuid.v4();

    final session = ConversationState(
      sessionId: sessionId,
      studentId: params.studentId,
      goal: params.goal,
      phase: AssessmentPhase.onboarding,
      status: SessionStatus.active,
      messages: const [],
      collectedEvidence: const [],
      askedQuestionIds: const [],
      domainConfidences: const {},
      recommendations: const [],
      createdAt: now,
      updatedAt: now,
    );

    // 4. Persist the session.
    final saveResult = await _sessionRepository.saveSession(session);
    if (saveResult.isFailure) return Result.failure(saveResult.failure);

    // 5. Update the Digital Twin with the new active session.
    final updatedTwin = twin.copyWith(
      activeSessionId: sessionId,
      sessionIds: [...twin.sessionIds, sessionId],
      lastSyncedAt: now,
    );
    final twinSave = await _studentRepository.saveDigitalTwin(updatedTwin);
    if (twinSave.isFailure) return Result.failure(twinSave.failure);

    return Result.success(session);
  }
}
