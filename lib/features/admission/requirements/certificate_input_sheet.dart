import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/certificate_service.dart';
import '../../../core/services/certificate_storage_service.dart';
import '../models/admission_enums.dart';
import '../models/high_school_certificate.dart';
import '../models/subject_catalog.dart';
import 'widgets/certificate_form_fields.dart';
import 'widgets/subject_grades_field.dart';

/// ورقة إدخال شهادة الثانوية.
///
/// تُفتح كورقة سفلية وتُعيد `HighSchoolCertificate` عند الحفظ.
/// تُستهلك في موضعين: فحص الأهلية هنا، ومساعد اختيار التخصص في المرحلة 7 —
/// ولهذا بُنيت كورقة مستقلة لا كجزء من شاشة.
class CertificateInputSheet extends StatefulWidget {
  final HighSchoolCertificate? initial;

  const CertificateInputSheet({super.key, this.initial});

  /// فتح الورقة وإرجاع الشهادة، أو `null` عند الإلغاء.
  static Future<HighSchoolCertificate?> show(
    BuildContext context, {
    HighSchoolCertificate? initial,
  }) {
    return showModalBottomSheet<HighSchoolCertificate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CertificateInputSheet(initial: initial),
    );
  }

  @override
  State<CertificateInputSheet> createState() => _CertificateInputSheetState();
}

class _CertificateInputSheetState extends State<CertificateInputSheet> {
  final _formKey = GlobalKey<FormState>();
  final _gpaController = TextEditingController();
  final _certificateService = CertificateService();

  late CertificateType _type;
  late HighSchoolTrack _track;
  late GpaScale _scale;
  late int _graduationYear;
  late bool _hasEquivalency;

  final Map<String, TextEditingController> _subjectControllers = {
    for (final subject in SubjectCatalog.all)
      subject.code: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? CertificateType.yemeniGeneral;
    _track = initial?.track ?? HighSchoolTrack.scientific;
    _scale = initial?.gpaScale ?? GpaScale.percentage;
    _graduationYear = initial?.graduationYear ?? DateTime.now().year;
    _hasEquivalency = initial?.hasEquivalency ?? false;

    if (initial != null && initial.gpa > 0) {
      _gpaController.text = initial.gpa.toString();
      initial.subjectGrades.forEach((code, grade) {
        _subjectControllers[code]?.text = grade.toStringAsFixed(0);
      });
    }
  }

  @override
  void dispose() {
    _gpaController.dispose();
    for (final controller in _subjectControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validateGpa(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null) return 'admission.certificate.invalid_number'.tr();
    if (!_certificateService.isGpaValueValid(parsed, _scale)) {
      return 'admission.certificate.invalid_for_scale'.tr();
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final certificate = HighSchoolCertificate(
      type: _type,
      track: _track,
      gpa: double.parse(_gpaController.text.trim()),
      gpaScale: _scale,
      graduationYear: _graduationYear,
      hasEquivalency: _hasEquivalency,
      subjectGrades: SubjectGradesField.collect(_subjectControllers),
    );

    await CertificateStorageService().save(certificate);
    if (mounted) Navigator.pop(context, certificate);
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = _scale.maxValue;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _buildHandle(),
              _buildTitle(context),
              const SizedBox(height: 20),

              FormFieldLabel(
                text: 'admission.certificate.type'.tr(),
                icon: Icons.badge_rounded,
              ),
              ChoiceChipsGroup<CertificateType>(
                options: CertificateType.values,
                selected: _type,
                labelBuilder: (option) => option.labelKey.tr(),
                onSelected: (option) => setState(() => _type = option),
              ),
              const SizedBox(height: 20),

              FormFieldLabel(
                text: 'admission.certificate.track'.tr(),
                icon: Icons.alt_route_rounded,
              ),
              ChoiceChipsGroup<HighSchoolTrack>(
                options: HighSchoolTrack.values,
                selected: _track,
                labelBuilder: (option) => option.labelKey.tr(),
                onSelected: (option) => setState(() => _track = option),
              ),
              const SizedBox(height: 20),

              FormFieldLabel(
                text: 'admission.certificate.scale'.tr(),
                icon: Icons.straighten_rounded,
              ),
              ChoiceChipsGroup<GpaScale>(
                options: GpaScale.values,
                selected: _scale,
                labelBuilder: (option) => option.labelKey.tr(),
                onSelected: (option) => setState(() {
                  _scale = option;
                  _formKey.currentState?.validate();
                }),
              ),
              const SizedBox(height: 20),

              FormFieldLabel(
                text: 'admission.certificate.gpa'.tr(),
                icon: Icons.grade_rounded,
              ),
              GpaNumberField(
                controller: _gpaController,
                validator: _validateGpa,
                hint: maxValue == null ? '1 - 4' : '0 - $maxValue',
                helperText: _scale == GpaScale.grade
                    ? 'admission.certificate.grade_hint'.tr()
                    : null,
              ),
              const SizedBox(height: 20),

              FormFieldLabel(
                text: 'admission.certificate.graduation_year'.tr(),
                icon: Icons.event_rounded,
              ),
              GraduationYearField(
                years: _certificateService.availableGraduationYears(),
                selected: _graduationYear,
                onChanged: (year) => setState(() => _graduationYear = year),
              ),

              if (_type.needsEquivalency) ...[
                const SizedBox(height: 20),
                EquivalencySwitch(
                  value: _hasEquivalency,
                  onChanged: (value) =>
                      setState(() => _hasEquivalency = value),
                ),
              ],

              const SizedBox(height: 24),
              FormFieldLabel(
                text: 'admission.certificate.subject_grades'.tr(),
                icon: Icons.checklist_rounded,
              ),
              SubjectGradesField(controllers: _subjectControllers),

              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text('admission.certificate.save'.tr()),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admission.certificate.title'.tr(),
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'admission.certificate.subtitle'.tr(),
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
