/// SAIE — ISessionRepository
///
/// Abstract contract for assessment session persistence.
library;

import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/models/conversation_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ISessionRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for persisting and retrieving [ConversationState] sessions.
abstract interface class ISessionRepository {
  /// Saves or updates a [ConversationState] in storage.
  Future<Result<void>> saveSession(ConversationState session);

  /// Loads a [ConversationState] by its [sessionId].
  Future<Result<ConversationState>> loadSession(String sessionId);

  /// Returns all sessions belonging to a [studentId].
  Future<Result<List<ConversationState>>> loadSessionsForStudent(
    String studentId,
  );

  /// Deletes the session with the given [sessionId].
  Future<Result<void>> deleteSession(String sessionId);

  /// Returns the currently active session for [studentId], or null.
  Future<Result<ConversationState?>> getActiveSession(String studentId);

  /// Returns `true` if a session with [sessionId] exists.
  Future<bool> exists(String sessionId);
}
