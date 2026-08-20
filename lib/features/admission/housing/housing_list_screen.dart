import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/housing_service.dart';
import '../models/housing_model.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'add_housing_screen.dart';
import 'housing_detail_screen.dart';
import 'my_housings_screen.dart';
import 'widgets/housing_card.dart';
import 'widgets/housing_filters_sheet.dart';

/// قائمة السكنات الطلابية — القسم الثالث من البوابة.
///
/// كل الفلترة والبحث يتمّان **في الذاكرة على نتيجة بثّ واحد**، لا باستعلامات
/// جديدة عند كل تغيير فلتر. سببان: الجمع بين عدة شروط `where` وترتيب يفرض
/// فهرساً مركّباً والموديول ملتزم بصفر فهارس، وتكرار الاستعلام مع كل حركة
/// شريط تمرير كان سيستهلك حصة القراءات بلا فائدة.
class HousingListScreen extends StatefulWidget {
  const HousingListScreen({super.key});

  @override
  State<HousingListScreen> createState() => _HousingListScreenState();
}

class _HousingListScreenState extends State<HousingListScreen> {
  HousingFilters _filters = const HousingFilters();
  String _query = '';

  Future<void> _openFilters() async {
    final result = await HousingFiltersSheet.show(context, initial: _filters);
    if (result != null && mounted) setState(() => _filters = result);
  }

  void _open(HousingModel housing) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HousingDetailScreen(housing: housing)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(
        title: 'admission.housing.title'.tr(),
        actions: [
          IconButton(
            tooltip: 'admission.housing.my_listings'.tr(),
            icon: const Icon(Icons.folder_shared_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyHousingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHousingScreen()),
        ),
        icon: const Icon(Icons.add_home_work_rounded),
        label: Text('admission.housing.add'.tr()),
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: StreamBuilder<List<HousingModel>>(
              stream: HousingService().watchHousings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdmissionLoadingState();
                }
                if (snapshot.hasError) {
                  return const AdmissionErrorState();
                }

                final all = snapshot.data ?? const <HousingModel>[];
                if (all.isEmpty) {
                  return AdmissionEmptyState(
                    icon: Icons.home_work_outlined,
                    message: 'admission.housing.empty'.tr(),
                  );
                }

                final visible = HousingService.applyFilters(
                  all,
                  status: _filters.status,
                  gender: _filters.gender,
                  maxPrice: _filters.maxPrice,
                  maxDistanceKm: _filters.maxDistanceKm,
                  query: _query,
                );

                if (visible.isEmpty) {
                  return AdmissionEmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    message: 'admission.housing.no_match'.tr(),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => HousingCard(
                    housing: visible[index],
                    delayMilliseconds: (index * 60).clamp(0, 400),
                    onTap: () => _open(visible[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'admission.housing.search_hint'.tr(),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildFilterButton(context),
        ],
      ),
    );
  }

  /// زر الفلترة مع شارة تعرض عدد الفلاتر المفعّلة.
  ///
  /// الشارة ليست زينة: بدونها ينسى المستخدم أن فلتراً مفعّل فيظن أن السكنات
  /// اختفت من قاعدة البيانات.
  Widget _buildFilterButton(BuildContext context) {
    final count = _filters.activeCount;
    final primary = Theme.of(context).primaryColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: count > 0 ? primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _openFilters,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: count > 0 ? Colors.white : null,
              ),
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
