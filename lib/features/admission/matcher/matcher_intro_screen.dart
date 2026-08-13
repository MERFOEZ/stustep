import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/services/certificate_storage_service.dart';
import '../models/high_school_certificate.dart';
import '../requirements/certificate_input_sheet.dart';
import '../widgets/admission_app_bar.dart';
import '../widgets/admission_state_views.dart';
import 'interests_picker_screen.dart';
import 'widgets/matcher_intro_cards.dart';

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

  /// فتح ورقة إدخال الشهادة المبنية في المرحلة 4 — إعادة استخدام كاملة
  /// بلا سطر واحد مكرر.
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
              const MatcherHeroCard(),
              const SizedBox(height: 22),
              const MatcherWeightsCard(),
              const SizedBox(height: 22),
              MatcherCertificateCard(
                certificate: _certificate,
                onEdit: _editCertificate,
              ),
              const SizedBox(height: 24),
              _buildStartButton(),
            ],
          );
        },
      ),
    );
  }

  /// زر البدء معطَّل ما لم تُدخَل الشهادة — التعطيل أوضح من السماح بالضغط
  /// ثم إظهار رسالة خطأ.
  Widget _buildStartButton() {
    return FilledButton.icon(
      onPressed: _certificate == null ? null : _start,
      icon: const Icon(Icons.arrow_forward_rounded),
      label: Text('admission.matcher.start'.tr()),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
