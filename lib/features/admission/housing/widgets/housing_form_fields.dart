import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/storage_service.dart';
import '../../models/upload_file.dart';
import '../../requirements/widgets/certificate_form_fields.dart';

/// حقل نصي موحّد لنموذج السكن.
///
/// وُحِّد شكل الحقول في ودجت واحدة بدل تكرار `InputDecoration` في عشرة
/// مواضع: أي تغيير في هوية النموذج البصرية يمسّ ملفاً واحداً، ولا يمكن أن
/// يشذّ حقل عن البقية سهواً.
class HousingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  const HousingTextField({
    super.key,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: border,
        enabledBorder: border,
      ),
    );
  }
}

/// حقل نصي مسبوق بعنوانه وأيقونته — الشكل المتكرر في كل النموذج.
class HousingLabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  const HousingLabeledField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: label, icon: icon),
        HousingTextField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      ],
    );
  }
}

/// شريط اختيار صور السكن وعرض المختار منها.
///
/// الحد الأقصى يأتي من `StorageService.maxImageCount` لا من رقم مكتوب هنا،
/// حتى تبقى قيمة واحدة تحكم الواجهة والرفع معاً.
class HousingImagesPicker extends StatelessWidget {
  final List<UploadFile> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const HousingImagesPicker({
    super.key,
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(
          text: 'admission.housing.images'.tr(
            namedArgs: {
              'count': '${images.length}',
              'max': '${StorageService.maxImageCount}',
            },
          ),
          icon: Icons.photo_library_outlined,
        ),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (images.length < StorageService.maxImageCount)
                _buildAddTile(context),
              ...images.asMap().entries.map(
                (entry) => _buildImageTile(entry.key, entry.value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddTile(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: 88,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.35),
          ),
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// المعاينة من الذاكرة لا من المسار.
  ///
  /// `FileImage` يعتمد على `dart:io` فلا يعمل على الويب إطلاقاً، بينما
  /// `MemoryImage` يقرأ البايتات نفسها التي ستُرفع فعلاً — فما يراه
  /// المستخدم في المعاينة هو بعينه ما يصل إلى الخادم.
  Widget _buildImageTile(int index, UploadFile file) {
    return Stack(
      children: [
        Container(
          width: 88,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: MemoryImage(file.bytes),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// أدوات التحقق من مدخلات نموذج السكن — **دوال خالصة قابلة للاختبار**.
class HousingValidators {
  const HousingValidators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'admission.housing.field_required'.tr();
    }
    return null;
  }

  /// التحقق من رقم الهاتف.
  ///
  /// نتساهل عمداً في الصيغة (نقبل المسافات والشرطات والبادئات الدولية)
  /// ونشترط تسعة أرقام فقط كحد أدنى، لأن التشدد في صيغة الرقم يمنع أرقاماً
  /// صحيحة أكثر مما يمنع أرقاماً خاطئة.
  static String? phone(String? value) {
    final missing = required(value);
    if (missing != null) return missing;

    final digits = value!.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) return 'admission.housing.invalid_phone'.tr();
    return null;
  }
}
