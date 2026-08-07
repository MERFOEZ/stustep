import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/external_launcher_service.dart';
import '../../../../core/services/storage_service.dart';

// حقول نموذج إضافة السكن.

/// حقل الموقع: يقبل رابط خرائط ملصوقاً أو إحداثيات مباشرة.
///
/// **لماذا لصق رابط بدل خريطة مدمجة؟**
/// الخريطة المدمجة تتطلب مفتاح API وتعديل ملفات إعداد المنصات — وهي ملفات
/// مصنّفة حساسة في هذا المشروع. صاحب السكن يفتح خرائط جوجل، يشارك الموقع،
/// ويلصق الرابط. النتيجة نفسها بصفر إعدادات.
class HousingLocationField extends StatelessWidget {
  final TextEditingController controller;
  final GeoPoint? parsed;
  final ValueChanged<GeoPoint?> onParsed;

  const HousingLocationField({
    super.key,
    required this.controller,
    required this.parsed,
    required this.onParsed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          textDirection: TextDirection.ltr,
          onChanged: (value) =>
              onParsed(ExternalLauncherService.parseCoordinates(value)),
          decoration: InputDecoration(
            labelText: 'admission.housing.map_link'.tr(),
            helperText: 'admission.housing.map_link_hint'.tr(),
            helperMaxLines: 3,
            prefixIcon: const Icon(Icons.map_rounded),
            suffixIcon: parsed == null
                ? null
                : const Icon(Icons.check_circle, color: Color(0xFF00A152)),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
          ),
        ),
        if (parsed != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text(
              '${parsed!.latitude.toStringAsFixed(5)}, '
              '${parsed!.longitude.toStringAsFixed(5)}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF00A152),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 14),
      ],
    );
  }
}

/// شبكة اختيار صور السكن مع زر إضافة وحذف.
class HousingImagePicker extends StatelessWidget {
  final List<File> images;
  final List<String> existingUrls;
  final ValueChanged<List<File>> onChanged;
  final ValueChanged<String>? onRemoveExisting;

  const HousingImagePicker({
    super.key,
    required this.images,
    required this.onChanged,
    this.existingUrls = const [],
    this.onRemoveExisting,
  });

  int get _total => images.length + existingUrls.length;

  Future<void> _pick(BuildContext context) async {
    if (_total >= StorageService.maxImageCount) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (picked.isEmpty) return;

    final remaining = StorageService.maxImageCount - _total;
    onChanged([
      ...images,
      ...picked.take(remaining).map((file) => File(file.path)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admission.housing.images_hint'.tr(
            args: ['${StorageService.maxImageCount}'],
          ),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...existingUrls.map(
              (url) => _thumb(
                context,
                child: Image.network(url, fit: BoxFit.cover),
                onRemove: onRemoveExisting == null
                    ? null
                    : () => onRemoveExisting!(url),
              ),
            ),
            ...images.map(
              (file) => _thumb(
                context,
                child: Image.file(file, fit: BoxFit.cover),
                onRemove: () =>
                    onChanged(images.where((item) => item != file).toList()),
              ),
            ),
            if (_total < StorageService.maxImageCount)
              _buildAddButton(context),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _thumb(
    BuildContext context, {
    required Widget child,
    VoidCallback? onRemove,
  }) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(13), child: child),
          if (onRemove != null)
            PositionedDirectional(
              top: 2,
              end: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
          ),
        ),
        child: Icon(
          Icons.add_photo_alternate_rounded,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
