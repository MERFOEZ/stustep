/// StuStep — AssessmentResult model
library;

import 'package:stustep/features/saie_core/models/user_role.dart';

/// Structured result of a completed assessment.
///
/// `data` is role-specific:
/// - student:        {R, I, A, S, E, C scores, holland_code, top_majors}
/// - graduate:       {major, experience_years, target_field, skills, barrier}
/// - careerChanger:  {current_field, target_field, years_exp, reason, skills}
/// - jobSeeker:      {education, target_field, skills, search_duration, work_type}
///
/// Designed for future fine-tuning export: each result maps 1-to-1 with
/// a conversation and can be extracted as training context.
class AssessmentResult {
  const AssessmentResult({
    required this.assessmentId,
    required this.userId,
    required this.role,
    required this.completedAt,
    required this.data,
  });

  final String assessmentId;
  final String userId;
  final UserRole role;
  final DateTime completedAt;

  /// Structured answers — varies per [role]. Always JSON-serialisable.
  final Map<String, dynamic> data;

  factory AssessmentResult.fromJson(Map<String, dynamic> json) =>
      AssessmentResult(
        assessmentId: json['assessment_id'] as String,
        userId: json['user_id'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.storageKey == json['role'],
        ),
        completedAt: DateTime.parse(json['completed_at'] as String),
        data: Map<String, dynamic>.from(json['data'] as Map),
      );

  Map<String, dynamic> toJson() => {
        'assessment_id': assessmentId,
        'user_id': userId,
        'role': role.storageKey,
        'completed_at': completedAt.toIso8601String(),
        'data': data,
      };
}
