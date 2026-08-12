import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/leaderboard_entry_model.dart';

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const String leaderboardCacheBoxName = 'leaderboard_cache_box';

  /// Initializer for Hive cache box
  static Future<void> initHive() async {
    try {
      await Hive.openBox(leaderboardCacheBoxName);
    } catch (_) {}
  }

  Box get _cacheBox => Hive.box(leaderboardCacheBoxName);

  /// Fetches group leaderboard data through Cloud Function or Firestore
  Future<Map<String, dynamic>> fetchLeaderboard({
    required String currentUserId,
    int limit = 30,
    int? startAfterPoints,
  }) async {
    try {
      final callable = _functions.httpsCallable('getLeaderboard');
      final response = await callable.call<Map<String, dynamic>>({
        'limit': limit,
        'startAfterPoints': startAfterPoints,
      });

      final data = Map<String, dynamic>.from(response.data);
      final rawMembers = (data['members'] as List<dynamic>?) ?? [];
      final members = rawMembers
          .map((m) => LeaderboardEntryModel.fromMap(
                Map<String, dynamic>.from(m as Map),
                currentUserId: currentUserId,
              ))
          .toList();

      // Cache locally
      _cacheBox.put('cached_members', rawMembers);
      _cacheBox.put('cached_tier', data['tierLevel'] ?? 'bronze');
      _cacheBox.put('cached_week_start', data['weekStartDate'] ?? '');

      return {
        'members': members,
        'weekStartDate': data['weekStartDate'] ?? '',
        'tierLevel': data['tierLevel'] ?? 'bronze',
        'groupId': data['groupId'] ?? '',
      };
    } catch (e) {
      // Fallback to cached data if offline or function unavailable
      final cached = _cacheBox.get('cached_members');
      if (cached is List) {
        final members = cached
            .map((m) => LeaderboardEntryModel.fromMap(
                  Map<String, dynamic>.from(m as Map),
                  currentUserId: currentUserId,
                ))
            .toList();
        return {
          'members': members,
          'weekStartDate': _cacheBox.get('cached_week_start') ?? '',
          'tierLevel': _cacheBox.get('cached_tier') ?? 'bronze',
          'groupId': '',
        };
      }
      return {
        'members': <LeaderboardEntryModel>[],
        'weekStartDate': '',
        'tierLevel': 'bronze',
        'groupId': '',
        'error': e.toString(),
      };
    }
  }

  /// Live Firestore Stream on current users in the assigned group
  Stream<List<LeaderboardEntryModel>> getGroupLiveStream(String groupId, String currentUserId) {
    if (groupId.isEmpty) return Stream.value([]);
    return _firestore.collection('leaderboardGroups').doc(groupId).snapshots().asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) return [];
      final memberIds = (doc.data()!['memberIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (memberIds.isEmpty) return [];

      final members = <LeaderboardEntryModel>[];
      for (int i = 0; i < memberIds.length; i += 10) {
        final chunk = memberIds.slice(i, i + 10 > memberIds.length ? memberIds.length : i + 10);
        final snap = await _firestore.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
        for (var uDoc in snap.docs) {
          final u = uDoc.data();
          members.add(LeaderboardEntryModel(
            userId: uDoc.id,
            name: u['name'] as String? ?? 'Student',
            photoUrl: u['photoUrl'] as String? ?? u['profileImage'] as String?,
            weeklyPoints: (u['weeklyPoints'] as num?)?.toInt() ?? 0,
            totalPoints: (u['totalPoints'] as num?)?.toInt() ?? 0,
            currentStreak: (u['currentStreak'] as num?)?.toInt() ?? 0,
            tierLevel: u['tierLevel'] as String? ?? doc.data()!['tierLevel'] as String? ?? 'bronze',
            rank: 0,
            isCurrentUser: uDoc.id == currentUserId,
          ));
        }
      }

      members.sort((a, b) {
        final diff = b.weeklyPoints.compareTo(a.weeklyPoints);
        if (diff != 0) return diff;
        return b.totalPoints.compareTo(a.totalPoints);
      });
      for (int idx = 0; idx < members.length; idx++) {
        members[idx] = LeaderboardEntryModel(
          userId: members[idx].userId,
          name: members[idx].name,
          photoUrl: members[idx].photoUrl,
          weeklyPoints: members[idx].weeklyPoints,
          totalPoints: members[idx].totalPoints,
          currentStreak: members[idx].currentStreak,
          tierLevel: members[idx].tierLevel,
          rank: idx + 1,
          isCurrentUser: members[idx].isCurrentUser,
        );
      }
      return members;
    });
  }
}

extension _SliceExtension<T> on List<T> {
  List<T> slice(int start, int end) {
    return sublist(start, end > length ? length : end);
  }
}
