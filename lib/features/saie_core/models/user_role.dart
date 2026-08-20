/// StuStep — UserRole
///
/// Defines all user paths available in the app.
/// Kept in core/models so it can be imported by any layer
/// without creating circular dependencies.
library;

/// The four user paths in StuStep.
enum UserRole {
  student,
  graduate,
  careerChanger,
  jobSeeker;

  /// Arabic display name.
  String get titleAr => switch (this) {
    UserRole.student       => 'للطلاب',
    UserRole.graduate      => 'للخريجين',
    UserRole.careerChanger => 'لمحوّلي المسار المهني',
    UserRole.jobSeeker     => 'للباحثين عن عمل',
  };

  /// Storage key suffix — used to namespace SharedPreferences keys.
  String get storageKey => switch (this) {
    UserRole.student       => 'student',
    UserRole.graduate      => 'graduate',
    UserRole.careerChanger => 'career_changer',
    UserRole.jobSeeker     => 'job_seeker',
  };

  /// Default introductory message shown at the start of a conversation.
  String get introAr => switch (this) {
    UserRole.student =>
      'مرحباً! 👋 أنا سيرا، مستشارتك في منصة StuStep.\n\n'
      'بناءً على نتائج اختبارك، سأساعدك في اكتشاف التخصص الجامعي الأنسب لك في اليمن.\n\n'
      'هل تريد أن نبدأ بمناقشة نتائجك؟',
    UserRole.graduate =>
      'أهلاً! 👋 أنا سيرا من منصة StuStep.\n\n'
      'بناءً على معلوماتك، سأساعدك في اكتشاف أفضل الفرص المهنية المناسبة لك.\n\n'
      'كيف يمكنني مساعدتك اليوم؟',
    UserRole.careerChanger =>
      'أهلاً! 👋 أنا سيرا من منصة StuStep.\n\n'
      'سأساعدك في التخطيط للانتقال من مجالك الحالي إلى مجالك المستهدف بخطوات واضحة.\n\n'
      'هل تريد أن نبدأ بتحليل الفجوة المهارية؟',
    UserRole.jobSeeker =>
      'أهلاً! 👋 أنا سيرا من منصة StuStep.\n\n'
      'سأساعدك في تحديد المهارات التي تحتاجها والشهادات التي تعزز سيرتك الذاتية.\n\n'
      'ما أول سؤال تريد مناقشته؟',
  };
}
