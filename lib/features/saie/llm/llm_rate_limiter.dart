/// SAIE LLM — LlmRateLimiter
///
/// Tracks request counts and enforces per-minute request limits.
/// All state is in-memory. Thread-safety is maintained via a sequential
/// request queue enforced by the caller (LlmClient).
library;

// ─────────────────────────────────────────────────────────────────────────────
// LlmRateLimiter
// ─────────────────────────────────────────────────────────────────────────────

/// In-process rate limiter — prevents request floods against the LLM provider.
///
/// Uses a sliding-window algorithm: counts requests in the last [windowSeconds].
final class LlmRateLimiter {
  /// Maximum requests allowed within [windowSeconds].
  final int maxRequests;

  /// Sliding window duration.
  final Duration window;

  final List<DateTime> _timestamps = [];

  LlmRateLimiter({
    this.maxRequests = 60,
    this.window = const Duration(minutes: 1),
  });

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns true if a new request is allowed right now.
  bool get isAllowed {
    _evictExpired();
    return _timestamps.length < maxRequests;
  }

  /// Record that a request was just sent.
  void recordRequest() {
    _evictExpired();
    _timestamps.add(DateTime.now().toUtc());
  }

  /// How long to wait before the next request is allowed.
  /// Returns [Duration.zero] if already allowed.
  Duration get waitDuration {
    if (isAllowed) return Duration.zero;
    final oldest = _timestamps.first;
    final windowEnd = oldest.add(window);
    final now = DateTime.now().toUtc();
    return windowEnd.isAfter(now) ? windowEnd.difference(now) : Duration.zero;
  }

  /// Current request count within the active window.
  int get currentCount {
    _evictExpired();
    return _timestamps.length;
  }

  /// Remaining requests available in this window.
  int get remaining => (maxRequests - currentCount).clamp(0, maxRequests);

  /// Resets all recorded timestamps.
  void reset() => _timestamps.clear();

  // ── Private ─────────────────────────────────────────────────────────────────

  void _evictExpired() {
    final cutoff = DateTime.now().toUtc().subtract(window);
    _timestamps.removeWhere((t) => t.isBefore(cutoff));
  }
}
