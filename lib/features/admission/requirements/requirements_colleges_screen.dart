import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/academic_guide_service.dart';
import '../guide/widgets/guide_visuals.dart';
import '../models/college_summary.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_gradient_card.dart';
import '../widgets/admission_state_views.dart';
import 'college_requirements_screen.dart';

/// اختيار الكلية لعرض شروط قبولها.
class RequirementsCollegesScreen extends StatelessWidget {
  const RequirementsCollegesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(
        title: 'admission.modules.requirements.title'.tr(),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: StreamBuilder<List<CollegeSummary>>(
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

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Text(
                      'admission.requirements.hint'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.92,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final college = colleges[index];
                      final gradient = GuideVisuals.gradientAt(index);
                      return AdmissionGradientCard(
                        title: college.name,
                        icon: GuideVisuals.collegeIcon(college.icon),
                        gradient: gradient,
                        delayMilliseconds: index * 80,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CollegeRequirementsScreen(
                              college: college,
                              gradient: gradient,
                            ),
                          ),
                        ),
                      );
                    }, childCount: colleges.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
