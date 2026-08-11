import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/admission/models/matcher_input.dart';
import '../../features/admission/models/matcher_outcome.dart';
import 'admission_collections.dart';
import 'auth_service.dart';

/// نتيجة مطابقة محفوظة سابقاً، كما تُقرأ من Firestore.
class SavedMatcherResult {
  final String id;
  final MatcherInput input;

  /// أعلى الاقتراحات كما حُفظت — مصفوفة خرائط لا كائنات، لأن الكائن الكامل
  /// يحتاج بيانات الدليل والقسم التي قد تكون تغيّرت منذ الحفظ.
  final List<Map<String, dynamic>> topSuggestions;

  final int eligibleCount;
  final Timestamp? createdAt;

  const SavedMatcherResult({
    required this.id,
    required this.input,
    this.topSuggestions = const [],
    this.eligibleCount = 0,
    this.createdAt,
  });

  factory SavedMatcherResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final raw = data['topSuggestions'];

    return SavedMatcherResult(
      id: doc.id,
      input: MatcherInput.fromMap(
        Map<String, dynamic>.from(data['input'] as Map? ?? {}),
      ),
      topSuggestions: raw is List
          ? raw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : const [],
      eligibleCount: (data['eligibleCount'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
    );
  }
}

/// حفظ نتائج مساعد اختيار التخصص واسترجاعها.
///
/// **موقع التخزين:** مجموعة فرعية تحت وثيقة المستخدم
/// `users/{uid}/matcher_results`. اخترنا المجموعة الفرعية لا حقلاً داخل
/// وثيقة المستخدم لسببين:
///
///   • وثيقة `users/{uid}` يملكها `auth_service.dart` وهو ملف محظور علينا.
///     الكتابة في مجموعة فرعية **لا تمسّ الوثيقة الأم إطلاقاً**.
///   • النتائج تتراكم بمرور الوقت، وحقل مصفوفة داخل وثيقة واحدة يصطدم
///     بحد المليون بايت للوثيقة في Firestore.
///
/// **لماذا هذه هي المجموعة الوحيدة التي نكتب فيها بيانات مستخدم؟**
/// لأن نتيجة المطابقة هي الشيء الوحيد الذي يستفيد الطالب من مزامنته بين
/// أجهزته. الشهادة نفسها تبقى محلية في `CertificateStorageService` لأنها
/// بيانات شخصية لا تحتاج سحابة.
class MatcherResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final MatcherResultService _instance =
      MatcherResultService._internal();

  factory MatcherResultService() => _instance;

  MatcherResultService._internal();

  /// أقصى عدد اقتراحات تُحفظ — نحفظ القمة فقط لا القائمة كلها.
  static const int savedSuggestionsLimit = 5;

  CollectionReference<Map<String, dynamic>>? _collectionForCurrentUser() {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return null;
    return _firestore
        .collection(AdmissionCollections.users)
        .doc(uid)
        .collection(AdmissionCollections.matcherResults);
  }

  /// حفظ حصيلة مطابقة. يُعيد `false` بصمت للزائر غير المسجَّل — المساعد
  /// يجب أن يعمل بلا حساب، والحفظ ميزة إضافية لا شرط استخدام.
  Future<bool> save({
    required MatcherInput input,
    required MatcherOutcome outcome,
  }) async {
    final collection = _collectionForCurrentUser();
    if (collection == null) return false;

    try {
      await collection.add({
        'input': input.toMap(),
        'topSuggestions': outcome.suggestions
            .take(savedSuggestionsLimit)
            .map((suggestion) => suggestion.toMap())
            .toList(),
        'eligibleCount': outcome.eligibleCount,
        'totalEvaluated': outcome.suggestions.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('MatcherResultService: failed to save result: $e');
      return false;
    }
  }

  /// آخر نتيجة محفوظة للمستخدم الحالي.
  ///
  /// نرتّب في الذاكرة لا بـ `orderBy` مع `limit`، التزاماً بقاعدة «صفر
  /// فهارس مركّبة» المعتمدة في الموديول. حجم البيانات هنا صغير جداً
  /// (نتائج مستخدم واحد) فتكلفة الترتيب المحلي مهملة.
  Future<SavedMatcherResult?> latest() async {
    final results = await history();
    return results.isEmpty ? null : results.first;
  }

  /// كل النتائج المحفوظة، الأحدث أولاً.
  Future<List<SavedMatcherResult>> history() async {
    final collection = _collectionForCurrentUser();
    if (collection == null) return const [];

    try {
      final snapshot = await collection.get();
      final results = snapshot.docs
          .map(SavedMatcherResult.fromFirestore)
          .toList();

      results.sort((a, b) {
        final left = a.createdAt;
        final right = b.createdAt;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });

      return results;
    } catch (e) {
      debugPrint('MatcherResultService: failed to load history: $e');
      return const [];
    }
  }

  Future<bool> delete(String resultId) async {
    final collection = _collectionForCurrentUser();
    if (collection == null) return false;

    try {
      await collection.doc(resultId).delete();
      return true;
    } catch (e) {
      debugPrint('MatcherResultService: failed to delete result: $e');
      return false;
    }
  }
}
