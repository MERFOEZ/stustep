import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/admission/models/college_summary.dart';
import '../../features/admission/models/department_guide_model.dart';
import '../../features/admission/models/department_summary.dart';
import 'admission_collections.dart';

/// خدمة قراءة البيانات الأكاديمية: الكليات والأقسام وأدلة التخصصات.
///
/// تقرأ من `colleges` و`departments` القائمتين **قراءةً فقط**، ومن مجموعة
/// الظل `department_guides` التي يملكها موديول القبول.
///
/// نمطان للقراءة، ولكلٍّ سببه:
///   • `watch…` تُعيد `Stream` للشاشات التي تعرض قوائم حيّة.
///   • `get…`  تُعيد `Future` مع تخزين مؤقت، لأن مساعد اختيار التخصص يحتاج
///     كل الأدلة دفعة واحدة ولا يحتاجها حيّة.
class AcademicGuideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final AcademicGuideService _instance =
      AcademicGuideService._internal();

  factory AcademicGuideService() => _instance;

  AcademicGuideService._internal();

  List<CollegeSummary>? _collegesCache;
  final Map<String, List<DepartmentSummary>> _departmentsCache = {};
  final Map<String, DepartmentGuideModel?> _guideCache = {};
  List<DepartmentGuideModel>? _allGuidesCache;

  // ===================== الكليات =====================

  /// بث حيّ لقائمة الكليات، مرتّبة بالاسم في الذاكرة.
  ///
  /// الترتيب في الذاكرة لا عبر `orderBy` تفادياً لفهرس مركّب، التزاماً
  /// بالنمط المتّبع في المشروع.
  Stream<List<CollegeSummary>> watchColleges() {
    return _firestore
        .collection(AdmissionCollections.colleges)
        .snapshots()
        .map((snapshot) {
          final colleges = snapshot.docs
              .map(CollegeSummary.fromFirestore)
              .toList();
          colleges.sort((a, b) => a.name.compareTo(b.name));
          _collegesCache = colleges;
          return colleges;
        });
  }

  Future<List<CollegeSummary>> getColleges({bool forceRefresh = false}) async {
    if (!forceRefresh && _collegesCache != null) return _collegesCache!;
    try {
      final snapshot = await _firestore
          .collection(AdmissionCollections.colleges)
          .get();
      final colleges = snapshot.docs.map(CollegeSummary.fromFirestore).toList();
      colleges.sort((a, b) => a.name.compareTo(b.name));
      _collegesCache = colleges;
    } catch (e) {
      debugPrint('AcademicGuideService: failed to load colleges: $e');
      _collegesCache = const [];
    }
    return _collegesCache!;
  }

  Future<CollegeSummary?> getCollege(String collegeId) async {
    final colleges = await getColleges();
    for (final college in colleges) {
      if (college.id == collegeId) return college;
    }
    return null;
  }

  // ===================== الأقسام =====================

  Stream<List<DepartmentSummary>> watchDepartments(String collegeId) {
    return _firestore
        .collection(AdmissionCollections.departments)
        .where('collegeId', isEqualTo: collegeId)
        .snapshots()
        .map((snapshot) {
          final departments = snapshot.docs
              .map(DepartmentSummary.fromFirestore)
              .toList();
          departments.sort((a, b) => a.name.compareTo(b.name));
          _departmentsCache[collegeId] = departments;
          return departments;
        });
  }

  Future<List<DepartmentSummary>> getDepartments(
    String collegeId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _departmentsCache.containsKey(collegeId)) {
      return _departmentsCache[collegeId]!;
    }
    try {
      final snapshot = await _firestore
          .collection(AdmissionCollections.departments)
          .where('collegeId', isEqualTo: collegeId)
          .get();
      final departments = snapshot.docs
          .map(DepartmentSummary.fromFirestore)
          .toList();
      departments.sort((a, b) => a.name.compareTo(b.name));
      _departmentsCache[collegeId] = departments;
    } catch (e) {
      debugPrint('AcademicGuideService: failed to load departments: $e');
      _departmentsCache[collegeId] = const [];
    }
    return _departmentsCache[collegeId]!;
  }

  /// كل الأقسام في كل الكليات — يحتاجها مساعد اختيار التخصص.
  Future<List<DepartmentSummary>> getAllDepartments({
    bool forceRefresh = false,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AdmissionCollections.departments)
          .get();
      final departments = snapshot.docs
          .map(DepartmentSummary.fromFirestore)
          .toList();
      if (forceRefresh) _departmentsCache.clear();
      return departments;
    } catch (e) {
      debugPrint('AcademicGuideService: failed to load all departments: $e');
      return const [];
    }
  }

  // ===================== أدلة التخصصات =====================

  /// قراءة دليل تخصص بمعرّف القسم مباشرة.
  ///
  /// لأن معرّف وثيقة الدليل مطابق لمعرّف القسم، هذه قراءة بمعرّف معلوم:
  /// لا استعلام، لا فهرس، وأقل تكلفة ممكنة.
  Future<DepartmentGuideModel?> getGuide(String departmentId) async {
    if (_guideCache.containsKey(departmentId)) return _guideCache[departmentId];
    try {
      final doc = await _firestore
          .collection(AdmissionCollections.departmentGuides)
          .doc(departmentId)
          .get();
      _guideCache[departmentId] = doc.exists
          ? DepartmentGuideModel.fromFirestore(doc)
          : null;
    } catch (e) {
      debugPrint('AcademicGuideService: failed to load guide $departmentId: $e');
      _guideCache[departmentId] = null;
    }
    return _guideCache[departmentId];
  }

  Stream<List<DepartmentGuideModel>> watchGuidesByCollege(String collegeId) {
    return _firestore
        .collection(AdmissionCollections.departmentGuides)
        .where('collegeId', isEqualTo: collegeId)
        .snapshots()
        .map((snapshot) {
          final guides = snapshot.docs
              .map(DepartmentGuideModel.fromFirestore)
              .toList();
          guides.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return guides;
        });
  }

  /// كل الأدلة دفعة واحدة — المدخل الأساسي لمساعد اختيار التخصص.
  Future<List<DepartmentGuideModel>> getAllGuides({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _allGuidesCache != null) return _allGuidesCache!;
    try {
      final snapshot = await _firestore
          .collection(AdmissionCollections.departmentGuides)
          .get();
      final guides = snapshot.docs
          .map(DepartmentGuideModel.fromFirestore)
          .toList();
      guides.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      _allGuidesCache = guides;
      for (final guide in guides) {
        _guideCache[guide.departmentId] = guide;
      }
    } catch (e) {
      debugPrint('AcademicGuideService: failed to load all guides: $e');
      _allGuidesCache = const [];
    }
    return _allGuidesCache!;
  }

  void clearCache() {
    _collegesCache = null;
    _departmentsCache.clear();
    _guideCache.clear();
    _allGuidesCache = null;
  }
}
