import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_config_service.dart';
import '../../../core/services/external_launcher_service.dart';
import '../models/admission_config.dart';
import '../models/university_portal_link.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'widgets/university_link_tile.dart';

/// بوابة الجامعة الرسمية — تسليم الطالب لأنظمة جامعته لا محاكاتها.
///
/// **حدود هذه الشاشة مقصودة:** لا تُقدِّم طلباً ولا تنفّذ دفعاً. التقديم
/// والدفع يجريان على أنظمة الجامعة نفسها، فتفتح الشاشة العنوان الرسمي في
/// المتصفح الخارجي وتتوقف عند هذا الحد. البديل — استقبال بيانات الطالب
/// وبطاقته داخل التطبيق ثم تمريرها — يجعل مشروعاً طلابياً وسيطاً في مسار
/// دفع، وهو ما لا تبرّره أي فائدة للطالب.
///
/// **صفر استدعاء Firestore هنا:** العناوين تأتي من `AppConfigService`
/// المخزَّنة مؤقتاً، وتحويلها إلى روابط صالحة دالة خالصة مُختبَرة آلياً.
class UniversityPortalScreen extends StatefulWidget {
  const UniversityPortalScreen({super.key});

  @override
  State<UniversityPortalScreen> createState() => _UniversityPortalScreenState();
}

class _UniversityPortalScreenState extends State<UniversityPortalScreen> {
  final AppConfigService _configService = AppConfigService();

  UniversityConfig? _config;
  List<UniversityPortalLink> _links = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final config = await _configService.getUniversityConfig(
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    setState(() {
      _config = config;
      _links = UniversityPortalLink.fromMap(config.links);
      _isLoading = false;
    });
  }

  /// فتح الرابط، والإبلاغ عند الفشل.
  ///
  /// الفشل الصامت هنا مضلّل: الطالب يضغط «بوابة التقديم» ولا يحدث شيء
  /// فيظن التطبيق معطّلاً، بينما السبب غياب متصفح أو عنوان مكسور.
  Future<void> _open(UniversityPortalLink link) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await ExternalLauncherService().openUrl(link.url);
    if (!opened && mounted) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('admission.portal.open_failed'.tr()),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.portal.title'.tr()),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return const AdmissionLoadingState();

    if (_links.isEmpty) {
      return ListView(
        // القائمة ضرورية رغم عنصرها الواحد: `RefreshIndicator` لا يعمل فوق
        // ودجت غير قابلة للتمرير، والسحب للتحديث هو المخرج الوحيد للطالب
        // حين تصله إعدادات فارغة.
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: AdmissionEmptyState(
              icon: Icons.link_off_rounded,
              message: 'admission.portal.empty'.tr(),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: _links.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHeader(context);
        final link = _links[index - 1];
        return UniversityLinkTile(
          link: link,
          delayMilliseconds: (index - 1) * 70,
          onTap: () => _open(link),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = _config?.name ?? '';
    final city = _config?.city ?? '';

    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty)
              Text(
                city.isEmpty ? name : '$name — $city',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            _buildNotice(context),
          ],
        ),
      ),
    );
  }

  /// تنبيه المغادرة — يُقرأ مرة واحدة أعلى القائمة بدل تكراره على كل بطاقة.
  Widget _buildNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'admission.portal.external_notice'.tr(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
