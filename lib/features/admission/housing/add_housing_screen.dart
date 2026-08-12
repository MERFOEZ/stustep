import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/housing_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/admission_enums.dart';
import '../models/housing_model.dart';
import '../models/upload_file.dart';
import '../requirements/widgets/certificate_form_fields.dart';
import '../widgets/admission_app_bar.dart';
import 'widgets/housing_form_fields.dart';

/// نموذج إضافة إعلان سكن.
///
/// أُعيد استخدام ودجت النماذج المبنية في المرحلة 4 (`FormFieldLabel` و
/// `ChoiceChipsGroup`) بدل بناء نسخة ثانية منها، فبدا النموذج جزءاً أصيلاً
/// من الموديول لا إضافة غريبة عليه.
class AddHousingScreen extends StatefulWidget {
  const AddHousingScreen({super.key});

  @override
  State<AddHousingScreen> createState() => _AddHousingScreenState();
}

class _AddHousingScreenState extends State<AddHousingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _rooms = TextEditingController();
  final _distance = TextEditingController();

  HousingStatus _status = HousingStatus.available;
  HousingGender _gender = HousingGender.male;

  final List<UploadFile> _images = [];
  bool _isSaving = false;
  int _uploadedCount = 0;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _phone,
      _whatsapp,
      _address,
      _price,
      _rooms,
      _distance,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// اختيار الصور وقراءتها **بايتات لا مسارات**.
  ///
  /// مسار `XFile` على الويب رابط `blob:` لا يفهمه `dart:io`، بينما
  /// `readAsBytes` يعمل على المنصات الثلاث. والضغط عند الاختيار لأن صورة
  /// الهاتف الخام قد تتجاوز خمسة ميغابايت فيفشل رفع ست صور على اتصال ضعيف.
  Future<void> _pickImages() async {
    final remaining = StorageService.maxImageCount - _images.length;
    if (remaining <= 0) return;

    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 70,
      limit: remaining,
    );
    if (picked.isEmpty) return;

    final files = [
      for (final file in picked.take(remaining))
        UploadFile(name: file.name, bytes: await file.readAsBytes()),
    ];

    if (!mounted) return;
    setState(() => _images.addAll(files));
  }

  double? _optionalNumber(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _uploadedCount = 0;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final housing = HousingModel(
      id: '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      phone: _phone.text.trim(),
      whatsapp: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
      addressText: _address.text.trim(),
      distanceKm: _optionalNumber(_distance) ?? 0,
      status: _status,
      gender: _gender,
      priceMonthly: _optionalNumber(_price),
      roomsAvailable: _optionalNumber(_rooms)?.toInt(),
      // الملكية تُكتب داخل الخدمة من جلسة المصادقة لا من هنا — لا انتحال.
      createdBy: '',
    );

    final id = await HousingService().create(
      housing: housing,
      images: _images,
      onUploadProgress: (completed, _) {
        if (mounted) setState(() => _uploadedCount = completed);
      },
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          id == null
              ? 'admission.housing.save_failed'.tr()
              : 'admission.housing.saved'.tr(),
        ),
      ),
    );

    if (id != null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.housing.add'.tr()),
      // نمنع التفاعل أثناء الحفظ بدل تعطيل كل حقل على حدة: الضغط المزدوج
      // على زر النشر كان سيُنشئ إعلانين.
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              HousingImagesPicker(
                images: _images,
                onAdd: _pickImages,
                onRemove: (index) => setState(() => _images.removeAt(index)),
              ),
              const SizedBox(height: 22),

              HousingLabeledField(
                label: 'admission.housing.name'.tr(),
                icon: Icons.home_rounded,
                controller: _name,
                validator: HousingValidators.required,
              ),
              const SizedBox(height: 18),

              HousingLabeledField(
                label: 'admission.housing.phone'.tr(),
                icon: Icons.phone_rounded,
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: HousingValidators.phone,
              ),
              const SizedBox(height: 18),

              HousingLabeledField(
                label: 'admission.housing.whatsapp_optional'.tr(),
                icon: Icons.chat_rounded,
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.housing.gender'.tr(),
                icon: Icons.people_outline_rounded,
              ),
              ChoiceChipsGroup<HousingGender>(
                options: HousingGender.values,
                selected: _gender,
                labelBuilder: (option) => option.labelKey.tr(),
                onSelected: (option) => setState(() => _gender = option),
              ),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.housing.status'.tr(),
                icon: Icons.event_available_rounded,
              ),
              ChoiceChipsGroup<HousingStatus>(
                options: HousingStatus.values,
                selected: _status,
                labelBuilder: (option) => option.labelKey.tr(),
                onSelected: (option) => setState(() => _status = option),
              ),
              const SizedBox(height: 18),

              _buildNumbersRow(),
              const SizedBox(height: 18),

              HousingLabeledField(
                label: 'admission.housing.distance'.tr(),
                icon: Icons.directions_walk_rounded,
                controller: _distance,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 18),

              HousingLabeledField(
                label: 'admission.housing.address'.tr(),
                icon: Icons.place_outlined,
                controller: _address,
                maxLines: 2,
              ),
              const SizedBox(height: 18),

              HousingLabeledField(
                label: 'admission.housing.description'.tr(),
                icon: Icons.notes_rounded,
                controller: _description,
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumbersRow() {
    return Row(
      children: [
        Expanded(child: _numberField('price', Icons.payments_outlined, _price)),
        const SizedBox(width: 12),
        Expanded(
          child: _numberField('rooms', Icons.meeting_room_outlined, _rooms),
        ),
      ],
    );
  }

  Widget _numberField(String key, IconData icon, TextEditingController c) {
    return HousingLabeledField(
      label: 'admission.housing.$key'.tr(),
      icon: icon,
      controller: c,
      keyboardType: TextInputType.number,
    );
  }

  /// زر الحفظ مع تقدّم الرفع.
  ///
  /// عرض «٢ من ٥» أثناء الرفع لا مجرد دوّارة: رفع ست صور على اتصال ضعيف
  /// يستغرق دقيقة، ومؤشر بلا تقدّم يجعل المستخدم يظنّه معلّقاً فيغلق الشاشة
  /// ويفقد ما كتبه.
  Widget _buildSubmitButton() {
    return FilledButton.icon(
      onPressed: _isSaving ? null : _submit,
      icon: _isSaving
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_circle_outline_rounded),
      label: Text(
        _isSaving && _images.isNotEmpty
            ? 'admission.housing.uploading'.tr(
                namedArgs: {
                  'done': '$_uploadedCount',
                  'total': '${_images.length}',
                },
              )
            : 'admission.housing.publish'.tr(),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
