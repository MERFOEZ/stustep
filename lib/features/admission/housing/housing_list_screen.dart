import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/housing_service.dart';
import '../models/housing_filter.dart';
import '../models/housing_model.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'add_housing_screen.dart';
import 'housing_detail_screen.dart';
import 'my_housings_screen.dart';
import 'widgets/housing_card.dart';
import 'widgets/housing_filter_sheet.dart';

/// قائمة السكنات مع البحث والتصفية.
class HousingListScreen extends StatefulWidget {
  const HousingListScreen({super.key});

  @override
  State<HousingListScreen> createState() => _HousingListScreenState();
}

class _HousingListScreenState extends State<HousingListScreen> {
  final _searchController = TextEditingController();
  HousingFilter _filter = const HousingFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await HousingFilterSheet.show(context, _filter);
    if (result != null) setState(() => _filter = result);
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = AuthService().currentUser != null;

    return Scaffold(
      appBar: AdmissionAppBar(
        title: 'admission.modules.housing.title'.tr(),
        actions: [
          if (isSignedIn)
            IconButton(
              tooltip: 'admission.housing.my_listings'.tr(),
              icon: const Icon(Icons.folder_shared_rounded),
              onPressed: () => _open(const MyHousingsScreen()),
            ),
          IconButton(
            tooltip: 'admission.housing.filters'.tr(),
            icon: Badge(
              isLabelVisible: _filter.activeCount > 0,
              label: Text('${_filter.activeCount}'),
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      floatingActionButton: isSignedIn
          ? FloatingActionButton.extended(
              onPressed: () => _open(const AddHousingScreen()),
              icon: const Icon(Icons.add_home_rounded),
              label: Text('admission.housing.add'.tr()),
            )
          : null,
      body: Column(
        children: [
          _buildSearchBar(),
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
                    icon: Icons.holiday_village_outlined,
                    message: 'admission.housing.empty'.tr(),
                  );
                }

                final items = _filter.apply(all);
                if (items.isEmpty) {
                  return AdmissionEmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    message: 'admission.housing.no_match'.tr(),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                  itemCount: items.length,
                  itemBuilder: (context, index) => HousingCard(
                    housing: items[index],
                    delayMilliseconds: index * 60,
                    onTap: () =>
                        _open(HousingDetailScreen(housing: items[index])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _filter = _filter.copyWith(query: value)),
        decoration: InputDecoration(
          hintText: 'admission.housing.search_hint'.tr(),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _filter.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _filter = _filter.copyWith(query: ''));
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}
