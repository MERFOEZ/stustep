/// SAIE — DetectedLanguage
///
/// Represents the language detected in a student message and the overall
/// conversation language policy. The engine always tracks language state
/// separately from intent to enable automatic switching.
library;

import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Language
// ─────────────────────────────────────────────────────────────────────────────

/// Languages supported by the SAIE engine.
enum Language {
  /// Modern Standard Arabic or Arabic dialects.
  arabic,

  /// English.
  english,

  /// Mixed Arabic and English (detected but not preferred).
  mixed,

  /// Could not be determined from the message.
  unknown,
}

extension LanguageX on Language {
  String get isoCode => switch (this) {
    Language.arabic => 'ar',
    Language.english => 'en',
    Language.mixed => 'mixed',
    Language.unknown => 'unknown',
  };

  String get displayName => switch (this) {
    Language.arabic => 'Arabic',
    Language.english => 'English',
    Language.mixed => 'Mixed',
    Language.unknown => 'Unknown',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// DetectedLanguage
// ─────────────────────────────────────────────────────────────────────────────

/// The result of language detection on a single message.
final class DetectedLanguage extends Equatable {
  /// The detected language.
  final Language language;

  /// Confidence in this detection, in [0.0, 1.0].
  final double confidence;

  /// Ratio of Arabic characters found in the message, in [0.0, 1.0].
  final double arabicRatio;

  /// Ratio of Latin characters found in the message, in [0.0, 1.0].
  final double latinRatio;

  const DetectedLanguage({
    required this.language,
    required this.confidence,
    required this.arabicRatio,
    required this.latinRatio,
  });

  factory DetectedLanguage.fromJson(Map<String, dynamic> json) =>
      DetectedLanguage(
        language: Language.values.byName(json['language'] as String),
        confidence: (json['confidence'] as num).toDouble(),
        arabicRatio: (json['arabic_ratio'] as num).toDouble(),
        latinRatio: (json['latin_ratio'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'language': language.name,
    'confidence': confidence,
    'arabic_ratio': arabicRatio,
    'latin_ratio': latinRatio,
  };

  DetectedLanguage copyWith({
    Language? language,
    double? confidence,
    double? arabicRatio,
    double? latinRatio,
  }) => DetectedLanguage(
    language: language ?? this.language,
    confidence: confidence ?? this.confidence,
    arabicRatio: arabicRatio ?? this.arabicRatio,
    latinRatio: latinRatio ?? this.latinRatio,
  );

  @override
  List<Object?> get props => [language, confidence];

  @override
  String toString() =>
      'DetectedLanguage(${language.name}, ${confidence.toStringAsFixed(2)})';
}
