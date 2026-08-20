/// SAIE — ConversationLanguage
///
/// Manages automatic language detection and switching.
/// Default: Arabic. Switches to English when student writes English.
/// Never mixes both languages in one response.
library;

import 'package:equatable/equatable.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConversationLanguage
// ─────────────────────────────────────────────────────────────────────────────

/// Current language state of the conversation.
final class ConversationLanguage extends Equatable {
  /// The currently active response language.
  final Language active;

  /// The default fallback language.
  final Language defaultLanguage;

  /// Whether the language was auto-switched this turn.
  final bool switchedThisTurn;

  /// Total number of language switches in this session.
  final int switchCount;

  const ConversationLanguage({
    required this.active,
    required this.defaultLanguage,
    required this.switchedThisTurn,
    required this.switchCount,
  });

  /// Default state — Arabic.
  factory ConversationLanguage.initial() => const ConversationLanguage(
    active: Language.arabic,
    defaultLanguage: Language.arabic,
    switchedThisTurn: false,
    switchCount: 0,
  );

  bool get isArabic => active == Language.arabic;
  bool get isEnglish => active == Language.english;

  /// Applies a detected language from a [DetectedLanguage] result.
  ConversationLanguage applyDetection(DetectedLanguage detected) {
    final newLang = detected.language == Language.mixed
        ? active // keep current on mixed
        : detected.language == Language.unknown
            ? active
            : detected.language;
    final switched = newLang != active;
    return ConversationLanguage(
      active: newLang,
      defaultLanguage: defaultLanguage,
      switchedThisTurn: switched,
      switchCount: switchCount + (switched ? 1 : 0),
    );
  }

  /// Resets switched flag for next turn.
  ConversationLanguage nextTurn() => copyWith(switchedThisTurn: false);

  factory ConversationLanguage.fromJson(Map<String, dynamic> json) =>
      ConversationLanguage(
        active: Language.values.byName(json['active'] as String),
        defaultLanguage:
            Language.values.byName(json['default_language'] as String),
        switchedThisTurn: json['switched_this_turn'] as bool,
        switchCount: json['switch_count'] as int,
      );

  Map<String, dynamic> toJson() => {
    'active': active.name,
    'default_language': defaultLanguage.name,
    'switched_this_turn': switchedThisTurn,
    'switch_count': switchCount,
  };

  ConversationLanguage copyWith({
    Language? active,
    Language? defaultLanguage,
    bool? switchedThisTurn,
    int? switchCount,
  }) => ConversationLanguage(
    active: active ?? this.active,
    defaultLanguage: defaultLanguage ?? this.defaultLanguage,
    switchedThisTurn: switchedThisTurn ?? this.switchedThisTurn,
    switchCount: switchCount ?? this.switchCount,
  );

  @override
  List<Object?> get props => [active, switchCount];
}
