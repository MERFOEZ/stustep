/// SAIE — IProfileRepository
///
/// Abstract contract for persisting and loading [StudentCognitiveProfile] data.
library;

import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';
import 'package:stustep/features/saie/profile/student_snapshot.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IProfileRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for persisting the Student Cognitive Profile.
abstract interface class IProfileRepository {
  /// Saves or updates a [StudentCognitiveProfile].
  Future<Result<void>> saveProfile(StudentCognitiveProfile profile);

  /// Loads a [StudentCognitiveProfile] by [studentId].
  Future<Result<StudentCognitiveProfile>> loadProfile(String studentId);

  /// Returns `true` if a profile exists for [studentId].
  Future<bool> exists(String studentId);

  /// Deletes the profile for [studentId].
  Future<Result<void>> deleteProfile(String studentId);

  /// Saves an individual [StudentSnapshot].
  Future<Result<void>> saveSnapshot(StudentSnapshot snapshot);

  /// Loads all snapshots for [studentId].
  Future<Result<List<StudentSnapshot>>> loadSnapshots(String studentId);
}
