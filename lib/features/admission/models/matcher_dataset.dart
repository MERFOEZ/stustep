import 'admission_requirement_model.dart';
import 'college_summary.dart';
import 'department_guide_model.dart';
import 'department_summary.dart';

/// حزمة البيانات الكاملة التي يحتاجها مساعد اختيار التخصص.
///
/// لماذا نجمع كل شيء في كائن واحد بدل أن تقرأ خوارزمية الترتيب من الخدمات
/// مباشرة؟ لسببين:
///
///   • **الاختبار:** خوارزمية الترتيب تستقبل هذا الكائن جاهزاً، فتصبح دالة
///     خالصة بلا أي اتصال بالشبكة، ويمكن اختبارها آلياً ببيانات مصنوعة.
///
///   • **محاكي «ماذا لو؟»:** الطالب يحرّك معدله فتُعاد الحسبة عشرات المرات
///     في الثانية. تحميل البيانات مرة واحدة في هذا الكائن يجعل كل إعادة
///     حساب تتم في الذاكرة بصفر قراءة من Firestore.
class MatcherDataset {
  /// كل الأقسام في كل الكليات.
  final List<DepartmentSummary> departments;

  /// دليل كل قسم — المفتاح `departmentId`. قد لا يوجد دليل لكل قسم.
  final Map<String, DepartmentGuideModel> guidesByDepartment;

  /// شروط كل كلية — المفتاح `collegeId`. الكلية بلا شروط منشورة لا يمكن
  /// الحكم على أهليتها، وتُستبعد من الترتيب مع الإبلاغ عن عددها.
  final Map<String, AdmissionRequirementModel> requirementsByCollege;

  /// أسماء الكليات لعرضها تحت اسم القسم بلا قراءة إضافية.
  final Map<String, String> collegeNames;

  /// جدول تحويل التقديرات القادم من `app_config/certificates`.
  final Map<int, double> gradeBands;

  const MatcherDataset({
    this.departments = const [],
    this.guidesByDepartment = const {},
    this.requirementsByCollege = const {},
    this.collegeNames = const {},
    this.gradeBands = const {},
  });

  /// حزمة فارغة — تُستخدم كقيمة أولية وعند فشل التحميل.
  static const MatcherDataset empty = MatcherDataset();

  bool get isEmpty => departments.isEmpty;

  /// عدد الأقسام التي تنتمي لكليات نُشرت شروطها فعلاً.
  int get evaluableDepartmentsCount => departments
      .where((department) => requirementsByCollege.containsKey(department.collegeId))
      .length;

  /// بناء الحزمة من القوائم الخام التي تُعيدها الخدمات.
  ///
  /// التحويل إلى خرائط يتم هنا مرة واحدة، لا داخل حلقة الترتيب، حتى يبقى
  /// البحث عن دليل أو شرط بتكلفة ثابتة مهما كبر عدد الأقسام.
  factory MatcherDataset.build({
    required List<DepartmentSummary> departments,
    required List<DepartmentGuideModel> guides,
    required List<AdmissionRequirementModel> requirements,
    required List<CollegeSummary> colleges,
    Map<int, double> gradeBands = const {},
  }) {
    return MatcherDataset(
      departments: departments,
      guidesByDepartment: {
        for (final guide in guides) guide.departmentId: guide,
      },
      requirementsByCollege: {
        for (final requirement in requirements) requirement.collegeId: requirement,
      },
      collegeNames: {for (final college in colleges) college.id: college.name},
      gradeBands: gradeBands,
    );
  }
}
