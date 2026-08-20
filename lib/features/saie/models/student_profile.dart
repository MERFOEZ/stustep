/// SAIE — StudentProfile Model
///
/// The base demographic and academic profile of a student.
/// Populated during onboarding and updated as the session progresses.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StudentProfile
// ─────────────────────────────────────────────────────────────────────────────

/// Core demographic and academic background data for a student.
///
/// This is the foundational profile used during assessment initialization.
/// It does NOT include cognitive or personality data — those are held in
/// [StudentCognitiveProfile].
final class StudentProfile extends Equatable {
  /// Unique student identifier (UUID v4).
  final String id;

  /// Student's full name.
  final String name;

  /// Student's age in years.
  final int? age;

  /// Current academic grade or year (e.g., "Grade 12", "First Year").
  final String? gradeLevel;

  /// Country of residence (ISO 3166-1 alpha-2, e.g., `"SA"`, `"EG"`).
  final String? countryCode;

  /// Preferred language for UI and assessment (ISO 639-1, e.g., `"ar"`, `"en"`).
  final String languageCode;

  /// Self-reported subjects the student excels in.
  final List<String> strongSubjects;

  /// Self-reported subjects the student struggles with.
  final List<String> weakSubjects;

  /// Self-reported extracurricular activities.
  final List<String> extracurriculars;

  /// Self-reported GPA or equivalent academic score (normalized [0.0, 4.0]).
  final double? normalizedGpa;

  /// UTC timestamp when this profile was first created.
  final DateTime createdAt;

  /// UTC timestamp of the last update.
  final DateTime updatedAt;

  const StudentProfile({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
    this.age,
    this.gradeLevel,
    this.countryCode,
    this.strongSubjects = const [],
    this.weakSubjects = const [],
    this.extracurriculars = const [],
    this.normalizedGpa,
  });

  /// Creates a [StudentProfile] from a decoded JSON map.
  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    languageCode: json['language_code'] as String? ?? 'ar',
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    age: json['age'] as int?,
    gradeLevel: json['grade_level'] as String?,
    countryCode: json['country_code'] as String?,
    strongSubjects: (json['strong_subjects'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    weakSubjects: (json['weak_subjects'] as List<dynamic>?)?.cast<String>() ??
        const [],
    extracurriculars: (json['extracurriculars'] as List<dynamic>?)
            ?.cast<String>() ??
        const [],
    normalizedGpa: (json['normalized_gpa'] as num?)?.toDouble(),
  );

  /// Serializes this [StudentProfile] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'language_code': languageCode,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (age != null) 'age': age,
    if (gradeLevel != null) 'grade_level': gradeLevel,
    if (countryCode != null) 'country_code': countryCode,
    if (strongSubjects.isNotEmpty) 'strong_subjects': strongSubjects,
    if (weakSubjects.isNotEmpty) 'weak_subjects': weakSubjects,
    if (extracurriculars.isNotEmpty) 'extracurriculars': extracurriculars,
    if (normalizedGpa != null) 'normalized_gpa': normalizedGpa,
  };

  /// Returns a copy of this [StudentProfile] with specified fields replaced.
  StudentProfile copyWith({
    String? id,
    String? name,
    String? languageCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? age,
    String? gradeLevel,
    String? countryCode,
    List<String>? strongSubjects,
    List<String>? weakSubjects,
    List<String>? extracurriculars,
    double? normalizedGpa,
  }) => StudentProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    languageCode: languageCode ?? this.languageCode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    age: age ?? this.age,
    gradeLevel: gradeLevel ?? this.gradeLevel,
    countryCode: countryCode ?? this.countryCode,
    strongSubjects: strongSubjects ?? this.strongSubjects,
    weakSubjects: weakSubjects ?? this.weakSubjects,
    extracurriculars: extracurriculars ?? this.extracurriculars,
    normalizedGpa: normalizedGpa ?? this.normalizedGpa,
  );

  @override
  List<Object?> get props => [id, name, languageCode];

  @override
  String toString() => 'StudentProfile(id: $id, name: $name)';
}
