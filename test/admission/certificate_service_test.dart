import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/core/services/certificate_service.dart';
import 'package:stustep/features/admission/models/admission_enums.dart';
import 'package:stustep/features/admission/models/high_school_certificate.dart';

/// اختبارات تطبيع المعدل — أساس كل حكم قبول في الموديول.
///
/// لماذا هذه أول ما يُختبر؟ لأن خطأ واحداً في التطبيع يقلب كل نتائج الأهلية
/// والمطابقة معاً: طالب بمعدل 3.6 من 4 معدله الحقيقي 90%، فإن قُورن رقمه
/// الخام (3.6) بحد أدنى قدره 85 لرُفض وهو من المتفوقين.
void main() {
  final service = CertificateService();

  HighSchoolCertificate build({
    required double gpa,
    required GpaScale scale,
    int graduationYear = 2026,
    CertificateType type = CertificateType.yemeniGeneral,
    Map<String, double> subjects = const {},
  }) {
    return HighSchoolCertificate(
      type: type,
      track: HighSchoolTrack.scientific,
      gpa: gpa,
      gpaScale: scale,
      graduationYear: graduationYear,
      subjectGrades: subjects,
    );
  }

  group('تطبيع المعدل حسب السلّم', () {
    test('سلّم النسبة المئوية يبقى كما هو', () {
      final result = service.normalize(
        build(gpa: 87, scale: GpaScale.percentage),
      );
      expect(result, 87);
    });

    test('سلّم 4.0 يُحوَّل إلى نسبة مئوية', () {
      final result = service.normalize(build(gpa: 3.6, scale: GpaScale.gpa4));
      expect(result, closeTo(90, 0.001));
    });

    test('سلّم 5.0 يُحوَّل إلى نسبة مئوية', () {
      final result = service.normalize(build(gpa: 4.0, scale: GpaScale.gpa5));
      expect(result, closeTo(80, 0.001));
    });

    test('القيمة الأعلى من حد السلّم تُقصّ عند 100 ولا تتجاوزه', () {
      final result = service.normalize(build(gpa: 5, scale: GpaScale.gpa4));
      expect(result, 100);
    });

    test('المعدل صفر أو سالب يُعيد صفراً بلا انهيار', () {
      expect(service.normalize(build(gpa: 0, scale: GpaScale.gpa4)), 0);
      expect(service.normalize(build(gpa: -3, scale: GpaScale.percentage)), 0);
    });
  });

  group('سلّم التقديرات — يحتاج جدول تحويل خارجياً', () {
    test('الجدول الافتراضي يحوّل التقدير إلى نسبته', () {
      // 1 = ممتاز → 95 حسب الجدول الافتراضي في الخدمة.
      final result = service.normalize(build(gpa: 1, scale: GpaScale.grade));
      expect(result, 95);
    });

    test('جدول قادم من الإعدادات يتجاوز الجدول الافتراضي', () {
      final result = service.normalize(
        build(gpa: 1, scale: GpaScale.grade),
        gradeBands: {1: 98, 2: 88},
      );
      expect(result, 98);
    });

    test('تقدير خارج الجدول يُعيد صفراً بدل الانهيار', () {
      final result = service.normalize(
        build(gpa: 9, scale: GpaScale.grade),
        gradeBands: {1: 95},
      );
      expect(result, 0);
    });
  });

  group('صلاحية سنة التخرج', () {
    test('غياب القيد يعني قبول أي سنة', () {
      final certificate = build(
        gpa: 90,
        scale: GpaScale.percentage,
        graduationYear: 1999,
      );
      expect(service.isWithinAllowedAge(certificate, null), isTrue);
    });

    test('شهادة داخل المدة المسموحة تُقبل', () {
      final certificate = build(
        gpa: 90,
        scale: GpaScale.percentage,
        graduationYear: 2024,
      );
      expect(
        service.isWithinAllowedAge(certificate, 5, referenceYear: 2026),
        isTrue,
      );
    });

    test('شهادة أقدم من المدة المسموحة تُرفض', () {
      final certificate = build(
        gpa: 90,
        scale: GpaScale.percentage,
        graduationYear: 2015,
      );
      expect(
        service.isWithinAllowedAge(certificate, 5, referenceYear: 2026),
        isFalse,
      );
    });

    test('سنة تخرج في المستقبل تُرفض — بيانات غير منطقية', () {
      final certificate = build(
        gpa: 90,
        scale: GpaScale.percentage,
        graduationYear: 2030,
      );
      expect(
        service.isWithinAllowedAge(certificate, 5, referenceYear: 2026),
        isFalse,
      );
    });
  });

  group('معادلة الشهادات الأجنبية', () {
    test('الشهادة اليمنية لا تحتاج معادلة حتى لو اشترطتها الكلية', () {
      final certificate = build(gpa: 90, scale: GpaScale.percentage);
      expect(service.satisfiesEquivalency(certificate, true), isTrue);
    });

    test('الشهادة الأجنبية بلا معادلة تُرفض عند اشتراطها', () {
      const certificate = HighSchoolCertificate(
        type: CertificateType.foreignEquivalent,
        track: HighSchoolTrack.scientific,
        gpa: 90,
        gpaScale: GpaScale.percentage,
        graduationYear: 2026,
      );
      expect(service.satisfiesEquivalency(certificate, true), isFalse);
    });

    test('الشهادة الأجنبية مع معادلة تُقبل', () {
      const certificate = HighSchoolCertificate(
        type: CertificateType.foreignEquivalent,
        track: HighSchoolTrack.scientific,
        gpa: 90,
        gpaScale: GpaScale.percentage,
        graduationYear: 2026,
        hasEquivalency: true,
      );
      expect(service.satisfiesEquivalency(certificate, true), isTrue);
    });
  });

  group('التحقق من صحة قيمة المعدل ضمن سلّمها', () {
    test('4.5 قيمة غير صالحة في سلّم 4.0', () {
      expect(service.isGpaValueValid(4.5, GpaScale.gpa4), isFalse);
    });

    test('3.9 قيمة صالحة في سلّم 4.0', () {
      expect(service.isGpaValueValid(3.9, GpaScale.gpa4), isTrue);
    });

    test('سلّم التقديرات يقبل الفئات من 1 إلى 4 فقط', () {
      expect(service.isGpaValueValid(2, GpaScale.grade), isTrue);
      expect(service.isGpaValueValid(5, GpaScale.grade), isFalse);
    });
  });
}
