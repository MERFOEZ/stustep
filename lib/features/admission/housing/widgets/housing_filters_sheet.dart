import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/admission_enums.dart';

/// معايير تصفية قائمة السكنات.
///
/// كائن غير قابل للتعديل يُمرَّر بين الشاشة والورقة: الشاشة تملك الحالة،
/// والورقة تُعيد نسخة جديدة. هذا يمنع الحالة المشتركة القابلة للتعديل من
/// موضعين، وهي أكثر مصادر أخطاء الفلاتر شيوعاً.
class HousingFilters {
  final HousingStatus? status;
  final HousingGender? gender;
  final double? maxPrice;
  final double? maxDistanceKm;

  const HousingFilters({
    this.status,
    this.gender,
    this.maxPrice,
    this.maxDistanceKm,
  });

  bool get isEmpty =>
      status == null &&
      gender == null &&
      maxPrice == null &&
      maxDistanceKm == null;

  /// عدد الفلاتر المفعّلة — يُعرض كشارة على زر الفلترة.
  int get activeCount => [
    status,
    gender,
    maxPrice,
    maxDistanceKm,
  ].where((value) => value != null).length;

  HousingFilters copyWith({
    HousingStatus? status,
    HousingGender? gender,
    double? maxPrice,
    double? maxDistanceKm,
    bool clearStatus = false,
    bool clearGender = false,
    bool clearPrice = false,
    bool clearDistance = false,
  }) {
    return HousingFilters(
      status: clearStatus ? null : (status ?? this.status),
      gender: clearGender ? null : (gender ?? this.gender),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      maxDistanceKm: clearDistance
          ? null
          : (maxDistanceKm ?? this.maxDistanceKm),
    );
  }
}

/// ورقة سفلية لضبط فلاتر السكنات.
class HousingFiltersSheet extends StatefulWidget {
  final HousingFilters initial;

  const HousingFiltersSheet({super.key, required this.initial});

  static Future<HousingFilters?> show(
    BuildContext context, {
    required HousingFilters initial,
  }) {
    return showModalBottomSheet<HousingFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HousingFiltersSheet(initial: initial),
    );
  }

  @override
  State<HousingFiltersSheet> createState() => _HousingFiltersSheetState();
}

class _HousingFiltersSheetState extends State<HousingFiltersSheet> {
  late HousingFilters _filters;

  /// حدود الأشرطة — قيم واقعية للسوق المحلي، وقابلة للضبط في مكان واحد.
  static const double _maxPriceLimit = 200000;
  static const double _maxDistanceLimit = 15;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _buildHandle(),
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildLabel('admission.housing.filter_status'.tr()),
          _buildStatusChips(context),
          const SizedBox(height: 20),
          _buildLabel('admission.housing.filter_gender'.tr()),
          _buildGenderChips(context),
          const SizedBox(height: 20),
          _buildPriceSlider(context),
          const SizedBox(height: 12),
          _buildDistanceSlider(context),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pop(context, _filters),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text('admission.housing.apply_filters'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'admission.housing.filters'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (!_filters.isEmpty)
          TextButton.icon(
            onPressed: () => setState(() => _filters = const HousingFilters()),
            icon: const Icon(Icons.clear_all_rounded, size: 17),
            label: Text(
              'admission.housing.clear_filters'.tr(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: HousingStatus.values.map((status) {
        final selected = _filters.status == status;
        return FilterChip(
          selected: selected,
          label: Text(status.labelKey.tr()),
          onSelected: (value) => setState(() {
            _filters = value
                ? _filters.copyWith(status: status)
                : _filters.copyWith(clearStatus: true);
          }),
        );
      }).toList(),
    );
  }

  Widget _buildGenderChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: HousingGender.values.map((gender) {
        final selected = _filters.gender == gender;
        return FilterChip(
          selected: selected,
          label: Text(gender.labelKey.tr()),
          onSelected: (value) => setState(() {
            _filters = value
                ? _filters.copyWith(gender: gender)
                : _filters.copyWith(clearGender: true);
          }),
        );
      }).toList(),
    );
  }

  Widget _buildPriceSlider(BuildContext context) {
    final value = _filters.maxPrice ?? _maxPriceLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLabel('admission.housing.filter_max_price'.tr()),
            ),
            Text(
              _filters.maxPrice == null
                  ? 'admission.housing.no_limit'.tr()
                  : value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: _maxPriceLimit,
          divisions: 20,
          onChanged: (newValue) => setState(() {
            // بلوغ أقصى الشريط يعني «بلا حد» لا «الحد الأعلى»، وإلا استُبعد
            // أي سكن سعره أعلى من سقف الشريط بلا قصد من المستخدم.
            _filters = newValue >= _maxPriceLimit
                ? _filters.copyWith(clearPrice: true)
                : _filters.copyWith(maxPrice: newValue);
          }),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider(BuildContext context) {
    final value = _filters.maxDistanceKm ?? _maxDistanceLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildLabel('admission.housing.filter_max_distance'.tr()),
            ),
            Text(
              _filters.maxDistanceKm == null
                  ? 'admission.housing.no_limit'.tr()
                  : 'admission.housing.distance_km'.tr(
                      namedArgs: {'km': value.toStringAsFixed(1)},
                    ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: _maxDistanceLimit,
          divisions: 30,
          onChanged: (newValue) => setState(() {
            _filters = newValue >= _maxDistanceLimit
                ? _filters.copyWith(clearDistance: true)
                : _filters.copyWith(maxDistanceKm: newValue);
          }),
        ),
      ],
    );
  }
}
