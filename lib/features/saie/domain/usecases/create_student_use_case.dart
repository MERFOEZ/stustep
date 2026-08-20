/// SAIE — CreateStudentUseCase
///
/// Creates a new student profile and initializes their Digital Twin.
library;

import 'package:stustep/features/saie/core/failures.dart';
import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/domain/repositories/i_student_repository.dart';
import 'package:stustep/features/saie/domain/usecases/use_case_base.dart';
import 'package:stustep/features/saie/models/student_digital_twin.dart';
import 'package:stustep/features/saie/models/student_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Params
// ─────────────────────────────────────────────────────────────────────────────

/// Parameters required to create a new student.
final class CreateStudentParams {
  /// The base profile data for the new student.
  final StudentProfile profile;

  const CreateStudentParams({required this.profile});
}

// ─────────────────────────────────────────────────────────────────────────────
// UseCase
// ─────────────────────────────────────────────────────────────────────────────

/// Creates a new [StudentDigitalTwin] from a [StudentProfile].
///
/// Validates that no student with the same ID already exists before creating.
final class CreateStudentUseCase
    extends UseCase<CreateStudentParams, StudentDigitalTwin> {
  final IStudentRepository _repository;

  CreateStudentUseCase(this._repository);

  @override
  Future<Result<StudentDigitalTwin>> call(CreateStudentParams params) async {
    // Guard: prevent duplicate student creation.
    final exists = await _repository.exists(params.profile.id);
    if (exists) {
      return Result.failure(
        ValidationFailure(
          message:
              'A student with ID "${params.profile.id}" already exists.',
          field: 'profile.id',
        ),
      );
    }

    return _repository.create(params.profile);
  }
}
