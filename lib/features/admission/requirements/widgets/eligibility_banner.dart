import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/admission_enums.dart';
import '../../models/certificate_eligibility.dart';

/// لافتة نتيجة الأهلية مع أسبابها.
///
/// المبدأ المطبَّق: **لا رفض مبهم.** كل سبب يُعرض بنصه وبالقيمة المطلوبة
/// والقيمة الفعلية، حتى يعرف الطالب ما الذي ينقصه بالضبط.
class EligibilityBanner extends StatelessWidget {
  final CertificateEligibility eligibility;
  final String targetName;
  final bool compact;

  const EligibilityBanner({
    super.key,
    required this.eligibility,
    required this.targetName,
    this.compact = false,
  });

  Color get _color {
    switch (eligibility.level) {
      case EligibilityLevel.eligible:
        return const Color(0xFF00A152);
      case EligibilityLevel.borderline:
        return const Color(0xFFEF6C00);
      case EligibilityLevel.notEligible:
        return const Color(0xFFD32F2F);
    }
  }

  IconData get _icon {
    switch (eligibility.level) {
      case EligibilityLevel.eligible:
        return Icons.verified_rounded;
      case EligibilityLevel.borderline:
        return Icons.error_outline_rounded;
      case EligibilityLevel.notEligible:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: EdgeInsets.all(compact ? 14 : 18),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: _color, size: compact ? 22 : 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetName,
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        eligibility.level.labelKey.tr(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _color,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildGpaBadge(),
              ],
            ),
            if (eligibility.failedReasons.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...eligibility.failedReasons.map(_buildReason),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGpaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            eligibility.normalizedGpa.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
          Text(
            '/ ${eligibility.requiredGpa.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 10, color: _color),
          ),
        ],
      ),
    );
  }

  Widget _buildReason(EligibilityReason reason) {
    final buffer = StringBuffer(reason.labelKey.tr());

    if (reason.subjectName != null) {
      buffer.write(' (${reason.subjectName})');
    }
    if (reason.required != null && reason.actual != null) {
      buffer.write(
        ' — ${'admission.reason_required'.tr()}: ${reason.required}'
        ' · ${'admission.reason_actual'.tr()}: ${reason.actual}',
      );
    } else if (reason.required != null) {
      buffer.write(' — ${'admission.reason_required'.tr()}: ${reason.required}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.close_rounded, size: 15, color: _color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              buffer.toString(),
              style: const TextStyle(fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
