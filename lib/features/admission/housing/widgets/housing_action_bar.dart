import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/external_launcher_service.dart';
import '../../models/housing_model.dart';

/// شريط أفعال التواصل الثابت أسفل صفحة السكن: اتصال · واتساب · خريطة.
///
/// **لماذا شريط ثابت لا أزرار داخل المحتوى؟**
/// هذه هي الأفعال الوحيدة التي جاء الطالب من أجلها. دفنها أسفل وصف طويل
/// يجعله يفوّتها، ووضعها ثابتة يعني أنها في متناوله في كل لحظة.
///
/// **ولماذا نُبلغ عند فشل الفتح؟**
/// الفشل الصامت هنا خطير: الطالب يضغط «اتصال» ولا يحدث شيء فيظن التطبيق
/// معطّلاً، بينما السبب أن الجهاز بلا تطبيق هاتف (جهاز لوحي مثلاً).
class HousingActionBar extends StatelessWidget {
  final HousingModel housing;

  const HousingActionBar({super.key, required this.housing});

  Future<void> _run(
    BuildContext context,
    Future<bool> Function() action,
    String failureKey,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await action();
    if (!success && context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(failureKey.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final launcher = ExternalLauncherService();
    final mapsUrl = housing.mapsUrl;
    final whatsapp = housing.whatsapp;

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
              onPressed: () => _run(
                context,
                () => launcher.call(housing.phone),
                'admission.housing.call_failed',
              ),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text(
                'admission.housing.call'.tr(),
                style: const TextStyle(fontSize: 12.5),
              ),
              style: _buttonStyle(),
            ),
          ),
          if (whatsapp != null) ...[
            const SizedBox(width: 9),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _run(
                  context,
                  () => launcher.whatsapp(
                    whatsapp,
                    message: 'admission.housing.whatsapp_message'.tr(
                      namedArgs: {'name': housing.name},
                    ),
                  ),
                  'admission.housing.whatsapp_failed',
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: Text(
                  'admission.housing.whatsapp'.tr(),
                  style: const TextStyle(fontSize: 12.5),
                ),
                style: _buttonStyle(background: const Color(0xFF25D366)),
              ),
            ),
          ],
          if (mapsUrl != null) ...[
            const SizedBox(width: 9),
            SizedBox(
              width: 52,
              child: OutlinedButton(
                onPressed: () => _run(
                  context,
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

  ButtonStyle _buttonStyle({Color? background}) {
    return FilledButton.styleFrom(
      backgroundColor: background,
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    );
  }
}
