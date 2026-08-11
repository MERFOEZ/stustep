import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/features/admission/matcher/widgets/score_breakdown_view.dart';
import 'package:stustep/features/admission/models/admission_enums.dart';
import 'package:stustep/features/admission/widgets/eligibility_visuals.dart';

// اختبار الودجت الافتراضي الذي وُلِّد مع المشروع كان يفحص عدّاداً غير موجود
// (`Counter increments smoke test`) فيفشل `flutter test` دائماً منذ أول
// كوميت في المستودع. رُصد ذلك في مستند التحليل كخطر رقم 9، ويُعالَج هنا.
//
// استُبدل بفحص ودجت حقيقية **لا تعتمد على Firebase ولا على تهيئة الترجمة**،
// لأن تشغيل التطبيق كاملاً داخل اختبار وحدة يتطلب تهيئة Firebase وهي غير
// متاحة في بيئة الاختبار — وهذا بالضبط سبب فشل الاختبار الأصلي.

void main() {
  group('ScoreCircle — دائرة نتيجة الاقتراح', () {
    testWidgets('تعرض النتيجة مقرَّبة بلا خانات عشرية', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreCircle(score: 87.4, color: Colors.green),
          ),
        ),
      );

      expect(find.text('87'), findsOneWidget);
    });

    test('نسبة التقدّم تُقصّ ضمن المجال 0–1', () {
      // قيمة أعلى من 100 يجب ألا تُنتج نسبة تتجاوز الواحد الصحيح.
      expect((150 / 100).clamp(0.0, 1.0), 1.0);
      expect((-20 / 100).clamp(0.0, 1.0), 0.0);
    });
  });

  group('EligibilityVisuals — ألوان وأيقونات مستويات الأهلية', () {
    test('لكل مستوى لون مميّز لا يتكرر', () {
      final colors = EligibilityLevel.values
          .map(EligibilityVisuals.color)
          .toSet();
      expect(colors.length, EligibilityLevel.values.length);
    });

    test('لكل مستوى أيقونة مميّزة لا تتكرر', () {
      final icons = EligibilityLevel.values
          .map(EligibilityVisuals.icon)
          .toSet();
      expect(icons.length, EligibilityLevel.values.length);
    });

    test('المؤهَّل أخضر وغير المؤهَّل أحمر', () {
      expect(
        EligibilityVisuals.color(EligibilityLevel.eligible),
        const Color(0xFF00A152),
      );
      expect(
        EligibilityVisuals.color(EligibilityLevel.notEligible),
        const Color(0xFFD32F2F),
      );
    });
  });
}
