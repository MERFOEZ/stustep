import 'package:flutter/material.dart';

/// روابط بوابة الجامعة الرسمية — نوعها وقواعد قبولها.
///
/// **لماذا روابط خارجية بدل تكامل حقيقي مع أنظمة الجامعة؟**
/// التقديم الإلكتروني ودفع الرسوم يجريان على أنظمة تملكها الجامعة، ولا
/// تُتاح لها واجهة برمجية عامة. أي محاولة لمحاكاة صفحاتها داخل التطبيق
/// تعني نقل بيانات الطالب وبيانات دفعه عبر طرف ثالث — وهذا ما لا يجوز
/// هندسياً ولا أخلاقياً في مشروع طلابي. تسليم الطالب للبوابة الرسمية نفسها
/// يبقي بياناته بينه وبين جامعته، ويبقي التطبيق دليلاً لا وسيطاً.
///
/// المعرّفات تُخزَّن **نصاً** في `app_config/university` التزاماً بقاعدة
/// الموديول: لا فهارس رقمية في قاعدة البيانات.

/// نوع الرابط الرسمي — ترتيب التعداد هو ترتيب العرض على الشاشة.
enum UniversityLinkKind {
  /// الموقع الرسمي — المدخل العام، ويظل مفيداً حتى لو غابت بقية الروابط.
  website('website', Icons.public_rounded),

  /// بوابة التقديم الإلكتروني — الفعل الذي يأتي الطالب من أجله.
  admissionPortal('admission_portal', Icons.how_to_reg_rounded),

  /// نتائج القبول.
  results('results', Icons.assignment_turned_in_rounded),

  /// الرسوم الدراسية والدفع الإلكتروني.
  feesPayment('fees_payment', Icons.payments_rounded);

  const UniversityLinkKind(this.code, this.icon);

  /// المفتاح المخزَّن في Firestore تحت `app_config/university.links`.
  final String code;

  final IconData icon;

  String get labelKey => 'admission.portal.links.$code.title';

  String get descriptionKey => 'admission.portal.links.$code.desc';
}

/// رابط رسمي واحد جاهز للفتح — لا يُنشَأ إلا بعنوان اجتاز الفحص.
class UniversityPortalLink {
  final UniversityLinkKind kind;

  /// العنوان بعد التحقق منه — نحتفظ به `Uri` لا `String` حتى يستحيل بناء
  /// رابط لم يمرّ على `tryParse`.
  final Uri uri;

  const UniversityPortalLink({required this.kind, required this.uri});

  /// اسم المضيف بلا `www.` — يُعرض للطالب تحت عنوان الرابط.
  ///
  /// **لماذا نُظهر المضيف؟** لأن هذه العناوين تأتي من إعدادات بعيدة يملكها
  /// المشرف، والطالب على وشك مغادرة التطبيق إلى صفحة قد يُدخل فيها بياناته.
  /// رؤية `portal.university.edu.ye` قبل الضغط تجعل انتحال البوابة مكشوفاً
  /// بدل أن يكون خفياً.
  String get displayHost {
    final host = uri.host;
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  /// العنوان الكامل كما يُمرَّر لمُشغّل الروابط الخارجي.
  String get url => uri.toString();

  /// بناء قائمة الروابط الصالحة من خريطة الإعدادات — **دالة خالصة بلا شبكة**.
  ///
  /// الروابط الغائبة أو الفارغة أو التي لا تجتاز الفحص تُحذف بصمت بدل أن
  /// تُعرض معطَّلة: بطاقة لا تعمل أسوأ من بطاقة غير موجودة.
  static List<UniversityPortalLink> fromMap(Map<String, String> links) {
    final result = <UniversityPortalLink>[];
    for (final kind in UniversityLinkKind.values) {
      final uri = parseSafeUrl(links[kind.code]);
      if (uri != null) result.add(UniversityPortalLink(kind: kind, uri: uri));
    }
    return result;
  }

  /// فحص العنوان قبل السماح بفتحه.
  ///
  /// **لماذا نرفض ما عدا `http`/`https`؟**
  /// `launchUrl` يسلّم العنوان لنظام التشغيل، وعنوان بمخطط آخر
  /// (`javascript:` على الويب، أو مخطط تطبيق آخر على الجوال) يتحوّل من
  /// «فتح صفحة» إلى «تنفيذ شيء». مصدر هذه العناوين وثيقة إعدادات بعيدة،
  /// فالخطأ فيها — أو العبث بها — يجب أن يتوقف هنا لا عند نظام التشغيل.
  ///
  /// واشتراط وجود مضيف يمنع مدخلات مثل `https:` وحدها، وهي تُحلَّل بنجاح
  /// لكنها لا تقود إلى أي مكان.
  static Uri? parseSafeUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    if (uri.host.isEmpty) return null;

    return uri;
  }
}
