import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/services/exam_papers_service.dart';
import '../models/admission_enums.dart';
import '../models/college_summary.dart';
import '../models/department_summary.dart';
import '../models/exam_paper_model.dart';
import '../requirements/widgets/certificate_form_fields.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_text_field.dart';

/// رفع نموذج اختبار جديد بصيغة PDF.
class UploadExamPaperScreen extends StatefulWidget {
  final CollegeSummary college;
  final List<DepartmentSummary> departments;

  const UploadExamPaperScreen({
    super.key,
    required this.college,
    this.departments = const [],
  });

  @override
  State<UploadExamPaperScreen> createState() => _UploadExamPaperScreenState();
}

class _UploadExamPaperScreenState extends State<UploadExamPaperScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _courseName = TextEditingController();
  final _term = TextEditingController();

  File? _file;
  String? _fileName;
  int _fileSize = 0;
  String? _departmentId;
  late int _year;
  ExamPaperType _type = ExamPaperType.model;
  bool _saving = false;

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

  /// اختيار ملف PDF فقط.
  ///
  /// نقيّد الامتداد عند الاختيار لا بعده، حتى لا يرفع الطالب ملفاً كبيراً
  /// ثم يُرفض.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final picked = result?.files.single;
    if (picked?.path == null) return;

    setState(() {
      _file = File(picked!.path!);
      _fileName = picked.name;
      _fileSize = picked.size;
      if (_title.text.trim().isEmpty) {
        _title.text = picked.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_file == null) {
      _toast('admission.papers.pick_file_first'.tr());
      return;
    }

    setState(() => _saving = true);

    final paper = ExamPaperModel(
      id: '',
      title: _title.text.trim(),
      fileUrl: '',
      fileName: _fileName ?? '',
      collegeId: widget.college.id,
      departmentId: _departmentId,
      courseName: _courseName.text.trim().isEmpty
          ? null
          : _courseName.text.trim(),
      year: _year,
      term: _term.text.trim(),
      type: _type,
      uploadedBy: '',
    );

    final id = await ExamPapersService().uploadPaper(
      paper: paper,
      file: _file!,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    _toast(
      id != null
          ? 'admission.papers.upload_done'.tr()
          : 'admission.papers.upload_failed'.tr(),
    );
    if (id != null) Navigator.pop(context);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'field_required'.tr() : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.papers.upload'.tr()),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _buildFilePicker(),
              const SizedBox(height: 18),
              AdmissionTextField(
                controller: _title,
                label: 'admission.papers.title'.tr(),
                icon: Icons.title_rounded,
                validator: _required,
              ),
              AdmissionTextField(
                controller: _courseName,
                label: 'admission.papers.course_optional'.tr(),
                icon: Icons.menu_book_rounded,
              ),
              AdmissionTextField(
                controller: _term,
                label: 'admission.papers.term_optional'.tr(),
                icon: Icons.date_range_rounded,
              ),
              if (widget.departments.isNotEmpty) ...[
                FormFieldLabel(
                  text: 'admission.papers.department'.tr(),
                  icon: Icons.school_rounded,
                ),
                ChoiceChipsGroup<String?>(
                  options: [null, ...widget.departments.map((d) => d.id)],
                  selected: _departmentId,
                  labelBuilder: (value) => value == null
                      ? 'admission.papers.whole_college'.tr()
                      : widget.departments
                            .firstWhere((d) => d.id == value)
                            .name,
                  onSelected: (value) =>
                      setState(() => _departmentId = value),
                ),
                const SizedBox(height: 18),
              ],
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
                years: ExamPapersService.availableYears(),
                selected: _year,
                onChanged: (value) => setState(() => _year = value),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
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
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _saving
                      ? 'admission.papers.uploading'.tr()
                      : 'admission.papers.upload'.tr(),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
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

  Widget _buildFilePicker() {
    final hasFile = _file != null;
    final accent = Theme.of(context).primaryColor;

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: hasFile
              ? const Color(0xFF00A152).withValues(alpha: 0.07)
              : accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? const Color(0xFF00A152).withValues(alpha: 0.4)
                : accent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile
                  ? Icons.picture_as_pdf_rounded
                  : Icons.add_circle_outline_rounded,
              size: 30,
              color: hasFile ? const Color(0xFFD32F2F) : accent,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFile
                        ? _fileName!
                        : 'admission.papers.pick_file'.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (hasFile) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${(_fileSize / 1024).toStringAsFixed(0)} KB',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasFile)
              Icon(Icons.change_circle_outlined, color: accent, size: 22),
          ],
        ),
      ),
    );
  }
}
