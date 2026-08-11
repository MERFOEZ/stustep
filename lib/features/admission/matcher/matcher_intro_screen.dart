import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/certificate_storage_service.dart';
import '../models/high_school_certificate.dart';
import '../models/major_suggestion.dart';
import '../requirements/certificate_input_sheet.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'interests_picker_screen.dart';

/// شاشة بداية مساعد اختيار التخصص.
///
/// وظيفتها الأهم ليست بصرية بل **إدارة الشرط المسبق**: المساعد لا يعمل بلا
/// شهادة. بدل أن نفاجئ الطالب برسالة خطأ في منتصف المسار، نتحقق هنا أولاً
/// ونعرض له شهادته المحفوظة إن وُجدت مع إمكانية تعديلها.
///
/// الشهادة تُقرأ من التخزين المحلي المرتبط بمعرّف المستخدم — أي أن الطالب
/// الذي أدخلها في المرحلة 4 لفحص الأهلية لا يُطالَب بإدخالها مرة ثانية.
class MatcherIntroScreen extends StatefulWidget {
  const MatcherIntroScreen({super.key});

  @override
  State<MatcherIntroScreen> createState() => _MatcherIntroScreenState();
}

class _MatcherIntroScreenState extends State<MatcherIntroScreen> {
  late Future<HighSchoolCertificate?> _certificateFuture;
  HighSchoolCertificate? _certificate;

  @override
  void initState() {
    super.initState();
    _certificateFuture = _load();
  }

  Future<HighSchoolCertificate?> _load() async {
    final saved = await CertificateStorageService().load();
    _certificate = saved;
    return saved;
  }

  /// فتح ورقة إدخال الشهادة المبنية في المرحلة 4 — إعادة استخدام كاملة.
  Future<void> _editCertificate() async {
    final result = await CertificateInputSheet.show(
      context,
      initial: _certificate,
    );
    if (result != null && mounted) {
      setState(() {
        _certificate = result;
        _certificateFuture = Future.value(result);
      });
    }
  }

  void _start() {
    final certificate = _certificate;
    if (certificate == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterestsPickerScreen(certificate: certificate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdmissionAppBar(title: 'admission.matcher.title'.tr()),
      body: FutureBuilder<HighSchoolCertificate?>(
        future: _certificateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AdmissionLoadingState();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _buildHero(context),
              const SizedBox(height: 22),
              _buildHowItWorks(context),
              const SizedBox(height: 22),
              _buildCertificateStatus(context),
              const SizedBox(height: 24),
              _buildStartButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return FadeInDown(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC51162), Color(0xFFFF4081)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
            const SizedBox(height: 14),
            Text(
              'admission.matcher.hero_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'admission.matcher.hero_subtitle'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// شرح الأوزان الأربعة للطالب قبل أن يرى النتيجة.
  ///
  /// إظهار المعيار **قبل** الحكم لا بعده هو ما يجعل الطالب يثق بالترتيب
  /// بدل أن يظنّه رأياً عشوائياً من التطبيق.
  Widget _buildHowItWorks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.balance_rounded,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'admission.matcher.how_it_works'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildWeightRow(
            'admission.matcher.factor.interests'.tr(),
            MatcherWeights.interests,
            const Color(0xFF6200EE),
          ),
          _buildWeightRow(
            'admission.matcher.factor.gpa_fit'.tr(),
            MatcherWeights.gpaFit,
            const Color(0xFF00C853),
          ),
          _buildWeightRow(
            'admission.matcher.factor.certificate_fit'.tr(),
            MatcherWeights.certificateFit,
            const Color(0xFF304FFE),
          ),
          _buildWeightRow(
            'admission.matcher.factor.completeness'.tr(),
            MatcherWeights.completeness,
            const Color(0xFFFF6D00),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightRow(String label, double weight, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12.5)),
          ),
          Text(
            '${weight.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateStatus(BuildContext context) {
    final certificate = _certificate;
    final hasCertificate = certificate != null;
    final color = hasCertificate
        ? const Color(0xFF00A152)
        : const Color(0xFFEF6C00);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCertificate
                    ? Icons.verified_rounded
                    : Icons.warning_amber_rounded,
                size: 19,
                color: color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  hasCertificate
                      ? 'admission.matcher.certificate_ready'.tr()
                      : 'admission.matcher.certificate_missing'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (hasCertificate) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _buildTag(certificate.type.labelKey.tr()),
                _buildTag(certificate.track.labelKey.tr()),
                _buildTag(
                  '${certificate.gpa} ${certificate.gpaScale.labelKey.tr()}',
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _editCertificate,
            icon: Icon(
              hasCertificate ? Icons.edit_rounded : Icons.add_rounded,
              size: 17,
            ),
            label: Text(
              hasCertificate
                  ? 'admission.matcher.edit_certificate'.tr()
                  : 'admission.matcher.add_certificate'.tr(),
              style: const TextStyle(fontSize: 12.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final enabled = _certificate != null;

    return FilledButton.icon(
      onPressed: enabled ? _start : null,
      icon: const Icon(Icons.arrow_forward_rounded),
      label: Text('admission.matcher.start'.tr()),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
