import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quest_model.dart';
import '../models/quest_progress_model.dart';
import '../services/quests_service.dart';

class QuestsProvider extends ChangeNotifier {
  final QuestsService _questsService = QuestsService();

  List<QuestModel> _dailyQuests = [];
  List<QuestModel> _weeklyQuests = [];
  Map<String, QuestProgressModel> _dailyProgress = {};
  Map<String, QuestProgressModel> _weeklyProgress = {};

  bool _isLoading = true;
  String? _errorMessage;
  int _activeTabIndex = 0; // 0 = Daily, 1 = Weekly

  StreamSubscription? _dailyQuestsSub;
  StreamSubscription? _weeklyQuestsSub;
  StreamSubscription? _dailyProgressSub;
  StreamSubscription? _weeklyProgressSub;

  QuestsProvider() {
    _init();
  }

  List<QuestModel> get dailyQuests => _dailyQuests;
  List<QuestModel> get weeklyQuests => _weeklyQuests;
  Map<String, QuestProgressModel> get dailyProgress => _dailyProgress;
  Map<String, QuestProgressModel> get weeklyProgress => _weeklyProgress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get activeTabIndex => _activeTabIndex;

  int get completedDailyCount => _dailyQuests.where((q) => _dailyProgress[q.id]?.isCompleted ?? false).length;
  int get completedWeeklyCount => _weeklyQuests.where((q) => _weeklyProgress[q.id]?.isCompleted ?? false).length;

  void _init() {
    // 1. Load offline cached quests immediately
    _dailyQuests = _questsService.getCachedDailyQuests();
    _weeklyQuests = _questsService.getCachedWeeklyQuests();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest_user';
    _dailyProgress = _questsService.getCachedDailyProgress(uid);
    _weeklyProgress = _questsService.getCachedWeeklyProgress(uid);

    if (_dailyQuests.isNotEmpty || _weeklyQuests.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
    }

    // 2. Listen to Auth changes to subscribe to user progress
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToStreams(user.uid);
      } else {
        _clearUserData();
      }
    });
  }

  void _subscribeToStreams(String userId) {
    _dailyQuestsSub?.cancel();
    _weeklyQuestsSub?.cancel();
    _dailyProgressSub?.cancel();
    _weeklyProgressSub?.cancel();

    _dailyQuestsSub = _questsService.getDailyQuestsStream().listen((quests) {
      _dailyQuests = quests;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });

    _weeklyQuestsSub = _questsService.getWeeklyQuestsStream().listen((quests) {
      _weeklyQuests = quests;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });

    _dailyProgressSub = _questsService.getUserDailyProgressStream(userId).listen((progress) {
      _dailyProgress = progress;
      notifyListeners();
    });

    _weeklyProgressSub = _questsService.getUserWeeklyProgressStream(userId).listen((progress) {
      _weeklyProgress = progress;
      notifyListeners();
    });
  }

  void switchTab(int index) {
    if (_activeTabIndex != index) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  Future<void> refreshQuests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _subscribeToStreams(user.uid);
    }
  }

  Future<Map<String, dynamic>> recordActivity({
    required String actionType,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    final result = await _questsService.recordActivity(
      actionType: actionType,
      referenceId: referenceId,
      metadata: metadata,
    );
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest_user';
    _dailyProgress = _questsService.getCachedDailyProgress(uid);
    _weeklyProgress = _questsService.getCachedWeeklyProgress(uid);
    notifyListeners();
    return result;
  }

  void _clearUserData() {
    _dailyProgressSub?.cancel();
    _weeklyProgressSub?.cancel();
    _dailyProgress = {};
    _weeklyProgress = {};
    notifyListeners();
  }

  @override
  void dispose() {
    _dailyQuestsSub?.cancel();
    _weeklyQuestsSub?.cancel();
    _dailyProgressSub?.cancel();
    _weeklyProgressSub?.cancel();
    super.dispose();
  }
}
