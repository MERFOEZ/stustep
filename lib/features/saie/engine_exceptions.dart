/// SAIE — EngineExceptions
///
/// Typed exceptions thrown by the SAIEEngine public API.
/// All are pure Dart — no Flutter dependency.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Base
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for all SAIE engine exceptions.
sealed class SAIEException implements Exception {
  final String message;
  final StackTrace? stackTrace;
  const SAIEException(this.message, [this.stackTrace]);

  @override
  String toString() => 'SAIEException(${runtimeType.toString()}): $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// Specific exceptions
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when [SAIEEngine.processMessage] is called before [initialize].
final class EngineNotInitializedException extends SAIEException {
  const EngineNotInitializedException()
      : super('SAIEEngine has not been initialised. Call initialize() first.');
}

/// Thrown when the knowledge base fails to load.
final class KnowledgeBaseLoadException extends SAIEException {
  const KnowledgeBaseLoadException(super.message, [super.stackTrace]);
}

/// Thrown when a session save or restore operation fails.
final class SessionPersistenceException extends SAIEException {
  const SessionPersistenceException(super.message, [super.stackTrace]);
}

/// Thrown when [getRecommendation] is called before the assessment completes.
final class RecommendationNotReadyException extends SAIEException {
  const RecommendationNotReadyException()
      : super(
            'No recommendation is available yet. Complete the assessment first.');
}

/// Thrown when the student profile is requested before a session starts.
final class SessionNotStartedException extends SAIEException {
  const SessionNotStartedException()
      : super('No active session. Call startAssessment() first.');
}

/// Thrown when an invalid (empty/null) message is processed.
final class InvalidMessageException extends SAIEException {
  const InvalidMessageException(super.message);
}

/// Thrown when the engine is in an unexpected state for the requested operation.
final class SAIEEngineStateException extends SAIEException {
  const SAIEEngineStateException(super.message);
}
