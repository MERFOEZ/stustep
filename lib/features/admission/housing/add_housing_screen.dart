import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/housing_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/admission_enums.dart';
import '../models/housing_model.dart';
import '../requirements/widgets/certificate_form_fields.dart';
import '../widgets/admission_app_bar.dart';

/// نموذج إضافة إعلان سكن.
///
/// أعيد استخدام ودجت النماذج المبنية في المرحلة 4 (`FormFieldLabel` و
/// `ChoiceChipsGroup`) بدل بناء نسخة ثانية منها. هذا ما يجعل نموذجاً في
/// موديول مختلف يبدو ويتصرّف كنماذج الموديول نفسه بلا كود مكرر.
class AddHousingScreen extends StatefulWidget {
  const AddHousingScreen({super.key});

  @override
  State<AddHousingScreen> createState() => _AddHousingScreenState();
}

class _AddHousingScreenState extends State<AddHousingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomsController = TextEditingController();
  final _distanceController = TextEditingController();

  HousingStatus _status = HousingStatus.available;
  HousingGender _gender = HousingGender.male;

  final List<File> _images = [];
  bool _isSaving = false;
  int _uploadedCount = 0;

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _descriptionController,
      _phoneController,
      _whatsappController,
      _addressController,
      _priceController,
      _roomsController,
      _distanceController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = StorageService.maxImageCount - _images.length;
    if (remaining <= 0) return;

    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 70, // ضغط قبل الرفع: اتصال الطالب غالباً محدود.
      limit: remaining,
    );
    if (picked.isEmpty || !mounted) return;

    setState(() {
      _images.addAll(picked.take(remaining).map((file) => File(file.path)));
    });
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'admission.housing.field_required'.tr();
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    // تسعة أرقام هو أقصر رقم محلي معقول؛ نتساهل عمداً لأن الصيغ تختلف.
    final digits = value!.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) return 'admission.housing.invalid_phone'.tr();
    return null;
  }

  double? _parseOptionalNumber(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
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
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      phone: _phoneController.text.trim(),
      whatsapp: _whatsappController.text.trim().isEmpty
          ? null
          : _whatsappController.text.trim(),
      addressText: _addressController.text.trim(),
      distanceKm: _parseOptionalNumber(_distanceController) ?? 0,
      status: _status,
      gender: _gender,
      priceMonthly: _parseOptionalNumber(_priceController),
      roomsAvailable: _parseOptionalNumber(_roomsController)?.toInt(),
      // الملكية تُكتب في الخدمة من جلسة المصادقة لا من هنا — لا انتحال.
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

    if (id == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('admission.housing.save_failed'.tr())),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('admission.housing.saved'.tr())),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.housing.add'.tr()),
      body: AbsorbPointer(
        absorbing: _isSaving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _buildImagesSection(context),
              const SizedBox(height: 22),

              FormFieldLabel(
                text: 'admission.housing.name'.tr(),
                icon: Icons.home_rounded,
              ),
              _buildTextField(
                controller: _nameController,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.housing.phone'.tr(),
                icon: Icons.phone_rounded,
              ),
              _buildTextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
              ),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.housing.whatsapp_optional'.tr(),
                icon: Icons.chat_rounded,
              ),
              _buildTextField(
                controller: _whatsappController,
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

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormFieldLabel(
                          text: 'admission.housing.price'.tr(),
                          icon: Icons.payments_outlined,
                        ),
                        _buildTextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormFieldLabel(
                          text: 'admission.housing.rooms'.tr(),
                          icon: Icons.meeting_room_outlined,
                        ),
                        _buildTextField(
                          controller: _roomsController,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.housing.distance'.tr(),
                icon: Icons.directions_walk_rounded,
              ),
              _buildTextField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.housing.address'.tr(),
                icon: Icons.place_outlined,
              ),
              _buildTextField(controller: _addressController, maxLines: 2),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.housing.description'.tr(),
                icon: Icons.notes_rounded,
              ),
              _buildTextField(controller: _descriptionController, maxLines: 4),
              const SizedBox(height: 24),

              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        isDense: true,
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
    );
  }

  Widget _buildImagesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(
          text: 'admission.housing.images'.tr(
            namedArgs: {
              'count': '${_images.length}',
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
              if (_images.length < StorageService.maxImageCount)
                _buildAddImageTile(context),
              ..._images.asMap().entries.map(
                (entry) => _buildImageTile(entry.key, entry.value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageTile(BuildContext context) {
    return GestureDetector(
      onTap: _pickImages,
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

  Widget _buildImageTile(int index, File file) {
    return Stack(
      children: [
        Container(
          width: 88,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: () => setState(() => _images.removeAt(index)),
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

  /// زر الحفظ مع تقدّم الرفع.
  ///
  /// عرض «٢ من ٥» أثناء الرفع لا مجرد دوّارة: رفع ست صور على اتصال ضعيف
  /// يستغرق دقيقة، ومؤشر بلا تقدّم يجعل المستخدم يظنّه معلّقاً فيغلق الشاشة.
  Widget _buildSubmitButton(BuildContext context) {
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
