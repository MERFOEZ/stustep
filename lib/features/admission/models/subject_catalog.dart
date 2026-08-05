import 'package:flutter/material.dart';

/// مادة من مواد الثانوية يمكن أن تُشترط درجتها في القبول.
class SubjectEntry {
  /// معرّف إنجليزي ثابت — يطابق `SubjectRequirement.subjectCode`.
  final String code;

  final IconData icon;

  const SubjectEntry({required this.code, required this.icon});

  String get labelKey => 'admission.subjects.$code';
}

/// كتالوج المواد التي تُدخَل درجاتها عند إدخال الشهادة.
///
/// ثابت في الكود لا في Firestore، لنفس سبب كتالوج الاهتمامات: قائمة صغيرة
/// لا تتغيّر، وكل عنصر يحمل أيقونة وهي كائن Dart لا يُخزَّن في قاعدة بيانات.
///
/// ⚠️ هذه المعرّفات يجب أن تطابق حقل `subjectCode` في بيانات شروط القبول.
class SubjectCatalog {
  const SubjectCatalog._();

  static const List<SubjectEntry> all = [
    SubjectEntry(code: 'math', icon: Icons.functions_rounded),
    SubjectEntry(code: 'physics', icon: Icons.bolt_rounded),
    SubjectEntry(code: 'chemistry', icon: Icons.science_rounded),
    SubjectEntry(code: 'biology', icon: Icons.biotech_rounded),
    SubjectEntry(code: 'english', icon: Icons.translate_rounded),
    SubjectEntry(code: 'arabic', icon: Icons.menu_book_rounded),
  ];

  static SubjectEntry? byCode(String code) {
    for (final subject in all) {
      if (subject.code == code) return subject;
    }
    return null;
  }

  /// مفتاح ترجمة المادة، مع تراجع آمن للاسم القادم من قاعدة البيانات إذا
  /// كان المعرّف غير معروف في الكتالوج.
  static String? labelKeyFor(String code) => byCode(code)?.labelKey;
}
