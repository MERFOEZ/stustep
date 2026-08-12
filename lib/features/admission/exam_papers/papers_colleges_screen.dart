import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/academic_guide_service.dart';
import '../guide/widgets/guide_visuals.dart';
import '../models/college_summary.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_gradient_card.dart';
import '../widgets/admission_state_views.dart';
import 'my_papers_screen.dart';
import 'papers_list_screen.dart';

/// اختيار الكلية قبل عرض نماذجها.
///
/// نفس نمط شاشتَي الدليل والشروط: الكلية أولاً ثم محتواها. الاتساق مقصود
/// — الطالب تعلّم المسار مرة واحدة فصار يعرفه في كل أقسام البوابة.
class PapersCollegesScreen extends StatelessWidget {
  const PapersCollegesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(
        title: 'admission.papers.title'.tr(),
        actions: [
          IconButton(
            tooltip: 'admission.papers.my_papers'.tr(),
            icon: const Icon(Icons.folder_shared_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyPapersScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<CollegeSummary>>(
        stream: AcademicGuideService().watchColleges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdmissionLoadingState();
          }
          if (snapshot.hasError) {
            return const AdmissionErrorState();
          }

          final colleges = snapshot.data ?? const <CollegeSummary>[];
          if (colleges.isEmpty) {
            return AdmissionEmptyState(
              icon: Icons.account_balance_outlined,
              message: 'admission.guide.no_colleges'.tr(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            itemCount: colleges.length,
            itemBuilder: (context, index) {
              final college = colleges[index];
              final gradient = GuideVisuals.gradientAt(index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AdmissionGradientCard(
                  title: college.name,
                  icon: GuideVisuals.collegeIcon(college.icon),
                  gradient: gradient,
                  delayMilliseconds: (index * 70).clamp(0, 400),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PapersListScreen(
                        college: college,
                        gradient: gradient,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
