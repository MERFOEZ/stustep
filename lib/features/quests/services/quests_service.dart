import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/quest_model.dart';
import '../models/quest_progress_model.dart';

class QuestsService {
  static final QuestsService _instance = QuestsService._internal();
  factory QuestsService() => _instance;
  QuestsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const String questsCacheBoxName = 'quests_cache_box';

  /// Initializes Hive cache box for quests
  static Future<void> initHive() async {
    try {
      await Hive.openBox(questsCacheBoxName);
    } catch (_) {}
  }

  Box get _cacheBox => Hive.box(questsCacheBoxName);

  /// Helper to get today's UTC date key (YYYY-MM-DD)
  static String getTodayDateKey([DateTime? date]) {
    final d = date ?? DateTime.now().toUtc();
    return d.toIso8601String().split('T')[0];
  }

  /// Helper to get Monday UTC Date of current week (YYYY-MM-DD)
  static String getWeekStartDateKey([DateTime? date]) {
    final d = date ?? DateTime.now().toUtc();
    final day = d.weekday; // 1 = Monday, 7 = Sunday
    final diff = d.day - day + 1;
    final monday = DateTime.utc(d.year, d.month, diff);
    return monday.toIso8601String().split('T')[0];
  }

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

  /// Real-time stream of daily quests from Firestore with offline fallback
  Stream<List<QuestModel>> getDailyQuestsStream() {
    return _firestore
        .collection('dailyQuests')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.isEmpty
          ? defaultDailyQuests
          : snap.docs.map((doc) => QuestModel.fromMap(doc.id, doc.data())).toList();
      _cacheBox.put('cached_daily_quests', list.map((q) => q.toMap()).toList());
      return list;
    });
  }

  /// Real-time stream of weekly quests from Firestore with offline fallback
  Stream<List<QuestModel>> getWeeklyQuestsStream() {
    return _firestore
        .collection('weeklyQuests')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.isEmpty
          ? defaultWeeklyQuests
          : snap.docs.map((doc) => QuestModel.fromMap(doc.id, doc.data())).toList();
      _cacheBox.put('cached_weekly_quests', list.map((q) => q.toMap()).toList());
      return list;
    });
  }

  /// Stream of user daily quest progress for today
  Stream<Map<String, QuestProgressModel>> getUserDailyProgressStream(String userId) {
    final todayKey = getTodayDateKey();
    return _firestore
        .collection('userDailyQuestProgress')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: todayKey)
        .snapshots()
        .map((snap) {
      final map = <String, QuestProgressModel>{};
      for (final doc in snap.docs) {
        final progress = QuestProgressModel.fromMap(doc.id, doc.data());
        map[progress.questId] = progress;
      }
      if (map.isNotEmpty) {
        _cacheBox.put('daily_progress_${userId}_$todayKey', map.map((k, v) => MapEntry(k, v.toMap())));
      }
      return map;
    });
  }

  /// Stream of user weekly quest progress for current week
  Stream<Map<String, QuestProgressModel>> getUserWeeklyProgressStream(String userId) {
    final weekStartKey = getWeekStartDateKey();
    return _firestore
        .collection('userWeeklyQuestProgress')
        .where('userId', isEqualTo: userId)
        .where('weekStartDate', isEqualTo: weekStartKey)
        .snapshots()
        .map((snap) {
      final map = <String, QuestProgressModel>{};
      for (final doc in snap.docs) {
        final progress = QuestProgressModel.fromMap(doc.id, doc.data());
        map[progress.questId] = progress;
      }
      if (map.isNotEmpty) {
        _cacheBox.put('weekly_progress_${userId}_$weekStartKey', map.map((k, v) => MapEntry(k, v.toMap())));
      }
      return map;
    });
  }

  /// Gets cached daily progress for today
  Map<String, QuestProgressModel> getCachedDailyProgress(String userId) {
    final todayKey = getTodayDateKey();
    final cached = _cacheBox.get('daily_progress_${userId}_$todayKey');
    if (cached is Map) {
      return cached.map((k, v) => MapEntry(
            k.toString(),
            QuestProgressModel.fromMap(k.toString(), Map<String, dynamic>.from(v as Map)),
          ));
    }
    return {};
  }

  /// Gets cached weekly progress for current week
  Map<String, QuestProgressModel> getCachedWeeklyProgress(String userId) {
    final weekStartKey = getWeekStartDateKey();
    final cached = _cacheBox.get('weekly_progress_${userId}_$weekStartKey');
    if (cached is Map) {
      return cached.map((k, v) => MapEntry(
            k.toString(),
            QuestProgressModel.fromMap(k.toString(), Map<String, dynamic>.from(v as Map)),
          ));
    }
    return {};
  }

  /// Records an activity via Callable Cloud Function with seamless local fallback
  Future<Map<String, dynamic>> recordActivity({
    required String actionType,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    final todayKey = getTodayDateKey();
    final weekStartKey = getWeekStartDateKey();

    try {
      final callable = _functions.httpsCallable('recordActivity');
      final response = await callable.call<Map<String, dynamic>>({
        'actionType': actionType,
        'referenceId': referenceId,
        'metadata': metadata ?? {},
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      // Local development/offline fallback: simulate quest completion in local Hive cache
      int pointsEarned = 0;
      final completedQuests = <String>[];
      const userId = 'guest_user';

      // 1. Process matching daily quests locally
      final dailyList = getCachedDailyQuests();
      final matchingDaily = dailyList.where((q) => q.actionType == actionType).toList();
      final dailyMap = Map<String, dynamic>.from(_cacheBox.get('daily_progress_${userId}_$todayKey') ?? {});

      for (final quest in matchingDaily) {
        final existing = dailyMap[quest.id];
        if (existing == null) {
          pointsEarned += quest.pointsValue;
          completedQuests.add(quest.id);
          dailyMap[quest.id] = {
            'id': '${userId}_${quest.id}_$todayKey',
            'userId': userId,
            'questId': quest.id,
            'date': todayKey,
            'currentCount': 1,
            'targetCount': quest.targetCount,
            'status': 'completed',
            'pointsAwarded': quest.pointsValue,
            'repeatCount': 0,
          };
        } else {
          final repeat = ((existing as Map)['repeatCount'] as num? ?? 0).toInt() + 1;
          final diminishing = repeat == 1 ? (quest.pointsValue * 0.2).toInt().clamp(1, 999) : 1;
          pointsEarned += diminishing;
          dailyMap[quest.id] = {
            ...existing,
            'currentCount': ((existing['currentCount'] as num? ?? 0).toInt() + 1),
            'repeatCount': repeat,
            'pointsAwarded': ((existing['pointsAwarded'] as num? ?? 0).toInt() + diminishing),
          };
        }
      }
      _cacheBox.put('daily_progress_${userId}_$todayKey', dailyMap);

      // 2. Process matching weekly quests locally
      final weeklyList = getCachedWeeklyQuests();
      final matchingWeekly = weeklyList.where((q) => q.actionType == actionType).toList();
      final weeklyMap = Map<String, dynamic>.from(_cacheBox.get('weekly_progress_${userId}_$weekStartKey') ?? {});

      for (final quest in matchingWeekly) {
        final existing = weeklyMap[quest.id];
        final currentCount = (existing != null ? ((existing as Map)['currentCount'] as num? ?? 0).toInt() : 0) + 1;
        final isComplete = currentCount >= quest.targetCount;
        final isFirst = isComplete && (existing == null || (existing as Map)['status'] != 'completed');
        final pts = isFirst ? quest.pointsValue : 0;
        if (pts > 0) {
          pointsEarned += pts;
          completedQuests.add(quest.id);
        }
        weeklyMap[quest.id] = {
          'id': '${userId}_${quest.id}_$weekStartKey',
          'userId': userId,
          'questId': quest.id,
          'weekStartDate': weekStartKey,
          'currentCount': currentCount,
          'targetCount': quest.targetCount,
          'status': isComplete ? 'completed' : 'pending',
          'pointsAwarded': (existing != null ? ((existing as Map)['pointsAwarded'] as num? ?? 0).toInt() : 0) + pts,
        };
      }
      _cacheBox.put('weekly_progress_${userId}_$weekStartKey', weeklyMap);

      return {
        'success': true,
        'awardedPoints': pointsEarned,
        'completedQuests': completedQuests,
        'totalPoints': pointsEarned,
        'weeklyPoints': pointsEarned,
        'currentStreak': 1,
        'streakIncremented': true,
        'message': 'Local activity recorded successfully',
      };
    }
  }

  /// Gets cached daily quests for offline immediate display
  List<QuestModel> getCachedDailyQuests() {
    final cached = _cacheBox.get('cached_daily_quests');
    if (cached is List && cached.isNotEmpty) {
      return cached
          .map((item) => QuestModel.fromMap((item as Map)['id']?.toString() ?? '', Map<String, dynamic>.from(item)))
          .toList();
    }
    return defaultDailyQuests;
  }

  /// Gets cached weekly quests for offline immediate display
  List<QuestModel> getCachedWeeklyQuests() {
    final cached = _cacheBox.get('cached_weekly_quests');
    if (cached is List && cached.isNotEmpty) {
      return cached
          .map((item) => QuestModel.fromMap((item as Map)['id']?.toString() ?? '', Map<String, dynamic>.from(item)))
          .toList();
    }
    return defaultWeeklyQuests;
  }
}
