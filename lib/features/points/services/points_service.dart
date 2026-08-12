import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/points_user_model.dart';
import '../models/points_transaction_model.dart';
import '../models/quest_model.dart';
import '../models/user_quest_progress_model.dart';

class PointsService {
  static final PointsService _instance = PointsService._internal();
  factory PointsService() => _instance;
  PointsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const String pointsCacheBoxName = 'points_cache_box';

  /// Initializer for Hive cache box
  static Future<void> initHive() async {
    try {
      await Hive.openBox(pointsCacheBoxName);
    } catch (_) {
      // If already opened or in memory
    }
  }

  Box get _cacheBox => Hive.box(pointsCacheBoxName);

  /// Helper to get today's date key YYYY-MM-DD
  String getTodayKey() {
    final now = DateTime.now().toUtc();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Helper to get current week Monday key YYYY-MM-DD
  String getWeekStartKey() {
    final now = DateTime.now().toUtc();
    final day = now.weekday; // 1: Monday, 7: Sunday
    final monday = now.subtract(Duration(days: day - 1));
    return "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}";
  }

  // -------------------------------------------------------------
  // 1. User Profile & Live Streams
  // -------------------------------------------------------------

  /// Stream of user points and streak
  Stream<PointsUserModel?> getUserPointsStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final user = PointsUserModel.fromMap(doc.id, doc.data()!);
      // Update Hive cache
      _cacheBox.put('user_points_$userId', user.toMap());
      return user;
    });
  }

  /// Cached user points for immediate offline display
  PointsUserModel? getCachedUserPoints(String userId) {
    final data = _cacheBox.get('user_points_$userId');
    if (data is Map) {
      return PointsUserModel.fromMap(userId, Map<String, dynamic>.from(data));
    }
    return null;
  }

  // -------------------------------------------------------------
  // 2. Quests Templates & Progress
  // -------------------------------------------------------------

  static const List<QuestModel> defaultDailyQuests = [
    QuestModel(
      id: 'daily_lesson',
      type: 'daily',
      titleKey: 'quests.daily_lesson_title',
      descriptionKey: 'quests.daily_lesson_desc',
      section: 'courses',
      pointsValue: 15,
      targetCount: 1,
      actionType: 'complete_lesson',
    ),
    QuestModel(
      id: 'daily_ai_chat',
      type: 'daily',
      titleKey: 'quests.daily_ai_title',
      descriptionKey: 'quests.daily_ai_desc',
      section: 'ai_chat',
      pointsValue: 15,
      targetCount: 1,
      actionType: 'ai_chat_session',
    ),
    QuestModel(
      id: 'daily_quiz',
      type: 'daily',
      titleKey: 'quests.daily_quiz_title',
      descriptionKey: 'quests.daily_quiz_desc',
      section: 'academic_tools',
      pointsValue: 10,
      targetCount: 1,
      actionType: 'pass_quiz',
    ),
    QuestModel(
      id: 'daily_community',
      type: 'daily',
      titleKey: 'quests.daily_community_title',
      descriptionKey: 'quests.daily_community_desc',
      section: 'groups',
      pointsValue: 10,
      targetCount: 1,
      actionType: 'community_interaction',
    ),
    QuestModel(
      id: 'daily_login',
      type: 'daily',
      titleKey: 'quests.daily_login_title',
      descriptionKey: 'quests.daily_login_desc',
      section: 'home',
      pointsValue: 5,
      targetCount: 1,
      actionType: 'daily_login',
    ),
  ];

  static const List<QuestModel> defaultWeeklyQuests = [
    QuestModel(
      id: 'weekly_5_days',
      type: 'weekly',
      titleKey: 'quests.weekly_5_days_title',
      descriptionKey: 'quests.weekly_5_days_desc',
      section: 'home',
      pointsValue: 50,
      targetCount: 5,
      actionType: 'daily_login',
    ),
    QuestModel(
      id: 'weekly_course_complete',
      type: 'weekly',
      titleKey: 'quests.weekly_course_title',
      descriptionKey: 'quests.weekly_course_desc',
      section: 'courses',
      pointsValue: 80,
      targetCount: 1,
      actionType: 'complete_course',
    ),
    QuestModel(
      id: 'weekly_3_sections',
      type: 'weekly',
      titleKey: 'quests.weekly_sections_title',
      descriptionKey: 'quests.weekly_sections_desc',
      section: 'home',
      pointsValue: 40,
      targetCount: 3,
      actionType: 'use_section',
    ),
    QuestModel(
      id: 'weekly_10_likes',
      type: 'weekly',
      titleKey: 'quests.weekly_likes_title',
      descriptionKey: 'quests.weekly_likes_desc',
      section: 'groups',
      pointsValue: 30,
      targetCount: 10,
      actionType: 'receive_like',
    ),
  ];

  /// Stream of Daily Quests templates with fallback
  Stream<List<QuestModel>> getDailyQuestsStream() {
    return _firestore
        .collection('dailyQuests')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? defaultDailyQuests
            : snap.docs.map((d) => QuestModel.fromMap(d.id, d.data())).toList());
  }

  /// Stream of Weekly Quests templates with fallback
  Stream<List<QuestModel>> getWeeklyQuestsStream() {
    return _firestore
        .collection('weeklyQuests')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? defaultWeeklyQuests
            : snap.docs.map((d) => QuestModel.fromMap(d.id, d.data())).toList());
  }

  /// Stream of user's daily quest progress for today
  Stream<List<UserQuestProgressModel>> getUserDailyProgressStream(String userId) {
    final todayKey = getTodayKey();
    return _firestore
        .collection('userDailyQuestProgress')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: todayKey)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserQuestProgressModel.fromMap(d.id, d.data())).toList());
  }

  /// Stream of user's weekly quest progress for current week
  Stream<List<UserQuestProgressModel>> getUserWeeklyProgressStream(String userId) {
    final weekStartKey = getWeekStartKey();
    return _firestore
        .collection('userWeeklyQuestProgress')
        .where('userId', isEqualTo: userId)
        .where('weekStartDate', isEqualTo: weekStartKey)
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserQuestProgressModel.fromMap(d.id, d.data())).toList());
  }

  // -------------------------------------------------------------
  // 3. Transactions Audit Log
  // -------------------------------------------------------------

  /// Stream of user's points transaction history
  Stream<List<PointsTransactionModel>> getTransactionsStream(String userId, {int limit = 40}) {
    return _firestore
        .collection('pointsTransactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PointsTransactionModel.fromMap(d.id, d.data())).toList());
  }

  // -------------------------------------------------------------
  // 4. Secure Cloud Functions Invocation (Zero Client-Side Writes)
  // -------------------------------------------------------------

  /// Calls Cloud Function `recordActivity` to securely process action and award points.
  Future<Map<String, dynamic>> recordActivity({
    required String actionType,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final callable = _functions.httpsCallable('recordActivity');
      final response = await callable.call<Map<String, dynamic>>({
        'actionType': actionType,
        'referenceId': referenceId,
        'metadata': metadata ?? {},
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      // Fallback: If Cloud Functions is not deployed or network fails, log gracefully
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Seeds default quests into Firestore if needed
  Future<void> seedDefaultQuests() async {
    try {
      final callable = _functions.httpsCallable('seedDefaultQuests');
      await callable.call();
    } catch (_) {}
  }
}
