import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/academic_guide_service.dart';
import '../models/department_guide_model.dart';
import '../models/department_summary.dart';
import '../models/interest_tag.dart';
import '../widgets/admission_state_views.dart';
import 'widgets/guide_list_views.dart';
import 'widgets/guide_section_card.dart';

/// صفحة التخصص: الشرح والمواد الأساسية والمهارات ومجالات العمل.
///
/// تقرأ الدليل بمعرّف القسم مباشرة — قراءة بمعرّف معلوم بلا استعلام،
/// وهي ثمرة قرار «مجموعات الظل» المتخذ في مرحلة التحليل.
class DepartmentGuideScreen extends StatefulWidget {
  final DepartmentSummary department;
  final String collegeName;
  final Gradient gradient;

  const DepartmentGuideScreen({
    super.key,
    required this.department,
    required this.collegeName,
    required this.gradient,
  });

  @override
  State<DepartmentGuideScreen> createState() => _DepartmentGuideScreenState();
}

class _DepartmentGuideScreenState extends State<DepartmentGuideScreen> {
  late Future<DepartmentGuideModel?> _guideFuture;

  @override
  void initState() {
    super.initState();
    _guideFuture = AcademicGuideService().getGuide(widget.department.id);
  }

  void _retry() {
    setState(() {
      _guideFuture = AcademicGuideService().getGuide(widget.department.id);
    });
  }

  Color get _accent => widget.gradient is LinearGradient
      ? (widget.gradient as LinearGradient).colors.first
      : Colors.deepPurple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DepartmentGuideModel?>(
        future: _guideFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdmissionLoadingState();
          }
          if (snapshot.hasError) {
            return AdmissionErrorState(onRetry: _retry);
          }

          final guide = snapshot.data;
          return CustomScrollView(
            slivers: [
              _buildHeader(context, guide),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: guide == null
                      ? _buildMissingGuide()
                      : _buildSections(guide),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DepartmentGuideModel? guide) {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: widget.gradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.collegeName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.department.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (guide != null) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        GuideInfoPill(
                          icon: Icons.calendar_today_rounded,
                          label: 'admission.guide.study_years'.tr(),
                          value: '${guide.studyYears}',
                        ),
                        if (guide.degreeAwarded.isNotEmpty)
                          GuideInfoPill(
                            icon: Icons.workspace_premium_rounded,
                            label: 'admission.guide.degree'.tr(),
                            value: guide.degreeAwarded,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingGuide() {
    return AdmissionEmptyState(
      icon: Icons.menu_book_outlined,
      message: 'admission.guide.no_guide'.tr(),
    );
  }

  Widget _buildSections(DepartmentGuideModel guide) {
    return Column(
      children: [
        if (guide.description.isNotEmpty)
          GuideSectionCard(
            title: 'admission.guide.about'.tr(),
            icon: Icons.info_outline_rounded,
            accentColor: _accent,
            delayMilliseconds: 0,
            child: Text(
              guide.description,
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ),
        if (guide.coreSubjects.isNotEmpty)
          GuideSectionCard(
            title: 'admission.guide.core_subjects'.tr(),
            icon: Icons.library_books_rounded,
            accentColor: _accent,
            delayMilliseconds: 80,
            child: GuideNumberedList(
              items: guide.coreSubjects,
              accentColor: _accent,
            ),
          ),
        if (guide.skills.isNotEmpty)
          GuideSectionCard(
            title: 'admission.guide.skills'.tr(),
            icon: Icons.auto_awesome_rounded,
            accentColor: _accent,
            delayMilliseconds: 160,
            child: GuideChipsWrap(
              items: guide.skills,
              accentColor: _accent,
              chipIcon: Icons.check_rounded,
            ),
          ),
        if (guide.careers.isNotEmpty)
          GuideSectionCard(
            title: 'admission.guide.careers'.tr(),
            icon: Icons.work_outline_rounded,
            accentColor: _accent,
            delayMilliseconds: 240,
            child: GuideNumberedList(
              items: guide.careers,
              accentColor: _accent,
              leadingIcon: Icons.arrow_forward_rounded,
            ),
          ),
        if (guide.knownInterestTags.isNotEmpty)
          GuideSectionCard(
            title: 'admission.guide.suits_you_if'.tr(),
            icon: Icons.favorite_outline_rounded,
            accentColor: _accent,
            delayMilliseconds: 320,
            child: GuideChipsWrap(
              items: guide.knownInterestTags
                  .map((id) => 'admission.interests.$id'.tr())
                  .toList(),
              accentColor: _accent,
              chipIcon: Icons.star_rounded,
            ),
          ),
      ],
    );
  }
}

/// نستخدم `InterestCatalog` للتحقق من صحة الوسوم قبل عرضها، فأي وسم غير
/// معروف لا يظهر كمفتاح ترجمة مكسور أمام المستخدم.
extension GuideInterestFilter on DepartmentGuideModel {
  List<String> get knownInterestTags => InterestCatalog.sanitize(interestTags);
}
