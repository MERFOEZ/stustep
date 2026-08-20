/// StuStep — UserService
///
/// Creates and persists a single device-local user_id.
/// The ID is generated once on first launch and never changes.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stustep/features/saie_core/models/app_user.dart';
import 'package:uuid/uuid.dart';

const _kUserKey = 'stustep_user';

/// Manages the device-local [AppUser].
///
/// Thread-safe: `SharedPreferences` operations are atomic on the same
/// isolate. Call [getOrCreate] once at app startup and cache the result.
final class UserService {
  const UserService();

  /// Returns the existing [AppUser] or creates one if not found.
  Future<AppUser> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserKey);

    if (raw != null) {
      try {
        return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupted data — recreate.
      }
    }

    final user = AppUser(
      userId: const Uuid().v4(),
      createdAt: DateTime.now(),
    );
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
    return user;
  }

  /// Clears the stored user. Use ONLY for testing / "delete account".
  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
  }
}
