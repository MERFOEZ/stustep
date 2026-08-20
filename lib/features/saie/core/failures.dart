/// SAIE — Core Failure Types
///
/// Represents typed, recoverable failures across all SAIE layers.
/// Follows the Either monad pattern used with [Result] wrappers.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Base Failure
// ─────────────────────────────────────────────────────────────────────────────

/// Abstract base class for all typed failures within SAIE.
///
/// Every failure carries a human-readable [message] and an optional
/// [stackTrace] for debugging. Never use raw exceptions across layer
/// boundaries — always convert to a [Failure] subtype.
abstract class Failure extends Equatable {
  /// Human-readable description of the failure.
  final String message;

  /// Optional Dart stack trace for debugging.
  final StackTrace? stackTrace;

  const Failure({required this.message, this.stackTrace});

  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// Knowledge Base Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Knowledge base asset could not be located or parsed.
class KnowledgeLoadFailure extends Failure {
  /// The asset path that failed to load.
  final String assetPath;

  const KnowledgeLoadFailure({
    required super.message,
    required this.assetPath,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, assetPath];
}

/// A required field in a knowledge base JSON record is absent or malformed.
class KnowledgeParseFailure extends Failure {
  /// The JSON key or field name that caused the parse failure.
  final String fieldName;

  const KnowledgeParseFailure({
    required super.message,
    required this.fieldName,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, fieldName];
}

// ─────────────────────────────────────────────────────────────────────────────
// Reasoning Engine Failures
// ─────────────────────────────────────────────────────────────────────────────

/// The reasoning engine encountered an invalid or incomplete state.
class EngineStateFailure extends Failure {
  const EngineStateFailure({required super.message, super.stackTrace});
}

/// The engine could not generate a valid recommendation from available evidence.
class InsufficientEvidenceFailure extends Failure {
  /// Minimum number of evidence signals required.
  final int minimumRequired;

  /// Actual number of evidence signals present.
  final int actualCount;

  const InsufficientEvidenceFailure({
    required super.message,
    required this.minimumRequired,
    required this.actualCount,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, minimumRequired, actualCount];
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistence Failures
// ─────────────────────────────────────────────────────────────────────────────

/// A session could not be persisted or restored from local storage.
class PersistenceFailure extends Failure {
  const PersistenceFailure({required super.message, super.stackTrace});
}

// ─────────────────────────────────────────────────────────────────────────────
// Validation Failures
// ─────────────────────────────────────────────────────────────────────────────

/// Input validation failed; the operation should not proceed.
class ValidationFailure extends Failure {
  /// The specific field or value that failed validation.
  final String field;

  const ValidationFailure({
    required super.message,
    required this.field,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, field];
}

// ─────────────────────────────────────────────────────────────────────────────
// Network Failures (future-proof; currently unused in offline mode)
// ─────────────────────────────────────────────────────────────────────────────

/// Network call failed; not expected in offline operation but preserved for
/// optional cloud sync in future iterations.
class NetworkFailure extends Failure {
  /// HTTP status code, if available.
  final int? statusCode;

  const NetworkFailure({
    required super.message,
    this.statusCode,
    super.stackTrace,
  });

  @override
  List<Object?> get props => [message, statusCode];
}
