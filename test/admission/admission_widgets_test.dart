import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/features/admission/exam_papers/widgets/exam_paper_card.dart';
import 'package:stustep/features/admission/housing/widgets/housing_card.dart';
import 'package:stustep/features/admission/housing/widgets/housing_form_fields.dart';
import 'package:stustep/features/admission/matcher/widgets/interest_chip_grid.dart';
import 'package:stustep/features/admission/matcher/widgets/matcher_summary_bar.dart';
import 'package:stustep/features/admission/matcher/widgets/score_breakdown_view.dart';
import 'package:stustep/features/admission/matcher/widgets/suggestion_card.dart';
import 'package:stustep/features/admission/models/admission_enums.dart';
import 'package:stustep/features/admission/models/certificate_eligibility.dart';
import 'package:stustep/features/admission/models/department_summary.dart';
import 'package:stustep/features/admission/models/exam_paper_model.dart';
import 'package:stustep/features/admission/models/housing_model.dart';
import 'package:stustep/features/admission/models/interest_tag.dart';
import 'package:stustep/features/admission/models/major_suggestion.dart';
import 'package:stustep/features/admission/models/matcher_outcome.dart';
import 'package:stustep/features/admission/models/university_portal_link.dart';
import 'package:stustep/features/admission/models/upload_file.dart';
import 'package:stustep/features/admission/portal/widgets/university_link_tile.dart';
import 'package:stustep/features/admission/requirements/widgets/eligibility_banner.dart';
import 'package:stustep/features/admission/widgets/admission_gradient_card.dart';
import 'package:stustep/features/admission/widgets/admission_state_views.dart';

import 'support/localized_pump.dart';

/// اختبارات **رسم** ودجت الموديول بترجماتها الحقيقية.
///
/// الاختبارات المئة السابقة كلها منطق خالص: لا واحد منها يرسم بكسلاً واحداً.
/// هذه الطبقة تسدّ الثغرة الوحيدة الباقية في التحقق الآلي — أن الشاشات
/// **تُبنى فعلاً** بلا استثناءات، وأن كل نص فيها يمرّ عبر ملف الترجمة.
void main() {
  setUpAll(initLocalizationForTests);

  // ===================== ودجت العرض العامة =====================

  group('AdmissionGradientCard — بطاقة القسم في البوابة', () {
    testWidgets('تعرض العنوان والوصف الممرَّرين', (tester) async {
      await pumpLocalized(
        tester,
        AdmissionGradientCard(
          title: 'دليل الكليات',
          subtitle: 'تعرّف على التخصصات',
          icon: Icons.account_balance_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF6200EE), Color(0xFF9C27B0)],
          ),
          onTap: () {},
        ),
      );

      expect(find.text('دليل الكليات'), findsOneWidget);
      expect(find.text('تعرّف على التخصصات'), findsOneWidget);
    });

    testWidgets('الضغط يستدعي onTap مرة واحدة', (tester) async {
      var taps = 0;
      await pumpLocalized(
        tester,
        AdmissionGradientCard(
          title: 'السكنات',
          icon: Icons.holiday_village_rounded,
          gradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
          onTap: () => taps++,
        ),
      );

      // نستدعي `onTap` من الودجت نفسها لا بضغطة إحداثيات: البطاقة داخل
      // حركة `animate_do` تتحرك أثناء الرسم، فالضغط بالإحداثيات يصيب موضعاً
      // مؤقتاً ويجعل الاختبار هشّاً بلا أن يفحص شيئاً إضافياً.
      final card = tester.widget<InkWell>(find.byType(InkWell).first);
      card.onTap!();
      expect(taps, 1);
    });
  });

  group('AdmissionStateViews — حالات التحميل والفراغ والخطأ', () {
    testWidgets('حالة الفراغ تُترجَم ولا تُظهر مفتاحاً خاماً', (tester) async {
      await pumpLocalized(tester, const AdmissionEmptyState());

      expectNoRawTranslationKeys();
    });

    testWidgets('حالة الخطأ تعرض زر إعادة المحاولة عند تمرير onRetry', (
      tester,
    ) async {
      var retries = 0;
      await pumpLocalized(
        tester,
        AdmissionErrorState(onRetry: () => retries++),
      );

      expect(find.text('إعادة المحاولة'), findsOneWidget);
      final retryButton = tester.widget<InkWell>(find.byType(InkWell).first);
      retryButton.onTap!();
      expect(retries, 1);
      expectNoRawTranslationKeys();
    });

    testWidgets('حالة التحميل تُرسم بلا استثناء', (tester) async {
      await pumpLocalized(tester, const AdmissionLoadingState());

      expect(tester.takeException(), isNull);
    });
  });

  // ===================== الأهلية =====================

  group('EligibilityBanner — لافتة نتيجة الأهلية', () {
    testWidgets('المؤهَّل: لا أسباب رفض ولا مفاتيح خام', (tester) async {
      await pumpLocalized(
        tester,
        const EligibilityBanner(
          eligibility: CertificateEligibility(
            level: EligibilityLevel.eligible,
            normalizedGpa: 90,
            requiredGpa: 85,
            gapToMinGpa: 5,
          ),
          targetName: 'كلية الطب',
        ),
      );

      expect(find.text('كلية الطب'), findsOneWidget);
      expectNoRawTranslationKeys();
    });

    testWidgets('غير المؤهَّل: كل سبب رفض يُعرض بالقيمة المطلوبة والفعلية', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        const EligibilityBanner(
          eligibility: CertificateEligibility(
            level: EligibilityLevel.notEligible,
            failedReasons: [
              EligibilityReason(code: 'gpa', required: '85.0', actual: '82.0'),
              EligibilityReason(
                code: 'subject_grade',
                required: '85',
                actual: '82',
                subjectName: 'الأحياء',
              ),
            ],
            normalizedGpa: 82,
            requiredGpa: 85,
            gapToMinGpa: -3,
          ),
          targetName: 'الطب البشري',
        ),
      );

      // الرفض لا يكون مبهماً أبداً: القيمة المطلوبة والفعلية تظهران معاً.
      expect(find.textContaining('85.0'), findsWidgets);
      expect(find.textContaining('82.0'), findsWidgets);
      expect(find.textContaining('الأحياء'), findsOneWidget);
      expectNoRawTranslationKeys();
    });

    testWidgets('«قريب من الشرط» تُرسم بلا استثناء', (tester) async {
      await pumpLocalized(
        tester,
        const EligibilityBanner(
          eligibility: CertificateEligibility(
            level: EligibilityLevel.borderline,
            failedReasons: [
              EligibilityReason(code: 'gpa', required: '85.0', actual: '83.0'),
            ],
            normalizedGpa: 83,
            requiredGpa: 85,
            gapToMinGpa: -2,
          ),
          targetName: 'التمريض',
          compact: true,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  // ===================== مساعد اختيار التخصص =====================

  group('SuggestionCard — بطاقة اقتراح التخصص', () {
    const suggestion = MajorSuggestion(
      department: DepartmentSummary(
        id: 'dep_cs',
        name: 'علوم الحاسوب',
        collegeId: 'col_it',
      ),
      collegeName: 'كلية الحاسوب',
      score: 87.5,
      breakdown: SuggestionBreakdown(
        interestScore: 52.5,
        gpaFitScore: 25,
        certificateFitScore: 10,
        completenessScore: 0,
      ),
      eligibility: CertificateEligibility(
        level: EligibilityLevel.eligible,
        normalizedGpa: 88,
        requiredGpa: 75,
      ),
      matchedInterests: ['programming', 'math'],
    );

    testWidgets('تعرض اسم التخصص وكليته والنتيجة مقرَّبة', (tester) async {
      await pumpLocalized(
        tester,
        const SuggestionCard(
          suggestion: suggestion,
          rank: 1,
          onOpenGuide: _noop,
        ),
      );

      expect(find.text('علوم الحاسوب'), findsOneWidget);
      expect(find.textContaining('كلية الحاسوب'), findsWidgets);
      // النتيجة تُعرض بلا خانات عشرية — 87.5 ← 88.
      expect(find.text('88'), findsWidgets);
    });

    testWidgets('الاهتمامات المطابقة تُعرض بأسمائها المترجَمة', (tester) async {
      await pumpLocalized(
        tester,
        const SuggestionCard(
          suggestion: suggestion,
          rank: 1,
          onOpenGuide: _noop,
        ),
      );

      expectNoRawTranslationKeys();
    });
  });

  group('ScoreBreakdownView — تفصيل النقاط الأربعة', () {
    testWidgets('يعرض المكوّنات الأربعة كلها', (tester) async {
      await pumpLocalized(
        tester,
        const ScoreBreakdownView(
          breakdown: SuggestionBreakdown(
            interestScore: 45,
            gpaFitScore: 25,
            certificateFitScore: 10,
            completenessScore: 5,
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
      expectNoRawTranslationKeys();
    });
  });

  group('MatcherSummaryBar — شريط ملخّص النتائج', () {
    testWidgets('يُبلغ صراحةً عن الأقسام المستبعَدة لغياب شروط كليتها', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        MatcherSummaryBar(
          outcome: const MatcherOutcome(
            suggestions: [],
            skippedForMissingRequirements: 3,
            totalDepartments: 15,
          ),
          eligibleOnly: false,
          onEligibleOnlyChanged: (_) {},
        ),
      );

      // «لا اختفاء صامت»: العدد المستبعَد يظهر رقماً على الشاشة.
      expect(find.textContaining('3'), findsWidgets);
      expectNoRawTranslationKeys();
    });

    testWidgets('مرشّح المؤهَّل فقط يُبلّغ بالتغيير', (tester) async {
      bool? lastValue;
      await pumpLocalized(
        tester,
        MatcherSummaryBar(
          outcome: const MatcherOutcome(totalDepartments: 4),
          eligibleOnly: false,
          onEligibleOnlyChanged: (value) => lastValue = value,
        ),
      );

      await tester.tap(find.byType(Switch));
      expect(lastValue, isTrue);
    });
  });

  group('InterestChipGrid — شبكة الاهتمامات', () {
    testWidgets('تعرض الوسوم الأربعة عشر كلها بأسماء مترجَمة', (tester) async {
      await pumpLocalized(
        tester,
        InterestChipGrid(selected: const {}, onToggle: (_) {}),
      );

      expect(
        find.byType(InkWell),
        findsNWidgets(InterestCatalog.all.length),
      );
      expectNoRawTranslationKeys();
    });

    testWidgets('الضغط على وسم يُبلّغ بمعرّفه لا بنصه المعروض', (tester) async {
      String? toggled;
      await pumpLocalized(
        tester,
        InterestChipGrid(selected: const {}, onToggle: (id) => toggled = id),
      );

      final firstChip = tester.widget<InkWell>(find.byType(InkWell).first);
      firstChip.onTap!();
      expect(toggled, InterestCatalog.all.first.id);
    });
  });

  // ===================== السكنات ونماذج الاختبارات =====================

  group('HousingCard — بطاقة السكن', () {
    testWidgets('تعرض الاسم والسعر والمسافة معاً', (tester) async {
      await pumpLocalized(
        tester,
        HousingCard(
          housing: const HousingModel(
            id: 'h1',
            name: 'سكن النور',
            phone: '777123456',
            createdBy: 'uid1',
            addressText: 'شارع الجامعة',
            priceMonthly: 25000,
            distanceKm: 1.5,
          ),
          onTap: () {},
        ),
      );

      expect(find.text('سكن النور'), findsOneWidget);
      expect(find.textContaining('25000'), findsWidgets);
      expect(find.textContaining('1.5'), findsWidgets);
      expectNoRawTranslationKeys();
    });

    testWidgets('سكن بلا سعر معلن يُرسم بلا استثناء', (tester) async {
      await pumpLocalized(
        tester,
        HousingCard(
          housing: const HousingModel(
            id: 'h2',
            name: 'سكن بلا سعر',
            phone: '777000000',
            createdBy: 'uid1',
          ),
          onTap: () {},
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ExamPaperCard — بطاقة نموذج الاختبار', () {
    testWidgets('تعرض العنوان والسنة وحجم الملف', (tester) async {
      await pumpLocalized(
        tester,
        ExamPaperCard(
          paper: const ExamPaperModel(
            id: 'p1',
            title: 'اختبار الرياضيات النهائي',
            fileUrl: 'https://example.com/a.pdf',
            fileName: 'math.pdf',
            fileSizeBytes: 2 * 1024 * 1024,
            collegeId: 'col_it',
            uploadedBy: 'uid1',
            year: 2025,
            downloadCount: 12,
          ),
          onOpen: () {},
        ),
      );

      expect(find.text('اختبار الرياضيات النهائي'), findsOneWidget);
      expect(find.textContaining('2025'), findsWidgets);
      expect(find.textContaining('MB'), findsWidgets);
      expectNoRawTranslationKeys();
    });
  });

  // ===================== حارس توافق الويب =====================

  group('HousingImagesPicker — معاينة الصور من الذاكرة', () {
    testWidgets('المعاينة تقرأ البايتات لا المسار — فتعمل على الويب أيضاً', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        HousingImagesPicker(
          images: [UploadFile(name: 'a.png', bytes: _onePixelPng)],
          onAdd: () {},
          onRemove: (_) {},
        ),
      );

      // `MemoryImage` لا `FileImage`: الثانية تعتمد على `dart:io` وترمي
      // استثناءً على الويب. هذا الاختبار حارس ضد الرجوع إلى المسارات.
      final decoration = tester
          .widgetList<Container>(find.byType(Container))
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) => decoration.image != null);

      expect(decoration.image!.image, isA<MemoryImage>());
      expect(tester.takeException(), isNull);
    });
  });

  // ===================== بوابة الجامعة الرسمية =====================

  group('UniversityLinkTile — بطاقة الرابط الرسمي', () {
    UniversityPortalLink link(UniversityLinkKind kind, String url) =>
        UniversityPortalLink(
          kind: kind,
          uri: UniversityPortalLink.parseSafeUrl(url)!,
        );

    testWidgets('تعرض عنوان الرابط ووصفه مترجَمين لا كمفاتيح خام', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        UniversityLinkTile(
          link: link(
            UniversityLinkKind.admissionPortal,
            'https://apply.edu.ye',
          ),
          onTap: _noop,
        ),
      );

      expect(find.text('بوابة التقديم الإلكتروني'), findsOneWidget);
      expectNoRawTranslationKeys();
    });

    testWidgets('تعرض المضيف كما هو — هو ما يتحقق منه الطالب قبل الخروج', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        UniversityLinkTile(
          link: link(
            UniversityLinkKind.feesPayment,
            'https://www.apply.edu.ye/fees?year=2026',
          ),
          onTap: _noop,
        ),
      );

      // المضيف بلا `www.` وبلا المسار: قصّة العنوان لا تُقرأ، والمضيف وحده
      // هو ما يميّز الموقع الرسمي من المنتحِل.
      expect(find.text('apply.edu.ye'), findsOneWidget);
    });

    testWidgets('تحمل أيقونة مغادرة التطبيق', (tester) async {
      await pumpLocalized(
        tester,
        UniversityLinkTile(
          link: link(UniversityLinkKind.website, 'https://edu.ye'),
          onTap: _noop,
        ),
      );

      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    });

    testWidgets('الضغط يستدعي onTap مرة واحدة', (tester) async {
      var taps = 0;
      await pumpLocalized(
        tester,
        UniversityLinkTile(
          link: link(UniversityLinkKind.results, 'https://results.edu.ye'),
          onTap: () => taps++,
        ),
      );

      // نفس نهج بطاقة القسم أعلاه: نستدعي `onTap` من الودجت لا بضغطة
      // إحداثيات، لأن `animate_do` تحرّك البطاقة أثناء الرسم.
      tester.widget<InkWell>(find.byType(InkWell).first).onTap!();

      expect(taps, 1);
    });

    testWidgets('الأنواع الأربعة كلها تُرسم بترجماتها بلا استثناء', (
      tester,
    ) async {
      // حارس ضد إضافة نوع جديد للتعداد وننسى مفاتيح ترجمته: الاختبار يمرّ
      // على `values` لا على قائمة مكتوبة يدوياً.
      for (final kind in UniversityLinkKind.values) {
        await pumpLocalized(
          tester,
          UniversityLinkTile(
            link: link(kind, 'https://edu.ye'),
            onTap: _noop,
          ),
        );

        expectNoRawTranslationKeys();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('بالإنجليزية تتغيّر النصوص ويبقى المضيف كما هو', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        UniversityLinkTile(
          link: link(UniversityLinkKind.website, 'https://www.edu.ye'),
          onTap: _noop,
        ),
        locale: const Locale('en'),
      );

      // النص المكتوب داخل الكود لا يتغيّر بتغيّر اللغة — وهذا ما يكشفه.
      expect(find.text('Official Website'), findsOneWidget);
      expect(find.text('edu.ye'), findsOneWidget);
    });
  });
}

void _noop() {}

/// أصغر صورة PNG صالحة (بكسل واحد شفاف) — تكفي لاختبار مسار المعاينة.
final Uint8List _onePixelPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);
