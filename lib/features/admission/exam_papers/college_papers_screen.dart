import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../../core/services/academic_guide_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/exam_papers_service.dart';
import '../../../core/services/paper_downloads_service.dart';
import '../models/college_summary.dart';
import '../models/department_summary.dart';
import '../models/exam_paper_filter.dart';
import '../models/exam_paper_model.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'upload_exam_paper_screen.dart';
import 'widgets/paper_card.dart';
import 'widgets/paper_filter_bar.dart';

/// نماذج اختبارات كلية واحدة، مع التصنيف حسب التخصص والسنة والنوع.
class CollegePapersScreen extends StatefulWidget {
  final CollegeSummary college;

  const CollegePapersScreen({super.key, required this.college});

  @override
  State<CollegePapersScreen> createState() => _CollegePapersScreenState();
}

class _CollegePapersScreenState extends State<CollegePapersScreen> {
  final _downloads = PaperDownloadsService();

  ExamPaperFilter _filter = const ExamPaperFilter();
  List<DepartmentSummary> _departments = const [];

  /// معرّفات النماذج المحمَّلة محلياً.
  final Set<String> _downloaded = {};

  /// تقدّم التنزيل الجاري لكل نموذج.
  final Map<String, double> _progress = {};

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final departments = await AcademicGuideService().getDepartments(
      widget.college.id,
    );
    if (mounted) setState(() => _departments = departments);
  }

  /// تحديث حالة التنزيل لكل نموذج ظاهر.
  Future<void> _refreshDownloadState(List<ExamPaperModel> papers) async {
    final found = <String>{};
    for (final paper in papers) {
      if (await _downloads.isDownloaded(paper)) found.add(paper.id);
    }
    if (!mounted || setEquals(found, _downloaded)) return;
    setState(() {
      _downloaded
        ..clear()
        ..addAll(found);
    });
  }

  Future<void> _handleAction(ExamPaperModel paper) async {
    if (_downloaded.contains(paper.id)) {
      final opened = await _downloads.open(paper);
      if (!opened && mounted) _toast('admission.papers.open_failed'.tr());
      return;
    }

    setState(() => _progress[paper.id] = 0);
    final path = await _downloads.download(
      paper,
      onProgress: (value) {
        if (mounted) setState(() => _progress[paper.id] = value);
      },
    );

    if (!mounted) return;
    setState(() => _progress.remove(paper.id));

    if (path == null) {
      _toast('admission.papers.download_failed'.tr());
      return;
    }

    setState(() => _downloaded.add(paper.id));
    ExamPapersService().incrementDownloadCount(paper.id);
    _toast('admission.papers.downloaded'.tr());
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = AuthService().currentUser != null;

    return Scaffold(
      appBar: AdmissionAppBar(title: widget.college.name),
      floatingActionButton: isSignedIn
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadExamPaperScreen(
                    college: widget.college,
                    departments: _departments,
                  ),
                ),
              ),
              icon: const Icon(Icons.upload_file_rounded),
              label: Text('admission.papers.upload'.tr()),
            )
          : null,
      body: StreamBuilder<List<ExamPaperModel>>(
        stream: ExamPapersService().watchByCollege(widget.college.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdmissionLoadingState();
          }
          if (snapshot.hasError) {
            return const AdmissionErrorState();
          }

          final all = snapshot.data ?? const <ExamPaperModel>[];
          if (all.isEmpty) {
            return AdmissionEmptyState(
              icon: Icons.picture_as_pdf_outlined,
              message: 'admission.papers.empty'.tr(),
            );
          }

          // تحديث حالة التنزيل بعد بناء الإطار حتى لا نستدعي setState أثناءه.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _refreshDownloadState(all),
          );

          final items = _filter.apply(all);

          return Column(
            children: [
              const SizedBox(height: 12),
              PaperFilterBar(
                filter: _filter,
                departments: _departments,
                years: ExamPaperFilter.yearsIn(all),
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? AdmissionEmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        message: 'admission.papers.no_match'.tr(),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final paper = items[index];
                          return PaperCard(
                            paper: paper,
                            isDownloaded: _downloaded.contains(paper.id),
                            progress: _progress[paper.id],
                            delayMilliseconds: index * 50,
                            onAction: () => _handleAction(paper),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
