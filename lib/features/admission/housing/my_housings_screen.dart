import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/housing_service.dart';
import '../models/admission_enums.dart';
import '../models/housing_model.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'housing_detail_screen.dart';
import 'widgets/housing_card.dart';

/// إعلاناتي — إدارة السكنات التي أضافها المستخدم الحالي.
///
/// العملية الأكثر تكراراً هنا ليست التعديل بل **تبديل حالة التوفّر**: صاحب
/// السكن يمتلئ عنده مكان فيريد إخفاءه بضغطة واحدة لا بفتح نموذج كامل. لذلك
/// وُضع التبديل مباشرة في القائمة.
class MyHousingsScreen extends StatelessWidget {
  const MyHousingsScreen({super.key});

  Future<void> _toggleStatus(
    BuildContext context,
    HousingModel housing,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final next = housing.isAvailable
        ? HousingStatus.full
        : HousingStatus.available;

    final success = await HousingService().toggleStatus(
      housingId: housing.id,
      status: next,
    );

    if (!success) {
      messenger.showSnackBar(
        SnackBar(content: Text('admission.housing.save_failed'.tr())),
      );
    }
  }

  /// حذف بتأكيد صريح.
  ///
  /// الحذف هنا نهائي ولا رجعة فيه (تُفقد الصور المرفوعة أيضاً)، فحوار
  /// التأكيد ليس احتياطاً زائداً.
  Future<void> _confirmDelete(
    BuildContext context,
    HousingModel housing,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('admission.housing.delete_title'.tr()),
        content: Text(
          'admission.housing.delete_confirm'.tr(
            namedArgs: {'name': housing.name},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('admission.housing.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: Text('admission.housing.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await HousingService().delete(housing.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'admission.housing.deleted'.tr()
              : 'admission.housing.save_failed'.tr(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.housing.my_listings'.tr()),
      body: StreamBuilder<List<HousingModel>>(
        stream: HousingService().watchMyHousings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdmissionLoadingState();
          }
          if (snapshot.hasError) {
            return const AdmissionErrorState();
          }

          final items = snapshot.data ?? const <HousingModel>[];
          if (items.isEmpty) {
            return AdmissionEmptyState(
              icon: Icons.folder_off_outlined,
              message: 'admission.housing.no_listings'.tr(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final housing = items[index];
              return Column(
                children: [
                  HousingCard(
                    housing: housing,
                    delayMilliseconds: (index * 60).clamp(0, 400),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HousingDetailScreen(housing: housing),
                      ),
                    ),
                  ),
                  _buildOwnerActions(context, housing),
                  const SizedBox(height: 18),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOwnerActions(BuildContext context, HousingModel housing) {
    return Container(
      margin: const EdgeInsets.only(top: -10),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _toggleStatus(context, housing),
              icon: Icon(
                housing.isAvailable
                    ? Icons.do_not_disturb_on_outlined
                    : Icons.check_circle_outline_rounded,
                size: 17,
              ),
              label: Text(
                housing.isAvailable
                    ? 'admission.housing.mark_full'.tr()
                    : 'admission.housing.mark_available'.tr(),
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          OutlinedButton(
            onPressed: () => _confirmDelete(context, housing),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
              side: BorderSide(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
