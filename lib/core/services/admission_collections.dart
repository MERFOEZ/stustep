/// أسماء مجموعات Firestore الخاصة بموديول القبول الجامعي.
///
/// تجميعها في مكان واحد يمنع الأخطاء المطبعية المتفرّقة في الخدمات، ويجعل
/// أي إعادة تسمية مستقبلية تمسّ ملفاً واحداً فقط.
class AdmissionCollections {
  const AdmissionCollections._();

  // ===== مجموعات قائمة تُقرأ فقط ولا تُعدَّل =====

  /// مملوكة لميزة المواد الدراسية — القراءة فقط.
  static const String colleges = 'colleges';

  /// مملوكة لميزة المواد الدراسية — القراءة فقط.
  static const String departments = 'departments';

  /// مملوكة لخدمة المصادقة — لا يكتب فيها موديولنا إطلاقاً.
  static const String users = 'users';

  // ===== مجموعات الموديول الجديدة =====

  /// مجموعة ظل لـ `departments` — معرّف الوثيقة = معرّف القسم.
  static const String departmentGuides = 'department_guides';

  /// مجموعة ظل لـ `colleges` — معرّف الوثيقة = معرّف الكلية.
  static const String admissionRequirements = 'admission_requirements';

  static const String housings = 'housings';

  static const String examPapers = 'exam_papers';

  static const String appConfig = 'app_config';

  /// وجود وثيقة بمعرّف المستخدم هنا يعني أنه مشرف.
  /// اخترنا هذا بدل حقل `role` داخل `users` لتفادي تعديل خدمة المصادقة
  /// وتفادي ترحيل بيانات المستخدمين الحاليين.
  static const String admins = 'admins';

  /// مجموعة فرعية تحت وثيقة المستخدم — لا نلمس الوثيقة نفسها.
  static const String matcherResults = 'matcher_results';

  // ===== معرّفات وثائق الإعدادات =====

  static const String universityConfigDoc = 'university';
  static const String admissionConfigDoc = 'admission';
  static const String certificatesConfigDoc = 'certificates';
}
