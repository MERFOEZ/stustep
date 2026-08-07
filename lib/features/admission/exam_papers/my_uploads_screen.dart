import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/exam_papers_service.dart';
import '../../../core/services/paper_downloads_service.dart';
import '../models/exam_paper_model.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'widgets/paper_card.dart';

/// النماذج التي رفعها المستخدم الحالي، مع إمكانية حذفها.
class MyUploadsScreen extends StatelessWidget {
  const MyUploadsScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    ExamPaperModel paper,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('admission.papers.delete_title'.tr()),
        content: Text('admission.papers.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await ExamPapersService().deletePaper(paper);
    // نحذف النسخة المحلية أيضاً حتى لا تبقى معلّقة بلا مرجع.
    if (ok) await PaperDownloadsService().deleteLocal(paper);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'admission.papers.deleted'.tr()
              : 'admission.papers.upload_failed'.tr(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.papers.my_uploads'.tr()),
      body: uid == null
          ? AdmissionEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'admission.housing.sign_in_required'.tr(),
            )
          : StreamBuilder<List<ExamPaperModel>>(
              stream: ExamPapersService().watchMyUploads(uid),
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
                    icon: Icons.cloud_off_rounded,
                    message: 'admission.papers.no_uploads'.tr(),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final paper = items[index];
                    return PaperCard(
                      paper: paper,
                      isDownloaded: false,
                      delayMilliseconds: index * 50,
                      onAction: () => PaperDownloadsService().download(paper),
                      onDelete: () => _confirmDelete(context, paper),
                    );
                  },
                );
              },
            ),
    );
  }
}
