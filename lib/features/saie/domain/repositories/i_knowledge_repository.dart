/// SAIE — IKnowledgeRepository
///
/// Abstract contract for loading knowledge base entities from asset files.
/// Implementations parse JSON from Flutter's asset bundle.
library;

import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/models/career.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/models/skill.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IKnowledgeRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Contract for reading the static academic knowledge base.
///
/// All data is loaded from JSON asset files. No network or database calls.
/// Implementations must be fully offline-capable.
abstract interface class IKnowledgeRepository {
  // ── Majors ────────────────────────────────────────────────────────────────

  /// Loads all available [Major] records from the knowledge base.
  Future<Result<List<Major>>> loadAllMajors();

  /// Loads a single [Major] by its [id].
  Future<Result<Major>> loadMajor(String id);

  /// Loads all [Major] records belonging to [category].
  Future<Result<List<Major>>> loadMajorsByCategory(MajorCategory category);

  // ── Careers ───────────────────────────────────────────────────────────────

  /// Loads all available [Career] records from the knowledge base.
  Future<Result<List<Career>>> loadAllCareers();

  /// Loads a single [Career] by its [id].
  Future<Result<Career>> loadCareer(String id);

  /// Loads all [Career] records for a given [environment].
  Future<Result<List<Career>>> loadCareersByEnvironment(
    CareerEnvironment environment,
  );

  // ── Questions ─────────────────────────────────────────────────────────────

  /// Loads all available [Question] records from the knowledge base.
  Future<Result<List<Question>>> loadAllQuestions();

  /// Loads questions targeting a specific [phase].
  Future<Result<List<Question>>> loadQuestionsForPhase(AssessmentPhase phase);

  /// Loads questions associated with specific [domainIds].
  Future<Result<List<Question>>> loadQuestionsForDomains(
    List<String> domainIds,
  );

  // ── Skills ────────────────────────────────────────────────────────────────

  /// Loads all [Skill] records from the knowledge base.
  Future<Result<List<Skill>>> loadAllSkills();

  /// Loads a single [Skill] by its [id].
  Future<Result<Skill>> loadSkill(String id);

  /// Loads skills matching given [ids].
  Future<Result<List<Skill>>> loadSkillsByIds(List<String> ids);
}
