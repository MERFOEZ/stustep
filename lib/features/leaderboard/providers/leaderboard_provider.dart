import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard_entry_model.dart';
import '../services/leaderboard_service.dart';

class LeaderboardProvider extends ChangeNotifier {
  final LeaderboardService _leaderboardService = LeaderboardService();

  List<LeaderboardEntryModel> _members = [];
  LeaderboardEntryModel? _currentUserEntry;
  String _tierLevel = 'bronze';
  String _weekStartDate = '';
  String _groupId = '';
  bool _isLoading = true;
  String? _errorMessage;

  List<LeaderboardEntryModel> get members => _members;
  LeaderboardEntryModel? get currentUserEntry => _currentUserEntry;
  String get tierLevel => _tierLevel;
  String get weekStartDate => _weekStartDate;
  String get groupId => _groupId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isPromotionZone => (_currentUserEntry?.rank ?? 99) <= 7;
  bool get isDemotionZone =>
      _members.isNotEmpty && (_currentUserEntry?.rank ?? 0) > (_members.length - 5);

  int get pointsToPromotion {
    if (_currentUserEntry == null || isPromotionZone) return 0;
    if (_members.length >= 7) {
      final rank7Points = _members[6].weeklyPoints;
      return (rank7Points - _currentUserEntry!.weeklyPoints + 1).clamp(0, 999999);
    }
    return 0;
  }

  LeaderboardProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        fetchLeaderboard();
      } else {
        _clearState();
      }
    });
  }

  Future<void> fetchLeaderboard() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _leaderboardService.fetchLeaderboard(
        currentUserId: currentUserId,
      );

      _members = (result['members'] as List<LeaderboardEntryModel>?) ?? [];
      _tierLevel = result['tierLevel'] as String? ?? 'bronze';
      _weekStartDate = result['weekStartDate'] as String? ?? '';
      _groupId = result['groupId'] as String? ?? '';

      _currentUserEntry = _members.firstWhere(
        (m) => m.isCurrentUser,
        orElse: () => LeaderboardEntryModel(
          userId: currentUserId,
          name: FirebaseAuth.instance.currentUser?.displayName ?? 'You',
          weeklyPoints: 0,
          totalPoints: 0,
          currentStreak: 0,
          tierLevel: _tierLevel,
          rank: _members.length + 1,
          isCurrentUser: true,
        ),
      );

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearState() {
    _members = [];
    _currentUserEntry = null;
    _tierLevel = 'bronze';
    _weekStartDate = '';
    _groupId = '';
    _isLoading = false;
    notifyListeners();
  }
}
