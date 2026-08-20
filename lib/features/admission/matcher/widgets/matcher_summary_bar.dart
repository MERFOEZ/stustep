import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/matcher_outcome.dart';

/// شريط ملخّص نتائج المطابق: الأرقام الثلاثة، والتنبيه، ومرشّح المؤهَّل.
///
/// فُصل عن شاشة النتائج لإبقائها تحت سقف الثلاثمئة سطر، ولأنه وحدة عرض
/// مستقلة تُعرض فوق القائمة ولا تشارك حالتها.
class MatcherSummaryBar extends StatelessWidget {
  final MatcherOutcome outcome;

  /// حالة مرشّح «المؤهَّلة فقط» ودالة تبديله — الحالة تبقى في الشاشة الأم
  /// لأنها هي من يعيد بناء القائمة.
  final bool eligibleOnly;
  final ValueChanged<bool> onEligibleOnlyChanged;

  const MatcherSummaryBar({
    super.key,
    required this.outcome,
    required this.eligibleOnly,
    required this.onEligibleOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStat(
                value: '${outcome.eligibleCount}',
                labelKey: 'admission.matcher.stat_eligible',
                color: const Color(0xFF00A152),
              ),
              _buildStat(
                value: '${outcome.borderlineCount}',
                labelKey: 'admission.matcher.stat_borderline',
                color: const Color(0xFFEF6C00),
              ),
              _buildStat(
                value: '${outcome.suggestions.length}',
                labelKey: 'admission.matcher.stat_total',
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
          if (outcome.skippedForMissingRequirements > 0) ...[
            const SizedBox(height: 10),
            _buildSkippedNotice(outcome.skippedForMissingRequirements),
          ],
          const SizedBox(height: 10),
          _buildFilterRow(context),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String value,
    required String labelKey,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            labelKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// إبلاغ صريح عن الأقسام المستبعَدة.
  ///
  /// الاختفاء الصامت يوهم الطالب بأن التخصص غير موجود أصلاً، بينما الحقيقة
  /// أن كليته لم تُنشر شروطها بعد. الفرق بين الرسالتين قرار مصيري له.
  Widget _buildSkippedNotice(int count) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 15,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'admission.matcher.skipped_notice'.tr(
              namedArgs: {'count': '$count'},
            ),
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.filter_alt_rounded, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'admission.matcher.eligible_only'.tr(),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Switch(value: eligibleOnly, onChanged: onEligibleOnlyChanged),
      ],
    );
  }
}
