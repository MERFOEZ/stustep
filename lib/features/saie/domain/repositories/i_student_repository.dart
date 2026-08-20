/// SAIE — IStudentRepository
///
/// Abstract contract for all student persistence operations.
/// The engine depends on this interface — never on a concrete implementation.
library;

import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/models/student_digital_twin.dart';
import 'package:stustep/features/saie/models/student_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IStudentRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for persisting and retrieving student data.
///
/// Implementations may store data locally (SharedPreferences, SQLite, Hive)
/// or remotely — the engine is agnostic.
abstract interface class IStudentRepository {
  /// Saves or updates a [StudentDigitalTwin] in storage.
  Future<Result<void>> saveDigitalTwin(StudentDigitalTwin twin);

  /// Loads a [StudentDigitalTwin] by the student's [id].
  /// Returns [FailureResult] if not found.
  Future<Result<StudentDigitalTwin>> loadDigitalTwin(String id);

  /// Returns all stored [StudentDigitalTwin] records.
  Future<Result<List<StudentDigitalTwin>>> loadAll();

  /// Deletes the [StudentDigitalTwin] with the given [id].
  Future<Result<void>> delete(String id);

  /// Creates and saves a new [StudentDigitalTwin] from [profile].
  Future<Result<StudentDigitalTwin>> create(StudentProfile profile);

  /// Returns `true` if a student with [id] exists in storage.
  Future<bool> exists(String id);
}
