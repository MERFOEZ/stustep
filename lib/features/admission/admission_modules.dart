import 'package:flutter/material.dart';

import 'exam_papers/papers_colleges_screen.dart';
import 'guide/guide_colleges_screen.dart';
import 'housing/housing_list_screen.dart';
import 'matcher/matcher_intro_screen.dart';
import 'requirements/requirements_colleges_screen.dart';

/// تعريف الأقسام الخمسة لموديول القبول.
///
/// لماذا ملف تعريف مستقل بدل كتابة البطاقات داخل شاشة الـ Hub؟
/// لأن كل مرحلة قادمة (3 إلى 7) ستربط شاشتها بتغيير **سطر واحد** هنا فقط:
/// تعبئة الحقل `builder`. هذا يبقي شاشة الـ Hub ثابتة بلا تعديل، ويجعل كل
/// مرحلة تلمس ملفاتها الخاصة فقط فتقلّ فرص تعارض الدمج بين أعضاء الفريق.
class AdmissionModuleEntry {
  /// مفتاح الترجمة للعنوان والوصف.
  final String labelKey;
  final String descriptionKey;

  final IconData icon;
  final Gradient gradient;

  /// بانِ الشاشة — `null` يعني أن المرحلة الخاصة بهذا القسم لم تُنفَّذ بعد،
  /// فتعرض الواجهة رسالة «قيد التطوير» بدل التنقّل.
  final WidgetBuilder? builder;

  const AdmissionModuleEntry({
    required this.labelKey,
    required this.descriptionKey,
    required this.icon,
    required this.gradient,
    this.builder,
  });

  bool get isAvailable => builder != null;
}

/// بانِ شاشة كل قسم — دالة عليا مستقلة حتى تبقى القائمة `const`.
Widget _guideBuilder(BuildContext context) => const GuideCollegesScreen();

Widget _requirementsBuilder(BuildContext context) =>
    const RequirementsCollegesScreen();

Widget _matcherBuilder(BuildContext context) => const MatcherIntroScreen();

Widget _housingBuilder(BuildContext context) => const HousingListScreen();

Widget _examPapersBuilder(BuildContext context) =>
    const PapersCollegesScreen();

/// قائمة الأقسام بترتيب العرض في شاشة الـ Hub.
class AdmissionModules {
  const AdmissionModules._();

  static const List<AdmissionModuleEntry> all = [
    AdmissionModuleEntry(
      labelKey: 'admission.modules.guide.title',
      descriptionKey: 'admission.modules.guide.desc',
      icon: Icons.account_balance_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
      ),
      builder: _guideBuilder,
    ),
    AdmissionModuleEntry(
      labelKey: 'admission.modules.requirements.title',
      descriptionKey: 'admission.modules.requirements.desc',
      icon: Icons.fact_check_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF00E676)],
      ),
      builder: _requirementsBuilder,
    ),
    AdmissionModuleEntry(
      labelKey: 'admission.modules.housing.title',
      descriptionKey: 'admission.modules.housing.desc',
      icon: Icons.holiday_village_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFFF6D00), Color(0xFFFFAB40)],
      ),
      builder: _housingBuilder,
    ),
    AdmissionModuleEntry(
      labelKey: 'admission.modules.exam_papers.title',
      descriptionKey: 'admission.modules.exam_papers.desc',
      icon: Icons.picture_as_pdf_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFF304FFE), Color(0xFF448AFF)],
      ),
      builder: _examPapersBuilder,
    ),
    AdmissionModuleEntry(
      labelKey: 'admission.modules.matcher.title',
      descriptionKey: 'admission.modules.matcher.desc',
      icon: Icons.psychology_rounded,
      gradient: LinearGradient(
        colors: [Color(0xFFC51162), Color(0xFFFF4081)],
      ),
      builder: _matcherBuilder,
    ),
  ];
}
