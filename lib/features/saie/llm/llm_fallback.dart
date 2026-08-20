/// SAIE LLM — LlmFallback
///
/// Provides offline fallback text for every [LlmTask] using only
/// local data: ExplainableReport, RecommendationReport, and Knowledge Base.
///
/// This is ALWAYS called when the LLM is unavailable, disabled, or fails.
library;

import 'package:stustep/features/saie/llm/llm_request.dart';
import 'package:stustep/features/saie/llm/llm_response.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LlmFallback
// ─────────────────────────────────────────────────────────────────────────────

/// Generates fully offline fallback responses for every [LlmTask].
///
/// Integrates with [RecommendationReport] to produce meaningful local content
/// without any network call.
final class LlmFallback {
  const LlmFallback();

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Produce a [LlmResponse] with fallback content for [request].
  ///
  /// [report] is optional — provided when the task relates to a recommendation.
  LlmResponse buildFallback({
    required LlmRequest request,
    RecommendationReport? report,
  }) {
    final text = _resolveText(request.task, report);
    return LlmResponse.fallback(
      request: request,
      fallbackText: text,
      reason: 'LLM unavailable — local fallback applied.',
    );
  }

  // ── Task resolution ─────────────────────────────────────────────────────────

  String _resolveText(LlmTask task, RecommendationReport? report) =>
      switch (task) {
        LlmTask.academicDiscussion => _academicDiscussion(),
        LlmTask.questionExplanation => _questionExplanation(),
        LlmTask.wordMeaning => _wordMeaning(),
        LlmTask.whyThisQuestion => _whyThisQuestion(),
        LlmTask.questionExamples => _questionExamples(),
        LlmTask.questionClarification => _questionClarification(),
        LlmTask.uncertaintyHelp => _uncertaintyHelp(),
        LlmTask.recommendationExplanation =>
          _recommendationExplanation(report),
        LlmTask.careerExplanation => _careerExplanation(report),
        LlmTask.universityExplanation => _universityExplanation(),
        LlmTask.conversationSummarization => _conversationSummary(),
        LlmTask.responsePolishing => _responsePolishing(),
        LlmTask.translation => _translation(),
      };

  // ── Per-task fallbacks ──────────────────────────────────────────────────────

  String _academicDiscussion() =>
      'هذا موضوع أكاديمي مهم. يمكنني مناقشته معك بشكل أعمق بعد اكتمال التقييم.';

  String _questionExplanation() =>
      'هذا السؤال يهدف إلى فهم ميولك الأكاديمية وقدراتك بشكل أفضل. '
      'أجب بصدق وبما يعبر عن تجربتك الحقيقية.';

  // ── QUL offline fallbacks ─────────────────────────────────────────────────
  // Used when LLM is unavailable. LocalExplanationFallback provides richer
  // context-aware text; these are last-resort messages only.

  String _wordMeaning() =>
      'هذا المصطلح يشير إلى الميل أو القدرة المطلوبة في هذا السؤال. '
      'حاول الإجابة بناءً على شعورك الحقيقي.';

  String _whyThisQuestion() =>
      'هذا السؤال يساعدني على فهم ميولك واهتماماتك بشكل أفضل. '
      'إجابتك تساعدني في اقتراح التخصص الأكاديمي المناسب لك.';

  String _questionExamples() =>
      'بعض الإجابات الممكنة: نعم، لا، أفضل، لا أفضل، لست متأكداً. '
      'أجب بما يعبر عن رأيك بصدق.';

  String _questionClarification() =>
      'السؤال يهدف إلى فهم ميولك واهتماماتك. '
      'أجب بصدق وبما يعبر عن تجربتك الحقيقية.';

  String _uncertaintyHelp() =>
      'لا بأس! جرّب الإجابة بناءً على شعورك الحالي. '
      'لا توجد إجابة خاطئة — أي رد صادق يساعدني في فهمك أفضل.';


  String _recommendationExplanation(RecommendationReport? report) {
    if (report == null || report.recommendations.isEmpty) {
      return 'لم تكتمل عملية التقييم بعد. يرجى الإجابة على المزيد من الأسئلة.';
    }
    final top = report.recommendations.first;
    final strengths = top.topStrengths.take(3).join('، ');
    return 'بناءً على تحليل ملفك المعرفي، تبرز تخصص "${top.majorName}" '
        'كخيار مناسب بفضل نقاط قوتك في: $strengths. '
        'درجة التوافق: ${top.similarityScore}%.';
  }

  String _careerExplanation(RecommendationReport? report) {
    if (report == null || report.recommendations.isEmpty) {
      return 'يمكنني شرح مسارات مهنية مفصلة بعد اكتمال التقييم.';
    }
    final top = report.recommendations.first;
    if (top.careerPaths.isEmpty) {
      return 'تخصص "${top.majorName}" يفتح أبواباً واسعة في سوق العمل.';
    }
    final paths = top.careerPaths.take(4).join(' / ');
    return 'من أبرز المسارات المهنية لتخصص "${top.majorName}": $paths.';
  }

  String _universityExplanation() =>
      'الجامعات الرائدة في هذا المجال متعددة. '
      'يمكنني مساعدتك في اختيار المؤسسة الأكاديمية المناسبة بعد تحديد تخصصك.';

  String _conversationSummary() =>
      'استمرت محادثتنا وجمعنا معلومات قيمة عنك. '
      'سنواصل التقييم للوصول إلى توصية دقيقة.';

  String _responsePolishing() =>
      'أفهم ما تقوله. هل يمكنك مشاركتي المزيد من التفاصيل؟';

  String _translation() =>
      'يمكنني التواصل معك باللغة التي تفضلها.';
}
