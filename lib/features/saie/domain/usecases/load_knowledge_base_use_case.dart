/// SAIE — LoadKnowledgeBaseUseCase
///
/// Loads and validates the entire knowledge base (majors, careers,
/// questions, skills) from JSON asset files. Called once at engine startup.
///
/// SEMANTIC VALIDATION (Phase 2A):
/// After loading all entities, [KnowledgeSemanticValidator.validate] is called
/// to confirm that every identifier used as a cognitive dimension key maps to
/// a canonical [DimensionKeys] value. This check runs in all build modes —
/// debug AND release — without relying on Dart assertions. If any violation is
/// found, the use case returns a [KnowledgeSemanticFailure] and the engine does
/// not start. No student interaction can begin with a misconfigured knowledge
/// base.
library;

import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/domain/repositories/i_knowledge_repository.dart';
import 'package:stustep/features/saie/domain/usecases/knowledge_semantic_validator.dart';
import 'package:stustep/features/saie/domain/usecases/use_case_base.dart';
import 'package:stustep/features/saie/models/career.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/models/skill.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KnowledgeBaseSnapshot
// ─────────────────────────────────────────────────────────────────────────────

/// The complete, loaded and semantically validated knowledge base.
final class KnowledgeBaseSnapshot {
  /// All loaded majors.
  final List<Major> majors;

  /// All loaded careers.
  final List<Career> careers;

  /// All loaded assessment questions.
  final List<Question> questions;

  /// All loaded skills.
  final List<Skill> skills;

  const KnowledgeBaseSnapshot({
    required this.majors,
    required this.careers,
    required this.questions,
    required this.skills,
  });

  /// Total number of domain entities loaded.
  int get totalEntities =>
      majors.length + careers.length + questions.length + skills.length;

  @override
  String toString() =>
      'KnowledgeBaseSnapshot('
      'majors: ${majors.length}, '
      'careers: ${careers.length}, '
      'questions: ${questions.length}, '
      'skills: ${skills.length})';
}

// ─────────────────────────────────────────────────────────────────────────────
// UseCase
// ─────────────────────────────────────────────────────────────────────────────

/// Loads all knowledge base entities and returns a [KnowledgeBaseSnapshot].
///
/// This use case is called once during engine initialization.
/// On failure, the SAIE engine cannot operate.
///
/// Steps:
/// 1. Load all entities in parallel (fast startup).
/// 2. Fail fast on any I/O or parse error.
/// 3. Run semantic validation — all targetDomainIds and requiredSkillIds must
///    be canonical DimensionKeys. This check is release-safe (no assertions).
/// 4. Return the validated snapshot.
final class LoadKnowledgeBaseUseCase
    extends NoParamUseCase<KnowledgeBaseSnapshot> {
  final IKnowledgeRepository _repository;

  LoadKnowledgeBaseUseCase(this._repository);

  @override
  Future<Result<KnowledgeBaseSnapshot>> call() async {
    // Step 1: Load all entities in parallel for faster startup.
    final results = await Future.wait([
      _repository.loadAllMajors(),
      _repository.loadAllCareers(),
      _repository.loadAllQuestions(),
      _repository.loadAllSkills(),
    ]);

    // Step 2: Fail fast on any loading error.
    for (final result in results) {
      if (result.isFailure) return Result.failure(result.failure);
    }

    final majors    = (results[0] as Result<List<Major>>).value;
    final careers   = (results[1] as Result<List<Career>>).value;
    final questions = (results[2] as Result<List<Question>>).value;
    final skills    = (results[3] as Result<List<Skill>>).value;

    // Step 3: Semantic validation — release-safe, no assertions.
    // Every question targetDomainId and major skill ID must be a canonical
    // DimensionKeys value. The engine must not start with invalid configuration.
    final semanticResult = KnowledgeSemanticValidator.validate(
      questions: questions,
      majors: majors,
    );
    if (semanticResult.isFailure) {
      return Result.failure(semanticResult.failure);
    }

    // Step 4: Return the validated snapshot.
    return Result.success(
      KnowledgeBaseSnapshot(
        majors: majors,
        careers: careers,
        questions: questions,
        skills: skills,
      ),
    );
  }
}
