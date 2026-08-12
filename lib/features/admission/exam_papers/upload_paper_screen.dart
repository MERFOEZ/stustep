import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/services/certificate_service.dart';
import '../../../core/services/exam_paper_service.dart';
import '../housing/widgets/housing_form_fields.dart';
import '../models/admission_enums.dart';
import '../models/college_summary.dart';
import '../models/exam_paper_model.dart';
import '../requirements/widgets/certificate_form_fields.dart';
import '../widgets/admission_app_bar.dart';

/// شاشة رفع نموذج اختبار.
class UploadPaperScreen extends StatefulWidget {
  final CollegeSummary college;

  const UploadPaperScreen({super.key, required this.college});

  @override
  State<UploadPaperScreen> createState() => _UploadPaperScreenState();
}

class _UploadPaperScreenState extends State<UploadPaperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _courseName = TextEditingController();
  final _term = TextEditingController();

  ExamPaperType _type = ExamPaperType.model;
  late int _year;

  File? _file;
  String? _fileName;
  int _fileSize = 0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
  }

  @override
  void dispose() {
    _title.dispose();
    _courseName.dispose();
    _term.dispose();
    super.dispose();
  }

  /// اختيار ملف PDF مع التحقق من الحجم **قبل** الرفع.
  ///
  /// رفض الملف الكبير هنا برسالة واضحة أفضل بكثير من محاولة رفعه دقيقتين
  /// ثم فشله بخطأ شبكة مبهم يظنّه الطالب مشكلة في اتصاله.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final file = File(path);
    final size = await file.length();

    if (!mounted) return;

    if (size > ExamPaperService.maxFileSizeBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admission.papers.file_too_large'.tr())),
      );
      return;
    }

    setState(() {
      _file = file;
      _fileName = result!.files.single.name;
      _fileSize = size;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final file = _file;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admission.papers.pick_file_first'.tr())),
      );
      return;
    }

    setState(() => _isUploading = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final paper = ExamPaperModel(
      id: '',
      title: _title.text.trim(),
      fileUrl: '',
      fileName: _fileName ?? '',
      collegeId: widget.college.id,
      courseName: _courseName.text.trim().isEmpty
          ? null
          : _courseName.text.trim(),
      year: _year,
      term: _term.text.trim(),
      type: _type,
      // الملكية تُكتب داخل الخدمة من جلسة المصادقة لا من هنا.
      uploadedBy: '',
    );

    final id = await ExamPaperService().upload(paper: paper, file: file);

    if (!mounted) return;
    setState(() => _isUploading = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          id == null
              ? 'admission.papers.upload_failed'.tr()
              : 'admission.papers.uploaded'.tr(),
        ),
      ),
    );

    if (id != null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.papers.upload'.tr()),
      body: AbsorbPointer(
        absorbing: _isUploading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _buildFilePicker(context),
              const SizedBox(height: 22),

              HousingLabeledField(
                label: 'admission.papers.paper_title'.tr(),
                icon: Icons.title_rounded,
                controller: _title,
                validator: HousingValidators.required,
              ),
              const SizedBox(height: 18),

              HousingLabeledField(
                label: 'admission.papers.course_name'.tr(),
                icon: Icons.menu_book_rounded,
                controller: _courseName,
              ),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.papers.type'.tr(),
                icon: Icons.category_rounded,
              ),
              ChoiceChipsGroup<ExamPaperType>(
                options: ExamPaperType.values,
                selected: _type,
                labelBuilder: (option) => option.labelKey.tr(),
                onSelected: (option) => setState(() => _type = option),
              ),
              const SizedBox(height: 18),

              FormFieldLabel(
                text: 'admission.papers.year'.tr(),
                icon: Icons.event_rounded,
              ),
              GraduationYearField(
                years: CertificateService().availableGraduationYears(),
                selected: _year,
                onChanged: (year) => setState(() => _year = year),
              ),
              const SizedBox(height: 18),

              HousingLabeledField(
                label: 'admission.papers.term'.tr(),
                icon: Icons.calendar_view_month_rounded,
                controller: _term,
              ),
              const SizedBox(height: 24),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(BuildContext context) {
    final hasFile = _file != null;
    final color = hasFile
        ? const Color(0xFF00A152)
        : Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile
                  ? Icons.picture_as_pdf_rounded
                  : Icons.cloud_upload_outlined,
              size: 38,
              color: color,
            ),
            const SizedBox(height: 10),
            Text(
              hasFile ? _fileName! : 'admission.papers.pick_file'.tr(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              hasFile
                  ? _formatSize(_fileSize)
                  : 'admission.papers.pick_file_hint'.tr(),
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  Widget _buildSubmitButton() {
    return FilledButton.icon(
      onPressed: _isUploading ? null : _submit,
      icon: _isUploading
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check_circle_outline_rounded),
      label: Text(
        _isUploading
            ? 'admission.papers.uploading'.tr()
            : 'admission.papers.publish'.tr(),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
