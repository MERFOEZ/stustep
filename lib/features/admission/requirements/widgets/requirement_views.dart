import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/entrance_exam_model.dart';
import '../../models/subject_catalog.dart';
import '../../models/subject_requirement.dart';

// ودجت عرض شروط القبول، مفصولة عن الشاشة لإبقائها تحت السقف.

/// سطر معلومة: أيقونة + عنوان + قيمة.
class RequirementInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const RequirementInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13.5)),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// قائمة الأوراق المطلوبة على هيئة قائمة تحقّق.
class DocumentsChecklist extends StatelessWidget {
  final List<String> documents;
  final Color accentColor;

  const DocumentsChecklist({
    super.key,
    required this.documents,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: documents.map((document) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_box_outline_blank_rounded,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  document,
                  style: const TextStyle(fontSize: 13.5, height: 1.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// بطاقة اختبار قبول.
class EntranceExamCard extends StatelessWidget {
  final EntranceExamModel exam;
  final Color accentColor;

  const EntranceExamCard({
    super.key,
    required this.exam,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exam.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: exam.isRequired
                      ? Colors.red.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exam.isRequired
                      ? 'admission.requirements.exam_required'.tr()
                      : 'admission.requirements.exam_optional'.tr(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: exam.isRequired
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (exam.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exam.description,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (exam.subjects.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: exam.subjects.map((subject) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subject,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// سطر اشتراط درجة مادة.
class SubjectRequirementTile extends StatelessWidget {
  final SubjectRequirement requirement;
  final Color accentColor;

  const SubjectRequirementTile({
    super.key,
    required this.requirement,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    // نفضّل الاسم المترجم من الكتالوج، ونتراجع لاسم قاعدة البيانات إذا كان
    // المعرّف غير معروف — فلا يظهر مفتاح ترجمة مكسور للمستخدم.
    final labelKey = SubjectCatalog.labelKeyFor(requirement.subjectCode);
    final name = labelKey != null ? labelKey.tr() : requirement.subjectName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            SubjectCatalog.byCode(requirement.subjectCode)?.icon ??
                Icons.subject_rounded,
            size: 17,
            color: accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13.5))),
          Text(
            '${requirement.minGrade.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
