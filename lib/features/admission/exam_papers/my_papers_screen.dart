import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/exam_paper_service.dart';
import '../../../core/services/external_launcher_service.dart';
import '../models/exam_paper_model.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'widgets/exam_paper_card.dart';

/// نماذجي — إدارة ما رفعه المستخدم من نماذج اختبارات.
class MyPapersScreen extends StatelessWidget {
  const MyPapersScreen({super.key});

  /// حذف بتأكيد صريح.
  ///
  /// الحذف نهائي: تختفي الوثيقة ويصبح الملف على Cloudinary يتيماً بلا مرجع.
  /// حوار التأكيد ليس احتياطاً زائداً بل الفاصل الوحيد قبل فقد لا رجعة فيه.
  Future<void> _confirmDelete(
    BuildContext context,
    ExamPaperModel paper,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('admission.papers.delete_title'.tr()),
        content: Text(
          'admission.papers.delete_confirm'.tr(
            namedArgs: {'title': paper.title},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('admission.papers.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: Text('admission.papers.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ExamPaperService().delete(paper.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'admission.papers.deleted'.tr()
              : 'admission.papers.upload_failed'.tr(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.papers.my_papers'.tr()),
      body: StreamBuilder<List<ExamPaperModel>>(
        stream: ExamPaperService().watchMyPapers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdmissionLoadingState();
          }
          if (snapshot.hasError) {
            return const AdmissionErrorState();
          }

          final items = snapshot.data ?? const <ExamPaperModel>[];
          if (items.isEmpty) {
            return AdmissionEmptyState(
              icon: Icons.folder_off_outlined,
              message: 'admission.papers.no_papers'.tr(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final paper = items[index];
              return ExamPaperCard(
                paper: paper,
                delayMilliseconds: (index * 50).clamp(0, 350),
                onOpen: () =>
                    ExternalLauncherService().openUrl(paper.fileUrl),
                onDelete: () => _confirmDelete(context, paper),
              );
            },
          );
        },
      ),
    );
  }
}
