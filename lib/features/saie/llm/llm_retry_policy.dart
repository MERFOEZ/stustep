/// SAIE LLM — LlmRetryPolicy
///
/// Controls how transient LLM failures are retried.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmRetryPolicy
// ─────────────────────────────────────────────────────────────────────────────

/// Retry strategy for transient LLM failures.
final class LlmRetryPolicy extends Equatable {
  /// Maximum number of retry attempts (0 = no retry).
  final int maxAttempts;

  /// Delay before the first retry.
  final Duration initialDelay;

  /// Multiplier applied to [initialDelay] on each subsequent attempt.
  final double backoffMultiplier;

  /// Maximum delay cap between retries.
  final Duration maxDelay;

  /// Whether to add jitter to the delay to avoid thundering herd.
  final bool jitter;

  const LlmRetryPolicy({
    this.maxAttempts = 2,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 10),
    this.jitter = true,
  });

  static const noRetry = LlmRetryPolicy(maxAttempts: 0);

  /// Computes the delay for [attempt] (0-indexed).
  Duration delayForAttempt(int attempt) {
    if (attempt <= 0) return initialDelay;
    var ms = initialDelay.inMilliseconds *
        (backoffMultiplier * attempt);
    if (ms > maxDelay.inMilliseconds) ms = maxDelay.inMilliseconds.toDouble();
    return Duration(milliseconds: ms.round());
  }

  factory LlmRetryPolicy.fromJson(Map<String, dynamic> json) => LlmRetryPolicy(
    maxAttempts: (json['max_attempts'] as int?) ?? 2,
    initialDelay:
        Duration(milliseconds: (json['initial_delay_ms'] as int?) ?? 1000),
    backoffMultiplier:
        ((json['backoff_multiplier'] as num?) ?? 2.0).toDouble(),
    maxDelay:
        Duration(milliseconds: (json['max_delay_ms'] as int?) ?? 10000),
    jitter: (json['jitter'] as bool?) ?? true,
  );

  Map<String, dynamic> toJson() => {
    'max_attempts': maxAttempts,
    'initial_delay_ms': initialDelay.inMilliseconds,
    'backoff_multiplier': backoffMultiplier,
    'max_delay_ms': maxDelay.inMilliseconds,
    'jitter': jitter,
  };

  @override
  List<Object?> get props => [maxAttempts, initialDelay, backoffMultiplier];
}
