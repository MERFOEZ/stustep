import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/exam_paper_model.dart';

/// بطاقة نموذج اختبار مع زر التنزيل والفتح.
///
/// حالات الزر الأربع: غير محمَّل · جاري التنزيل · محمَّل · خطأ.
class PaperCard extends StatelessWidget {
  final ExamPaperModel paper;
  final bool isDownloaded;
  final double? progress;
  final VoidCallback onAction;
  final VoidCallback? onDelete;
  final int delayMilliseconds;

  const PaperCard({
    super.key,
    required this.paper,
    required this.isDownloaded,
    required this.onAction,
    this.progress,
    this.onDelete,
    this.delayMilliseconds = 0,
  });

  bool get _isDownloading => progress != null;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).primaryColor;

    return FadeInUp(
      delay: Duration(milliseconds: delayMilliseconds),
      duration: const Duration(milliseconds: 450),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPdfIcon(accent),
                const SizedBox(width: 12),
                Expanded(child: _buildInfo(context)),
                const SizedBox(width: 8),
                _buildActionButton(accent),
              ],
            ),
            if (_isDownloading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: accent.withValues(alpha: 0.12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPdfIcon(Color accent) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.picture_as_pdf_rounded,
        color: Color(0xFFD32F2F),
        size: 24,
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          paper.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _tag(context, paper.type.labelKey.tr()),
            if (paper.year > 0) _tag(context, '${paper.year}'),
            if (paper.term.isNotEmpty) _tag(context, paper.term),
            _tag(context, paper.formattedSize),
            if (paper.downloadCount > 0)
              _tag(
                context,
                'admission.papers.downloads'.tr(
                  args: ['${paper.downloadCount}'],
                ),
              ),
          ],
        ),
        if (paper.courseName != null && paper.courseName!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            paper.courseName!,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _tag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10.5)),
    );
  }

  Widget _buildActionButton(Color accent) {
    if (_isDownloading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: accent),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onAction,
          tooltip: isDownloaded
              ? 'admission.papers.open'.tr()
              : 'admission.papers.download'.tr(),
          icon: Icon(
            isDownloaded
                ? Icons.folder_open_rounded
                : Icons.download_rounded,
            color: isDownloaded ? const Color(0xFF00A152) : accent,
          ),
        ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            tooltip: 'delete'.tr(),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
      ],
    );
  }
}
