import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/features/admission/models/admission_config.dart';
import 'package:stustep/features/admission/models/university_portal_link.dart';

/// اختبارات منطق روابط بوابة الجامعة — **دوال خالصة بلا شبكة**.
///
/// أهم ما تحرسه هذه الاختبارات ليس العرض بل الأمان: العناوين تأتي من وثيقة
/// إعدادات بعيدة، والشاشة تسلّمها لنظام التشغيل. الفحص هو الحاجز الوحيد
/// بين إعداد خاطئ (أو مُتلاعَب به) وبين `launchUrl`.
void main() {
  group('parseSafeUrl — فحص العنوان قبل السماح بفتحه', () {
    test('يقبل https و http', () {
      expect(
        UniversityPortalLink.parseSafeUrl('https://admission.edu.ye')?.host,
        'admission.edu.ye',
      );
      expect(
        UniversityPortalLink.parseSafeUrl('http://admission.edu.ye')?.host,
        'admission.edu.ye',
      );
    });

    test('يحذف المسافات المحيطة قبل الفحص', () {
      // نسخ العنوان من مستند رسمي يجرّ معه مسافة أو سطراً جديداً، وهو خطأ
      // إدخال شائع لا يستحق أن يُخفي البطاقة عن الطالب.
      expect(
        UniversityPortalLink.parseSafeUrl('  https://edu.ye  ')?.host,
        'edu.ye',
      );
    });

    test('يرفض المخططات الخطرة وغير الشبكية', () {
      for (final raw in [
        'javascript:alert(1)',
        'file:///etc/passwd',
        'data:text/html,<script>alert(1)</script>',
        'tel:+967771234567',
        'intent://scan/#Intent;scheme=zxing;end',
      ]) {
        expect(
          UniversityPortalLink.parseSafeUrl(raw),
          isNull,
          reason: 'كان يجب رفض $raw',
        );
      }
    });

    test('يرفض العنوان بلا مضيف', () {
      // `https:` وحدها تُحلَّل بنجاح ولا تقود إلى أي مكان.
      expect(UniversityPortalLink.parseSafeUrl('https:'), isNull);
      expect(UniversityPortalLink.parseSafeUrl('/admission'), isNull);
      expect(UniversityPortalLink.parseSafeUrl('www.edu.ye'), isNull);
    });

    test('يرفض الفارغ والمسافات و null', () {
      expect(UniversityPortalLink.parseSafeUrl(null), isNull);
      expect(UniversityPortalLink.parseSafeUrl(''), isNull);
      expect(UniversityPortalLink.parseSafeUrl('   '), isNull);
    });
  });

  group('fromMap — بناء قائمة الروابط من الإعدادات', () {
    test('يبني الروابط الأربعة بترتيب التعداد لا بترتيب الخريطة', () {
      final links = UniversityPortalLink.fromMap({
        'fees_payment': 'https://fees.edu.ye',
        'website': 'https://www.edu.ye',
        'results': 'https://results.edu.ye',
        'admission_portal': 'https://apply.edu.ye',
      });

      expect(links.map((link) => link.kind).toList(), [
        UniversityLinkKind.website,
        UniversityLinkKind.admissionPortal,
        UniversityLinkKind.results,
        UniversityLinkKind.feesPayment,
      ]);
    });

    test('الرابط الغائب لا تُبنى له بطاقة', () {
      final links = UniversityPortalLink.fromMap({
        'website': 'https://www.edu.ye',
      });

      expect(links, hasLength(1));
      expect(links.single.kind, UniversityLinkKind.website);
    });

    test('الرابط غير الصالح يسقط ولا يُسقط معه الروابط الصالحة', () {
      final links = UniversityPortalLink.fromMap({
        'website': 'javascript:alert(1)',
        'admission_portal': 'https://apply.edu.ye',
      });

      expect(links, hasLength(1));
      expect(links.single.kind, UniversityLinkKind.admissionPortal);
    });

    test('مفتاح غير معروف يُتجاهَل بلا استثناء', () {
      // الإعدادات يحرّرها بشر من Console، وحقل زائد أو مكتوب خطأً يجب أن
      // يمرّ بصمت لا أن يُفرغ الشاشة.
      final links = UniversityPortalLink.fromMap({
        'library': 'https://library.edu.ye',
        'website': 'https://www.edu.ye',
      });

      expect(links, hasLength(1));
      expect(links.single.kind, UniversityLinkKind.website);
    });

    test('خريطة فارغة تُنتج قائمة فارغة', () {
      expect(UniversityPortalLink.fromMap(const {}), isEmpty);
    });
  });

  group('displayHost — ما يراه الطالب قبل مغادرة التطبيق', () {
    UniversityPortalLink link(String url) => UniversityPortalLink(
      kind: UniversityLinkKind.website,
      uri: UniversityPortalLink.parseSafeUrl(url)!,
    );

    test('يحذف بادئة www وحدها', () {
      expect(link('https://www.edu.ye/apply').displayHost, 'edu.ye');
      expect(link('https://apply.edu.ye/x').displayHost, 'apply.edu.ye');
    });

    test('لا يحذف من نطاق يبدأ بـ www بلا نقطة', () {
      // `wwwedu.ye` نطاق مختلف تماماً عن `edu.ye` — قصّه يكذب على الطالب
      // في المكان الذي وُجد فيه ليصدقه.
      expect(link('https://wwwedu.ye').displayHost, 'wwwedu.ye');
    });

    test('يُبقي المسار خارج العرض ويُبقيه في العنوان المفتوح', () {
      final portal = link('https://www.edu.ye/admission/apply?year=2026');
      expect(portal.displayHost, 'edu.ye');
      expect(portal.url, 'https://www.edu.ye/admission/apply?year=2026');
    });
  });

  group('UniversityConfig.readLinks — قراءة الحقل من وثيقة يحرّرها بشر', () {
    test('يقرأ النصوص ويحذف مسافاتها', () {
      expect(UniversityConfig.readLinks({'website': '  https://edu.ye '}), {
        'website': 'https://edu.ye',
      });
    });

    test('يتجاهل القيم التي ليست نصاً بدل أن يرمي CastError', () {
      final links = UniversityConfig.readLinks({
        'website': 'https://edu.ye',
        'results': 42,
        'admission_portal': null,
        'fees_payment': ['https://fees.edu.ye'],
      });

      expect(links, {'website': 'https://edu.ye'});
    });

    test('يتجاهل النص الفارغ — الحقل المُفرَّغ يعني «احذف البطاقة»', () {
      expect(UniversityConfig.readLinks({'website': '   '}), isEmpty);
    });

    test('حقل غائب أو ليس خريطة يُنتج خريطة فارغة', () {
      expect(UniversityConfig.readLinks(null), isEmpty);
      expect(UniversityConfig.readLinks('https://edu.ye'), isEmpty);
      expect(UniversityConfig.readLinks(const {}), isEmpty);
    });

    test('الإعدادات الافتراضية بلا روابط تُنتج شاشة فارغة لا انهياراً', () {
      expect(
        UniversityPortalLink.fromMap(const UniversityConfig().links),
        isEmpty,
      );
    });
  });

  group('مفاتيح الترجمة — لا نص مكتوب في الكود', () {
    test('كل نوع يشتق مفتاحيه من معرّفه النصي', () {
      expect(
        UniversityLinkKind.admissionPortal.labelKey,
        'admission.portal.links.admission_portal.title',
      );
      expect(
        UniversityLinkKind.feesPayment.descriptionKey,
        'admission.portal.links.fees_payment.desc',
      );
    });

    test('المعرّفات نصية لا رقمية وكلها فريدة', () {
      // القاعدة السادسة في الموديول: التعداد يُخزَّن نصاً، فإضافة قيمة في
      // منتصفه لاحقاً لا تُتلف الإعدادات المكتوبة مسبقاً.
      final codes = UniversityLinkKind.values.map((kind) => kind.code);
      expect(codes.toSet(), hasLength(UniversityLinkKind.values.length));
      expect(codes.every((code) => code.isNotEmpty), isTrue);
    });
  });
}
