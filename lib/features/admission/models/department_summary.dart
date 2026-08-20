import 'package:cloud_firestore/cloud_firestore.dart';

/// إسقاط للقراءة فقط من مجموعة `departments` القائمة.
///
/// العلاقة مع الكلية معرّف نصي مسطّح (`collegeId`) وليست `DocumentReference`،
/// التزاماً بالنمط المتّبع في المشروع.
class DepartmentSummary {
  final String id;
  final String name;
  final String collegeId;

  const DepartmentSummary({
    required this.id,
    required this.name,
    required this.collegeId,
  });

  factory DepartmentSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DepartmentSummary(
      id: doc.id,
      name: data['name'] as String? ?? '',
      collegeId: data['collegeId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'collegeId': collegeId};
  }
}
