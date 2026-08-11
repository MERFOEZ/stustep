import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/external_launcher_service.dart';
import '../models/housing_model.dart';
import '../widgets/admission_app_bar.dart';

/// صفحة تفاصيل السكن: المعرض، البيانات، وأزرار التواصل والخريطة.
///
/// الأزرار الثلاثة (اتصال · واتساب · خريطة) في شريط سفلي ثابت لا داخل
/// المحتوى المتمرّر. السبب: هذه هي الأفعال الوحيدة التي جاء الطالب من
/// أجلها، ودفنها أسفل وصف طويل يجعله يفوّتها.
class HousingDetailScreen extends StatefulWidget {
  final HousingModel housing;

  const HousingDetailScreen({super.key, required this.housing});

  @override
  State<HousingDetailScreen> createState() => _HousingDetailScreenState();
}

class _HousingDetailScreenState extends State<HousingDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImage = 0;

  HousingModel get _housing => widget.housing;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// تنفيذ فعل خارجي مع إبلاغ واضح عند الفشل.
  ///
  /// الفشل الصامت هنا خطير: الطالب يضغط «اتصال» ولا يحدث شيء، فيظن أن
  /// التطبيق معطّل بينما السبب أن الجهاز بلا تطبيق هاتف (جهاز لوحي مثلاً).
  Future<void> _runAction(
    Future<bool> Function() action,
    String failureKey,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await action();
    if (!success && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(failureKey.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: _housing.name),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildGallery(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildFacts(context),
                if (_housing.description.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('admission.housing.description'.tr()),
                  Text(
                    _housing.description,
                    style: const TextStyle(fontSize: 13.5, height: 1.7),
                  ),
                ],
                if (_housing.addressText.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle('admission.housing.address'.tr()),
                  Text(
                    _housing.addressText,
                    style: const TextStyle(fontSize: 13.5, height: 1.7),
                  ),
                ],
                const SizedBox(height: 18),
                _buildOwnerNote(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(context),
    );
  }

  Widget _buildGallery(BuildContext context) {
    final images = _housing.images;

    if (images.isEmpty) {
      return Container(
        height: 200,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        child: Icon(
          Icons.home_work_outlined,
          size: 64,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentImage = index),
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, _) =>
                  Container(color: Colors.grey.withValues(alpha: 0.15)),
              errorWidget: (_, _, _) => Container(
                color: Colors.grey.withValues(alpha: 0.15),
                child: const Icon(Icons.broken_image_outlined, size: 40),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final isActive = index == _currentImage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isAvailable = _housing.isAvailable;
    final color = isAvailable
        ? const Color(0xFF00A152)
        : const Color(0xFFD32F2F);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _housing.name,
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
            _housing.status.labelKey.tr(),
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

  Widget _buildFacts(BuildContext context) {
    final facts = <({IconData icon, String label, String value})>[
      (
        icon: Icons.people_outline_rounded,
        label: 'admission.housing.gender'.tr(),
        value: _housing.gender.labelKey.tr(),
      ),
      if (_housing.priceMonthly != null)
        (
          icon: Icons.payments_outlined,
          label: 'admission.housing.price'.tr(),
          value: 'admission.housing.price_monthly'.tr(
            namedArgs: {'price': _housing.priceMonthly!.toStringAsFixed(0)},
          ),
        ),
      if (_housing.distanceKm > 0)
        (
          icon: Icons.directions_walk_rounded,
          label: 'admission.housing.distance'.tr(),
          value: 'admission.housing.distance_km'.tr(
            namedArgs: {'km': _housing.distanceKm.toStringAsFixed(1)},
          ),
        ),
      if (_housing.roomsAvailable != null)
        (
          icon: Icons.meeting_room_outlined,
          label: 'admission.housing.rooms'.tr(),
          value: '${_housing.roomsAvailable}',
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
            .map(
              (fact) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      fact.icon,
                      size: 17,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fact.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      fact.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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

  /// تنبيه المسؤولية: المحتوى من مستخدم لا من الجامعة.
  ///
  /// وجوده ليس شكلياً — التطبيق يعرض بيانات لم يتحقق منها أحد، وإخفاء ذلك
  /// يجعل الطالب يتعامل معها كأنها معتمدة رسمياً.
  Widget _buildOwnerNote(BuildContext context) {
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

  Widget _buildActionBar(BuildContext context) {
    final launcher = ExternalLauncherService();
    final mapsUrl = _housing.mapsUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _runAction(
                () => launcher.call(_housing.phone),
                'admission.housing.call_failed',
              ),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text(
                'admission.housing.call'.tr(),
                style: const TextStyle(fontSize: 12.5),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          if (_housing.whatsapp != null) ...[
            const SizedBox(width: 9),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _runAction(
                  () => launcher.whatsapp(
                    _housing.whatsapp!,
                    message: 'admission.housing.whatsapp_message'.tr(
                      namedArgs: {'name': _housing.name},
                    ),
                  ),
                  'admission.housing.whatsapp_failed',
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: Text(
                  'admission.housing.whatsapp'.tr(),
                  style: const TextStyle(fontSize: 12.5),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
          if (mapsUrl != null) ...[
            const SizedBox(width: 9),
            SizedBox(
              width: 52,
              child: OutlinedButton(
                onPressed: () => _runAction(
                  () => launcher.openMap(mapsUrl),
                  'admission.housing.map_failed',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Icon(Icons.map_rounded, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
