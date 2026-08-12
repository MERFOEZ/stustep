import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التقاط وحفظ كود الدعوة من الروابط التشعبية (Deep Links / URL query).
class ReferralLinkService {
  static const String _pendingReferralKey = 'pending_referral_code';

  /// Saves a referral code captured from a deep link or manual entry
  static Future<void> savePendingReferralCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingReferralKey, cleanCode);
    }
  }

  /// Retrieves the saved pending referral code, if any
  static Future<String?> getPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingReferralKey);
  }

  /// Clears the pending referral code after registration
  static Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingReferralKey);
  }

  /// Extracts the `ref` query parameter from a URI string
  static String? extractReferralCodeFromUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.queryParameters.containsKey('ref')) {
        return uri.queryParameters['ref']?.trim().toUpperCase();
      }
    } catch (_) {}
    return null;
  }
}
