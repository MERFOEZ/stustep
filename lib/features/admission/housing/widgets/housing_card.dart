import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/admission_enums.dart';
import '../../models/housing_model.dart';

/// بطاقة سكن في القائمة: صورة الغلاف + الاسم + الحالة + السعر والمسافة.
class HousingCard extends StatelessWidget {
  final HousingModel housing;
  final VoidCallback onTap;
  final int delayMilliseconds;

  const HousingCard({
    super.key,
    required this.housing,
    required this.onTap,
    this.delayMilliseconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: delayMilliseconds),
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        housing.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (housing.addressText.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                housing.addressText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildMetaRow(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    final cover = housing.coverImage;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: cover == null
                ? Container(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.holiday_village_rounded,
                      size: 52,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.4),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => Container(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                    errorWidget: (context, _, _) => Container(
                      color: Colors.grey.withValues(alpha: 0.15),
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        PositionedDirectional(
          top: 10,
          start: 10,
          child: HousingStatusBadge(status: housing.status),
        ),
        if (housing.images.length > 1)
          PositionedDirectional(
            top: 10,
            end: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${housing.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          context,
          Icons.group_rounded,
          housing.gender.labelKey.tr(),
        ),
        if (housing.distanceKm > 0)
          _chip(
            context,
            Icons.directions_walk_rounded,
            'admission.housing.km_from_uni'.tr(
              args: [housing.distanceKm.toStringAsFixed(1)],
            ),
          ),
        if (housing.priceMonthly != null)
          _chip(
            context,
            Icons.payments_rounded,
            'admission.housing.per_month'.tr(
              args: [housing.priceMonthly!.toStringAsFixed(0)],
            ),
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final color = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// شارة حالة السكن: متاح أو ممتلئ.
class HousingStatusBadge extends StatelessWidget {
  final HousingStatus status;

  const HousingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == HousingStatus.available;
    final color = isAvailable
        ? const Color(0xFF00A152)
        : const Color(0xFFD32F2F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAvailable ? Icons.check_circle_rounded : Icons.block_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            status.labelKey.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
