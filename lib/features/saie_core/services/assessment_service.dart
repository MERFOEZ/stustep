/// StuStep — AssessmentService
///
/// Persists and retrieves [AssessmentResult]s per user.
/// Each result is stored under a key scoped by user_id + role.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stustep/features/saie_core/models/assessment_result.dart';
import 'package:stustep/features/saie_core/models/user_role.dart';

/// Manages persistent storage of assessment results.
///
/// Storage keys are scoped by user_id to guarantee strict user isolation:
///   `stustep_assessments_{userId}_{role}`
///
/// Each key holds a JSON array of all assessments for that user+role pair.
final class AssessmentService {
  const AssessmentService();

  String _key(String userId, UserRole role) =>
      'stustep_assessments_${userId}_${role.storageKey}';

  /// Save a completed assessment result.
  Future<void> save(AssessmentResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(result.userId, result.role);
    final existing = _loadAll(prefs, key);
    existing.add(result);
    await prefs.setString(
      key,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  /// Get the latest assessment for a user + role.
  /// Returns null if no assessment exists.
  Future<AssessmentResult?> getLatest(String userId, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    final all = _loadAll(prefs, _key(userId, role));
    if (all.isEmpty) return null;
    return all.last;
  }

  /// Get all assessments for a user + role.
  Future<List<AssessmentResult>> getAll(String userId, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    return _loadAll(prefs, _key(userId, role));
  }

  /// Get a specific assessment by its ID.
  Future<AssessmentResult?> getById(
    String userId,
    UserRole role,
    String assessmentId,
  ) async {
    final all = await getAll(userId, role);
    for (final a in all) {
      if (a.assessmentId == assessmentId) return a;
    }
    return null;
  }

  /// Delete all assessments for a user + role.
  Future<void> clearAll(String userId, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId, role));
  }

  List<AssessmentResult> _loadAll(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) =>
              AssessmentResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
