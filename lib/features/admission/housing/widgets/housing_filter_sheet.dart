import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/admission_enums.dart';
import '../../models/housing_filter.dart';
import '../../requirements/widgets/certificate_form_fields.dart';

/// ورقة تصفية السكنات.
///
/// تعيد استخدام `ChoiceChipsGroup` المبني في المرحلة 4 — وهو العائد العملي
/// لقرار فصل حقول النماذج عن شاشاتها هناك.
class HousingFilterSheet extends StatefulWidget {
  final HousingFilter initial;

  const HousingFilterSheet({super.key, required this.initial});

  static Future<HousingFilter?> show(
    BuildContext context,
    HousingFilter initial,
  ) {
    return showModalBottomSheet<HousingFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HousingFilterSheet(initial: initial),
    );
  }

  @override
  State<HousingFilterSheet> createState() => _HousingFilterSheetState();
}

class _HousingFilterSheetState extends State<HousingFilterSheet> {
  late HousingStatus? _status;
  late HousingGender? _gender;
  late double _maxPrice;
  late double _maxDistance;
  late bool _priceEnabled;
  late bool _distanceEnabled;

  static const double _priceCeiling = 100000;
  static const double _distanceCeiling = 20;

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
    _gender = widget.initial.gender;
    _priceEnabled = widget.initial.maxPrice != null;
    _distanceEnabled = widget.initial.maxDistanceKm != null;
    _maxPrice = widget.initial.maxPrice ?? _priceCeiling / 2;
    _maxDistance = widget.initial.maxDistanceKm ?? _distanceCeiling / 2;
  }

  void _apply() {
    Navigator.pop(
      context,
      HousingFilter(
        status: _status,
        gender: _gender,
        maxPrice: _priceEnabled ? _maxPrice : null,
        maxDistanceKm: _distanceEnabled ? _maxDistance : null,
        query: widget.initial.query,
      ),
    );
  }

  void _reset() {
    Navigator.pop(context, HousingFilter(query: widget.initial.query));
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
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'admission.housing.filters'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          FormFieldLabel(
            text: 'admission.housing.status'.tr(),
            icon: Icons.check_circle_outline_rounded,
          ),
          ChoiceChipsGroup<HousingStatus?>(
            options: [null, ...HousingStatus.values],
            selected: _status,
            labelBuilder: (option) => option == null
                ? 'admission.housing.all'.tr()
                : option.labelKey.tr(),
            onSelected: (option) => setState(() => _status = option),
          ),
          const SizedBox(height: 20),

          FormFieldLabel(
            text: 'admission.housing.gender'.tr(),
            icon: Icons.group_rounded,
          ),
          ChoiceChipsGroup<HousingGender?>(
            options: [null, ...HousingGender.values],
            selected: _gender,
            labelBuilder: (option) => option == null
                ? 'admission.housing.all'.tr()
                : option.labelKey.tr(),
            onSelected: (option) => setState(() => _gender = option),
          ),
          const SizedBox(height: 12),

          _buildSlider(
            label: 'admission.housing.max_price'.tr(),
            icon: Icons.payments_rounded,
            enabled: _priceEnabled,
            value: _maxPrice,
            max: _priceCeiling,
            divisions: 20,
            valueLabel: _maxPrice.toStringAsFixed(0),
            onToggle: (value) => setState(() => _priceEnabled = value),
            onChanged: (value) => setState(() => _maxPrice = value),
          ),

          _buildSlider(
            label: 'admission.housing.max_distance'.tr(),
            icon: Icons.directions_walk_rounded,
            enabled: _distanceEnabled,
            value: _maxDistance,
            max: _distanceCeiling,
            divisions: 40,
            valueLabel: '${_maxDistance.toStringAsFixed(1)} km',
            onToggle: (value) => setState(() => _distanceEnabled = value),
            onChanged: (value) => setState(() => _maxDistance = value),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('admission.housing.reset'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text('admission.housing.apply'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required bool enabled,
    required double value,
    required double max,
    required int divisions,
    required String valueLabel,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (enabled)
              Text(
                valueLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            Switch(value: enabled, onChanged: onToggle),
          ],
        ),
        if (enabled)
          Slider(
            value: value.clamp(0, max),
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}
