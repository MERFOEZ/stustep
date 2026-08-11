import 'package:flutter_test/flutter_test.dart';
import 'package:stustep/core/services/external_launcher_service.dart';
import 'package:stustep/core/services/housing_service.dart';
import 'package:stustep/features/admission/models/admission_enums.dart';
import 'package:stustep/features/admission/models/housing_model.dart';

/// اختبارات منطق السكنات الخالص: الفلترة وتنظيف أرقام الهواتف.
///
/// الفلترة تُطبَّق في الذاكرة لا في استعلام Firestore (التزاماً بقاعدة صفر
/// فهارس مركّبة)، وهذا بالضبط ما يجعلها قابلة للاختبار هنا بلا شبكة.
void main() {
  HousingModel housing({
    required String id,
    String name = 'سكن',
    HousingStatus status = HousingStatus.available,
    HousingGender gender = HousingGender.male,
    double? price,
    double distanceKm = 0,
    String address = '',
    String description = '',
  }) {
    return HousingModel(
      id: id,
      name: name,
      phone: '771234567',
      createdBy: 'uid_1',
      status: status,
      gender: gender,
      priceMonthly: price,
      distanceKm: distanceKm,
      addressText: address,
      description: description,
    );
  }

  final items = [
    housing(
      id: 'h1',
      name: 'سكن الطلاب الشمالي',
      price: 30000,
      distanceKm: 1.5,
      address: 'حي الجامعة',
    ),
    housing(
      id: 'h2',
      name: 'سكن الطالبات',
      gender: HousingGender.female,
      price: 45000,
      distanceKm: 4,
      address: 'شارع الستين',
    ),
    housing(
      id: 'h3',
      name: 'شقة عائلية',
      gender: HousingGender.family,
      status: HousingStatus.full,
      price: 90000,
      distanceKm: 8,
    ),
    // سكن بلا سعر معلن — حالة حدّية مقصودة.
    housing(id: 'h4', name: 'سكن بلا سعر', distanceKm: 2),
  ];

  List<String> idsOf(List<HousingModel> list) =>
      list.map((item) => item.id).toList();

  group('الفلترة بلا معايير', () {
    test('تُعيد كل العناصر كما هي', () {
      expect(HousingService.applyFilters(items).length, 4);
    });
  });

  group('فلترة الحالة والفئة', () {
    test('المتاح فقط يستبعد الممتلئ', () {
      final result = HousingService.applyFilters(
        items,
        status: HousingStatus.available,
      );
      expect(idsOf(result), isNot(contains('h3')));
      expect(result.length, 3);
    });

    test('فئة الطالبات تُعيد سكنها وحده', () {
      final result = HousingService.applyFilters(
        items,
        gender: HousingGender.female,
      );
      expect(idsOf(result), <String>['h2']);
    });
  });

  group('فلترة السعر', () {
    test('الحد الأعلى يستبعد ما تجاوزه', () {
      final result = HousingService.applyFilters(items, maxPrice: 50000);
      expect(idsOf(result), isNot(contains('h3')));
    });

    test('السكن بلا سعر معلن لا يُستبعَد بفلتر السعر', () {
      // قرار مقصود: غياب المعلومة ليس دليلاً على تجاوز الحد، واستبعاده كان
      // سيُخفي خيارات صالحة عن الطالب.
      final result = HousingService.applyFilters(items, maxPrice: 10000);
      expect(idsOf(result), contains('h4'));
    });
  });

  group('فلترة المسافة', () {
    test('الحد الأقصى يستبعد الأبعد', () {
      final result = HousingService.applyFilters(items, maxDistanceKm: 3);
      expect(idsOf(result), containsAll(<String>['h1', 'h4']));
      expect(idsOf(result), isNot(contains('h3')));
    });
  });

  group('البحث النصي', () {
    test('يطابق الاسم', () {
      final result = HousingService.applyFilters(items, query: 'الطالبات');
      expect(idsOf(result), <String>['h2']);
    });

    test('يطابق العنوان أيضاً لا الاسم فقط', () {
      final result = HousingService.applyFilters(items, query: 'الستين');
      expect(idsOf(result), <String>['h2']);
    });

    test('المسافات الزائدة حول النص لا تؤثر', () {
      final result = HousingService.applyFilters(items, query: '   شقة  ');
      expect(idsOf(result), <String>['h3']);
    });

    test('نص غير موجود يُعيد قائمة فارغة', () {
      expect(HousingService.applyFilters(items, query: 'zzz'), isEmpty);
    });
  });

  group('تراكب عدة فلاتر معاً', () {
    test('الحالة والفئة والسعر تُطبَّق مجتمعة', () {
      final result = HousingService.applyFilters(
        items,
        status: HousingStatus.available,
        gender: HousingGender.male,
        maxPrice: 35000,
      );
      expect(idsOf(result), containsAll(<String>['h1', 'h4']));
      expect(result.length, 2);
    });
  });

  group('تنظيف رقم الهاتف قبل فتح واتساب', () {
    test('يزيل المسافات والرموز', () {
      expect(
        ExternalLauncherService.normalizePhone('+967 77 123 4567'),
        '967771234567',
      );
    });

    test('يوحّد البادئة 00 مع البادئة +', () {
      expect(
        ExternalLauncherService.normalizePhone('00967-771234567'),
        '967771234567',
      );
    });

    test('الرقم المحلي يبقى كما هو', () {
      expect(ExternalLauncherService.normalizePhone('771234567'), '771234567');
    });

    test('نص بلا أرقام يُعيد فراغاً بدل رابط مكسور', () {
      expect(ExternalLauncherService.normalizePhone('لا يوجد'), '');
    });
  });
}
