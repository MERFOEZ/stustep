import 'package:cloud_firestore/cloud_firestore.dart';

import 'admission_enums.dart';

/// إعلان سكن طلابي — مجموعة `housings`.
///
/// هذا أول محتوى في التطبيق ينشئه المستخدمون أنفسهم، لذلك يحمل حقل
/// `createdBy` الذي تُبنى عليه قواعد الأمان: الإنشاء يشترط أن يطابق الحقل
/// هوية صاحب الطلب، والتعديل والحذف يقتصران على المالك أو المشرف.
class HousingModel {
  final String id;
  final String name;
  final String description;
  final String phone;
  final String? whatsapp;

  /// إحداثيات السكن — نوع `GeoPoint` الأصلي في Firestore.
  final GeoPoint? location;

  final String addressText;

  /// المسافة عن الجامعة بالكيلومترات.
  final double distanceKm;

  /// روابط الصور على Cloudinary (بحد أقصى ست صور).
  final List<String> images;

  final HousingStatus status;
  final HousingGender gender;
  final double? priceMonthly;
  final int? roomsAvailable;

  /// معرّف المالك — أساس قواعد الأمان.
  final String createdBy;

  /// اسم المالك مُزال التطبيع لتفادي قراءة إضافية من `users`.
  final String createdByName;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final ModerationStatus moderationStatus;
  final int viewCount;

  const HousingModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdBy,
    this.description = '',
    this.whatsapp,
    this.location,
    this.addressText = '',
    this.distanceKm = 0,
    this.images = const [],
    this.status = HousingStatus.available,
    this.gender = HousingGender.male,
    this.priceMonthly,
    this.roomsAvailable,
    this.createdByName = '',
    this.createdAt,
    this.updatedAt,
    this.moderationStatus = ModerationStatus.published,
    this.viewCount = 0,
  });

  bool isOwnedBy(String? uid) => uid != null && uid == createdBy;

  bool get isAvailable => status == HousingStatus.available;

  String? get coverImage => images.isNotEmpty ? images.first : null;

  /// رابط فتح الموقع في تطبيق الخرائط الخارجي.
  ///
  /// اخترنا الرابط الخارجي بدل خريطة مدمجة لأن الأخيرة تتطلب مفتاح API
  /// وتعديل ملفات إعداد المنصات، وهي ملفات مصنّفة حساسة في هذا المشروع.
  String? get mapsUrl {
    final point = location;
    if (point == null) return null;
    return 'https://www.google.com/maps/search/?api=1'
        '&query=${point.latitude},${point.longitude}';
  }

  factory HousingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HousingModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      whatsapp: data['whatsapp'] as String?,
      location: data['location'] is GeoPoint
          ? data['location'] as GeoPoint
          : null,
      addressText: data['addressText'] as String? ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      images: data['images'] is List
          ? (data['images'] as List).map((item) => item.toString()).toList()
          : const [],
      status: HousingStatus.fromCode(data['status'] as String?),
      gender: HousingGender.fromCode(data['gender'] as String?),
      priceMonthly: (data['priceMonthly'] as num?)?.toDouble(),
      roomsAvailable: (data['roomsAvailable'] as num?)?.toInt(),
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
      moderationStatus: ModerationStatus.fromCode(
        data['moderationStatus'] as String?,
      ),
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'phone': phone,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (location != null) 'location': location,
      'addressText': addressText,
      'distanceKm': distanceKm,
      'images': images,
      'status': status.code,
      'gender': gender.code,
      if (priceMonthly != null) 'priceMonthly': priceMonthly,
      if (roomsAvailable != null) 'roomsAvailable': roomsAvailable,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'moderationStatus': moderationStatus.code,
      'viewCount': viewCount,
    };
  }
}
