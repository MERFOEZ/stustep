import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../../models/high_school_certificate.dart';
import '../../models/major_suggestion.dart';

/// بطاقة الترويسة التعريفية للمساعد.
class MatcherHeroCard extends StatelessWidget {
  const MatcherHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC51162), Color(0xFFFF4081)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
            const SizedBox(height: 14),
            Text(
              'admission.matcher.hero_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'admission.matcher.hero_subtitle'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة شرح أوزان الترتيب الأربعة.
///
/// **لماذا نُظهر المعيار قبل الحكم لا بعده؟**
/// لأن الطالب الذي يرى الأوزان أولاً يثق بالترتيب ويفهم لماذا تصدّر تخصص
/// على آخر. أما من يرى النتيجة أولاً فيتعامل معها كرأي عشوائي من التطبيق،
/// ويرفضها إن خالفت ما في ذهنه. الشفافية هنا ليست تجميلاً بل شرط قبول.
class MatcherWeightsCard extends StatelessWidget {
  const MatcherWeightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.balance_rounded,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'admission.matcher.how_it_works'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildRow(
            'admission.matcher.factor.interests'.tr(),
            MatcherWeights.interests,
            const Color(0xFF6200EE),
          ),
          _buildRow(
            'admission.matcher.factor.gpa_fit'.tr(),
            MatcherWeights.gpaFit,
            const Color(0xFF00C853),
          ),
          _buildRow(
            'admission.matcher.factor.certificate_fit'.tr(),
            MatcherWeights.certificateFit,
            const Color(0xFF304FFE),
          ),
          _buildRow(
            'admission.matcher.factor.completeness'.tr(),
            MatcherWeights.completeness,
            const Color(0xFFFF6D00),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double weight, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5))),
          Text(
            '${weight.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة حالة الشهادة: جاهزة أم ناقصة، مع زر الإدخال أو التعديل.
///
/// المساعد لا يعمل بلا شهادة. عرض الحالة هنا **قبل** بدء المسار يمنع أن
/// يُفاجأ الطالب برسالة خطأ في منتصفه بعد أن اختار اهتماماته.
class MatcherCertificateCard extends StatelessWidget {
  final HighSchoolCertificate? certificate;
  final VoidCallback onEdit;

  const MatcherCertificateCard({
    super.key,
    required this.certificate,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ready = certificate != null;
    final color = ready ? const Color(0xFF00A152) : const Color(0xFFEF6C00);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ready ? Icons.verified_rounded : Icons.warning_amber_rounded,
                size: 19,
                color: color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  ready
                      ? 'admission.matcher.certificate_ready'.tr()
                      : 'admission.matcher.certificate_missing'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (ready) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _buildTag(certificate!.type.labelKey.tr()),
                _buildTag(certificate!.track.labelKey.tr()),
                _buildTag(
                  '${certificate!.gpa} ${certificate!.gpaScale.labelKey.tr()}',
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: Icon(ready ? Icons.edit_rounded : Icons.add_rounded, size: 17),
            label: Text(
              ready
                  ? 'admission.matcher.edit_certificate'.tr()
                  : 'admission.matcher.add_certificate'.tr(),
              style: const TextStyle(fontSize: 12.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
