import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/housing_model.dart';

/// بطاقة سكن في القائمة.
///
/// تعرض الصورة والسعر والمسافة والحالة معاً، لأن الطالب يوازن بين الثلاثة
/// في اللحظة نفسها: سكن رخيص وبعيد قد يكون أغلى فعلياً بعد حساب المواصلات.
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
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (housing.addressText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                housing.addressText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
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
            height: 140,
            width: double.infinity,
            child: cover == null
                ? Container(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.home_work_outlined,
                      size: 46,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.5),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: cover,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: Colors.grey.withValues(alpha: 0.15),
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        Positioned(top: 10, right: 10, child: _buildStatusBadge()),
        if (housing.images.length > 1)
          Positioned(bottom: 10, left: 10, child: _buildPhotoCount()),
      ],
    );
  }

  /// شارة التوفّر — أهم معلومة للطالب: هل ما زال هناك مكان؟
  Widget _buildStatusBadge() {
    final isAvailable = housing.isAvailable;
    final color = isAvailable
        ? const Color(0xFF00A152)
        : const Color(0xFFD32F2F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        housing.status.labelKey.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhotoCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '${housing.images.length}',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _buildChip(
          context,
          icon: Icons.people_outline_rounded,
          label: housing.gender.labelKey.tr(),
        ),
        if (housing.priceMonthly != null)
          _buildChip(
            context,
            icon: Icons.payments_outlined,
            label: 'admission.housing.price_monthly'.tr(
              namedArgs: {
                'price': housing.priceMonthly!.toStringAsFixed(0),
              },
            ),
            highlight: true,
          ),
        if (housing.distanceKm > 0)
          _buildChip(
            context,
            icon: Icons.directions_walk_rounded,
            label: 'admission.housing.distance_km'.tr(
              namedArgs: {'km': housing.distanceKm.toStringAsFixed(1)},
            ),
          ),
        if (housing.roomsAvailable != null)
          _buildChip(
            context,
            icon: Icons.meeting_room_outlined,
            label: 'admission.housing.rooms_count'.tr(
              namedArgs: {'count': '${housing.roomsAvailable}'},
            ),
          ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool highlight = false,
  }) {
    final color = highlight
        ? Theme.of(context).primaryColor
        : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
