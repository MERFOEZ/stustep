import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/points_user_model.dart';
import '../models/points_transaction_model.dart';
import '../models/quest_model.dart';
import '../models/user_quest_progress_model.dart';
import '../services/points_service.dart';

class PointsProvider extends ChangeNotifier {
  final PointsService _pointsService = PointsService();

  PointsUserModel? _userPoints;
  List<QuestModel> _dailyQuests = [];
  List<QuestModel> _weeklyQuests = [];
  final Map<String, UserQuestProgressModel> _dailyProgress = {};
  final Map<String, UserQuestProgressModel> _weeklyProgress = {};
  List<PointsTransactionModel> _transactions = [];

  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription? _userSub;
  StreamSubscription? _dailyQuestsSub;
  StreamSubscription? _weeklyQuestsSub;
  StreamSubscription? _dailyProgSub;
  StreamSubscription? _weeklyProgSub;
  StreamSubscription? _txSub;

  PointsUserModel? get userPoints => _userPoints;
  int get totalPoints => _userPoints?.totalPoints ?? 0;
  int get weeklyPoints => _userPoints?.weeklyPoints ?? 0;
  int get currentStreak => _userPoints?.currentStreak ?? 0;
  String get tierLevel => _userPoints?.tierLevel ?? 'bronze';

  List<QuestModel> get dailyQuests => _dailyQuests;
  List<QuestModel> get weeklyQuests => _weeklyQuests;
  Map<String, UserQuestProgressModel> get dailyProgress => _dailyProgress;
  Map<String, UserQuestProgressModel> get weeklyProgress => _weeklyProgress;
  List<PointsTransactionModel> get transactions => _transactions;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PointsProvider() {
    _dailyQuests = PointsService.defaultDailyQuests;
    _weeklyQuests = PointsService.defaultWeeklyQuests;
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToStreams(user.uid);
      } else {
        _clearState();
      }
    });
  }

  void _subscribeToStreams(String userId) {
    _cancelSubscriptions();

    // 1. Load cached points immediately
    _userPoints = _pointsService.getCachedUserPoints(userId);
    notifyListeners();

    // 2. User points stream
    _userSub = _pointsService.getUserPointsStream(userId).listen((data) {
      _userPoints = data;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });

    // 3. Daily Quests stream
    _dailyQuestsSub = _pointsService.getDailyQuestsStream().listen((quests) {
      _dailyQuests = quests;
      notifyListeners();
    });

    // 4. Weekly Quests stream
    _weeklyQuestsSub = _pointsService.getWeeklyQuestsStream().listen((quests) {
      _weeklyQuests = quests;
      notifyListeners();
    });

    // 5. Daily Progress stream
    _dailyProgSub = _pointsService.getUserDailyProgressStream(userId).listen((progressList) {
      _dailyProgress.clear();
      for (var p in progressList) {
        _dailyProgress[p.questId] = p;
      }
      notifyListeners();
    });

    // 6. Weekly Progress stream
    _weeklyProgSub = _pointsService.getUserWeeklyProgressStream(userId).listen((progressList) {
      _weeklyProgress.clear();
      for (var p in progressList) {
        _weeklyProgress[p.questId] = p;
      }
      notifyListeners();
    });

    // 7. Transactions stream
    _txSub = _pointsService.getTransactionsStream(userId).listen((txList) {
      _transactions = txList;
      notifyListeners();
    });
  }

  void _cancelSubscriptions() {
    _userSub?.cancel();
    _dailyQuestsSub?.cancel();
    _weeklyQuestsSub?.cancel();
    _dailyProgSub?.cancel();
    _weeklyProgSub?.cancel();
    _txSub?.cancel();
  }

  void _clearState() {
    _cancelSubscriptions();
    _userPoints = null;
    _dailyQuests = [];
    _weeklyQuests = [];
    _dailyProgress.clear();
    _weeklyProgress.clear();
    _transactions = [];
    _isLoading = false;
    notifyListeners();
  }

  /// Records an activity via Cloud Functions
  Future<Map<String, dynamic>> recordActivity({
    required String actionType,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await _pointsService.recordActivity(
      actionType: actionType,
      referenceId: referenceId,
      metadata: metadata,
    );
    return result;
  }

  /// Calculates remaining time until midnight UTC (daily quest reset)
  Duration getRemainingDailyTime() {
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  /// Calculates remaining time until next Monday 00:00 UTC (weekly leaderboard reset)
  Duration getRemainingWeeklyTime() {
    final now = DateTime.now().toUtc();
    final daysUntilMonday = ((8 - now.weekday) % 7) == 0 ? 7 : (8 - now.weekday) % 7;
    final nextMonday = DateTime.utc(now.year, now.month, now.day + daysUntilMonday);
    return nextMonday.difference(now);
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
