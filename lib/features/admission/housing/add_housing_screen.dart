import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_config_service.dart';
import '../../../core/services/housing_service.dart';
import '../models/admission_enums.dart';
import '../models/housing_model.dart';
import '../requirements/widgets/certificate_form_fields.dart';
import '../widgets/admission_app_bar.dart';
import 'widgets/housing_form_controller.dart';
import 'widgets/housing_form_fields.dart';

/// إضافة أو تعديل إعلان سكن.
///
/// شاشة واحدة للحالتين: تمرير [existing] يحوّلها لوضع التعديل. توحيدهما
/// يمنع تكرار نموذج من عشرة حقول في ملفين ويضمن تطابق قواعد التحقق.
class AddHousingScreen extends StatefulWidget {
  final HousingModel? existing;

  const AddHousingScreen({super.key, this.existing});

  @override
  State<AddHousingScreen> createState() => _AddHousingScreenState();
}

class _AddHousingScreenState extends State<AddHousingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _form = HousingFormController();

  bool _saving = false;
  int _uploaded = 0;
  int _totalToUpload = 0;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) _form.fillFrom(existing);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// حساب المسافة تلقائياً من موقع الجامعة المخزَّن في الإعدادات.
  Future<void> _autoDistance() async {
    final point = _form.location;
    if (point == null) return;

    final university = await AppConfigService().getUniversityConfig();
    final origin = university.location;
    if (origin == null || !mounted) return;

    final km = AppConfigService().distanceInKm(origin, point);
    setState(() => _form.distance.text = km.toStringAsFixed(1));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _uploaded = 0;
      _totalToUpload = _form.newImages.length;
    });

    void onProgress(int done, int total) {
      if (mounted) setState(() => _uploaded = done);
    }

    final service = HousingService();
    final model = _form.buildModel(existing: widget.existing);
    final ok = _isEditing
        ? await service.updateHousing(
            housing: model,
            newImages: _form.newImages,
            onImageProgress: onProgress,
          )
        : await service.addHousing(
                housing: model,
                images: _form.newImages,
                onImageProgress: onProgress,
              ) !=
              null;

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'admission.housing.saved'.tr()
              : 'admission.housing.save_failed'.tr(),
        ),
      ),
    );
    if (ok) Navigator.pop(context);
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'field_required'.tr() : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(
        title: _isEditing
            ? 'admission.housing.edit'.tr()
            : 'admission.housing.add'.tr(),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              ..._buildTextFields(),
              ..._buildChoiceFields(),
              ..._buildImageFields(),
              const SizedBox(height: 10),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTextFields() {
    return [
      HousingTextField(
        controller: _form.name,
        label: 'admission.housing.name'.tr(),
        icon: Icons.home_rounded,
        validator: _required,
      ),
      HousingTextField(
        controller: _form.phone,
        label: 'admission.housing.phone'.tr(),
        icon: Icons.call_rounded,
        keyboardType: TextInputType.phone,
        validator: _required,
      ),
      HousingTextField(
        controller: _form.whatsapp,
        label: 'admission.housing.whatsapp_optional'.tr(),
        icon: Icons.chat_rounded,
        keyboardType: TextInputType.phone,
      ),
      HousingTextField(
        controller: _form.address,
        label: 'admission.housing.address'.tr(),
        icon: Icons.place_rounded,
        validator: _required,
      ),
      HousingLocationField(
        controller: _form.mapLink,
        parsed: _form.location,
        onParsed: (point) {
          setState(() => _form.location = point);
          if (point != null) _autoDistance();
        },
      ),
      Row(
        children: [
          Expanded(
            child: HousingTextField(
              controller: _form.distance,
              label: 'admission.housing.distance_km'.tr(),
              icon: Icons.directions_walk_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HousingTextField(
              controller: _form.price,
              label: 'admission.housing.price_optional'.tr(),
              icon: Icons.payments_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      HousingTextField(
        controller: _form.rooms,
        label: 'admission.housing.rooms_optional'.tr(),
        icon: Icons.meeting_room_rounded,
        keyboardType: TextInputType.number,
      ),
      HousingTextField(
        controller: _form.description,
        label: 'admission.housing.description'.tr(),
        icon: Icons.notes_rounded,
        maxLines: 4,
      ),
    ];
  }

  List<Widget> _buildChoiceFields() {
    return [
      FormFieldLabel(
        text: 'admission.housing.gender'.tr(),
        icon: Icons.group_rounded,
      ),
      ChoiceChipsGroup<HousingGender>(
        options: HousingGender.values,
        selected: _form.gender,
        labelBuilder: (option) => option.labelKey.tr(),
        onSelected: (option) => setState(() => _form.gender = option),
      ),
      const SizedBox(height: 18),
      FormFieldLabel(
        text: 'admission.housing.status'.tr(),
        icon: Icons.check_circle_outline_rounded,
      ),
      ChoiceChipsGroup<HousingStatus>(
        options: HousingStatus.values,
        selected: _form.status,
        labelBuilder: (option) => option.labelKey.tr(),
        onSelected: (option) => setState(() => _form.status = option),
      ),
      const SizedBox(height: 18),
    ];
  }

  List<Widget> _buildImageFields() {
    return [
      FormFieldLabel(
        text: 'admission.housing.images'.tr(),
        icon: Icons.photo_library_rounded,
      ),
      HousingImagePicker(
        images: _form.newImages,
        existingUrls: _form.keptImages,
        onChanged: (files) => setState(() => _form.newImages = files),
        onRemoveExisting: (url) =>
            setState(() => _form.removeExistingImage(url)),
      ),
    ];
  }

  Widget _buildSaveButton() {
    return FilledButton.icon(
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save_rounded),
      label: Text(
        _saving && _totalToUpload > 0
            ? 'admission.housing.uploading'.tr(
                args: ['$_uploaded', '$_totalToUpload'],
              )
            : 'admission.housing.save'.tr(),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }
}
