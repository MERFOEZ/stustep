import 'package:cloud_firestore/cloud_firestore.dart';

/// إسقاط للقراءة فقط من مجموعة `colleges` القائمة.
///
/// لماذا نموذج جديد رغم أن شاشات المواد تقرأ نفس المجموعة؟
/// لأن تلك الشاشات تتعامل مع `Map<String, dynamic>` خام بلا نموذج، وتعريف
/// نموذج داخل موديولنا يعني صفر تعديل على ملفات الزملاء وصفر تعارض دمج.
class CollegeSummary {
  final String id;
  final String name;
  final String? icon;

  const CollegeSummary({required this.id, required this.name, this.icon});

  factory CollegeSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CollegeSummary(
      id: doc.id,
      name: data['name'] as String? ?? '',
      icon: data['icon'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, if (icon != null) 'icon': icon};
  }
}
