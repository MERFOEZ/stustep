import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/housing_service.dart';
import '../models/housing_model.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'add_housing_screen.dart';
import 'widgets/housing_card.dart';

/// إعلانات المستخدم الحالي — تعديل وحذف وتبديل الحالة.
class MyHousingsScreen extends StatelessWidget {
  const MyHousingsScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    HousingModel housing,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('admission.housing.delete_title'.tr()),
        content: Text('admission.housing.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await HousingService().deleteHousing(housing);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'admission.housing.deleted'.tr()
              : 'admission.housing.save_failed'.tr(),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, HousingModel housing) async {
    final ok = await HousingService().toggleStatus(housing);
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('admission.housing.save_failed'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.housing.my_listings'.tr()),
      body: uid == null
          ? AdmissionEmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'admission.housing.sign_in_required'.tr(),
            )
          : StreamBuilder<List<HousingModel>>(
              stream: HousingService().watchMyHousings(uid),
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
                    icon: Icons.folder_open_rounded,
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
                          delayMilliseconds: index * 60,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddHousingScreen(existing: housing),
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
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _toggle(context, housing),
              icon: Icon(
                housing.isAvailable
                    ? Icons.block_rounded
                    : Icons.check_circle_rounded,
                size: 17,
              ),
              label: Text(
                housing.isAvailable
                    ? 'admission.housing.mark_full'.tr()
                    : 'admission.housing.mark_available'.tr(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => _confirmDelete(context, housing),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            child: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
