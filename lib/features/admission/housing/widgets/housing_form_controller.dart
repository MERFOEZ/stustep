import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/admission_enums.dart';
import '../../models/housing_model.dart';

/// حاوية حالة نموذج السكن.
///
/// **لماذا فُصلت عن الشاشة؟**
/// شاشة الإضافة بلغت 330 سطراً أي تجاوزت السقف المتفق عليه. النموذج يضم
/// تسعة متحكمات نصية وأربع قيم حالة، وتجميعها في كائن واحد قلّص الشاشة
/// وجعل تمريرها إلى الودجت الفرعية معاملاً واحداً بدل ثلاثة عشر.
class HousingFormController {
  final name = TextEditingController();
  final description = TextEditingController();
  final phone = TextEditingController();
  final whatsapp = TextEditingController();
  final address = TextEditingController();
  final price = TextEditingController();
  final rooms = TextEditingController();
  final distance = TextEditingController();
  final mapLink = TextEditingController();

  HousingGender gender = HousingGender.male;
  HousingStatus status = HousingStatus.available;
  GeoPoint? location;
  List<File> newImages = [];
  List<String> keptImages = [];

  /// تعبئة النموذج من إعلان قائم عند فتح وضع التعديل.
  void fillFrom(HousingModel existing) {
    name.text = existing.name;
    description.text = existing.description;
    phone.text = existing.phone;
    whatsapp.text = existing.whatsapp ?? '';
    address.text = existing.addressText;
    price.text = existing.priceMonthly?.toStringAsFixed(0) ?? '';
    rooms.text = existing.roomsAvailable?.toString() ?? '';
    distance.text = existing.distanceKm > 0
        ? existing.distanceKm.toStringAsFixed(1)
        : '';
    gender = existing.gender;
    status = existing.status;
    location = existing.location;
    keptImages = List<String>.from(existing.images);

    final point = existing.location;
    if (point != null) {
      mapLink.text = '${point.latitude},${point.longitude}';
    }
  }

  /// بناء النموذج للحفظ.
  ///
  /// حقول الملكية (`createdBy`) تُترك للخدمة لتملأها من هوية المستخدم
  /// الحالي، فلا تُشتق أبداً من مدخلات الواجهة.
  HousingModel buildModel({HousingModel? existing}) {
    return HousingModel(
      id: existing?.id ?? '',
      name: name.text.trim(),
      description: description.text.trim(),
      phone: phone.text.trim(),
      whatsapp: whatsapp.text.trim().isEmpty ? null : whatsapp.text.trim(),
      location: location,
      addressText: address.text.trim(),
      distanceKm: double.tryParse(distance.text.trim()) ?? 0,
      images: keptImages,
      status: status,
      gender: gender,
      priceMonthly: double.tryParse(price.text.trim()),
      roomsAvailable: int.tryParse(rooms.text.trim()),
      createdBy: existing?.createdBy ?? '',
    );
  }

  void removeExistingImage(String url) {
    keptImages = keptImages.where((item) => item != url).toList();
  }

  void dispose() {
    for (final controller in [
      name,
      description,
      phone,
      whatsapp,
      address,
      price,
      rooms,
      distance,
      mapLink,
    ]) {
      controller.dispose();
    }
  }
}
