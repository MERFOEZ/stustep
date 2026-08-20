/// SAIE — AssetKnowledgeRepository
///
/// Concrete implementation of [IKnowledgeRepository] that reads all
/// knowledge base entities from Flutter's asset bundle (JSON files).
///
/// Asset paths:
///   assets/knowledge/questions/questions.json
///   assets/knowledge/majors/majors.json
///   assets/knowledge/careers/careers.json
///   assets/knowledge/skills/skills.json
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/core/failures.dart';
import 'package:stustep/features/saie/core/result.dart';
import 'package:stustep/features/saie/domain/repositories/i_knowledge_repository.dart';
import 'package:stustep/features/saie/models/career.dart';
import 'package:stustep/features/saie/models/major.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/models/skill.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Asset paths
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _AssetPath {
  static const questions = 'assets/knowledge/questions/questions.json';
  static const majors    = 'assets/knowledge/majors/majors.json';
  static const careers   = 'assets/knowledge/careers/careers.json';
  static const skills    = 'assets/knowledge/skills/skills.json';
}

// ─────────────────────────────────────────────────────────────────────────────
// AssetKnowledgeRepository
// ─────────────────────────────────────────────────────────────────────────────

/// Reads knowledge base JSON files from the Flutter asset bundle.
///
/// Each JSON file is a top-level array of objects:
/// ```json
/// [ { "id": "...", ... }, { "id": "...", ... } ]
/// ```
final class AssetKnowledgeRepository implements IKnowledgeRepository {
  final AssetBundle _bundle;

  AssetKnowledgeRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Result<List<T>>> _loadList<T>({
    required String path,
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    try {
      final raw = await _bundle.loadString(path);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return Result.failure(KnowledgeLoadFailure(
          message: 'Expected a JSON array at $path but got ${decoded.runtimeType}.',
          assetPath: path,
        ));
      }
      final items = decoded
          .cast<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
      return Result.success(items);
    } on Exception catch (e, st) {
      return Result.failure(KnowledgeLoadFailure(
        message: 'Asset not found or unreadable: $path. $e',
        assetPath: path,
        stackTrace: st,
      ));
    } catch (e, st) {
      return Result.failure(KnowledgeLoadFailure(
        message: 'Failed to parse $path: $e',
        assetPath: path,
        stackTrace: st,
      ));
    }
  }

  // ── Majors ────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Major>>> loadAllMajors() =>
      _loadList(path: _AssetPath.majors, fromJson: Major.fromJson);

  @override
  Future<Result<Major>> loadMajor(String id) async {
    final result = await loadAllMajors();
    if (result.isFailure) return Result.failure(result.failure);
    final match = result.value.where((m) => m.id == id).firstOrNull;
    if (match == null) {
      return Result.failure(KnowledgeLoadFailure(
        message: 'Major "$id" not found.',
        assetPath: _AssetPath.majors,
      ));
    }
    return Result.success(match);
  }

  @override
  Future<Result<List<Major>>> loadMajorsByCategory(
    MajorCategory category,
  ) async {
    final result = await loadAllMajors();
    if (result.isFailure) return Result.failure(result.failure);
    return Result.success(
      result.value.where((m) => m.category == category).toList(),
    );
  }

  // ── Careers ───────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Career>>> loadAllCareers() =>
      _loadList(path: _AssetPath.careers, fromJson: Career.fromJson);

  @override
  Future<Result<Career>> loadCareer(String id) async {
    final result = await loadAllCareers();
    if (result.isFailure) return Result.failure(result.failure);
    final match = result.value.where((c) => c.id == id).firstOrNull;
    if (match == null) {
      return Result.failure(KnowledgeLoadFailure(
        message: 'Career "$id" not found.',
        assetPath: _AssetPath.careers,
      ));
    }
    return Result.success(match);
  }

  @override
  Future<Result<List<Career>>> loadCareersByEnvironment(
    CareerEnvironment environment,
  ) async {
    final result = await loadAllCareers();
    if (result.isFailure) return Result.failure(result.failure);
    return Result.success(
      result.value.where((c) => c.environment == environment).toList(),
    );
  }

  // ── Questions ─────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Question>>> loadAllQuestions() =>
      _loadList(path: _AssetPath.questions, fromJson: Question.fromJson);

  @override
  Future<Result<List<Question>>> loadQuestionsForPhase(
    AssessmentPhase phase,
  ) async {
    final result = await loadAllQuestions();
    if (result.isFailure) return Result.failure(result.failure);
    return Result.success(
      result.value.where((q) => q.targetPhase == phase).toList(),
    );
  }

  @override
  Future<Result<List<Question>>> loadQuestionsForDomains(
    List<String> domainIds,
  ) async {
    final result = await loadAllQuestions();
    if (result.isFailure) return Result.failure(result.failure);
    final domainSet = domainIds.toSet();
    return Result.success(
      result.value
          .where((q) => q.targetDomainIds.any(domainSet.contains))
          .toList(),
    );
  }

  // ── Skills ────────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Skill>>> loadAllSkills() =>
      _loadList(path: _AssetPath.skills, fromJson: Skill.fromJson);

  @override
  Future<Result<Skill>> loadSkill(String id) async {
    final result = await loadAllSkills();
    if (result.isFailure) return Result.failure(result.failure);
    final match = result.value.where((s) => s.id == id).firstOrNull;
    if (match == null) {
      return Result.failure(KnowledgeLoadFailure(
        message: 'Skill "$id" not found.',
        assetPath: _AssetPath.skills,
      ));
    }
    return Result.success(match);
  }

  @override
  Future<Result<List<Skill>>> loadSkillsByIds(List<String> ids) async {
    final result = await loadAllSkills();
    if (result.isFailure) return Result.failure(result.failure);
    final idSet = ids.toSet();
    return Result.success(
      result.value.where((s) => idSet.contains(s.id)).toList(),
    );
  }
}
