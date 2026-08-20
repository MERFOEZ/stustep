/// SAIE — SessionManager
///
/// Handles persistence and restoration of [SessionSnapshot] objects.
///
/// By default the snapshot is held in memory only (stateless between app
/// restarts). The Flutter host may inject a [SessionPersistenceAdapter] to
/// write/read from local storage (e.g. SharedPreferences, Hive, SQLite).
///
/// Pure Dart. No Flutter. No HTTP. No file I/O in this layer.
library;

import 'dart:convert';

import 'package:stustep/features/saie/engine_exceptions.dart';
import 'package:stustep/features/saie/session_snapshot.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionPersistenceAdapter
// ─────────────────────────────────────────────────────────────────────────────

/// Abstract adapter injected by the host app to provide actual I/O.
/// The SAIE core never does file/DB I/O itself.
abstract interface class SessionPersistenceAdapter {
  /// Write [jsonData] keyed by [sessionId].
  Future<void> write(String sessionId, String jsonData);

  /// Read JSON string for [sessionId], or null if absent.
  Future<String?> read(String sessionId);

  /// Delete the session entry for [sessionId].
  Future<void> delete(String sessionId);
}

// ─────────────────────────────────────────────────────────────────────────────
// InMemorySessionAdapter  (default, used when no adapter is injected)
// ─────────────────────────────────────────────────────────────────────────────

/// Simple in-memory adapter — data is lost when the process terminates.
final class InMemorySessionAdapter implements SessionPersistenceAdapter {
  final _store = <String, String>{};

  @override
  Future<void> write(String sessionId, String jsonData) async {
    _store[sessionId] = jsonData;
  }

  @override
  Future<String?> read(String sessionId) async => _store[sessionId];

  @override
  Future<void> delete(String sessionId) async => _store.remove(sessionId);
}

// ─────────────────────────────────────────────────────────────────────────────
// SessionManager
// ─────────────────────────────────────────────────────────────────────────────

/// Coordinates session save / restore on behalf of [SAIEEngine].
final class SessionManager {
  final SessionPersistenceAdapter _adapter;

  /// Most recently loaded or saved snapshot (cached for quick access).
  SessionSnapshot? _cached;

  SessionManager({SessionPersistenceAdapter? adapter})
      : _adapter = adapter ?? InMemorySessionAdapter();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Persist [snapshot] using the configured adapter.
  Future<void> save(SessionSnapshot snapshot) async {
    try {
      final json = jsonEncode(snapshot.toJson());
      await _adapter.write(snapshot.sessionId, json);
      _cached = snapshot;
    } catch (e, st) {
      throw SessionPersistenceException(
        'Failed to save session "${snapshot.sessionId}": $e',
        st,
      );
    }
  }

  /// Restore the snapshot for [sessionId].
  ///
  /// Returns null if no snapshot exists.
  Future<SessionSnapshot?> load(String sessionId) async {
    try {
      // Return cached copy immediately.
      if (_cached?.sessionId == sessionId) return _cached;

      final raw = await _adapter.read(sessionId);
      if (raw == null) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final snapshot = SessionSnapshot.fromJson(decoded);
      _cached = snapshot;
      return snapshot;
    } catch (e, st) {
      throw SessionPersistenceException(
        'Failed to load session "$sessionId": $e',
        st,
      );
    }
  }

  /// Delete the persisted snapshot for [sessionId].
  Future<void> delete(String sessionId) async {
    try {
      await _adapter.delete(sessionId);
      if (_cached?.sessionId == sessionId) _cached = null;
    } catch (e, st) {
      throw SessionPersistenceException(
        'Failed to delete session "$sessionId": $e',
        st,
      );
    }
  }

  /// True if a snapshot exists in the cache for [sessionId].
  bool hasCachedSession(String sessionId) =>
      _cached?.sessionId == sessionId;

  /// Return the cached snapshot if available.
  SessionSnapshot? get cached => _cached;

  /// Clear the in-memory cache (does not delete persisted data).
  void clearCache() => _cached = null;
}
