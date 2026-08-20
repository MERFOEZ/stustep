import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/academic_guide_service.dart';
import '../../guide/widgets/guide_list_views.dart';
import '../../guide/widgets/guide_section_card.dart';
import '../../models/admission_enums.dart';
import '../../models/admission_requirement_model.dart';
import '../../models/department_summary.dart';
import 'requirement_views.dart';

/// بانِي أقسام شاشة شروط القبول.
///
/// فُصل عن الشاشة لسبب واحد صريح: الشاشة تجاوزت سقف الـ 300 سطر المتفق
/// عليه. الفصل أبقى الشاشة مسؤولة عن التحميل والتنقّل فقط، وجعل بناء
/// الأقسام السبعة وحدة مستقلة قابلة للقراءة والتعديل.
class RequirementSectionsBuilder {
  final AdmissionRequirementModel requirements;
  final String collegeId;
  final Color accent;

  const RequirementSectionsBuilder({
    required this.requirements,
    required this.collegeId,
    required this.accent,
  });

  List<Widget> build(BuildContext context) {
    return [
      _buildCertificatesSection(),
      _buildGpaSection(),
      if (requirements.subjectRequirements.isNotEmpty) _buildSubjectsSection(),
      if (requirements.requiredDocuments.isNotEmpty) _buildDocumentsSection(),
      if (requirements.entranceExams.isNotEmpty) _buildExamsSection(),
      if (requirements.departmentOverrides.isNotEmpty) _buildOverridesSection(),
      if (requirements.notes != null && requirements.notes!.isNotEmpty)
        _buildNotesSection(),
    ];
  }

  Widget _buildCertificatesSection() {
    return GuideSectionCard(
      title: 'admission.requirements.accepted_certificates'.tr(),
      icon: Icons.badge_rounded,
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GuideChipsWrap(
            items: requirements.acceptedCertificates
                .map((code) => CertificateType.fromCode(code).labelKey.tr())
                .toList(),
            accentColor: accent,
            chipIcon: Icons.check_rounded,
          ),
          const SizedBox(height: 14),
          Text(
            'admission.requirements.allowed_tracks'.tr(),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          GuideChipsWrap(
            items: requirements.allowedTracks
                .map((code) => HighSchoolTrack.fromCode(code).labelKey.tr())
                .toList(),
            accentColor: accent,
            chipIcon: Icons.alt_route_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildGpaSection() {
    return GuideSectionCard(
      title: 'admission.requirements.min_gpa'.tr(),
      icon: Icons.trending_up_rounded,
      accentColor: accent,
      delayMilliseconds: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RequirementInfoTile(
            icon: Icons.star_rounded,
            label: 'admission.requirements.general_min'.tr(),
            value: '${requirements.minGpa.toStringAsFixed(0)}%',
            accentColor: accent,
          ),
          ...requirements.minGpaByTrack.entries.map(
            (entry) => RequirementInfoTile(
              icon: Icons.alt_route_rounded,
              label: HighSchoolTrack.fromCode(entry.key).labelKey.tr(),
              value: '${entry.value.toStringAsFixed(0)}%',
              accentColor: accent,
            ),
          ),
          ...requirements.minGpaByCertificate.entries.map(
            (entry) => RequirementInfoTile(
              icon: Icons.badge_rounded,
              label: CertificateType.fromCode(entry.key).labelKey.tr(),
              value: '${entry.value.toStringAsFixed(0)}%',
              accentColor: accent,
            ),
          ),
          if (requirements.maxCertificateAgeYears != null)
            RequirementInfoTile(
              icon: Icons.history_rounded,
              label: 'admission.requirements.max_age'.tr(),
              value: 'admission.requirements.years'.tr(
                args: ['${requirements.maxCertificateAgeYears}'],
              ),
              accentColor: accent,
            ),
          if (requirements.requiresEquivalency)
            RequirementInfoTile(
              icon: Icons.approval_rounded,
              label: 'admission.requirements.equivalency_needed'.tr(),
              value: 'admission.requirements.yes'.tr(),
              accentColor: accent,
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectsSection() {
    return GuideSectionCard(
      title: 'admission.requirements.subject_minimums'.tr(),
      icon: Icons.checklist_rounded,
      accentColor: accent,
      delayMilliseconds: 120,
      child: Column(
        children: requirements.subjectRequirements
            .map(
              (item) => SubjectRequirementTile(
                requirement: item,
                accentColor: accent,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return GuideSectionCard(
      title: 'admission.requirements.documents'.tr(),
      icon: Icons.folder_copy_rounded,
      accentColor: accent,
      delayMilliseconds: 180,
      child: DocumentsChecklist(
        documents: requirements.requiredDocuments,
        accentColor: accent,
      ),
    );
  }

  Widget _buildExamsSection() {
    return GuideSectionCard(
      title: 'admission.requirements.entrance_exams'.tr(),
      icon: Icons.quiz_rounded,
      accentColor: accent,
      delayMilliseconds: 240,
      child: Column(
        children: requirements.entranceExams
            .map((exam) => EntranceExamCard(exam: exam, accentColor: accent))
            .toList(),
      ),
    );
  }

  Widget _buildOverridesSection() {
    return GuideSectionCard(
      title: 'admission.requirements.department_exceptions'.tr(),
      icon: Icons.rule_rounded,
      accentColor: accent,
      delayMilliseconds: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admission.requirements.exceptions_hint'.tr(),
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          // نحلّ معرّفات الأقسام إلى أسمائها حتى لا يرى المستخدم معرّفاً خاماً.
          FutureBuilder<List<DepartmentSummary>>(
            future: AcademicGuideService().getDepartments(collegeId),
            builder: (context, snapshot) {
              final names = {
                for (final department in snapshot.data ?? const [])
                  department.id: department.name,
              };
              return Column(
                children: requirements.departmentOverrides.map((item) {
                  return RequirementInfoTile(
                    icon: Icons.school_rounded,
                    label: names[item.departmentId] ?? item.departmentId,
                    value: item.minGpa != null
                        ? '${item.minGpa!.toStringAsFixed(0)}%'
                        : '—',
                    accentColor: accent,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return GuideSectionCard(
      title: 'admission.requirements.notes'.tr(),
      icon: Icons.sticky_note_2_rounded,
      accentColor: accent,
      delayMilliseconds: 360,
      child: Text(
        requirements.notes!,
        style: const TextStyle(fontSize: 13.5, height: 1.6),
      ),
    );
  }
}
