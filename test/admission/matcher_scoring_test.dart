import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/core/services/matcher_scoring.dart';
import 'package:stustep/features/admission/models/admission_enums.dart';
import 'package:stustep/features/admission/models/certificate_eligibility.dart';
import 'package:stustep/features/admission/models/department_guide_model.dart';
import 'package:stustep/features/admission/models/effective_requirement.dart';
import 'package:stustep/features/admission/models/high_school_certificate.dart';
import 'package:stustep/features/admission/models/major_suggestion.dart';

/// اختبارات مكوّنات نقاط الاقتراح الأربعة.
///
/// كل دالة تُختبر وحدها بمدخلات صريحة، لأن الترتيب الذي لا يمكن تفسير
/// أرقامه لا يمكن الدفاع عنه أمام أحد.
void main() {
  group('نقاط الاهتمامات (وزن 60)', () {
    test('لا تطابق ← صفر', () {
      final result = MatcherScoring.interestScore(
        ['programming'],
        ['biology', 'chemistry'],
      );
      expect(result.score, 0);
      expect(result.matched, isEmpty);
    });

    test('تطابق تام ← الوزن كاملاً', () {
      // كل اهتمامات الطالب مغطاة، وكل وسوم التخصص تخصّه: تغطية 1 ودقة 1.
      final result = MatcherScoring.interestScore(
        ['programming', 'math'],
        ['programming', 'math'],
      );
      expect(result.score, closeTo(MatcherWeights.interests, 0.001));
      expect(result.matched, containsAll(<String>['programming', 'math']));
    });

    test('تُعيد الوسوم المطابقة لعرضها كسبب للطالب', () {
      final result = MatcherScoring.interestScore(
        ['programming', 'design', 'biology'],
        ['programming', 'design'],
      );
      expect(result.matched, <String>['programming', 'design']);
    });

    test('التوسيم المفرط يُعاقَب بشقّ الدقة', () {
      // تخصصان يغطيان اهتمام الطالب الوحيد تغطيةً كاملة، لكن الثاني وسم
      // نفسه بستة وسوم. لولا شقّ الدقة لتساوى الاثنان وتصدّر المتوسّع
      // لكل الطلاب مهما اختلفت اهتماماتهم.
      final focused = MatcherScoring.interestScore(
        ['programming'],
        ['programming'],
      );
      final broad = MatcherScoring.interestScore(
        ['programming'],
        [
          'programming',
          'math',
          'biology',
          'design',
          'writing',
          'business',
        ],
      );

      expect(focused.score, greaterThan(broad.score));
    });

    test('قائمة فارغة من الطرفين ← صفر بلا انهيار', () {
      expect(MatcherScoring.interestScore([], ['math']).score, 0);
      expect(MatcherScoring.interestScore(['math'], []).score, 0);
    });
  });

  group('نقاط ملاءمة المعدل (وزن 25)', () {
    const eligible = CertificateEligibility(level: EligibilityLevel.eligible);
    const borderline = CertificateEligibility(
      level: EligibilityLevel.borderline,
    );
    const notEligible = CertificateEligibility(
      level: EligibilityLevel.notEligible,
    );

    test('مؤهَّل ← الوزن كاملاً', () {
      expect(MatcherScoring.gpaFitScore(eligible), MatcherWeights.gpaFit);
    });

    test('قريب من الشرط ← نصف الوزن', () {
      expect(
        MatcherScoring.gpaFitScore(borderline),
        MatcherWeights.gpaFit / 2,
      );
    });

    test('غير مؤهَّل ← صفر', () {
      expect(MatcherScoring.gpaFitScore(notEligible), 0);
    });
  });

  group('نقاط توافق الشهادة والمسار (وزن 10)', () {
    const certificate = HighSchoolCertificate(
      type: CertificateType.yemeniGeneral,
      track: HighSchoolTrack.scientific,
      gpa: 90,
      gpaScale: GpaScale.percentage,
      graduationYear: 2025,
    );

    test('توافق النوع والمسار ← الوزن كاملاً', () {
      const requirement = EffectiveRequirement(
        collegeId: 'col_test',
        acceptedCertificates: ['yemeni_general'],
        allowedTracks: ['scientific'],
      );
      expect(
        MatcherScoring.certificateFitScore(certificate, requirement),
        MatcherWeights.certificateFit,
      );
    });

    test('توافق شرط واحد ← نصف الوزن', () {
      const requirement = EffectiveRequirement(
        collegeId: 'col_test',
        acceptedCertificates: ['yemeni_general'],
        allowedTracks: ['literary'],
      );
      expect(
        MatcherScoring.certificateFitScore(certificate, requirement),
        MatcherWeights.certificateFit / 2,
      );
    });

    test('لا توافق ← صفر', () {
      const requirement = EffectiveRequirement(
        collegeId: 'col_test',
        acceptedCertificates: ['azhari'],
        allowedTracks: ['literary'],
      );
      expect(MatcherScoring.certificateFitScore(certificate, requirement), 0);
    });
  });

  group('نقاط اكتمال الدليل (وزن 5)', () {
    test('غياب الدليل ← صفر', () {
      expect(MatcherScoring.completenessScore(null), 0);
    });

    test('دليل مكتمل ← الوزن كاملاً', () {
      const guide = DepartmentGuideModel(
        departmentId: 'dep_cs',
        collegeId: 'col_it',
        description: 'وصف',
        coreSubjects: ['برمجة'],
        skills: ['تحليل'],
        careers: ['مطوّر'],
      );
      expect(
        MatcherScoring.completenessScore(guide),
        MatcherWeights.completeness,
      );
    });

    test('دليل ناقص ← جزء من الوزن لا صفراً', () {
      // النقص عيب في بياناتنا لا في التخصص، فلا يُعاقَب بالإقصاء الكامل.
      const guide = DepartmentGuideModel(
        departmentId: 'dep_cs',
        collegeId: 'col_it',
        description: 'وصف',
      );
      final score = MatcherScoring.completenessScore(guide);
      expect(score, greaterThan(0));
      expect(score, lessThan(MatcherWeights.completeness));
    });
  });

  group('سقف النتيجة الإجمالية', () {
    test('أفضل حالة ممكنة لا تتجاوز 100', () {
      const certificate = HighSchoolCertificate(
        type: CertificateType.yemeniGeneral,
        track: HighSchoolTrack.scientific,
        gpa: 99,
        gpaScale: GpaScale.percentage,
        graduationYear: 2026,
      );
      const requirement = EffectiveRequirement(
        collegeId: 'col_it',
        acceptedCertificates: ['yemeni_general'],
        allowedTracks: ['scientific'],
      );
      const guide = DepartmentGuideModel(
        departmentId: 'dep_cs',
        collegeId: 'col_it',
        description: 'وصف',
        coreSubjects: ['برمجة'],
        skills: ['تحليل'],
        careers: ['مطوّر'],
        interestTags: ['programming'],
      );

      final breakdown = MatcherScoring.breakdown(
        interest: MatcherScoring.interestScore(['programming'], [
          'programming',
        ]),
        eligibility: const CertificateEligibility(
          level: EligibilityLevel.eligible,
        ),
        certificate: certificate,
        requirement: requirement,
        guide: guide,
      );

      expect(breakdown.total, closeTo(100, 0.001));
    });
  });
}
