import 'admission_enums.dart';
import 'housing_model.dart';

/// معايير تصفية قائمة السكنات.
///
/// **الفلترة تتم في الذاكرة لا في الاستعلام.** السبب أن الجمع بين عدة شروط
/// `where` وترتيب زمني يتطلب فهرساً مركّباً لكل تركيبة فلاتر ممكنة، وهي
/// عشرات الفهارس. وحجم البيانات المتوقع (< 300 إعلان) يجعل الفلترة المحلية
/// أسرع عملياً وبلا أي إعداد.
class HousingFilter {
  final HousingStatus? status;
  final HousingGender? gender;
  final double? maxPrice;
  final double? maxDistanceKm;
  final String query;

  const HousingFilter({
    this.status,
    this.gender,
    this.maxPrice,
    this.maxDistanceKm,
    this.query = '',
  });

  bool get isEmpty =>
      status == null &&
      gender == null &&
      maxPrice == null &&
      maxDistanceKm == null &&
      query.trim().isEmpty;

  /// عدد الفلاتر المفعّلة — يُعرض كشارة على زر الفلترة.
  int get activeCount {
    var count = 0;
    if (status != null) count++;
    if (gender != null) count++;
    if (maxPrice != null) count++;
    if (maxDistanceKm != null) count++;
    if (query.trim().isNotEmpty) count++;
    return count;
  }

  HousingFilter copyWith({
    HousingStatus? status,
    HousingGender? gender,
    double? maxPrice,
    double? maxDistanceKm,
    String? query,
    bool clearStatus = false,
    bool clearGender = false,
    bool clearMaxPrice = false,
    bool clearMaxDistance = false,
  }) {
    return HousingFilter(
      status: clearStatus ? null : (status ?? this.status),
      gender: clearGender ? null : (gender ?? this.gender),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      maxDistanceKm: clearMaxDistance
          ? null
          : (maxDistanceKm ?? this.maxDistanceKm),
      query: query ?? this.query,
    );
  }

  /// تطبيق كل المعايير على قائمة السكنات.
  List<HousingModel> apply(List<HousingModel> items) {
    final normalizedQuery = query.trim().toLowerCase();

    return items.where((item) {
      if (status != null && item.status != status) return false;
      if (gender != null && item.gender != gender) return false;

      if (maxPrice != null) {
        final price = item.priceMonthly;
        // السكن بلا سعر معلن لا يُستبعد عند التصفية بالسعر، لأن غياب
        // السعر ليس دليلاً على تجاوزه للحد.
        if (price != null && price > maxPrice!) return false;
      }

      if (maxDistanceKm != null &&
          item.distanceKm > 0 &&
          item.distanceKm > maxDistanceKm!) {
        return false;
      }

      if (normalizedQuery.isNotEmpty) {
        final haystack =
            '${item.name} ${item.addressText} ${item.description}'
                .toLowerCase();
        if (!haystack.contains(normalizedQuery)) return false;
      }

      return true;
    }).toList();
  }
}
