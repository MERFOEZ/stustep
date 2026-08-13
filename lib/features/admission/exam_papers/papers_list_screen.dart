import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/exam_paper_service.dart';
import '../../../core/services/external_launcher_service.dart';
import '../models/admission_enums.dart';
import '../models/college_summary.dart';
import '../models/exam_paper_model.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'upload_paper_screen.dart';
import 'widgets/exam_paper_card.dart';

/// قائمة نماذج اختبارات كلية واحدة، مع فلاتر النوع والسنة والبحث.
class PapersListScreen extends StatefulWidget {
  final CollegeSummary college;
  final Gradient gradient;

  const PapersListScreen({
    super.key,
    required this.college,
    required this.gradient,
  });

  @override
  State<PapersListScreen> createState() => _PapersListScreenState();
}

class _PapersListScreenState extends State<PapersListScreen> {
  ExamPaperType? _type;
  int? _year;
  String _query = '';

  /// فتح الملف في المتصفح أو قارئ PDF الخارجي.
  ///
  /// اخترنا الفتح الخارجي بدل تنزيل الملف وتخزينه داخل التطبيق: التنزيل
  /// الداخلي يتطلب إدارة تخزين وأذونات وتنظيفاً للملفات القديمة، ويكرّر
  /// نظام التنزيل القائم في المشروع بكل مشاكله الموثّقة. الفتح الخارجي
  /// يعطي الطالب النتيجة نفسها بصفر تعقيد.
  Future<void> _open(ExamPaperModel paper) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ExternalLauncherService().openUrl(paper.fileUrl);

    if (opened) {
      // الإحصاء بعد نجاح الفتح لا قبله، حتى لا يُحتسب تنزيل لم يحدث.
      await ExamPaperService().incrementDownloads(paper.id);
    } else if (mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text('admission.papers.open_failed'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: widget.college.name),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UploadPaperScreen(college: widget.college),
          ),
        ),
        icon: const Icon(Icons.upload_file_rounded),
        label: Text('admission.papers.upload'.tr()),
      ),
      body: StreamBuilder<List<ExamPaperModel>>(
        stream: ExamPaperService().watchByCollege(widget.college.id),
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

          final visible = ExamPaperService.applyFilters(
            all,
            type: _type,
            year: _year,
            query: _query,
          );

          return Column(
            children: [
              _buildSearchField(context),
              _buildFilters(context, ExamPaperService.availableYears(all)),
              Expanded(
                child: visible.isEmpty
                    ? AdmissionEmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        message: 'admission.papers.no_match'.tr(),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 96),
                        itemCount: visible.length,
                        itemBuilder: (context, index) => ExamPaperCard(
                          paper: visible[index],
                          delayMilliseconds: (index * 50).clamp(0, 350),
                          onOpen: () => _open(visible[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: TextField(
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'admission.papers.search_hint'.tr(),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: border,
          enabledBorder: border,
        ),
      ),
    );
  }

  /// صف الفلاتر الأفقي: النوع أولاً ثم السنوات المتاحة فعلاً في البيانات.
  ///
  /// عرض السنوات الموجودة فقط لا قائمة ثابتة: قائمة ثابتة كانت ستُظهر
  /// سنوات بلا نماذج فيضغطها الطالب ولا يجد شيئاً.
  Widget _buildFilters(BuildContext context, List<int> years) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          ...ExamPaperType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _type == type,
                label: Text(type.labelKey.tr()),
                onSelected: (value) =>
                    setState(() => _type = value ? type : null),
              ),
            ),
          ),
          if (years.isNotEmpty)
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ...years.map(
            (year) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _year == year,
                label: Text('$year'),
                onSelected: (value) =>
                    setState(() => _year = value ? year : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
