import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/housing_model.dart';
import '../widgets/admission_app_bar.dart';
import 'widgets/housing_action_bar.dart';
import 'widgets/housing_gallery.dart';

/// صفحة تفاصيل السكن: المعرض، البيانات، والتنبيه، وشريط التواصل الثابت.
///
/// المعرض وشريط الأفعال مفصولان في ودجت مستقلة، فبقيت الشاشة نفسها تحت
/// سقف الثلاثمئة سطر الذي التزم به الموديول منذ مرحلة التحليل.
class HousingDetailScreen extends StatelessWidget {
  final HousingModel housing;

  const HousingDetailScreen({super.key, required this.housing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: housing.name),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HousingGallery(images: housing.images),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildFacts(context),
                if (housing.description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('admission.housing.description'.tr()),
                  _buildBodyText(housing.description),
                ],
                if (housing.addressText.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('admission.housing.address'.tr()),
                  _buildBodyText(housing.addressText),
                ],
                const SizedBox(height: 18),
                _buildDisclaimer(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: HousingActionBar(housing: housing),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final color = housing.isAvailable
        ? const Color(0xFF00A152)
        : const Color(0xFFD32F2F);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            housing.name,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            housing.status.labelKey.tr(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// جدول الحقائق — يُبنى ديناميكياً فتختفي الحقول غير المعبَّأة بدل عرضها
  /// فارغة، لأن حقلاً فارغاً يوهم الطالب بأن المعلومة صفر لا أنها مجهولة.
  Widget _buildFacts(BuildContext context) {
    final facts = <({IconData icon, String label, String value})>[
      (
        icon: Icons.people_outline_rounded,
        label: 'admission.housing.gender'.tr(),
        value: housing.gender.labelKey.tr(),
      ),
      if (housing.priceMonthly != null)
        (
          icon: Icons.payments_outlined,
          label: 'admission.housing.price'.tr(),
          value: 'admission.housing.price_monthly'.tr(
            namedArgs: {'price': housing.priceMonthly!.toStringAsFixed(0)},
          ),
        ),
      if (housing.distanceKm > 0)
        (
          icon: Icons.directions_walk_rounded,
          label: 'admission.housing.distance'.tr(),
          value: 'admission.housing.distance_km'.tr(
            namedArgs: {'km': housing.distanceKm.toStringAsFixed(1)},
          ),
        ),
      if (housing.roomsAvailable != null)
        (
          icon: Icons.meeting_room_outlined,
          label: 'admission.housing.rooms'.tr(),
          value: '${housing.roomsAvailable}',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: facts
            .map((fact) => _buildFactRow(context, fact))
            .toList(),
      ),
    );
  }

  Widget _buildFactRow(
    BuildContext context,
    ({IconData icon, String label, String value}) fact,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(fact.icon, size: 17, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact.label,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ),
          Text(
            fact.value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(text, style: const TextStyle(fontSize: 13.5, height: 1.7));
  }

  /// تنبيه المسؤولية: المحتوى من مستخدم لا من الجامعة.
  ///
  /// وجوده ليس شكلياً — التطبيق يعرض بيانات لم يتحقق منها أحد، وإخفاء ذلك
  /// يجعل الطالب يتعامل معها كأنها معتمدة رسمياً فيبني عليها التزاماً مالياً.
  Widget _buildDisclaimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: Color(0xFFEF6C00),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'admission.housing.disclaimer'.tr(),
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
