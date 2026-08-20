import 'package:flutter/material.dart';

/// وسم اهتمام يختاره الطالب في مساعد اختيار التخصص.
class InterestTag {
  /// معرّف إنجليزي ثابت — يُخزَّن ويُطابَق مع `DepartmentGuideModel.interestTags`.
  final String id;

  final IconData icon;

  const InterestTag({required this.id, required this.icon});

  String get labelKey => 'admission.interests.$id';
}

/// كتالوج الاهتمامات — ثابت في الكود لا في Firestore.
///
/// السبب: الكتالوج يُقرأ في كل جلسة للمساعد، وتخزينه في Firestore يعني قراءة
/// إضافية بلا فائدة لبيانات لا تتغيّر. كما أن كل وسم يحمل أيقونة، والأيقونة
/// كائن Dart لا يُخزَّن في قاعدة بيانات.
///
/// ⚠️ هذه المعرّفات يجب أن تُكتب حرفياً في حقل `interestTags` عند تعبئة
/// أدلة التخصصات، وإلا لن يجد المطابق أي تطابق.
class InterestCatalog {
  const InterestCatalog._();

  static const List<InterestTag> all = [
    InterestTag(id: 'math', icon: Icons.functions_rounded),
    InterestTag(id: 'programming', icon: Icons.code_rounded),
    InterestTag(id: 'biology', icon: Icons.biotech_rounded),
    InterestTag(id: 'chemistry', icon: Icons.science_rounded),
    InterestTag(id: 'physics', icon: Icons.bolt_rounded),
    InterestTag(id: 'design', icon: Icons.palette_rounded),
    InterestTag(id: 'writing', icon: Icons.edit_note_rounded),
    InterestTag(id: 'business', icon: Icons.business_center_rounded),
    InterestTag(id: 'teaching', icon: Icons.school_rounded),
    InterestTag(id: 'helping_people', icon: Icons.volunteer_activism_rounded),
    InterestTag(id: 'law_justice', icon: Icons.gavel_rounded),
    InterestTag(id: 'languages', icon: Icons.translate_rounded),
    InterestTag(id: 'electronics', icon: Icons.memory_rounded),
    InterestTag(id: 'research', icon: Icons.travel_explore_rounded),
  ];

  static const List<String> allIds = [
    'math',
    'programming',
    'biology',
    'chemistry',
    'physics',
    'design',
    'writing',
    'business',
    'teaching',
    'helping_people',
    'law_justice',
    'languages',
    'electronics',
    'research',
  ];

  static InterestTag? byId(String id) {
    for (final tag in all) {
      if (tag.id == id) return tag;
    }
    return null;
  }

  /// تصفية المعرّفات غير المعروفة القادمة من البيانات.
  static List<String> sanitize(Iterable<String> ids) =>
      ids.where(allIds.contains).toList();
}
