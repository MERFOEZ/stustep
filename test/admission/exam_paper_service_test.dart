import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/core/services/exam_paper_service.dart';
import 'package:stustep/features/admission/models/admission_enums.dart';
import 'package:stustep/features/admission/models/exam_paper_model.dart';

/// اختبارات منطق نماذج الاختبارات الخالص: الفلترة وحساب الحجم والسنوات.
void main() {
  ExamPaperModel paper({
    required String id,
    String title = 'نموذج',
    String? departmentId,
    String? courseName,
    ExamPaperType type = ExamPaperType.model,
    int year = 2025,
    int sizeBytes = 0,
  }) {
    return ExamPaperModel(
      id: id,
      title: title,
      fileUrl: 'https://example.com/$id.pdf',
      collegeId: 'col_it',
      uploadedBy: 'uid_1',
      departmentId: departmentId,
      courseName: courseName,
      type: type,
      year: year,
      fileSizeBytes: sizeBytes,
    );
  }

  final items = [
    paper(
      id: 'p1',
      title: 'نهائي تراكيب البيانات',
      departmentId: 'dep_cs',
      courseName: 'تراكيب البيانات',
      type: ExamPaperType.finalExam,
      year: 2025,
    ),
    paper(
      id: 'p2',
      title: 'نصفي الشبكات',
      departmentId: 'dep_cs',
      type: ExamPaperType.midterm,
      year: 2024,
    ),
    paper(
      id: 'p3',
      title: 'نهائي الدوائر',
      departmentId: 'dep_ee',
      type: ExamPaperType.finalExam,
      year: 2025,
    ),
    // نموذج عام للكلية بلا قسم — حالة حدّية مقصودة.
    paper(id: 'p4', title: 'رياضيات عامة', year: 2023),
  ];

  List<String> idsOf(List<ExamPaperModel> list) =>
      list.map((item) => item.id).toList();

  group('فلترة القسم', () {
    test('اختيار قسم يُعيد نماذجه', () {
      final result = ExamPaperService.applyFilters(
        items,
        departmentId: 'dep_cs',
      );
      expect(idsOf(result), containsAll(<String>['p1', 'p2']));
      expect(idsOf(result), isNot(contains('p3')));
    });

    test('النموذج العام للكلية يظهر مع أي قسم مختار', () {
      // قرار مقصود: نموذج رياضيات عام ينفع طالب الحاسوب وطالب الكهرباء
      // معاً، وإخفاؤه عند اختيار قسم خسارة بلا سبب.
      final result = ExamPaperService.applyFilters(
        items,
        departmentId: 'dep_ee',
      );
      expect(idsOf(result), contains('p4'));
    });
  });

  group('فلترة النوع والسنة', () {
    test('النوع يستبعد ما خالفه', () {
      final result = ExamPaperService.applyFilters(
        items,
        type: ExamPaperType.midterm,
      );
      expect(idsOf(result), <String>['p2']);
    });

    test('السنة تستبعد ما خالفها', () {
      final result = ExamPaperService.applyFilters(items, year: 2025);
      expect(idsOf(result), containsAll(<String>['p1', 'p3']));
      expect(result.length, 2);
    });

    test('النوع والسنة معاً', () {
      final result = ExamPaperService.applyFilters(
        items,
        type: ExamPaperType.finalExam,
        year: 2025,
      );
      expect(idsOf(result), containsAll(<String>['p1', 'p3']));
    });
  });

  group('البحث النصي', () {
    test('يطابق العنوان', () {
      final result = ExamPaperService.applyFilters(items, query: 'الشبكات');
      expect(idsOf(result), <String>['p2']);
    });

    test('يطابق اسم المادة أيضاً لا العنوان فقط', () {
      final result = ExamPaperService.applyFilters(items, query: 'تراكيب');
      expect(idsOf(result), <String>['p1']);
    });

    test('نص غير موجود يُعيد قائمة فارغة', () {
      expect(ExamPaperService.applyFilters(items, query: 'zzz'), isEmpty);
    });
  });

  group('السنوات المتاحة', () {
    test('تُستخرج بلا تكرار ومرتّبة تنازلياً', () {
      // عرض السنوات الموجودة فعلاً لا قائمة ثابتة: القائمة الثابتة كانت
      // ستُظهر سنوات بلا نماذج فيضغطها الطالب ولا يجد شيئاً.
      expect(ExamPaperService.availableYears(items), <int>[2025, 2024, 2023]);
    });

    test('السنة صفر (غير محدَّدة) تُستبعَد', () {
      final withUnknown = [...items, paper(id: 'p5', year: 0)];
      expect(ExamPaperService.availableYears(withUnknown), isNot(contains(0)));
    });

    test('قائمة فارغة تُعيد فراغاً بلا انهيار', () {
      expect(ExamPaperService.availableYears(const []), isEmpty);
    });
  });

  group('تنسيق حجم الملف', () {
    test('الحجم بالميغابايت عند تجاوز الميغا', () {
      expect(paper(id: 'x', sizeBytes: 2 * 1024 * 1024).formattedSize, '2.0 MB');
    });

    test('الحجم بالكيلوبايت دون الميغا', () {
      expect(paper(id: 'x', sizeBytes: 500 * 1024).formattedSize, '500 KB');
    });

    test('الحجم المجهول يُعرض شرطة لا صفراً مضللاً', () {
      expect(paper(id: 'x', sizeBytes: 0).formattedSize, '—');
    });
  });

  group('اسم الملف المحلي', () {
    test('يُبنى من معرّف الوثيقة الثابت لا من العنوان', () {
      // تصحيح متعمَّد لخطأ في نظام تنزيل الفيديو القائم: بناء المعرّف من
      // title.hashCode يجعل الملف المنزَّل يتيماً عند أي تعديل على العنوان.
      final before = paper(id: 'abc123', title: 'عنوان قديم').localFileName;
      final after = paper(id: 'abc123', title: 'عنوان جديد').localFileName;
      expect(before, after);
      expect(before, 'paper_abc123.pdf');
    });
  });
}
