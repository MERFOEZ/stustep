/// SAIE — UseCase Base Classes
///
/// Provides typed base classes for all SAIE use cases.
/// Every use case has a single [call] method (execute pattern).
library;

import 'package:stustep/features/saie/core/result.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UseCase<Params, ReturnType>
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for use cases that require parameters and return a [Result].
///
/// ```dart
/// class StartSessionUseCase extends UseCase<StartSessionParams, ConversationState> {
///   @override
///   Future<Result<ConversationState>> call(StartSessionParams params) async { ... }
/// }
/// ```
abstract base class UseCase<Params, ReturnType> {
  /// Executes the use case with [params].
  Future<Result<ReturnType>> call(Params params);
}

// ─────────────────────────────────────────────────────────────────────────────
// NoParamUseCase<ReturnType>
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for use cases that require no parameters.
abstract base class NoParamUseCase<ReturnType> {
  /// Executes the use case.
  Future<Result<ReturnType>> call();
}

// ─────────────────────────────────────────────────────────────────────────────
// StreamUseCase<Params, ReturnType>
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for use cases that emit a [Stream] of [Result] values.
abstract base class StreamUseCase<Params, ReturnType> {
  /// Executes the use case and returns a stream of results.
  Stream<Result<ReturnType>> call(Params params);
}

// ─────────────────────────────────────────────────────────────────────────────
// NoParams
// ─────────────────────────────────────────────────────────────────────────────

/// Sentinel type for use cases that take no parameters.
///
/// Use [NoParams.instance] instead of instantiating directly.
final class NoParams {
  const NoParams._();

  /// Singleton instance.
  static const NoParams instance = NoParams._();
}
