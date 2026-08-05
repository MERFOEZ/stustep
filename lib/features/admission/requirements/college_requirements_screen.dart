import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/admission_service.dart';
import '../../../core/services/certificate_storage_service.dart';
import '../models/admission_requirement_model.dart';
import '../models/college_summary.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'certificate_input_sheet.dart';
import 'eligibility_result_screen.dart';
import 'widgets/requirement_sections_builder.dart';

/// شروط قبول كلية واحدة، مع زر فحص الأهلية.
class CollegeRequirementsScreen extends StatelessWidget {
  final CollegeSummary college;
  final Gradient gradient;

  const CollegeRequirementsScreen({
    super.key,
    required this.college,
    required this.gradient,
  });

  Color get _accent => gradient is LinearGradient
      ? (gradient as LinearGradient).colors.first
      : Colors.deepPurple;

  Future<void> _checkEligibility(BuildContext context) async {
    final saved = await CertificateStorageService().load();
    if (!context.mounted) return;

    final certificate = await CertificateInputSheet.show(
      context,
      initial: saved,
    );
    if (certificate == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EligibilityResultScreen(
          college: college,
          certificate: certificate,
          gradient: gradient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: college.name),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _checkEligibility(context),
        backgroundColor: _accent,
        icon: const Icon(Icons.fact_check_rounded, color: Colors.white),
        label: Text(
          'admission.requirements.check_eligibility'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<AdmissionRequirementModel?>(
        future: AdmissionService().getRequirements(college.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdmissionLoadingState();
          }
          if (snapshot.hasError) {
            return const AdmissionErrorState();
          }

          final requirements = snapshot.data;
          if (requirements == null) {
            return AdmissionEmptyState(
              icon: Icons.rule_folder_outlined,
              message: 'admission.requirements.not_published'.tr(),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: RequirementSectionsBuilder(
              requirements: requirements,
              collegeId: college.id,
              accent: _accent,
            ).build(context),
          );
        },
      ),
    );
  }
}
