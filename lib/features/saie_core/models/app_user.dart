/// StuStep — AppUser model
library;

/// Represents a device-local user.
///
/// Created once on first launch and persisted forever.
/// `userId` is a UUID v4 — the single source of truth for isolating
/// one user's data from another's.
class AppUser {
  const AppUser({
    required this.userId,
    required this.createdAt,
  });

  final String userId;
  final DateTime createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['user_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'created_at': createdAt.toIso8601String(),
      };
}
