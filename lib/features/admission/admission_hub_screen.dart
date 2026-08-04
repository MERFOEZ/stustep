import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/services/app_config_service.dart';
import '../../core/theme/app_theme.dart';
import 'admission_modules.dart';
import 'models/admission_config.dart';
import 'widgets/admission_app_bar.dart';
import 'widgets/admission_gradient_card.dart';

/// نقطة الدخول الوحيدة لموديول القبول الجامعي.
///
/// تُفتح من بطاقة «بوابة الجامعة» في الشاشة الرئيسية، وتعرض الأقسام الخمسة.
/// الأقسام تُقرأ من `AdmissionModules.all`، لذلك لا تحتاج هذه الشاشة أي
/// تعديل عند إضافة شاشات المراحل القادمة.
class AdmissionHubScreen extends StatefulWidget {
  const AdmissionHubScreen({super.key});

  @override
  State<AdmissionHubScreen> createState() => _AdmissionHubScreenState();
}

class _AdmissionHubScreenState extends State<AdmissionHubScreen> {
  final AppConfigService _configService = AppConfigService();
  AdmissionConfig? _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _configService.getAdmissionConfig();
    if (mounted) setState(() => _config = config);
  }

  void _openModule(AdmissionModuleEntry entry) {
    final builder = entry.builder;
    if (builder == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('admission.coming_soon'.tr()),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
        );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.title'.tr()),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.82,
                    ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = AdmissionModules.all[index];
                  return AdmissionGradientCard(
                    title: entry.labelKey.tr(),
                    subtitle: entry.descriptionKey.tr(),
                    icon: entry.icon,
                    gradient: entry.gradient,
                    delayMilliseconds: index * 90,
                    onTap: () => _openModule(entry),
                    trailing: entry.isAvailable
                        ? null
                        : _buildSoonBadge(context),
                  );
                }, childCount: AdmissionModules.all.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final announcement = _config?.announcement ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInLeft(
            duration: const Duration(milliseconds: 700),
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient(context).createShader(bounds),
              child: Text(
                'admission.subtitle'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (announcement.isNotEmpty) ...[
            const SizedBox(height: 14),
            FadeInRight(
              duration: const Duration(milliseconds: 700),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient(context),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        announcement,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildSoonBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'admission.soon_badge'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
