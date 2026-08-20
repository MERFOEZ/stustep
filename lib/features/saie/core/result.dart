/// SAIE — Result Type
///
/// A lightweight discriminated union for representing success or typed failure
/// across all SAIE layer boundaries. Eliminates exception-based control flow.
library;

import 'package:stustep/features/saie/core/failures.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result<T>
// ─────────────────────────────────────────────────────────────────────────────

/// A discriminated union representing either a [Success] or a [Failure].
///
/// Use [Result.success] and [Result.failure] factory constructors.
///
/// Example:
/// ```dart
/// Result<Major> loadMajor(String id) {
///   try {
///     final major = _find(id);
///     return Result.success(major);
///   } catch (e, st) {
///     return Result.failure(KnowledgeLoadFailure(message: e.toString(), assetPath: id, stackTrace: st));
///   }
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Creates a successful [Result] wrapping [value].
  factory Result.success(T value) => Success<T>(value);

  /// Creates a failed [Result] wrapping [failure].
  factory Result.failure(Failure failure) => FailureResult<T>(failure);

  /// Returns `true` if this result is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this result is a [FailureResult].
  bool get isFailure => this is FailureResult<T>;

  /// Unwraps the success value. Throws [StateError] if this is a failure.
  T get value {
    if (this is Success<T>) return (this as Success<T>).data;
    throw StateError(
      'Attempted to access value of a failed Result: '
      '${(this as FailureResult<T>).failure.message}',
    );
  }

  /// Unwraps the failure. Throws [StateError] if this is a success.
  Failure get failure {
    if (this is FailureResult<T>) return (this as FailureResult<T>).failure;
    throw StateError('Attempted to access failure of a successful Result.');
  }

  /// Transforms the success value using [transform], or propagates failure.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T> s => Result.success(transform(s.data)),
      FailureResult<T> f => Result.failure(f.failure),
    };
  }

  /// Chains a [Result]-returning function on success, or propagates failure.
  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success<T> s => transform(s.data),
      FailureResult<T> f => Result.failure(f.failure),
    };
  }

  /// Executes [onSuccess] or [onFailure] depending on the result state.
  void fold({
    required void Function(T value) onSuccess,
    required void Function(Failure failure) onFailure,
  }) {
    switch (this) {
      case Success<T> s:
        onSuccess(s.data);
      case FailureResult<T> f:
        onFailure(f.failure);
    }
  }

  /// Returns [value] on success, or [defaultValue] on failure.
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T> s => s.data,
      FailureResult<T> _ => defaultValue,
    };
  }

  /// Returns [value] on success, or the result of [fallback] on failure.
  T getOrElseGet(T Function(Failure failure) fallback) {
    return switch (this) {
      Success<T> s => s.data,
      FailureResult<T> f => fallback(f.failure),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtypes
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a successful [Result] carrying [data].
final class Success<T> extends Result<T> {
  /// The encapsulated success value.
  final T data;

  const Success(this.data);
}

/// Represents a failed [Result] carrying a typed [failure].
final class FailureResult<T> extends Result<T> {
  /// The encapsulated typed failure.
  @override
  final Failure failure;

  const FailureResult(this.failure);
}
