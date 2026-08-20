/// SAIE — StudentCognitiveProfile
///
/// The Digital Brain of the student.
/// This is the primary aggregate the SAIE engine reads from and writes to.
/// Everything the system learns about the student lives here.
///
/// The profile is always immutable — every update returns a new instance.
/// All mutations are evidence-driven and recorded in [StudentHistory].
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/profile/cognitive_dimension.dart';
import 'package:stustep/features/saie/profile/learning_style.dart';
import 'package:stustep/features/saie/profile/profile_statistics.dart';
import 'package:stustep/features/saie/profile/student_evidence.dart';
import 'package:stustep/features/saie/profile/student_goal.dart';
import 'package:stustep/features/saie/profile/student_history.dart';
import 'package:stustep/features/saie/profile/student_interest.dart';
import 'package:stustep/features/saie/profile/student_personality.dart';
import 'package:stustep/features/saie/profile/student_skill.dart';
import 'package:stustep/features/saie/profile/student_snapshot.dart';
import 'package:stustep/features/saie/profile/student_strength.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dimension Keys (constants — the full cognitive space)
// ─────────────────────────────────────────────────────────────────────────────

/// All core cognitive dimension keys tracked by the SAIE engine.
abstract final class DimensionKeys {
  // Cognitive & Reasoning
  static const String logic = 'logic';
  static const String mathematics = 'mathematics';
  static const String creativity = 'creativity';
  static const String research = 'research';
  static const String criticalThinking = 'critical_thinking';
  static const String problemSolving = 'problem_solving';

  // Interpersonal
  static const String teamwork = 'teamwork';
  static const String leadership = 'leadership';
  static const String communication = 'communication';
  static const String empathy = 'empathy';

  // Domain-specific aptitudes
  static const String business = 'business';
  static const String technology = 'technology';
  static const String science = 'science';
  static const String language = 'language';
  static const String art = 'art';
  static const String medicine = 'medicine';
  static const String law = 'law';

  // Behavioral
  static const String selfLearning = 'self_learning';
  static const String stressPreference = 'stress_preference';
  static const String decisionStyle = 'decision_style';
  static const String technologyAffinity = 'technology_affinity';

  // ── Extended: Major-Differentiating Dimensions ──────────────────────────
  // Only 3 new dimensions are introduced. All other candidates were audited
  // and found to map onto existing dimensions:
  //   research_orientation  → research
  //   people_orientation    → empathy + teamwork
  //   scientific_reasoning  → science + critical_thinking
  //   technical_curiosity   → technology + technology_affinity
  //   career_environment    → empathy + stress_preference
  //   motivation_strength   → self_learning
  //   business_orientation  → business
  //   academic_interest     → research + self_learning
  //
  // These 3 cannot be adequately represented by existing dimensions:

  /// Preferred mode of engagement: abstract conceptual understanding (high)
  /// vs concrete hands-on application (low).
  /// High = physics, mathematics, philosophy, fundamental research.
  /// Low  = engineering, medicine, business, applied computing.
  static const String practicalVsTheoretical = 'practical_vs_theoretical';

  /// Relative academic performance compared to peers.
  /// Collected from behavioral evidence, not pure self-rating.
  /// Used to calibrate major difficulty fit.
  static const String academicPerformance = 'academic_performance';

  /// Comfort operating in open-ended, unresolved situations.
  /// High = design, entrepreneurship, creative research.
  /// Low  = medicine (protocol-driven), law (precedent-driven).
  /// Distinct from decisionStyle which measures decision speed, not ambiguity.
  static const String ambiguityTolerance = 'ambiguity_tolerance';

  /// The complete ordered list of all tracked dimension keys.
  static const List<String> all = [
    // Original 21
    logic, mathematics, creativity, research, criticalThinking,
    problemSolving, teamwork, leadership, communication, empathy,
    business, technology, science, language, art, medicine, law,
    selfLearning, stressPreference, decisionStyle, technologyAffinity,
    // New 3 — major-differentiating
    practicalVsTheoretical, academicPerformance, ambiguityTolerance,
  ];

  static const Map<String, String> labels = {
    logic: 'Logical Reasoning',
    mathematics: 'Mathematical Aptitude',
    creativity: 'Creativity',
    research: 'Research Ability',
    criticalThinking: 'Critical Thinking',
    problemSolving: 'Problem Solving',
    teamwork: 'Teamwork',
    leadership: 'Leadership',
    communication: 'Communication',
    empathy: 'Empathy',
    business: 'Business Acumen',
    technology: 'Technology',
    science: 'Science',
    language: 'Language & Literature',
    art: 'Art & Design',
    medicine: 'Medicine & Health',
    law: 'Law & Governance',
    selfLearning: 'Self-Learning',
    stressPreference: 'Stress Tolerance',
    decisionStyle: 'Decision Style',
    technologyAffinity: 'Technology Affinity',
    // New 3
    practicalVsTheoretical: 'Practical vs Theoretical',
    academicPerformance: 'Academic Performance',
    ambiguityTolerance: 'Ambiguity Tolerance',
  };

  /// Arabic labels for all 24 tracked dimensions.
  /// Used by RecommendationRanker to produce Arabic explanations.
  static const Map<String, String> labelsAr = {
    logic: 'التفكير المنطقي',
    mathematics: 'القدرة الرياضية',
    creativity: 'الإبداع',
    research: 'القدرة البحثية',
    criticalThinking: 'التفكير النقدي',
    problemSolving: 'حل المشكلات',
    teamwork: 'العمل الجماعي',
    leadership: 'القيادة',
    communication: 'التواصل',
    empathy: 'التعاطف مع الآخرين',
    business: 'الحس التجاري',
    technology: 'التقنية',
    science: 'العلوم',
    language: 'اللغة والأدب',
    art: 'الفن والتصميم',
    medicine: 'الطب والصحة',
    law: 'القانون',
    selfLearning: 'التعلم الذاتي',
    stressPreference: 'تحمل الضغط',
    decisionStyle: 'أسلوب اتخاذ القرار',
    technologyAffinity: 'الميل للتقنية',
    practicalVsTheoretical: 'التوجه النظري',
    academicPerformance: 'الأداء الأكاديمي',
    ambiguityTolerance: 'تحمل الغموض',
  };
}


// ─────────────────────────────────────────────────────────────────────────────
// StudentCognitiveProfile
// ─────────────────────────────────────────────────────────────────────────────

/// The complete, living cognitive representation of a student.
///
/// Tracks:
/// - [dimensions]: all 21 core cognitive axes
/// - [interests]: detected academic and career interests
/// - [skills]: detected technical and soft skills
/// - [personality]: Big Five + academic personality dimensions
/// - [learningStyle]: VARK modality profile
/// - [goals]: academic and career goals
/// - [strengths]: detected academic strengths
/// - [weaknesses]: detected academic gaps
/// - [evidence]: every evidence record collected
/// - [history]: full audit log of all profile changes
/// - [snapshots]: immutable point-in-time profile captures
final class StudentCognitiveProfile extends Equatable {
  static const _uuid = Uuid();

  /// Unique identifier for this profile.
  final String id;

  /// The ID of the student this profile belongs to.
  final String studentId;

  /// All 21 core cognitive dimensions.
  final Map<String, CognitiveDimension> dimensions;

  /// All detected interests.
  final List<StudentInterest> interests;

  /// All inferred skills.
  final List<StudentSkill> skills;

  /// The personality profile.
  final StudentPersonality personality;

  /// The learning style profile.
  final LearningStyleProfile learningStyle;

  /// All academic and career goals.
  final List<StudentGoal> goals;

  /// All detected strengths.
  final List<StudentStrength> strengths;

  /// All detected weaknesses.
  final List<StudentWeakness> weaknesses;

  /// All evidence records collected across all sessions.
  final List<StudentEvidence> evidence;

  /// Full chronological history of all profile changes.
  final StudentHistory history;

  /// Immutable snapshots taken at key moments.
  final List<StudentSnapshot> snapshots;

  /// UTC timestamp when this profile was first created.
  final DateTime createdAt;

  /// UTC timestamp of the most recent update.
  final DateTime lastUpdatedAt;

  const StudentCognitiveProfile({
    required this.id,
    required this.studentId,
    required this.dimensions,
    required this.interests,
    required this.skills,
    required this.personality,
    required this.learningStyle,
    required this.goals,
    required this.strengths,
    required this.weaknesses,
    required this.evidence,
    required this.history,
    required this.snapshots,
    required this.createdAt,
    required this.lastUpdatedAt,
  });

  // ─── Factory: Initial ────────────────────────────────────────────────────

  /// Creates a blank [StudentCognitiveProfile] for a new student.
  factory StudentCognitiveProfile.initial({required String studentId}) {
    final now = DateTime.now().toUtc();
    return StudentCognitiveProfile(
      id: _uuid.v4(),
      studentId: studentId,
      dimensions: {
        for (final key in DimensionKeys.all)
          key: CognitiveDimension.initial(
            key: key,
            label: DimensionKeys.labels[key] ?? key,
          ),
      },
      interests: const [],
      skills: const [],
      personality: StudentPersonality.initial(),
      learningStyle: LearningStyleProfile.initial(),
      goals: const [],
      strengths: const [],
      weaknesses: const [],
      evidence: const [],
      history: StudentHistory.initial(),
      snapshots: const [],
      createdAt: now,
      lastUpdatedAt: now,
    );
  }

  // ─── Serialization ────────────────────────────────────────────────────────

  factory StudentCognitiveProfile.fromJson(Map<String, dynamic> json) =>
      StudentCognitiveProfile(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        dimensions: (json['dimensions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            k,
            CognitiveDimension.fromJson(v as Map<String, dynamic>),
          ),
        ),
        interests: (json['interests'] as List<dynamic>)
            .map((e) => StudentInterest.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: (json['skills'] as List<dynamic>)
            .map((e) => StudentSkill.fromJson(e as Map<String, dynamic>))
            .toList(),
        personality: StudentPersonality.fromJson(
          json['personality'] as Map<String, dynamic>,
        ),
        learningStyle: LearningStyleProfile.fromJson(
          json['learning_style'] as Map<String, dynamic>,
        ),
        goals: (json['goals'] as List<dynamic>)
            .map((e) => StudentGoal.fromJson(e as Map<String, dynamic>))
            .toList(),
        strengths: (json['strengths'] as List<dynamic>)
            .map((e) => StudentStrength.fromJson(e as Map<String, dynamic>))
            .toList(),
        weaknesses: (json['weaknesses'] as List<dynamic>)
            .map((e) => StudentWeakness.fromJson(e as Map<String, dynamic>))
            .toList(),
        evidence: (json['evidence'] as List<dynamic>)
            .map((e) => StudentEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: StudentHistory.fromJson(
          json['history'] as Map<String, dynamic>,
        ),
        snapshots: (json['snapshots'] as List<dynamic>)
            .map((e) => StudentSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
        lastUpdatedAt: DateTime.parse(json['last_updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'student_id': studentId,
    'dimensions': dimensions.map((k, v) => MapEntry(k, v.toJson())),
    'interests': interests.map((e) => e.toJson()).toList(),
    'skills': skills.map((e) => e.toJson()).toList(),
    'personality': personality.toJson(),
    'learning_style': learningStyle.toJson(),
    'goals': goals.map((e) => e.toJson()).toList(),
    'strengths': strengths.map((e) => e.toJson()).toList(),
    'weaknesses': weaknesses.map((e) => e.toJson()).toList(),
    'evidence': evidence.map((e) => e.toJson()).toList(),
    'history': history.toJson(),
    'snapshots': snapshots.map((e) => e.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
    'last_updated_at': lastUpdatedAt.toIso8601String(),
  };

  // ─── copyWith ─────────────────────────────────────────────────────────────

  StudentCognitiveProfile copyWith({
    String? id,
    String? studentId,
    Map<String, CognitiveDimension>? dimensions,
    List<StudentInterest>? interests,
    List<StudentSkill>? skills,
    StudentPersonality? personality,
    LearningStyleProfile? learningStyle,
    List<StudentGoal>? goals,
    List<StudentStrength>? strengths,
    List<StudentWeakness>? weaknesses,
    List<StudentEvidence>? evidence,
    StudentHistory? history,
    List<StudentSnapshot>? snapshots,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
  }) => StudentCognitiveProfile(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    dimensions: dimensions ?? this.dimensions,
    interests: interests ?? this.interests,
    skills: skills ?? this.skills,
    personality: personality ?? this.personality,
    learningStyle: learningStyle ?? this.learningStyle,
    goals: goals ?? this.goals,
    strengths: strengths ?? this.strengths,
    weaknesses: weaknesses ?? this.weaknesses,
    evidence: evidence ?? this.evidence,
    history: history ?? this.history,
    snapshots: snapshots ?? this.snapshots,
    createdAt: createdAt ?? this.createdAt,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );

  // ─── Evidence Application ─────────────────────────────────────────────────

  /// Applies a [StudentEvidence] record to all affected dimensions and returns
  /// a new [StudentCognitiveProfile] with the updates applied.
  ///
  /// Each entry in [studentEvidence.affectedDimensions] is treated as a signed
  /// delta applied via a weighted moving average to the current score.
  ///
  /// INVARIANT: All keys in [studentEvidence.affectedDimensions] must be
  /// canonical [DimensionKeys] values. If an unknown key is provided:
  /// - In debug mode: an [AssertionError] is thrown immediately.
  /// - In release mode: the key is skipped and a no-op is performed.
  ///
  /// This prevents the silent evidence loss that occurs when domain labels
  /// (e.g. "cs", "stem") accidentally reach this method.
  StudentCognitiveProfile applyEvidence(
    StudentEvidence studentEvidence, {
    required String sessionId,
  }) {
    final now = DateTime.now().toUtc();
    var updatedDimensions = Map<String, CognitiveDimension>.from(dimensions);

    for (final entry in studentEvidence.affectedDimensions.entries) {
      final key = entry.key;
      final delta = entry.value.clamp(-1.0, 1.0);
      final current = updatedDimensions[key];

      // Guard: unknown dimension key. In debug mode this is an immediate error
      // so knowledge-base misconfiguration is caught at development time.
      // In release mode the key is skipped to avoid crashing the app.
      assert(
        current != null,
        '[StudentCognitiveProfile] Evidence "${studentEvidence.id}" targets '
        'unknown dimension "$key". This key is not in DimensionKeys.all. '
        'Profile update was silently skipped for this key. Fix the knowledge '
        'base or EvidenceExtractor so only canonical dimension keys are used.',
      );
      if (current == null) continue;

      final rawNew = (current.score + delta * studentEvidence.weight)
          .clamp(0.0, 1.0);

      // Bayesian-style confidence update: grows with evidence count.
      final newConfidence = (current.confidence +
              (studentEvidence.confidence - current.confidence) /
                  (current.evidenceCount + 1))
          .clamp(0.0, 1.0);

      final update = DimensionUpdate(
        evidenceId: studentEvidence.id,
        previousScore: current.score,
        newScore: rawNew,
        newConfidence: newConfidence,
        timestamp: now,
        reason: studentEvidence.reason,
      );

      updatedDimensions[key] = current.withUpdate(
        newScore: rawNew,
        newConfidence: newConfidence,
        update: update,
      );
    }

    final updatedHistory = history.withEntry(
      ProfileHistoryEntry(
        id: _uuid.v4(),
        updateType: ProfileUpdateType.evidenceApplied,
        sessionId: sessionId,
        evidenceId: studentEvidence.id,
        description:
            'Evidence applied: ${studentEvidence.reason}',
        delta: {
          'evidence_id': studentEvidence.id,
          'affected_dimensions':
              studentEvidence.affectedDimensions,
        },
        timestamp: now,
      ),
    );

    return copyWith(
      dimensions: updatedDimensions,
      evidence: [...evidence, studentEvidence],
      history: updatedHistory,
      lastUpdatedAt: now,
    );
  }


  // ─── Interest Management ──────────────────────────────────────────────────

  /// Adds or updates an [StudentInterest] and records the change in history.
  StudentCognitiveProfile upsertInterest(
    StudentInterest interest, {
    required String sessionId,
  }) {
    final now = DateTime.now().toUtc();
    final existing = interests.indexWhere((i) => i.key == interest.key);
    final updated = existing >= 0
        ? interests.map((i) => i.key == interest.key ? interest : i).toList()
        : [...interests, interest];

    return copyWith(
      interests: updated,
      history: history.withEntry(
        ProfileHistoryEntry(
          id: _uuid.v4(),
          updateType: ProfileUpdateType.interestAdded,
          sessionId: sessionId,
          description: 'Interest upserted: ${interest.label}',
          delta: {'interest_key': interest.key, 'score': interest.score},
          timestamp: now,
        ),
      ),
      lastUpdatedAt: now,
    );
  }

  // ─── Skill Management ─────────────────────────────────────────────────────

  /// Adds or updates a [StudentSkill] and records the change in history.
  StudentCognitiveProfile upsertSkill(
    StudentSkill skill, {
    required String sessionId,
  }) {
    final now = DateTime.now().toUtc();
    final existing = skills.indexWhere((s) => s.skillId == skill.skillId);
    final updated = existing >= 0
        ? skills
            .map((s) => s.skillId == skill.skillId ? skill : s)
            .toList()
        : [...skills, skill];

    return copyWith(
      skills: updated,
      history: history.withEntry(
        ProfileHistoryEntry(
          id: _uuid.v4(),
          updateType: ProfileUpdateType.skillAdded,
          sessionId: sessionId,
          description: 'Skill upserted: ${skill.label}',
          delta: {
            'skill_id': skill.skillId,
            'proficiency': skill.proficiency.name,
          },
          timestamp: now,
        ),
      ),
      lastUpdatedAt: now,
    );
  }

  // ─── Goal Management ──────────────────────────────────────────────────────

  /// Adds or updates a [StudentGoal].
  StudentCognitiveProfile upsertGoal(
    StudentGoal goal, {
    required String sessionId,
  }) {
    final now = DateTime.now().toUtc();
    final existing = goals.indexWhere((g) => g.key == goal.key);
    final updated = existing >= 0
        ? goals.map((g) => g.key == goal.key ? goal : g).toList()
        : [...goals, goal];

    return copyWith(
      goals: updated,
      history: history.withEntry(
        ProfileHistoryEntry(
          id: _uuid.v4(),
          updateType: ProfileUpdateType.goalAdded,
          sessionId: sessionId,
          description: 'Goal upserted: ${goal.description}',
          delta: {'goal_key': goal.key, 'type': goal.type.name},
          timestamp: now,
        ),
      ),
      lastUpdatedAt: now,
    );
  }

  // ─── Strength / Weakness Management ──────────────────────────────────────

  /// Adds or updates a [StudentStrength].
  StudentCognitiveProfile upsertStrength(
    StudentStrength strength, {
    required String sessionId,
  }) {
    final now = DateTime.now().toUtc();
    final existing = strengths.indexWhere((s) => s.key == strength.key);
    final updated = existing >= 0
        ? strengths
            .map((s) => s.key == strength.key ? strength : s)
            .toList()
        : [...strengths, strength];

    return copyWith(
      strengths: updated,
      history: history.withEntry(
        ProfileHistoryEntry(
          id: _uuid.v4(),
          updateType: ProfileUpdateType.strengthDetected,
          sessionId: sessionId,
          description: 'Strength upserted: ${strength.label}',
          delta: {'key': strength.key, 'area': strength.area.name},
          timestamp: now,
        ),
      ),
      lastUpdatedAt: now,
    );
  }

  /// Adds or updates a [StudentWeakness].
  StudentCognitiveProfile upsertWeakness(
    StudentWeakness weakness, {
    required String sessionId,
  }) {
    final now = DateTime.now().toUtc();
    final existing = weaknesses.indexWhere((w) => w.key == weakness.key);
    final updated = existing >= 0
        ? weaknesses
            .map((w) => w.key == weakness.key ? weakness : w)
            .toList()
        : [...weaknesses, weakness];

    return copyWith(
      weaknesses: updated,
      history: history.withEntry(
        ProfileHistoryEntry(
          id: _uuid.v4(),
          updateType: ProfileUpdateType.weaknessDetected,
          sessionId: sessionId,
          description: 'Weakness upserted: ${weakness.label}',
          delta: {'key': weakness.key, 'area': weakness.area.name},
          timestamp: now,
        ),
      ),
      lastUpdatedAt: now,
    );
  }

  // ─── Snapshot ─────────────────────────────────────────────────────────────

  /// Generates an immutable [StudentSnapshot] of the current state and
  /// appends it to the [snapshots] list, returning a new profile.
  StudentCognitiveProfile takeSnapshot({
    required String sessionId,
    String? label,
  }) {
    final now = DateTime.now().toUtc();
    final stats = computeStatistics();
    final snap = StudentSnapshot(
      id: _uuid.v4(),
      studentId: studentId,
      sessionId: sessionId,
      dimensions: Map.unmodifiable(dimensions),
      interests: List.unmodifiable(interests),
      skills: List.unmodifiable(skills),
      personality: personality,
      learningStyle: learningStyle,
      goals: List.unmodifiable(goals),
      strengths: List.unmodifiable(strengths),
      weaknesses: List.unmodifiable(weaknesses),
      evidence: List.unmodifiable(evidence),
      statistics: stats,
      takenAt: now,
      label: label,
    );
    return copyWith(
      snapshots: [...snapshots, snap],
      lastUpdatedAt: now,
    );
  }

  // ─── Statistics ───────────────────────────────────────────────────────────

  /// Computes and returns a [ProfileStatistics] from the current state.
  ProfileStatistics computeStatistics({int topN = 5}) {
    final allDims = dimensions.values.toList();
    final withEvidence = allDims.where((d) => d.evidenceCount > 0).toList();

    final overallConf = allDims.isEmpty
        ? 0.0
        : allDims.fold(0.0, (sum, d) => sum + d.confidence) / allDims.length;

    final coverageRatio = allDims.isEmpty
        ? 0.0
        : withEvidence.length / allDims.length;

    final consistentDims = withEvidence
        .where((d) =>
            d.confidence >= 0.6 &&
            (d.trend == DimensionTrend.stable ||
                d.trend == DimensionTrend.rising))
        .length;
    final consistencyRatio = withEvidence.isEmpty
        ? 0.0
        : consistentDims / withEvidence.length;

    final sorted = [...withEvidence]
      ..sort((a, b) => b.score.compareTo(a.score));

    final weakSorted = [...withEvidence]
      ..sort((a, b) => a.score.compareTo(b.score));

    final risingSorted = withEvidence
        .where((d) => d.trend == DimensionTrend.rising)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final leastConf = [...withEvidence]
      ..sort((a, b) => a.confidence.compareTo(b.confidence));

    final questionsAnswered = evidence
        .where((e) => e.questionId != null)
        .map((e) => e.questionId!)
        .toSet()
        .length;

    return ProfileStatistics(
      totalQuestionsAnswered: questionsAnswered,
      totalEvidenceCount: evidence.length,
      totalMessageCount: evidence
          .where((e) => e.messageId != null)
          .map((e) => e.messageId!)
          .toSet()
          .length,
      overallConfidence: overallConf,
      coverageRatio: coverageRatio,
      consistencyRatio: consistencyRatio,
      strongestDimensions: sorted
          .take(topN)
          .map(DimensionStat.fromDimension)
          .toList(),
      weakestDimensions: weakSorted
          .take(topN)
          .map(DimensionStat.fromDimension)
          .toList(),
      risingDimensions: risingSorted
          .take(topN)
          .map(DimensionStat.fromDimension)
          .toList(),
      leastConfidentDimensions: leastConf
          .take(topN)
          .map(DimensionStat.fromDimension)
          .toList(),
      computedAt: DateTime.now().toUtc(),
    );
  }

  // ─── Dimension Helpers ────────────────────────────────────────────────────

  /// Returns the [CognitiveDimension] for [key], or an initial one if missing.
  CognitiveDimension dimension(String key) =>
      dimensions[key] ??
      CognitiveDimension.initial(
        key: key,
        label: DimensionKeys.labels[key] ?? key,
      );

  /// Returns the score for [key], or 0.0 if untracked.
  double scoreFor(String key) => dimension(key).score;

  /// Returns the confidence for [key], or 0.0 if untracked.
  double confidenceFor(String key) => dimension(key).confidence;

  /// Returns all evidence affecting [dimensionKey].
  List<StudentEvidence> evidenceFor(String dimensionKey) =>
      evidence.where((e) => e.affects(dimensionKey)).toList();

  // ─── Profile Readiness ────────────────────────────────────────────────────

  /// Returns `true` if the profile has enough data for reliable reasoning.
  bool get isActionable =>
      evidence.length >= 5 && computeStatistics().overallConfidence >= 0.35;

  /// Total evidence count.
  int get evidenceCount => evidence.length;

  @override
  List<Object?> get props => [id, studentId, lastUpdatedAt];

  @override
  String toString() =>
      'StudentCognitiveProfile(id: $id, student: $studentId, '
      'evidence: ${evidence.length}, dims: ${dimensions.length})';
}
