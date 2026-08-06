import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/external_launcher_service.dart';
import '../../../core/services/housing_service.dart';
import '../guide/widgets/guide_section_card.dart';
import '../models/housing_model.dart';
import '../requirements/widgets/requirement_views.dart';
import 'widgets/housing_card.dart';

/// تفاصيل السكن: معرض الصور، البيانات، والتواصل.
class HousingDetailScreen extends StatefulWidget {
  final HousingModel housing;

  const HousingDetailScreen({super.key, required this.housing});

  @override
  State<HousingDetailScreen> createState() => _HousingDetailScreenState();
}

class _HousingDetailScreenState extends State<HousingDetailScreen> {
  final _launcher = ExternalLauncherService();
  final _pageController = PageController();
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    // عدّاد المشاهدات — فشله لا يعني المستخدم فلا نعرض رسالة.
    HousingService().incrementView(widget.housing.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launch(Future<bool> action) async {
    final ok = await action;
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('admission.housing.launch_failed'.tr())),
        );
    }
  }

  Color get _accent => Theme.of(context).primaryColor;

  @override
  Widget build(BuildContext context) {
    final housing = widget.housing;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildGallery(housing),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(housing),
                const SizedBox(height: 16),
                _buildInfoSection(housing),
                if (housing.description.isNotEmpty)
                  _buildDescriptionSection(housing),
                _buildContactSection(housing),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(HousingModel housing) {
    final images = housing.images;

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: _accent,
      flexibleSpace: FlexibleSpaceBar(
        background: images.isEmpty
            ? Container(
                color: _accent.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.holiday_village_rounded,
                  size: 80,
                  color: Colors.white70,
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (index) =>
                        setState(() => _currentImage = index),
                    itemBuilder: (context, index) => CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      errorWidget: (context, _, _) => const ColoredBox(
                        color: Colors.black26,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    PositionedDirectional(
                      bottom: 14,
                      start: 0,
                      end: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (index) {
                          final active = index == _currentImage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: active ? 1 : 0.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(HousingModel housing) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            housing.name,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        HousingStatusBadge(status: housing.status),
      ],
    );
  }

  Widget _buildInfoSection(HousingModel housing) {
    return GuideSectionCard(
      title: 'admission.housing.details'.tr(),
      icon: Icons.info_outline_rounded,
      accentColor: _accent,
      child: Column(
        children: [
          RequirementInfoTile(
            icon: Icons.group_rounded,
            label: 'admission.housing.gender'.tr(),
            value: housing.gender.labelKey.tr(),
            accentColor: _accent,
          ),
          if (housing.priceMonthly != null)
            RequirementInfoTile(
              icon: Icons.payments_rounded,
              label: 'admission.housing.price'.tr(),
              value: 'admission.housing.per_month'.tr(
                args: [housing.priceMonthly!.toStringAsFixed(0)],
              ),
              accentColor: _accent,
            ),
          if (housing.distanceKm > 0)
            RequirementInfoTile(
              icon: Icons.directions_walk_rounded,
              label: 'admission.housing.distance'.tr(),
              value: 'admission.housing.km_from_uni'.tr(
                args: [housing.distanceKm.toStringAsFixed(1)],
              ),
              accentColor: _accent,
            ),
          if (housing.roomsAvailable != null)
            RequirementInfoTile(
              icon: Icons.meeting_room_rounded,
              label: 'admission.housing.rooms'.tr(),
              value: '${housing.roomsAvailable}',
              accentColor: _accent,
            ),
          if (housing.addressText.isNotEmpty)
            RequirementInfoTile(
              icon: Icons.place_rounded,
              label: 'admission.housing.address'.tr(),
              value: housing.addressText,
              accentColor: _accent,
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(HousingModel housing) {
    return GuideSectionCard(
      title: 'admission.housing.description'.tr(),
      icon: Icons.notes_rounded,
      accentColor: _accent,
      delayMilliseconds: 80,
      child: Text(
        housing.description,
        style: const TextStyle(fontSize: 13.5, height: 1.7),
      ),
    );
  }

  Widget _buildContactSection(HousingModel housing) {
    return GuideSectionCard(
      title: 'admission.housing.contact'.tr(),
      icon: Icons.contact_phone_rounded,
      accentColor: _accent,
      delayMilliseconds: 160,
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.call_rounded,
            label: 'admission.housing.call'.tr(),
            color: const Color(0xFF00A152),
            onTap: () => _launch(_launcher.call(housing.phone)),
          ),
          _buildActionButton(
            icon: Icons.chat_rounded,
            label: 'admission.housing.whatsapp'.tr(),
            color: const Color(0xFF25D366),
            onTap: () => _launch(
              _launcher.whatsapp(
                housing.whatsapp ?? housing.phone,
                message: 'admission.housing.wa_message'.tr(
                  args: [housing.name],
                ),
              ),
            ),
          ),
          if (housing.location != null)
            _buildActionButton(
              icon: Icons.map_rounded,
              label: 'admission.housing.open_map'.tr(),
              color: const Color(0xFF1A73E8),
              onTap: () => _launch(_launcher.openMap(housing.location!)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
