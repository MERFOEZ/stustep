import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/academic_guide_service.dart';
import '../../../core/services/admission_service.dart';
import '../../../core/services/app_config_service.dart';
import '../../../core/services/eligibility_evaluator.dart';
import '../models/admission_requirement_model.dart';
import '../models/certificate_eligibility.dart';
import '../models/college_summary.dart';
import '../models/department_summary.dart';
import '../models/effective_requirement.dart';
import '../models/high_school_certificate.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'widgets/eligibility_banner.dart';

/// نتيجة فحص الأهلية على مستوى الكلية وكل أقسامها.
///
/// عرض الأقسام منفصلةً مقصود: هو ما يُظهر أثر استثناءات الأقسام عملياً —
/// طالب قد يكون غير مؤهل لكلية الطب كاملة لكنه مؤهل لقسم التمريض داخلها.
class EligibilityResultScreen extends StatefulWidget {
  final CollegeSummary college;
  final HighSchoolCertificate certificate;
  final Gradient gradient;

  const EligibilityResultScreen({
    super.key,
    required this.college,
    required this.certificate,
    required this.gradient,
  });

  @override
  State<EligibilityResultScreen> createState() =>
      _EligibilityResultScreenState();
}

/// حصيلة الفحص لقسم واحد.
class _DepartmentVerdict {
  final DepartmentSummary department;
  final CertificateEligibility eligibility;

  const _DepartmentVerdict(this.department, this.eligibility);
}

/// حصيلة الفحص كاملة.
class _ResultBundle {
  final CertificateEligibility collegeVerdict;
  final List<_DepartmentVerdict> departmentVerdicts;

  const _ResultBundle(this.collegeVerdict, this.departmentVerdicts);
}

class _EligibilityResultScreenState extends State<EligibilityResultScreen> {
  late Future<_ResultBundle?> _resultFuture;

  @override
  void initState() {
    super.initState();
    _resultFuture = _evaluate();
  }

  /// يجمع البيانات من ثلاث خدمات ثم يمرّرها لمحرّك الأهلية.
  ///
  /// المحرّك نفسه لا يعرف Firestore — يستقبل كائنات جاهزة ويُعيد نتيجة،
  /// ولهذا يمكن اختباره آلياً بلا شبكة.
  Future<_ResultBundle?> _evaluate() async {
    final requirements = await AdmissionService().getRequirements(
      widget.college.id,
    );
    if (requirements == null) return null;

    final departments = await AcademicGuideService().getDepartments(
      widget.college.id,
    );
    final certificatesConfig = await AppConfigService().getCertificatesConfig();
    final bands = certificatesConfig.gradeBands;
    final evaluator = EligibilityEvaluator();

    final collegeVerdict = evaluator.evaluate(
      certificate: widget.certificate,
      requirement: _effective(requirements, null),
      gradeBands: bands,
    );

    final departmentVerdicts = departments.map((department) {
      return _DepartmentVerdict(
        department,
        evaluator.evaluate(
          certificate: widget.certificate,
          requirement: _effective(requirements, department.id),
          gradeBands: bands,
        ),
      );
    }).toList();

    // نرتّب المؤهَّل أولاً حتى يرى الطالب فرصه المتاحة قبل المغلقة.
    departmentVerdicts.sort(
      (a, b) => a.eligibility.level.index.compareTo(b.eligibility.level.index),
    );

    return _ResultBundle(collegeVerdict, departmentVerdicts);
  }

  EffectiveRequirement _effective(
    AdmissionRequirementModel requirements,
    String? departmentId,
  ) {
    return requirements.effectiveFor(
      departmentId: departmentId,
      certificateCode: widget.certificate.type.code,
      trackCode: widget.certificate.track.code,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(
        title: 'admission.eligibility_result.title'.tr(),
      ),
      body: FutureBuilder<_ResultBundle?>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdmissionLoadingState();
          }
          if (snapshot.hasError) {
            return const AdmissionErrorState();
          }

          final bundle = snapshot.data;
          if (bundle == null) {
            return AdmissionEmptyState(
              icon: Icons.rule_folder_outlined,
              message: 'admission.requirements.not_published'.tr(),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _buildCertificateSummary(),
              const SizedBox(height: 18),
              _buildSectionTitle(
                'admission.eligibility_result.college_level'.tr(),
              ),
              EligibilityBanner(
                eligibility: bundle.collegeVerdict,
                targetName: widget.college.name,
              ),
              if (bundle.departmentVerdicts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSectionTitle(
                  'admission.eligibility_result.department_level'.tr(),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'admission.eligibility_result.department_hint'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ...bundle.departmentVerdicts.map(
                  (verdict) => EligibilityBanner(
                    eligibility: verdict.eligibility,
                    targetName: verdict.department.name,
                    compact: true,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCertificateSummary() {
    final certificate = widget.certificate;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admission.eligibility_result.your_certificate'.tr(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(certificate.type.labelKey.tr()),
              _buildTag(certificate.track.labelKey.tr()),
              _buildTag(
                '${certificate.gpa} ${certificate.gpaScale.labelKey.tr()}',
              ),
              _buildTag('${certificate.graduationYear}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
