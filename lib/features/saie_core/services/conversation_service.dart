/// StuStep — ConversationService
///
/// Persists and retrieves [Conversation]s per user.
/// Storage keys are scoped by user_id + conversation_id.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stustep/features/saie_core/models/chat_message_model.dart';
import 'package:stustep/features/saie_core/models/conversation.dart';
import 'package:stustep/features/saie_core/models/user_role.dart';
import 'package:uuid/uuid.dart';

// Storage key patterns:
//   stustep_conv_{conversationId}           → full conversation JSON
//   stustep_conv_index_{userId}_{roleKey}   → list of conversationIds

final class ConversationService {
  const ConversationService();

  static const _uuid = Uuid();

  // ── Keys ────────────────────────────────────────────────────────────────────

  String _convKey(String convId) => 'stustep_conv_$convId';

  String _indexKey(String userId, UserRole role) =>
      'stustep_conv_index_${userId}_${role.storageKey}';

  // ── Create ──────────────────────────────────────────────────────────────────

  /// Create a brand-new [Conversation] for the given user + assessment.
  Future<Conversation> create({
    required String userId,
    required String assessmentId,
    required UserRole role,
  }) async {
    final conv = Conversation(
      conversationId: _uuid.v4(),
      userId: userId,
      assessmentId: assessmentId,
      role: role,
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      messages: const [],
    );
    await _save(conv);
    await _addToIndex(userId, role, conv.conversationId);
    return conv;
  }

  // ── Append ──────────────────────────────────────────────────────────────────

  /// Append a message and persist immediately.
  Future<Conversation> appendMessage({
    required Conversation conversation,
    required String text,
    required MessageSender sender,
  }) async {
    final msg = ChatMessageModel(
      messageId: _uuid.v4(),
      sender: sender,
      text: text,
      timestamp: DateTime.now(),
    );
    final updated = conversation.addMessage(msg);
    await _save(updated);
    return updated;
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Load a conversation by ID. Returns null if not found.
  Future<Conversation?> load(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_convKey(conversationId));
    if (raw == null) return null;
    try {
      return Conversation.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Load the latest conversation for a user + role.
  /// Returns null if none exists yet.
  Future<Conversation?> loadLatest(String userId, UserRole role) async {
    final ids = await _loadIndex(userId, role);
    if (ids.isEmpty) return null;
    return load(ids.last);
  }

  /// Load all conversation IDs for a user + role.
  Future<List<String>> listIds(String userId, UserRole role) =>
      _loadIndex(userId, role);

  // ── Delete ──────────────────────────────────────────────────────────────────

  /// Delete a conversation and remove from index.
  Future<void> delete(String userId, UserRole role,
      String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_convKey(conversationId));
    final ids = await _loadIndex(userId, role);
    ids.remove(conversationId);
    await prefs.setString(_indexKey(userId, role), jsonEncode(ids));
  }

  /// Delete all conversations for a user + role.
  Future<void> deleteAll(String userId, UserRole role) async {
    final ids = await _loadIndex(userId, role);
    final prefs = await SharedPreferences.getInstance();
    for (final id in ids) {
      await prefs.remove(_convKey(id));
    }
    await prefs.remove(_indexKey(userId, role));
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _save(Conversation conv) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _convKey(conv.conversationId),
      jsonEncode(conv.toJson()),
    );
  }

  Future<void> _addToIndex(
      String userId, UserRole role, String convId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await _loadIndex(userId, role);
    if (!ids.contains(convId)) ids.add(convId);
    await prefs.setString(_indexKey(userId, role), jsonEncode(ids));
  }

  Future<List<String>> _loadIndex(String userId, UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indexKey(userId, role));
    if (raw == null) return [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }
}
