import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/admission/models/admission_requirement_model.dart';
import '../../features/admission/models/effective_requirement.dart';
import '../../features/admission/models/high_school_certificate.dart';
import 'admission_collections.dart';

/// خدمة قراءة شروط القبول من مجموعة الظل `admission_requirements`.
///
/// معرّف كل وثيقة مطابق لمعرّف الكلية، لذلك كل القراءات هنا بمعرّف معلوم
/// ولا تحتاج استعلاماً ولا فهرساً.
class AdmissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final AdmissionService _instance = AdmissionService._internal();

  factory AdmissionService() => _instance;

  AdmissionService._internal();

  final Map<String, AdmissionRequirementModel?> _cache = {};
  List<AdmissionRequirementModel>? _allCache;

  /// شروط كلية واحدة — `null` إذا لم تُدخَل بعد.
  Future<AdmissionRequirementModel?> getRequirements(
    String collegeId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(collegeId)) return _cache[collegeId];
    try {
      final doc = await _firestore
          .collection(AdmissionCollections.admissionRequirements)
          .doc(collegeId)
          .get();
      _cache[collegeId] = doc.exists
          ? AdmissionRequirementModel.fromFirestore(doc)
          : null;
    } catch (e) {
      debugPrint('AdmissionService: failed to load requirements $collegeId: $e');
      _cache[collegeId] = null;
    }
    return _cache[collegeId];
  }

  /// بث حيّ لشروط كلية — تستخدمه شاشة الشروط في المرحلة 4.
  Stream<AdmissionRequirementModel?> watchRequirements(String collegeId) {
    return _firestore
        .collection(AdmissionCollections.admissionRequirements)
        .doc(collegeId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final model = AdmissionRequirementModel.fromFirestore(doc);
          _cache[collegeId] = model;
          return model;
        });
  }

  /// كل شروط الكليات دفعة واحدة — يحتاجها مساعد اختيار التخصص.
  Future<List<AdmissionRequirementModel>> getAllRequirements({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _allCache != null) return _allCache!;
    try {
      final snapshot = await _firestore
          .collection(AdmissionCollections.admissionRequirements)
          .get();
      final items = snapshot.docs
          .map(AdmissionRequirementModel.fromFirestore)
          .toList();
      _allCache = items;
      for (final item in items) {
        _cache[item.collegeId] = item;
      }
    } catch (e) {
      debugPrint('AdmissionService: failed to load all requirements: $e');
      _allCache = const [];
    }
    return _allCache!;
  }

  /// خريطة سريعة من معرّف الكلية إلى شروطها — تُسرّع المطابقة.
  Future<Map<String, AdmissionRequirementModel>> getRequirementsMap({
    bool forceRefresh = false,
  }) async {
    final items = await getAllRequirements(forceRefresh: forceRefresh);
    return {for (final item in items) item.collegeId: item};
  }

  /// الشروط النهائية المطبَّقة على قسم بعينه بعد دمج استثناءات القسم.
  ///
  /// تمرير الشهادة اختياري، لكنه ضروري لتطبيق ترتيب أسبقية الحد الأدنى
  /// للمعدل بشكل صحيح (استثناء القسم ← نوع الشهادة ← المسار ← العام).
  Future<EffectiveRequirement?> getEffectiveRequirement({
    required String collegeId,
    String? departmentId,
    HighSchoolCertificate? certificate,
  }) async {
    final requirements = await getRequirements(collegeId);
    if (requirements == null) return null;
    return requirements.effectiveFor(
      departmentId: departmentId,
      certificateCode: certificate?.type.code,
      trackCode: certificate?.track.code,
    );
  }

  /// هل أُدخلت شروط لهذه الكلية أصلاً؟ تستخدمه الواجهة لعرض حالة مناسبة
  /// بدل صفحة فارغة بلا تفسير.
  Future<bool> hasRequirements(String collegeId) async {
    return await getRequirements(collegeId) != null;
  }

  void clearCache() {
    _cache.clear();
    _allCache = null;
  }
}
