import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/admission/models/admission_config.dart';
import 'admission_collections.dart';

/// خدمة قراءة إعدادات موديول القبول من `app_config`.
///
/// لماذا تخزين مؤقت في الذاكرة؟
/// لأن هذه البيانات شبه ثابتة (تُحدَّث مرة كل عام دراسي) بينما تُقرأ في كل
/// شاشة تقريباً. بلا تخزين مؤقت ستُقرأ من Firestore عشرات المرات في الجلسة
/// الواحدة بلا فائدة، وهذه قراءات محسوبة على حصة المشروع.
class AppConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final AppConfigService _instance = AppConfigService._internal();

  factory AppConfigService() => _instance;

  AppConfigService._internal();

  UniversityConfig? _universityCache;
  AdmissionConfig? _admissionCache;
  CertificatesConfig? _certificatesCache;

  Future<UniversityConfig> getUniversityConfig({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _universityCache != null) return _universityCache!;
    try {
      final doc = await _configDoc(
        AdmissionCollections.universityConfigDoc,
      ).get();
      _universityCache = UniversityConfig.fromFirestore(doc);
    } catch (e) {
      debugPrint('AppConfigService: failed to load university config: $e');
      _universityCache = const UniversityConfig();
    }
    return _universityCache!;
  }

  Future<AdmissionConfig> getAdmissionConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _admissionCache != null) return _admissionCache!;
    try {
      final doc = await _configDoc(
        AdmissionCollections.admissionConfigDoc,
      ).get();
      _admissionCache = AdmissionConfig.fromFirestore(doc);
    } catch (e) {
      debugPrint('AppConfigService: failed to load admission config: $e');
      _admissionCache = const AdmissionConfig();
    }
    return _admissionCache!;
  }

  Future<CertificatesConfig> getCertificatesConfig({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _certificatesCache != null) return _certificatesCache!;
    try {
      final doc = await _configDoc(
        AdmissionCollections.certificatesConfigDoc,
      ).get();
      _certificatesCache = CertificatesConfig.fromFirestore(doc);
    } catch (e) {
      debugPrint('AppConfigService: failed to load certificates config: $e');
      _certificatesCache = const CertificatesConfig();
    }
    return _certificatesCache!;
  }

  /// حساب المسافة التقريبية بين نقطتين بالكيلومترات (صيغة هافرساين).
  ///
  /// تُستخدم لاقتراح المسافة عند إضافة سكن جديد، ولا تحلّ محل القيمة التي
  /// يُدخلها المالك يدوياً.
  double distanceInKm(GeoPoint from, GeoPoint to) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);

    final halfChord =
        math.pow(math.sin(dLat / 2), 2) +
        math.pow(math.sin(dLon / 2), 2) * math.cos(lat1) * math.cos(lat2);
    final angle = 2 * math.asin(math.sqrt(halfChord));
    return earthRadiusKm * angle;
  }

  /// إفراغ التخزين المؤقت — يُستدعى بعد أي تحديث إداري للإعدادات.
  void clearCache() {
    _universityCache = null;
    _admissionCache = null;
    _certificatesCache = null;
  }

  DocumentReference<Map<String, dynamic>> _configDoc(String docId) =>
      _firestore.collection(AdmissionCollections.appConfig).doc(docId);

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
