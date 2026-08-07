import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/admission_enums.dart';
import '../../models/department_summary.dart';
import '../../models/exam_paper_filter.dart';

/// شريط تصفية أفقي فوق قائمة النماذج.
///
/// اخترنا شريطاً ظاهراً لا ورقة سفلية كما في السكنات، لأن التصفية هنا هي
/// الاستخدام الأساسي: الطالب يبحث عن مادة قسمه في سنة محددة، فإخفاء
/// الفلاتر خلف زر يضيف خطوة في كل مرة.
class PaperFilterBar extends StatelessWidget {
  final ExamPaperFilter filter;
  final List<DepartmentSummary> departments;
  final List<int> years;
  final ValueChanged<ExamPaperFilter> onChanged;

  const PaperFilterBar({
    super.key,
    required this.filter,
    required this.departments,
    required this.years,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (departments.isNotEmpty)
            _buildMenu<String?>(
              context,
              icon: Icons.school_rounded,
              label: filter.departmentId == null
                  ? 'admission.papers.all_departments'.tr()
                  : _departmentName(filter.departmentId!),
              isActive: filter.departmentId != null,
              options: [null, ...departments.map((item) => item.id)],
              labelBuilder: (value) => value == null
                  ? 'admission.papers.all_departments'.tr()
                  : _departmentName(value),
              onSelected: (value) => onChanged(
                value == null
                    ? filter.copyWith(clearDepartment: true)
                    : filter.copyWith(departmentId: value),
              ),
            ),
          if (years.isNotEmpty)
            _buildMenu<int?>(
              context,
              icon: Icons.event_rounded,
              label: filter.year?.toString() ??
                  'admission.papers.all_years'.tr(),
              isActive: filter.year != null,
              options: [null, ...years],
              labelBuilder: (value) =>
                  value?.toString() ?? 'admission.papers.all_years'.tr(),
              onSelected: (value) => onChanged(
                value == null
                    ? filter.copyWith(clearYear: true)
                    : filter.copyWith(year: value),
              ),
            ),
          _buildMenu<ExamPaperType?>(
            context,
            icon: Icons.category_rounded,
            label: filter.type?.labelKey.tr() ??
                'admission.papers.all_types'.tr(),
            isActive: filter.type != null,
            options: [null, ...ExamPaperType.values],
            labelBuilder: (value) =>
                value?.labelKey.tr() ?? 'admission.papers.all_types'.tr(),
            onSelected: (value) => onChanged(
              value == null
                  ? filter.copyWith(clearType: true)
                  : filter.copyWith(type: value),
            ),
          ),
          if (filter.activeCount > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: ActionChip(
                avatar: const Icon(Icons.close_rounded, size: 16),
                label: Text('admission.housing.reset'.tr()),
                onPressed: () => onChanged(
                  ExamPaperFilter(query: filter.query),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _departmentName(String id) {
    for (final department in departments) {
      if (department.id == id) return department.name;
    }
    return id;
  }

  Widget _buildMenu<T>(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required List<T> options,
    required String Function(T value) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    final accent = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: PopupMenuButton<T>(
        onSelected: onSelected,
        itemBuilder: (context) => options
            .map(
              (value) => PopupMenuItem<T>(
                value: value,
                child: Text(labelBuilder(value)),
              ),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isActive
                ? accent.withValues(alpha: 0.14)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isActive ? accent : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: isActive ? accent : null),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? accent : null,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
