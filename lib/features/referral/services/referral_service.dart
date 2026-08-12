import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/referral_model.dart';
import '../models/referral_stats_model.dart';

class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const String referralCacheBoxName = 'referral_cache_box';

  /// Initializes Hive cache box for referrals
  static Future<void> initHive() async {
    try {
      await Hive.openBox(referralCacheBoxName);
    } catch (_) {}
  }

  Box get _cacheBox => Hive.box(referralCacheBoxName);

  /// Applies a referral code via Callable Cloud Function
  Future<Map<String, dynamic>> applyReferralCode({
    required String referralCode,
    String? deviceId,
  }) async {
    try {
      final callable = _functions.httpsCallable('applyReferralCode');
      final response = await callable.call<Map<String, dynamic>>({
        'referralCode': referralCode.trim().toUpperCase(),
        'deviceId': deviceId,
      });
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'status': 'error',
      };
    }
  }

  /// Fetches referral stats from Cloud Function or Hive Cache
  Future<ReferralStatsModel> getReferralStats(String userId) async {
    try {
      final callable = _functions.httpsCallable('getReferralStats');
      final response = await callable.call<Map<String, dynamic>>();
      final data = Map<String, dynamic>.from(response.data);

      final stats = ReferralStatsModel.fromMap(data);
      // Update Hive cache
      _cacheBox.put('stats_$userId', stats.toMap());
      return stats;
    } catch (e) {
      final cached = _cacheBox.get('stats_$userId');
      if (cached is Map) {
        return ReferralStatsModel.fromMap(Map<String, dynamic>.from(cached));
      }
      return const ReferralStatsModel(
        referralCode: 'STEP',
        referralLink: 'https://stustep.app/signup?ref=STEP',
      );
    }
  }

  /// Real-time stream of referrals made by this user
  Stream<List<ReferralModel>> getReferralsStream(String userId) {
    return _firestore
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ReferralModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Cached stats for instantaneous offline rendering
  ReferralStatsModel? getCachedStats(String userId) {
    final cached = _cacheBox.get('stats_$userId');
    if (cached is Map) {
      return ReferralStatsModel.fromMap(Map<String, dynamic>.from(cached));
    }
    return null;
  }
}
