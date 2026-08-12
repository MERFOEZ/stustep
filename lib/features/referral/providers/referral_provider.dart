import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/referral_model.dart';
import '../models/referral_stats_model.dart';
import '../services/referral_service.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralService _referralService = ReferralService();

  ReferralStatsModel? _stats;
  List<ReferralModel> _referrals = [];
  bool _isLoading = true;
  bool _isApplying = false;
  String? _errorMessage;

  StreamSubscription? _referralsSub;

  ReferralStatsModel? get stats => _stats;
  String get referralCode => _stats?.referralCode ?? '';
  String get referralLink => _stats?.referralLink ?? 'https://stustep.app/signup?ref=$referralCode';
  int get totalInvited => _stats?.totalInvited ?? _referrals.length;
  int get activeReferrals => _stats?.activeReferrals ?? _referrals.where((r) => r.isActivated || r.isRewarded).length;
  int get totalPointsEarned => _stats?.totalPointsEarned ?? 0;
  List<ReferralModel> get referrals => _referrals;

  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  String? get errorMessage => _errorMessage;

  ReferralProvider() {
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
    _referralsSub?.cancel();

    // 1. Load cached stats immediately
    _stats = _referralService.getCachedStats(userId);
    notifyListeners();

    // 2. Fetch fresh stats
    fetchStats();

    // 3. Real-time stream of referrals
    _referralsSub = _referralService.getReferralsStream(userId).listen((list) {
      _referrals = list;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      notifyListeners();
    });
  }

  Future<void> fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _stats = await _referralService.getReferralStats(user.uid);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Applies an invitation code during or after signup
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    if (code.trim().isEmpty) {
      return {'success': false, 'message': 'referral.enter_valid_code'.tr()};
    }

    _isApplying = true;
    notifyListeners();

    try {
      final result = await _referralService.applyReferralCode(
        referralCode: code,
      );
      _isApplying = false;
      await fetchStats();
      return result;
    } catch (e) {
      _isApplying = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Shares referral link via native system share sheet
  Future<void> shareReferralLink() async {
    final text = 'referral.share_message'.tr(namedArgs: {
      'code': referralCode,
      'link': referralLink,
    });

    try {
      await Share.share(
        text,
        subject: 'referral.share_subject'.tr(),
      );
    } catch (_) {
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: referralLink));
    }
  }

  /// Copies referral code to clipboard
  Future<void> copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: referralCode));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('referral.code_copied'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Copies full referral link to clipboard
  Future<void> copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: referralLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('referral.link_copied'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearState() {
    _referralsSub?.cancel();
    _stats = null;
    _referrals = [];
    _isLoading = false;
    _isApplying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _referralsSub?.cancel();
    super.dispose();
  }
}
