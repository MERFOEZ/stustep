/// SAIE — Top-Level Module Barrel
///
/// The single import point for the entire SAIE module.
/// Flutter presentation code imports ONLY this file.
///
/// ```dart
/// import 'package:stustep/features/saie/saie.dart';
/// ```
library;

export 'analysis/analysis.dart';
export 'assessment/assessment.dart';
export 'conversation/conversation.dart';
export 'core/core.dart';
export 'decision/decision.dart' hide ConversationContext;
export 'domain/domain.dart';
export 'engine_configuration.dart';
export 'engine_events.dart';
export 'engine_exceptions.dart';
export 'engine_result.dart';
export 'engine_state.dart';
export 'explainable/explainable.dart';
export 'llm/llm.dart';
export 'matching/matching.dart';
export 'models/models.dart';
export 'profile/profile.dart' hide StudentSnapshot;
export 'recommendation/recommendation.dart';
export 'saie_engine.dart';
export 'session_manager.dart';
export 'session_snapshot.dart';
export 'utils/utils.dart';
