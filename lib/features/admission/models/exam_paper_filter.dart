import 'admission_enums.dart';
import 'exam_paper_model.dart';

/// معايير تصفية نماذج الاختبارات.
///
/// كل هذه المعايير تُطبَّق في الذاكرة، لأن `collegeId` وحده هو شرط
/// الاستعلام في Firestore. الجمع بينه وبين التخصص والسنة والنوع في
/// الاستعلام يتطلب فهرساً مركّباً لكل تركيبة ممكنة.
class ExamPaperFilter {
  /// `null` يعني كل التخصصات، بما فيها النماذج العامة للكلية.
  final String? departmentId;

  final int? year;
  final ExamPaperType? type;
  final String query;

  const ExamPaperFilter({
    this.departmentId,
    this.year,
    this.type,
    this.query = '',
  });

  int get activeCount {
    var count = 0;
    if (departmentId != null) count++;
    if (year != null) count++;
    if (type != null) count++;
    if (query.trim().isNotEmpty) count++;
    return count;
  }

  ExamPaperFilter copyWith({
    String? departmentId,
    int? year,
    ExamPaperType? type,
    String? query,
    bool clearDepartment = false,
    bool clearYear = false,
    bool clearType = false,
  }) {
    return ExamPaperFilter(
      departmentId: clearDepartment ? null : (departmentId ?? this.departmentId),
      year: clearYear ? null : (year ?? this.year),
      type: clearType ? null : (type ?? this.type),
      query: query ?? this.query,
    );
  }

  List<ExamPaperModel> apply(List<ExamPaperModel> items) {
    final normalizedQuery = query.trim().toLowerCase();

    return items.where((item) {
      // النماذج العامة للكلية (`departmentId == null`) تظهر مع أي تخصص،
      // لأنها تخص طلاب الكلية كلهم لا قسماً بعينه.
      if (departmentId != null &&
          item.departmentId != null &&
          item.departmentId != departmentId) {
        return false;
      }

      if (year != null && item.year != year) return false;
      if (type != null && item.type != type) return false;

      if (normalizedQuery.isNotEmpty) {
        final haystack = '${item.title} ${item.courseName ?? ''}'.toLowerCase();
        if (!haystack.contains(normalizedQuery)) return false;
      }

      return true;
    }).toList();
  }

  /// السنوات الموجودة فعلاً في النتائج — تُبنى منها قائمة الاختيار حتى
  /// لا نعرض للطالب سنوات لا يوجد فيها أي نموذج.
  static List<int> yearsIn(List<ExamPaperModel> items) {
    final years = items.map((item) => item.year).where((y) => y > 0).toSet();
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }
}
