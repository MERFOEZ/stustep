import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/academic_guide_service.dart';
import '../models/college_summary.dart';
import '../models/department_summary.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'department_guide_screen.dart';

/// الشاشة الثانية: أقسام الكلية المختارة.
class GuideDepartmentsScreen extends StatelessWidget {
  final CollegeSummary college;
  final Gradient gradient;

  const GuideDepartmentsScreen({
    super.key,
    required this.college,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: college.name),
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
        child: StreamBuilder<List<DepartmentSummary>>(
          stream: AcademicGuideService().watchDepartments(college.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AdmissionLoadingState();
            }
            if (snapshot.hasError) {
              return const AdmissionErrorState();
            }

            final departments = snapshot.data ?? const <DepartmentSummary>[];
            if (departments.isEmpty) {
              return AdmissionEmptyState(
                icon: Icons.school_outlined,
                message: 'admission.guide.no_departments'.tr(),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: departments.length,
              itemBuilder: (context, index) {
                return _buildDepartmentTile(
                  context,
                  departments[index],
                  index,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDepartmentTile(
    BuildContext context,
    DepartmentSummary department,
    int index,
  ) {
    return FadeInUp(
      delay: Duration(milliseconds: index * 70),
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DepartmentGuideScreen(
                  department: department,
                  collegeName: college.name,
                  gradient: gradient,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 20,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      department.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
