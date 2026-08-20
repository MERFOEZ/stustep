import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'admission_collections.dart';

/// نتيجة عملية استيراد البيانات الأولية.
class SeedResult {
  final bool success;
  final Map<String, int> written;
  final String? error;

  const SeedResult({required this.success, this.written = const {}, this.error});

  int get totalDocuments =>
      written.values.fold(0, (acc, val) => acc + val);
}

/// أداة تطوير لاستيراد البيانات الأولية من `assets/seed/admission_seed.json`
/// إلى Firestore دفعة واحدة.
///
/// **لماذا وُجدت هذه الأداة؟**
/// البذرة تحتوي أكثر من أربعين وثيقة، بعضها يحمل مصفوفات وكائنات متداخلة.
/// إدخالها يدوياً من Firebase Console يستغرق ساعات ويُنتج أخطاء مطبعية في
/// المعرّفات تُعطّل مساعد اختيار التخصص لاحقاً. الاستيراد الآلي يضمن تطابق
/// المعرّفات مع `InterestCatalog` تماماً.
///
/// **حدود الاستخدام:**
///   • تعمل في وضع التطوير فقط (`kDebugMode`).
///   • تُستدعى **مرة واحدة** ثم يُعاد `enabled` إلى `false`.
///   • بعد تطبيق قواعد الأمان في المرحلة 8، ستفشل الكتابة إلا لمشرف.
class AdmissionSeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final AdmissionSeedService _instance =
      AdmissionSeedService._internal();

  factory AdmissionSeedService() => _instance;

  AdmissionSeedService._internal();

  /// مفتاح التشغيل اليدوي. اجعله `true` مؤقتاً عند الحاجة للاستيراد فقط.
  static const bool enabled = false;

  static const String seedAssetPath = 'assets/seed/admission_seed.json';

  /// هل يُسمح بإظهار زر الاستيراد في الواجهة؟
  static bool get isAvailable => kDebugMode && enabled;

  /// استيراد البذرة كاملة.
  ///
  /// [includeAcademicTree] عند `false` لا تُكتب `colleges` و`departments`،
  /// وهو الخيار الصحيح إذا كانت الكليات والأقسام مُدخلة مسبقاً من الفريق.
  /// في هذه الحالة يجب أن تطابق معرّفات البذرة المعرّفات الحقيقية.
  Future<SeedResult> seed({bool includeAcademicTree = true}) async {
    if (!isAvailable) {
      return const SeedResult(
        success: false,
        error: 'Seeder is disabled. Set AdmissionSeedService.enabled = true.',
      );
    }

    try {
      final raw = await rootBundle.loadString(seedAssetPath);
      final data = json.decode(raw) as Map<String, dynamic>;
      final written = <String, int>{};

      if (includeAcademicTree) {
        written[AdmissionCollections.colleges] = await _writeList(
          collection: AdmissionCollections.colleges,
          items: data['colleges'],
        );
        written[AdmissionCollections.departments] = await _writeList(
          collection: AdmissionCollections.departments,
          items: data['departments'],
        );
      }

      written[AdmissionCollections.departmentGuides] = await _writeList(
        collection: AdmissionCollections.departmentGuides,
        items: data['department_guides'],
        idKey: 'departmentId',
      );

      written[AdmissionCollections.admissionRequirements] = await _writeList(
        collection: AdmissionCollections.admissionRequirements,
        items: data['admission_requirements'],
        idKey: 'collegeId',
      );

      written[AdmissionCollections.appConfig] = await _writeAppConfig(
        data['app_config'],
      );

      debugPrint('AdmissionSeedService: seeding finished — $written');
      return SeedResult(success: true, written: written);
    } catch (e) {
      debugPrint('AdmissionSeedService: seeding failed: $e');
      return SeedResult(success: false, error: e.toString());
    }
  }

  /// كتابة قائمة وثائق بمعرّفات صريحة.
  ///
  /// نستخدم `set` مع `merge: true` لا `add`، حتى لا تتضاعف الوثائق إذا
  /// شُغّل الاستيراد مرتين بالخطأ.
  Future<int> _writeList({
    required String collection,
    required dynamic items,
    String idKey = 'id',
  }) async {
    if (items is! List) return 0;

    final batch = _firestore.batch();
    var count = 0;

    for (final item in items) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final docId = map[idKey]?.toString();
      if (docId == null || docId.isEmpty) continue;

      if (idKey == 'id') map.remove('id');
      map['updatedAt'] = FieldValue.serverTimestamp();

      batch.set(
        _firestore.collection(collection).doc(docId),
        _convertGeoPoints(map),
        SetOptions(merge: true),
      );
      count++;
    }

    if (count > 0) await batch.commit();
    return count;
  }

  Future<int> _writeAppConfig(dynamic config) async {
    if (config is! Map) return 0;

    final batch = _firestore.batch();
    var count = 0;

    config.forEach((key, value) {
      if (value is! Map) return;
      batch.set(
        _firestore
            .collection(AdmissionCollections.appConfig)
            .doc(key.toString()),
        _convertGeoPoints(Map<String, dynamic>.from(value)),
        SetOptions(merge: true),
      );
      count++;
    });

    if (count > 0) await batch.commit();
    return count;
  }

  /// تحويل الإحداثيات المكتوبة كخريطة في ملف JSON إلى نوع `GeoPoint` الأصلي.
  ///
  /// ملف JSON لا يستطيع تمثيل أنواع Firestore الخاصة، لذلك يكتب الموقع
  /// على هيئة `{latitude, longitude}` ونحوّله هنا.
  Map<String, dynamic> _convertGeoPoints(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Map &&
          value.containsKey('latitude') &&
          value.containsKey('longitude')) {
        return MapEntry(
          key,
          GeoPoint(
            (value['latitude'] as num).toDouble(),
            (value['longitude'] as num).toDouble(),
          ),
        );
      }
      return MapEntry(key, value);
    });
  }
}
