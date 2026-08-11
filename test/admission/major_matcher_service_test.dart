import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/core/services/major_matcher_service.dart';
import 'package:stustep/features/admission/models/admission_enums.dart';
import 'package:stustep/features/admission/models/admission_requirement_model.dart';
import 'package:stustep/features/admission/models/college_summary.dart';
import 'package:stustep/features/admission/models/department_admission_override.dart';
import 'package:stustep/features/admission/models/department_guide_model.dart';
import 'package:stustep/features/admission/models/department_summary.dart';
import 'package:stustep/features/admission/models/high_school_certificate.dart';
import 'package:stustep/features/admission/models/matcher_dataset.dart';
import 'package:stustep/features/admission/models/matcher_input.dart';
import 'package:stustep/features/admission/models/subject_requirement.dart';

/// اختبارات خوارزمية الترتيب ومحاكي «ماذا لو؟».
///
/// كل الاختبارات تعمل على [MatcherDataset] مصنوع يدوياً — **بلا Firestore
/// وبلا شبكة إطلاقاً**. هذا هو المكسب العملي لفصل التحميل عن الترتيب:
/// أعقد منطق في الموديول قابل للتشغيل في أقل من ثانية على أي جهاز.
void main() {
  const referenceYear = 2026;

  // ===================== بيانات اختبار مصنوعة =====================
  //
  // ثلاث كليات وأربعة أقسام تغطي الحالات المهمة:
  //   • الطب: حد عال (85) مع استثناء للتمريض (70) وشرط مادة الأحياء.
  //   • الحاسوب: حد متوسط (75) ووسوم برمجة ورياضيات.
  //   • الآداب: كلية **بلا شروط منشورة** لاختبار الاستبعاد المُبلَّغ عنه.

  const departments = [
    DepartmentSummary(
      id: 'dep_human_medicine',
      name: 'الطب البشري',
      collegeId: 'col_medicine',
    ),
    DepartmentSummary(
      id: 'dep_nursing',
      name: 'التمريض',
      collegeId: 'col_medicine',
    ),
    DepartmentSummary(
      id: 'dep_cs',
      name: 'علوم الحاسوب',
      collegeId: 'col_it',
    ),
    DepartmentSummary(
      id: 'dep_history',
      name: 'التاريخ',
      collegeId: 'col_arts',
    ),
  ];

  const guides = [
    DepartmentGuideModel(
      departmentId: 'dep_human_medicine',
      collegeId: 'col_medicine',
      description: 'وصف الطب',
      coreSubjects: ['تشريح'],
      skills: ['تشخيص'],
      careers: ['طبيب'],
      interestTags: ['biology', 'helping_people'],
    ),
    DepartmentGuideModel(
      departmentId: 'dep_nursing',
      collegeId: 'col_medicine',
      description: 'وصف التمريض',
      coreSubjects: ['رعاية'],
      skills: ['إسعاف'],
      careers: ['ممرض'],
      interestTags: ['helping_people'],
    ),
    DepartmentGuideModel(
      departmentId: 'dep_cs',
      collegeId: 'col_it',
      description: 'وصف الحاسوب',
      coreSubjects: ['برمجة'],
      skills: ['تحليل'],
      careers: ['مطوّر'],
      interestTags: ['programming', 'math'],
    ),
    DepartmentGuideModel(
      departmentId: 'dep_history',
      collegeId: 'col_arts',
      description: 'وصف التاريخ',
      interestTags: ['writing'],
    ),
  ];

  const requirements = [
    AdmissionRequirementModel(
      collegeId: 'col_medicine',
      minGpa: 85,
      acceptedCertificates: ['yemeni_general'],
      allowedTracks: ['scientific'],
      subjectRequirements: [
        SubjectRequirement(
          subjectCode: 'biology',
          subjectName: 'الأحياء',
          minGrade: 85,
        ),
      ],
      departmentOverrides: [
        DepartmentAdmissionOverride(departmentId: 'dep_nursing', minGpa: 70),
      ],
    ),
    AdmissionRequirementModel(
      collegeId: 'col_it',
      minGpa: 75,
      acceptedCertificates: ['yemeni_general'],
      allowedTracks: ['scientific'],
    ),
    // ملاحظة: لا توجد وثيقة شروط لكلية الآداب — مقصود.
  ];

  const colleges = [
    CollegeSummary(id: 'col_medicine', name: 'الطب'),
    CollegeSummary(id: 'col_it', name: 'الحاسوب'),
    CollegeSummary(id: 'col_arts', name: 'الآداب'),
  ];

  final dataset = MatcherDataset.build(
    departments: departments,
    guides: guides,
    requirements: requirements,
    colleges: colleges,
  );

  HighSchoolCertificate certificate({
    double gpa = 80,
    Map<String, double> subjects = const {},
  }) {
    return HighSchoolCertificate(
      type: CertificateType.yemeniGeneral,
      track: HighSchoolTrack.scientific,
      gpa: gpa,
      gpaScale: GpaScale.percentage,
      graduationYear: 2025,
      subjectGrades: subjects,
    );
  }

  final service = MajorMatcherService();

  group('بناء حزمة البيانات', () {
    test('تُحوَّل القوائم إلى خرائط بمفاتيح صحيحة', () {
      expect(dataset.departments.length, 4);
      expect(dataset.guidesByDepartment['dep_cs']?.collegeId, 'col_it');
      expect(dataset.requirementsByCollege['col_medicine']?.minGpa, 85);
      expect(dataset.collegeNames['col_it'], 'الحاسوب');
    });

    test('عدد الأقسام القابلة للتقييم يستثني كلية بلا شروط', () {
      expect(dataset.evaluableDepartmentsCount, 3);
    });
  });

  group('الترتيب الأساسي', () {
    test('التخصص المطابق للاهتمام والمؤهَّل يتصدّر', () {
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 80),
          interests: const ['programming', 'math'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      expect(outcome.top?.department.id, 'dep_cs');
      expect(outcome.top?.eligibility.level, EligibilityLevel.eligible);
    });

    test('تغيّر الاهتمامات يقلب الترتيب رغم ثبات المعدل', () {
      // الدليل الأقوى على أن الاهتمامات ليست زينة: نفس الشهادة تماماً،
      // واهتمامات مختلفة، وترتيب مختلف.
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 80),
          interests: const ['helping_people'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      expect(outcome.top?.department.id, 'dep_nursing');
    });

    test('النتائج مرتّبة تنازلياً بلا استثناء', () {
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 80),
          interests: const ['programming', 'biology'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      for (var i = 1; i < outcome.suggestions.length; i++) {
        expect(
          outcome.suggestions[i - 1].score,
          greaterThanOrEqualTo(outcome.suggestions[i].score),
        );
      }
    });

    test('الاهتمامات المطابقة تُعاد لعرضها كسبب', () {
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 80),
          interests: const ['programming', 'design'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      final cs = outcome.suggestions.firstWhere(
        (item) => item.department.id == 'dep_cs',
      );
      expect(cs.matchedInterests, <String>['programming']);
    });
  });

  group('استثناءات الأقسام داخل الكلية الواحدة', () {
    test('طالب مرفوض من الطب البشري ومقبول في التمريض', () {
      // نفس الكلية ونفس الشهادة ونتيجتان مختلفتان — هذا ما تُثبته
      // استثناءات الأقسام عملياً.
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 75, subjects: {'biology': 90}),
          interests: const ['helping_people', 'biology'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      final medicine = outcome.suggestions.firstWhere(
        (item) => item.department.id == 'dep_human_medicine',
      );
      final nursing = outcome.suggestions.firstWhere(
        (item) => item.department.id == 'dep_nursing',
      );

      expect(medicine.eligibility.isEligible, isFalse);
      expect(nursing.eligibility.isEligible, isTrue);
    });

    test('شرط مادة الأحياء يُطبَّق حتى مع معدل عال', () {
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 95, subjects: {'biology': 60}),
          interests: const ['biology'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      final medicine = outcome.suggestions.firstWhere(
        (item) => item.department.id == 'dep_human_medicine',
      );
      expect(medicine.eligibility.isEligible, isFalse);
    });
  });

  group('الأقسام بلا شروط منشورة', () {
    test('تُستبعَد من الترتيب ويُبلَّغ عن عددها بدل إخفائها بصمت', () {
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 80),
          interests: const ['writing'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      expect(outcome.skippedForMissingRequirements, 1);
      expect(
        outcome.suggestions.map((item) => item.department.id),
        isNot(contains('dep_history')),
      );
      expect(outcome.totalDepartments, 4);
    });
  });

  group('تقييد الكليات المفضّلة', () {
    test('اختيار كلية واحدة يقصر النتائج على أقسامها', () {
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 80),
          interests: const ['programming'],
          preferredCollegeIds: const ['col_it'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      expect(outcome.suggestions.length, 1);
      expect(outcome.suggestions.first.department.id, 'dep_cs');
    });
  });

  group('حزمة بيانات فارغة', () {
    test('تُعيد حصيلة فارغة بلا انهيار', () {
      final outcome = service.rank(
        input: MatcherInput(
          certificate: certificate(),
          interests: const ['math'],
        ),
        dataset: MatcherDataset.empty,
        referenceYear: referenceYear,
      );
      expect(outcome.isEmpty, isTrue);
    });
  });

  group('محاكي «ماذا لو؟»', () {
    final input = MatcherInput(
      certificate: certificate(gpa: 80, subjects: {'biology': 90}),
      interests: const ['biology', 'helping_people'],
    );

    final baseline = service.rank(
      input: input,
      dataset: dataset,
      referenceYear: referenceYear,
    );

    test('رفع المعدل يفتح تخصصاً ويُسمّيه بالاسم', () {
      // بمعدل 80 الطب البشري (85) مغلق. برفعه إلى 88 يجب أن ينفتح.
      final outcome = service.simulate(
        input: input,
        dataset: dataset,
        baseline: baseline,
        modifiedCertificate: input.certificate.copyWith(gpa: 88),
        referenceYear: referenceYear,
      );

      expect(outcome.delta, greaterThan(0));
      expect(
        outcome.unlocked.map((item) => item.department.id),
        contains('dep_human_medicine'),
      );
      expect(outcome.lost, isEmpty);
    });

    test('خفض المعدل يُغلق تخصصاً ويُبلغ بالخسارة', () {
      final outcome = service.simulate(
        input: input,
        dataset: dataset,
        baseline: baseline,
        modifiedCertificate: input.certificate.copyWith(gpa: 50),
        referenceYear: referenceYear,
      );

      expect(outcome.delta, lessThan(0));
      expect(outcome.lost, isNotEmpty);
      expect(outcome.unlocked, isEmpty);
    });

    test('خفض درجة مادة مشترطة وحدها يُغلق الطب رغم ثبات المعدل', () {
      final high = service.rank(
        input: MatcherInput(
          certificate: certificate(gpa: 95, subjects: {'biology': 90}),
          interests: const ['biology'],
        ),
        dataset: dataset,
        referenceYear: referenceYear,
      );

      final outcome = service.simulate(
        input: MatcherInput(
          certificate: certificate(gpa: 95, subjects: {'biology': 90}),
          interests: const ['biology'],
        ),
        dataset: dataset,
        baseline: high,
        modifiedCertificate: certificate(gpa: 95, subjects: {'biology': 50}),
        referenceYear: referenceYear,
      );

      expect(
        outcome.lost.map((item) => item.department.id),
        contains('dep_human_medicine'),
      );
    });

    test('سيناريو مطابق للأصل لا يُنتج أي تغيير', () {
      final outcome = service.simulate(
        input: input,
        dataset: dataset,
        baseline: baseline,
        modifiedCertificate: input.certificate,
        referenceYear: referenceYear,
      );

      expect(outcome.hasChange, isFalse);
      expect(outcome.delta, 0);
    });

    test('المحاكاة لا تُعدّل الشهادة الأصلية', () {
      // ضمانة مهمة: المحاكي فرضية للتخطيط، ويجب ألا يمسّ بيانات الطالب.
      service.simulate(
        input: input,
        dataset: dataset,
        baseline: baseline,
        modifiedCertificate: input.certificate.copyWith(gpa: 99),
        referenceYear: referenceYear,
      );

      expect(input.certificate.gpa, 80);
      expect(input.certificate.subjectGrades['biology'], 90);
    });
  });
}
