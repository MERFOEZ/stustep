/// SAIE — StudentHistory
///
/// Stores the complete chronological history of every profile update.
/// Supports rollback to any prior state and timeline queries.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileUpdateType
// ─────────────────────────────────────────────────────────────────────────────

/// The type of change that triggered a profile history entry.
enum ProfileUpdateType {
  evidenceApplied,
  dimensionRecalibrated,
  interestAdded,
  skillAdded,
  goalAdded,
  strengthDetected,
  weaknessDetected,
  personalityAxisUpdated,
  learningStyleUpdated,
  sessionStarted,
  sessionCompleted,
  manualCorrection,
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileHistoryEntry
// ─────────────────────────────────────────────────────────────────────────────

/// A single immutable record of a profile state change.
final class ProfileHistoryEntry extends Equatable {
  /// Unique identifier for this history entry.
  final String id;

  /// The type of change that occurred.
  final ProfileUpdateType updateType;

  /// The session ID during which this change occurred.
  final String sessionId;

  /// ID of the evidence that triggered this change (if applicable).
  final String? evidenceId;

  /// Human-readable description of what changed and why.
  final String description;

  /// A JSON-serializable snapshot of the changed portion of the profile.
  /// The engine stores only the delta — not the entire profile — for efficiency.
  final Map<String, dynamic> delta;

  /// UTC timestamp of this entry.
  final DateTime timestamp;

  const ProfileHistoryEntry({
    required this.id,
    required this.updateType,
    required this.sessionId,
    required this.description,
    required this.delta,
    required this.timestamp,
    this.evidenceId,
  });

  factory ProfileHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ProfileHistoryEntry(
        id: json['id'] as String,
        updateType:
            ProfileUpdateType.values.byName(json['update_type'] as String),
        sessionId: json['session_id'] as String,
        evidenceId: json['evidence_id'] as String?,
        description: json['description'] as String,
        delta: json['delta'] as Map<String, dynamic>,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'update_type': updateType.name,
    'session_id': sessionId,
    if (evidenceId != null) 'evidence_id': evidenceId,
    'description': description,
    'delta': delta,
    'timestamp': timestamp.toIso8601String(),
  };

  ProfileHistoryEntry copyWith({
    String? id,
    ProfileUpdateType? updateType,
    String? sessionId,
    String? evidenceId,
    String? description,
    Map<String, dynamic>? delta,
    DateTime? timestamp,
  }) => ProfileHistoryEntry(
    id: id ?? this.id,
    updateType: updateType ?? this.updateType,
    sessionId: sessionId ?? this.sessionId,
    evidenceId: evidenceId ?? this.evidenceId,
    description: description ?? this.description,
    delta: delta ?? this.delta,
    timestamp: timestamp ?? this.timestamp,
  );

  @override
  List<Object?> get props => [id, updateType, sessionId, timestamp];

  @override
  String toString() =>
      'ProfileHistoryEntry(id: $id, type: ${updateType.name}, '
      'session: $sessionId)';
}

// ─────────────────────────────────────────────────────────────────────────────
// StudentHistory
// ─────────────────────────────────────────────────────────────────────────────

/// The complete chronological history of all profile changes.
///
/// Supports:
/// - Full timeline traversal
/// - Rollback point identification
/// - Evidence-to-change tracing
/// - Session-scoped filtering
final class StudentHistory extends Equatable {
  /// Chronological list of all profile change records.
  final List<ProfileHistoryEntry> entries;

  /// UTC timestamp when this history was first created.
  final DateTime createdAt;

  const StudentHistory({
    required this.entries,
    required this.createdAt,
  });

  factory StudentHistory.initial() => StudentHistory(
    entries: const [],
    createdAt: DateTime.now().toUtc(),
  );

  factory StudentHistory.fromJson(Map<String, dynamic> json) => StudentHistory(
    entries: (json['entries'] as List<dynamic>)
        .map((e) => ProfileHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'entries': entries.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
  };

  StudentHistory copyWith({
    List<ProfileHistoryEntry>? entries,
    DateTime? createdAt,
  }) => StudentHistory(
    entries: entries ?? this.entries,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Returns a new [StudentHistory] with [entry] appended.
  StudentHistory withEntry(ProfileHistoryEntry entry) =>
      copyWith(entries: [...entries, entry]);

  /// Returns all entries for a specific [sessionId].
  List<ProfileHistoryEntry> entriesForSession(String sessionId) =>
      entries.where((e) => e.sessionId == sessionId).toList();

  /// Returns all entries triggered by [evidenceId].
  List<ProfileHistoryEntry> entriesForEvidence(String evidenceId) =>
      entries.where((e) => e.evidenceId == evidenceId).toList();

  /// Returns entries within a time range [from] to [to].
  List<ProfileHistoryEntry> entriesBetween(DateTime from, DateTime to) =>
      entries
          .where((e) =>
              e.timestamp.isAfter(from) && e.timestamp.isBefore(to))
          .toList();

  /// Returns all entries of a specific [updateType].
  List<ProfileHistoryEntry> entriesOfType(ProfileUpdateType updateType) =>
      entries.where((e) => e.updateType == updateType).toList();

  /// Total number of recorded changes.
  int get totalChanges => entries.length;

  @override
  List<Object?> get props => [entries.length, createdAt];

  @override
  String toString() =>
      'StudentHistory(entries: ${entries.length}, createdAt: $createdAt)';
}
