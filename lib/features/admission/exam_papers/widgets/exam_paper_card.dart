import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/exam_paper_model.dart';

/// بطاقة نموذج اختبار في القائمة.
///
/// تعرض حجم الملف وعدد التنزيلات بجانب العنوان: الحجم لأن الطالب على اتصال
/// محدود يحتاج أن يعرف قبل الضغط، وعدد التنزيلات لأنه أفضل مؤشر متاح على
/// جودة النموذج في غياب نظام تقييم.
class ExamPaperCard extends StatelessWidget {
  final ExamPaperModel paper;
  final VoidCallback onOpen;

  /// يُعرض زر الحذف لصاحب النموذج فقط.
  final VoidCallback? onDelete;

  final int delayMilliseconds;

  const ExamPaperCard({
    super.key,
    required this.paper,
    required this.onOpen,
    this.onDelete,
    this.delayMilliseconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return FadeInUp(
      delay: Duration(milliseconds: delayMilliseconds),
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFileIcon(primary),
                  const SizedBox(width: 13),
                  Expanded(child: _buildBody(context)),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: Color(0xFFD32F2F),
                      ),
                      tooltip: 'admission.papers.delete'.tr(),
                    )
                  else
                    Icon(
                      Icons.download_rounded,
                      size: 20,
                      color: primary.withValues(alpha: 0.7),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(Color primary) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.picture_as_pdf_rounded,
        size: 22,
        color: Color(0xFFD32F2F),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          paper.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        if (paper.courseName != null) ...[
          const SizedBox(height: 3),
          Text(
            paper.courseName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 9),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildChip(context, paper.type.labelKey.tr(), highlight: true),
            if (paper.year > 0) _buildChip(context, '${paper.year}'),
            _buildChip(context, paper.formattedSize),
            if (paper.downloadCount > 0)
              _buildChip(
                context,
                'admission.papers.downloads'.tr(
                  namedArgs: {'count': '${paper.downloadCount}'},
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label, {
    bool highlight = false,
  }) {
    final color = highlight
        ? Theme.of(context).primaryColor
        : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
