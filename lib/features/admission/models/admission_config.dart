import 'package:cloud_firestore/cloud_firestore.dart';

/// إعدادات الجامعة — وثيقة `app_config/university`.
class UniversityConfig {
  final String name;
  final String city;
  final GeoPoint? location;

  const UniversityConfig({this.name = '', this.city = '', this.location});

  factory UniversityConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UniversityConfig(
      name: data['name'] as String? ?? '',
      city: data['city'] as String? ?? '',
      location: data['location'] is GeoPoint
          ? data['location'] as GeoPoint
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'city': city,
      if (location != null) 'location': location,
    };
  }
}

/// إعدادات القبول العامة — وثيقة `app_config/admission`.
class AdmissionConfig {
  final String currentAcademicYear;
  final String announcement;
  final bool isMatcherEnabled;

  const AdmissionConfig({
    this.currentAcademicYear = '',
    this.announcement = '',
    this.isMatcherEnabled = true,
  });

  factory AdmissionConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdmissionConfig(
      currentAcademicYear: data['currentAcademicYear'] as String? ?? '',
      announcement: data['announcement'] as String? ?? '',
      isMatcherEnabled: data['isMatcherEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentAcademicYear': currentAcademicYear,
      'announcement': announcement,
      'isMatcherEnabled': isMatcherEnabled,
    };
  }
}

/// جدول تحويل التقديرات إلى نسب مئوية — وثيقة `app_config/certificates`.
///
/// وجوده في الإعدادات لا في الكود يسمح بتصحيح قيم التحويل دون إصدار نسخة
/// جديدة من التطبيق.
class CertificatesConfig {
  /// المفتاح رقم الفئة (1 = ممتاز … 4 = مقبول)، والقيمة نسبتها المئوية.
  final Map<int, double> gradeBands;

  const CertificatesConfig({this.gradeBands = const {}});

  factory CertificatesConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final raw = data['gradeBands'];
    if (raw is! Map) return const CertificatesConfig();
    return CertificatesConfig(
      gradeBands: raw.map(
        (key, value) => MapEntry(
          int.tryParse(key.toString()) ?? 0,
          (value as num?)?.toDouble() ?? 0,
        ),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gradeBands': gradeBands.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }
}
