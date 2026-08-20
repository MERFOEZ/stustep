import 'major_suggestion.dart';

/// حصيلة تشغيل واحد لمساعد اختيار التخصص.
///
/// نُعيد كائناً لا قائمة مجرّدة، لأن الطالب يحتاج أن يعرف **ما لم نستطع
/// الحكم عليه** لا ما حكمنا عليه فقط. قسم تنتمي كليته لشروط غير منشورة
/// لا يجوز أن يختفي بصمت — الاختفاء الصامت يوهم الطالب بأن الخيار غير
/// موجود أصلاً.
class MatcherOutcome {
  /// الاقتراحات مرتّبة تنازلياً بالنتيجة.
  final List<MajorSuggestion> suggestions;

  /// عدد الأقسام المستبعَدة لأن كليتها لم تُنشر شروط قبولها بعد.
  final int skippedForMissingRequirements;

  /// إجمالي الأقسام في قاعدة البيانات قبل أي استبعاد.
  final int totalDepartments;

  const MatcherOutcome({
    this.suggestions = const [],
    this.skippedForMissingRequirements = 0,
    this.totalDepartments = 0,
  });

  static const MatcherOutcome empty = MatcherOutcome();

  bool get isEmpty => suggestions.isEmpty;

  /// عدد التخصصات المؤهَّل لها الطالب فعلياً.
  int get eligibleCount =>
      suggestions.where((item) => item.eligibility.isEligible).length;

  /// عدد التخصصات القريبة من الشرط — أهم رقم في شاشة «ماذا لو؟».
  int get borderlineCount =>
      suggestions.where((item) => item.eligibility.isBorderline).length;

  /// أعلى اقتراح — `null` إذا لم تُنتج أي نتيجة.
  MajorSuggestion? get top => suggestions.isEmpty ? null : suggestions.first;

  /// معرّفات التخصصات المؤهَّل لها، لمقارنتها بين سيناريوهين.
  Set<String> get eligibleDepartmentIds => suggestions
      .where((item) => item.eligibility.isEligible)
      .map((item) => item.department.id)
      .toSet();
}

/// نتيجة مقارنة سيناريو «ماذا لو؟» بالوضع الحالي.
///
/// هذه هي القيمة الحقيقية للمحاكي: لا يكفي أن نُظهر للطالب أن معدله ارتفع،
/// بل **ما الذي انفتح له بالضبط** نتيجة ذلك، وما الذي يخسره لو نزل.
class WhatIfOutcome {
  /// تخصصات لم يكن مؤهَّلاً لها وصار مؤهَّلاً بعد التعديل.
  final List<MajorSuggestion> unlocked;

  /// تخصصات كان مؤهَّلاً لها وفقدها بعد التعديل.
  final List<MajorSuggestion> lost;

  /// عدد التخصصات المؤهَّل لها قبل التعديل وبعده.
  final int eligibleBefore;
  final int eligibleAfter;

  const WhatIfOutcome({
    this.unlocked = const [],
    this.lost = const [],
    this.eligibleBefore = 0,
    this.eligibleAfter = 0,
  });

  static const WhatIfOutcome unchanged = WhatIfOutcome();

  /// صافي التغيّر في عدد الفرص — موجب يعني مكسباً.
  int get delta => eligibleAfter - eligibleBefore;

  bool get hasChange => unlocked.isNotEmpty || lost.isNotEmpty;

  /// بناء المقارنة من حصيلتَي تشغيل.
  ///
  /// المقارنة بمعرّفات الأقسام لا بالكائنات، لأن الكائنات تُبنى من جديد في
  /// كل تشغيل ولا يصحّ الاعتماد على تطابقها المرجعي.
  factory WhatIfOutcome.compare({
    required MatcherOutcome before,
    required MatcherOutcome after,
  }) {
    final beforeIds = before.eligibleDepartmentIds;
    final afterIds = after.eligibleDepartmentIds;

    return WhatIfOutcome(
      unlocked: after.suggestions
          .where(
            (item) =>
                item.eligibility.isEligible &&
                !beforeIds.contains(item.department.id),
          )
          .toList(),
      lost: before.suggestions
          .where(
            (item) =>
                item.eligibility.isEligible &&
                !afterIds.contains(item.department.id),
          )
          .toList(),
      eligibleBefore: beforeIds.length,
      eligibleAfter: afterIds.length,
    );
  }
}
