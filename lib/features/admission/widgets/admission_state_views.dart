import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// حالات العرض الثلاث المشتركة: تحميل · فراغ · خطأ.
//
// جُمعت في ملف واحد لأنها متقاربة الحجم والغرض، وتجميعها يمنع تشتيت ثلاثة
// ملفات صغيرة جداً.
//
// كل النصوص هنا تمرّ عبر easy_localization. هذا يعالج ملاحظة رُصدت في
// التحليل: عدة شاشات في المشروع القائم تكتب «جاري التحميل...» مباشرة في
// الكود رغم وجود نظام ترجمة.

/// حالة التحميل.
class AdmissionLoadingState extends StatelessWidget {
  final String? message;

  const AdmissionLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'admission.loading'.tr(),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// حالة عدم وجود بيانات.
class AdmissionEmptyState extends StatelessWidget {
  final String? message;
  final IconData icon;

  const AdmissionEmptyState({
    super.key,
    this.message,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 76, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message ?? 'admission.empty'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة الخطأ مع إمكانية إعادة المحاولة.
class AdmissionErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const AdmissionErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 68,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message ?? 'admission.error'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('admission.retry'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
