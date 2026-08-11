import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/core/services/eligibility_evaluator.dart';
import 'package:stustep/features/admission/models/admission_enums.dart';
import 'package:stustep/features/admission/models/effective_requirement.dart';
import 'package:stustep/features/admission/models/high_school_certificate.dart';
import 'package:stustep/features/admission/models/subject_requirement.dart';

/// اختبارات محرّك الأهلية — الشروط الستة ومستويات النتيجة الثلاثة.
///
/// المحرّك بلا أي اتصال بالشبكة، ولهذا يُختبر مباشرة بمدخلات صريحة. كل
/// اختبار هنا يمثّل حالة طالب حقيقية، لا مجرد تغطية أسطر.
void main() {
  final evaluator = EligibilityEvaluator();

  // سنة مرجعية ثابتة: بدونها تتغيّر نتيجة اختبارات عمر الشهادة كل عام.
  const referenceYear = 2026;

  HighSchoolCertificate certificate({
    double gpa = 90,
    GpaScale scale = GpaScale.percentage,
    CertificateType type = CertificateType.yemeniGeneral,
    HighSchoolTrack track = HighSchoolTrack.scientific,
    int graduationYear = 2025,
    bool hasEquivalency = false,
    Map<String, double> subjects = const {},
  }) {
    return HighSchoolCertificate(
      type: type,
      track: track,
      gpa: gpa,
      gpaScale: scale,
      graduationYear: graduationYear,
      hasEquivalency: hasEquivalency,
      subjectGrades: subjects,
    );
  }

  EffectiveRequirement requirement({
    double minGpa = 85,
    List<String> certificates = const [],
    List<String> tracks = const [],
    int? maxAge,
    bool requiresEquivalency = false,
    List<SubjectRequirement> subjects = const [],
  }) {
    return EffectiveRequirement(
      collegeId: 'col_medicine',
      acceptedCertificates: certificates,
      allowedTracks: tracks,
      minGpa: minGpa,
      maxCertificateAgeYears: maxAge,
      requiresEquivalency: requiresEquivalency,
      subjectRequirements: subjects,
    );
  }

  group('الحالة المؤهَّلة', () {
    test('استيفاء كل الشروط يُنتج (مؤهَّل) بلا أسباب', () {
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 90),
        requirement: requirement(minGpa: 85),
        referenceYear: referenceYear,
      );

      expect(result.level, EligibilityLevel.eligible);
      expect(result.failedReasons, isEmpty);
      expect(result.normalizedGpa, 90);
      expect(result.requiredGpa, 85);
      expect(result.gapToMinGpa, 5);
    });

    test('القوائم الفارغة تعني (بلا قيد) لا (لا شيء مقبول)', () {
      // شرط بقوائم شهادات ومسارات فارغة يجب ألا يرفض أحداً.
      final result = evaluator.evaluate(
        certificate: certificate(type: CertificateType.azhari),
        requirement: requirement(minGpa: 70),
        referenceYear: referenceYear,
      );
      expect(result.level, EligibilityLevel.eligible);
    });
  });

  group('الشرط الأول — نوع الشهادة', () {
    test('نوع غير مقبول يُنتج سبباً برمز certificate_type', () {
      final result = evaluator.evaluate(
        certificate: certificate(type: CertificateType.technicalDiploma),
        requirement: requirement(certificates: ['yemeni_general']),
        referenceYear: referenceYear,
      );

      expect(result.level, EligibilityLevel.notEligible);
      expect(
        result.failedReasons.map((reason) => reason.code),
        contains('certificate_type'),
      );
    });
  });

  group('الشرط الثاني — المسار الدراسي', () {
    test('مسار غير مسموح يُنتج سبباً برمز track', () {
      final result = evaluator.evaluate(
        certificate: certificate(track: HighSchoolTrack.literary),
        requirement: requirement(tracks: ['scientific']),
        referenceYear: referenceYear,
      );

      expect(result.level, EligibilityLevel.notEligible);
      expect(
        result.failedReasons.map((reason) => reason.code),
        contains('track'),
      );
    });
  });

  group('الشرط الثالث — المعدل بعد التطبيع', () {
    test('المقارنة تتم بعد التطبيع لا بالقيمة الخام', () {
      // 3.6 من 4 تساوي 90% — يجب أن تتجاوز حداً قدره 85 لا أن ترسب دونه.
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 3.6, scale: GpaScale.gpa4),
        requirement: requirement(minGpa: 85),
        referenceYear: referenceYear,
      );

      expect(result.level, EligibilityLevel.eligible);
      expect(result.normalizedGpa, closeTo(90, 0.001));
    });

    test('السبب يحمل القيمة المطلوبة والقيمة الفعلية — لا رفض مبهم', () {
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 60),
        requirement: requirement(minGpa: 85),
        referenceYear: referenceYear,
      );

      final reason = result.failedReasons.firstWhere(
        (item) => item.code == 'gpa',
      );
      expect(reason.required, '85.0');
      expect(reason.actual, '60.0');
    });
  });

  group('مستوى (قريب من الشرط)', () {
    test('فارق ضمن الهامش والمعدل هو السبب الوحيد ← قريب', () {
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 83),
        requirement: requirement(minGpa: 85),
        referenceYear: referenceYear,
      );

      expect(result.level, EligibilityLevel.borderline);
      expect(result.gapToMinGpa, closeTo(-2, 0.001));
    });

    test('فارق أكبر من الهامش ← غير مؤهَّل', () {
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 78),
        requirement: requirement(minGpa: 85),
        referenceYear: referenceYear,
      );
      expect(result.level, EligibilityLevel.notEligible);
    });

    test('وجود سبب آخر مع المعدل يلغي (قريب) — لا أنصاف حلول للمسار', () {
      // المعدل ناقص درجتين فقط، لكن المسار مرفوض أصلاً. المسار لا يُجبر
      // بفارق بسيط، فالنتيجة يجب أن تكون رفضاً كاملاً لا (قريباً).
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 83, track: HighSchoolTrack.literary),
        requirement: requirement(minGpa: 85, tracks: ['scientific']),
        referenceYear: referenceYear,
      );

      expect(result.level, EligibilityLevel.notEligible);
      expect(result.failedReasons.length, 2);
    });
  });

  group('الشرط الرابع — صلاحية سنة التخرج', () {
    test('شهادة أقدم من المدة المسموحة تُرفض', () {
      final result = evaluator.evaluate(
        certificate: certificate(graduationYear: 2015),
        requirement: requirement(minGpa: 70, maxAge: 5),
        referenceYear: referenceYear,
      );

      expect(
        result.failedReasons.map((reason) => reason.code),
        contains('certificate_age'),
      );
    });
  });

  group('الشرط الخامس — المعادلة', () {
    test('شهادة أجنبية بلا معادلة تُرفض عند اشتراطها', () {
      final result = evaluator.evaluate(
        certificate: certificate(type: CertificateType.foreignEquivalent),
        requirement: requirement(minGpa: 70, requiresEquivalency: true),
        referenceYear: referenceYear,
      );

      expect(
        result.failedReasons.map((reason) => reason.code),
        contains('equivalency'),
      );
    });
  });

  group('الشرط السادس — درجات المواد المشترطة', () {
    const biology = SubjectRequirement(
      subjectCode: 'biology',
      subjectName: 'الأحياء',
      minGrade: 85,
    );

    test('درجة أقل من المطلوب ← سبب subject_grade بالقيمتين', () {
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 90, subjects: {'biology': 82}),
        requirement: requirement(minGpa: 85, subjects: [biology]),
        referenceYear: referenceYear,
      );

      final reason = result.failedReasons.firstWhere(
        (item) => item.code == 'subject_grade',
      );
      expect(reason.required, '85');
      expect(reason.actual, '82');
      expect(reason.subjectName, 'الأحياء');
      expect(result.level, EligibilityLevel.notEligible);
    });

    test('درجة غير مُدخلة ← سبب subject_missing لا subject_grade', () {
      // التفريق جوهري: الأولى رفض حقيقي، والثانية نقص معلومة يجب إخبار
      // الطالب بها بدل إيهامه بأنه مرفوض.
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 90),
        requirement: requirement(minGpa: 85, subjects: [biology]),
        referenceYear: referenceYear,
      );

      final codes = result.failedReasons.map((reason) => reason.code);
      expect(codes, contains('subject_missing'));
      expect(codes, isNot(contains('subject_grade')));
    });

    test('المعدل العام المرتفع لا يعوّض نقص درجة المادة', () {
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 99, subjects: {'biology': 50}),
        requirement: requirement(minGpa: 85, subjects: [biology]),
        referenceYear: referenceYear,
      );
      expect(result.level, EligibilityLevel.notEligible);
    });

    test('استيفاء درجة المادة مع المعدل ← مؤهَّل', () {
      final result = evaluator.evaluate(
        certificate: certificate(gpa: 90, subjects: {'biology': 88}),
        requirement: requirement(minGpa: 85, subjects: [biology]),
        referenceYear: referenceYear,
      );
      expect(result.level, EligibilityLevel.eligible);
    });
  });

  group('تراكم الأسباب', () {
    test('كل الشروط المخالفة تُبلَّغ دفعة واحدة لا أولها فقط', () {
      // الطالب يخالف: النوع والمسار والمعدل والمعادلة. عرض سبب واحد
      // كان سيجعله يصحّح شرطاً ثم يُرفض مرة أخرى بسبب آخر.
      final result = evaluator.evaluate(
        certificate: certificate(
          gpa: 50,
          type: CertificateType.foreignEquivalent,
          track: HighSchoolTrack.literary,
        ),
        requirement: requirement(
          minGpa: 85,
          certificates: ['yemeni_general'],
          tracks: ['scientific'],
          requiresEquivalency: true,
        ),
        referenceYear: referenceYear,
      );

      final codes = result.failedReasons.map((reason) => reason.code).toSet();
      expect(codes, containsAll(<String>{
        'certificate_type',
        'track',
        'gpa',
        'equivalency',
      }));
    });
  });
}
