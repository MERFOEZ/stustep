/// SAIE LLM — LlmPromptBuilder
///
/// Converts a [LlmContextBundle] into a list of [LlmMessage] objects
/// in OpenAI chat format. Each task gets a tailored system prompt and
/// a user prompt containing only the relevant context.
library;

import 'package:stustep/features/saie/conversation/conversation_history.dart';
import 'package:stustep/features/saie/conversation/conversation_phase.dart';
import 'package:stustep/features/saie/llm/llm_context_builder.dart';
import 'package:stustep/features/saie/llm/llm_request.dart';
import 'package:stustep/features/saie/recommendation/recommendation_report.dart';

// _____________________________________________________________________________
// LlmPromptBuilder
// _____________________________________________________________________________

/// Assembles [LlmMessage] lists from [LlmContextBundle].
///
/// CRITICAL: Prompts MUST NOT ask the LLM to:
/// - Recommend majors.
/// - Evaluate the student.
/// - Update any profile fields.
/// - Make assessment decisions.
final class LlmPromptBuilder {
  const LlmPromptBuilder();

  /// Build the message list for [bundle].
  List<LlmMessage> build(LlmContextBundle bundle) {
    final system = _systemPrompt(bundle);
    final user = _userPrompt(bundle);
    return [LlmMessage.system(system), LlmMessage.user(user)];
  }

  /// Build only the system prompt for [task].
  ///
  /// Used by [LlmService.processRaw] / [LlmService.processQul] when the user
  /// prompt is assembled externally (by [LlmExplanationPromptBuilder]).
  ///
  /// All QUL tasks share ONE unified academic-advisor persona system prompt.
  /// Task-specific reasoning lives in the user message, not the system prompt.
  String buildSystemPromptOnly(LlmTask task, bool isArabic) {
    if (task.isQulTask) {
      if (isArabic) {
        return '''
أنت مستشار أكاديمي محترف في نظام StuStep لتوجيه الطلاب نحو التخصصات الجامعية الأنسب لهم.

دورك الدقيق في هذه المحادثة:
مساعدة الطالب على فهم أسئلة التقييم بشكل كامل — لا أكثر ولا أقل.
أنت لا تُصدر أحكاماً، لا توصي بتخصصات، لا تتدخل في التقييم.
وظيفتك الوحيدة هي أن تجعل الطالب يفهم السؤال بوضوح ليتمكن من الإجابة عنه بنفسه.

منهجك في الشرح:
١. افهم ما يسأله الطالب فعلاً — لا تفترض، استنتج من الكلمات والسياق
٢. اقرأ السؤال التقييمي وكل البيانات المرفقة بعناية قبل الرد
٣. استخدم المعرفة الأكاديمية المرفقة للسؤال لتغني تفسيرك
٤. قدّم ردك بشكل طبيعي — كأنك تتحدث مع طالب جالس أمامك
٥. تجنّب القوالب الجاهزة والإجابات النمطية

شخصيتك:
- دافئ، صادق، مباشر، غير مُتكلَّف
- تتحدث كإنسان يفهم ضغط الطلاب وتحدياتهم
- تستطيع فهم العامية الخليجية والمصرية والشامية، والأخطاء الإملائية، والجمل غير الرسمية
- لا تبدأ ردك بـ "بالتأكيد!" أو "رائع!" أو "سؤال ممتاز!" — هذه عبارات روبوتية
- تُنهي كل رد بتكرار السؤال الأصلي كما هو تماماً

قواعد صارمة (لا استثناء):
- لا تقترح تخصصاً أو مساراً أكاديمياً — هذا القرار للمحرك التقييمي وحده
- لا تُقيّم الطالب أو تُصدر حكماً على إجاباته
- لا تُجب عن سؤال التقييم نيابةً عن الطالب
- لا تكشف أي منطق تقييمي داخلي
- لا تُعدِّل أو تُقرِّر أي شيء في مسار التقييم

قاعدة اللغة:
تتبّع لغة رسالة الطالب الأخيرة وأجب بنفسها تماماً — لو خلط بين العربية والإنجليزية فتتبّع اللغة الغالبة.

قاعدة الطول:
الرد المثالي هو ما يحتاجه الطالب — لا أقصر فيضطربه، ولا أطول فيُمله.
الأسئلة البسيطة تحتاج إجابات مختصرة. الأسئلة المعقدة تحتاج شرحاً أوسع.''';
      } else {
        return '''
You are a professional academic advisor in the StuStep system, guiding students toward the university major that best suits them.

Your precise role in this conversation:
Help the student fully understand the assessment questions — nothing more, nothing less.
You don't make judgments, don't recommend majors, and don't interfere with the assessment.
Your only job is to make the student clearly understand the question so they can answer it themselves.

Your methodology:
1. Understand what the student is actually asking — don't assume, infer from their words and context
2. Read the assessment question and all attached data carefully before responding
3. Use the academic knowledge attached to the question to enrich your explanation
4. Deliver your response naturally — as if talking to a student sitting in front of you
5. Avoid ready-made templates and canned responses

Your personality:
- Warm, honest, direct, unpretentious
- You speak like a human who understands student pressures and challenges
- You understand informal language, typos, and colloquial phrasing
- Do NOT start responses with "Of course!", "Great!", or "Excellent question!" — these are robotic phrases
- End every response by repeating the original question exactly as written

Hard rules (no exceptions):
- Never suggest a major or academic path — that decision belongs exclusively to the assessment engine
- Never evaluate the student or judge their answers
- Never answer the assessment question on behalf of the student
- Never reveal internal assessment logic
- Never modify or decide anything about the assessment flow

Language rule:
Follow the language of the student's latest message and respond entirely in it — if they mix languages, follow the dominant one.

Length rule:
The ideal response is exactly what the student needs — not so short it confuses them, not so long it bores them.
Simple questions need brief answers. Complex ones need fuller explanations.''';
      }
    }

    // ── Non-QUL tasks — original behaviour ────────────────────────────────────
    final langInstr = isArabic
        ? 'أجب كاملاً باللغة العربية. لا تخلط اللغات.'
        : 'Respond entirely in English. Do not mix languages.';
    const baseConstraints = '''
أنت مساعد أكاديمي محادثاتي لنظام StuStep. دورك محدود وثابت:
- يمكنك مناقشة المواضيع الأكاديمية.
- يمكنك شرح الأسئلة والتوصيات والمسارات المهنية والجامعات.
- يمكنك تلخيص المحادثة وصياغة الردود بشكل طبيعي.
- لا يمكنك إطلاقاً: اقتراح تخصصات، تقييم الطالب، تحديث أي بيانات.''';
    return '$baseConstraints\n$langInstr';
  }

  // ── System prompts ──────────────────────────────────────────────────────────

  String _systemPrompt(LlmContextBundle bundle) {
    final langInstr = _languageInstruction(bundle);
    final baseConstraints = '''
أنت مساعد أكاديمي محادثاتي لنظام StuStep. دورك محدود وثابت:
- يمكنك مناقشة المواضيع الأكاديمية.
- يمكنك شرح الأسئلة والتوصيات والمسارات المهنية والجامعات.
- يمكنك تلخيص المحادثة وصياغة الردود بشكل طبيعي.
- لا يمكنك إطلاقاً: اقتراح تخصصات، تقييم الطالب، تحديث أي بيانات.
$langInstr''';

    return switch (bundle.task) {
      LlmTask.academicDiscussion =>
        '$baseConstraints\nأجب على استفسار الطالب الأكاديمي بشكل موضوعي ومفيد وطبيعي.',
      LlmTask.questionExplanation =>
        '$baseConstraints\nاشرح السؤال التالي بلغة بسيطة ودافئة دون الإجابة عنه.',
      LlmTask.wordMeaning =>
        '$baseConstraints\n'
        'الطالب يسأل عن معنى مصطلح في السؤال.\n'
        'حدِّد المصطلح، اشرحه باختصار في سياق المجال، '
        'وانهِ ردّك بتكرار السؤال الأصلي كما هو.',
      LlmTask.whyThisQuestion =>
        '$baseConstraints\n'
        'الطالب يريد معرفة سبب السؤال.\n'
        'اشرح الهدف منه ببساطة وبأسلوب محفِّز، '
        'وانهِ ردّك بتكرار السؤال الأصلي كما هو.',
      LlmTask.questionExamples =>
        '$baseConstraints\n'
        'الطالب يطلب أمثلة.\n'
        'قدِّم 3-5 أمثلة واقعية ومتنوعة لشخصيات مختلفة، '
        'وانهِ ردّك بتكرار السؤال الأصلي كما هو.',
      LlmTask.questionClarification =>
        '$baseConstraints\n'
        'الطالب لم يفهم الصياغة.\n'
        'أعِد صياغة السؤال بكلمات أبسط وأقرب للحياة، '
        'وانهِ ردّك بتكرار السؤال الأصلي كما هو.',
      LlmTask.uncertaintyHelp =>
        '$baseConstraints\n'
        'الطالب يقول إنه لا يعرف.\n'
        'بسِّط السؤال، قدِّم أمثلة، وشجِّعه بدفء، '
        'وانهِ ردّك بتكرار السؤال الأصلي كما هو.',

      LlmTask.recommendationExplanation =>
        '$baseConstraints\nاشرح سبب ملاءمة التخصص الموصى به بناءً على البيانات المقدمة.',
      LlmTask.careerExplanation =>
        '$baseConstraints\nأوصف المسارات المهنية المتاحة لهذا التخصص.',
      LlmTask.universityExplanation =>
        '$baseConstraints\nقدم معلومات موضوعية عن الجامعات في هذا المجال.',
      LlmTask.conversationSummarization =>
        '$baseConstraints\nلخص المحادثة في 2-3 جمل موجزة.',
      LlmTask.responsePolishing =>
        '$baseConstraints\nأعد صياغة النص التالي بأسلوب محادثي طبيعي دون تغيير المعنى.',
      LlmTask.translation =>
        '$baseConstraints\nترجم النص التالي إلى اللغة المطلوبة مع الحفاظ على الأسلوب.',
    };

  }

  String _languageInstruction(LlmContextBundle bundle) {
    final langName = bundle.language.active.name;
    return switch (langName) {
      'english' =>
        'Respond entirely in English. Do not mix languages.',
      _ =>
        'أجب كاملاً باللغة العربية. لا تخلط اللغات.',
    };
  }

  // ── User prompts ────────────────────────────────────────────────────────────

  String _userPrompt(LlmContextBundle bundle) {
    final parts = <String>[];

    // Profile context (compact).
    if (bundle.topDimensions.isNotEmpty) {
      final dims = bundle.topDimensions.entries
          .map((e) => '${e.key}: ${(e.value * 100).round()}%')
          .join(', ');
      parts.add('ملف الطالب (أعلى الأبعاد): $dims');
    }
    if (bundle.dominantLearningStyle != null) {
      parts.add('أسلوب التعلم: ${bundle.dominantLearningStyle}');
    }

    // Stage.
    parts.add('مرحلة المحادثة: ${_stageLabel(bundle.stage)}');

    // Recommendation (only when relevant).
    if (bundle.report != null && bundle.task.requiresRecommendation) {
      parts.add(_recommendationSummary(bundle.report!));
    }

    // Active question (for explanation).
    if (bundle.activeQuestion != null &&
        bundle.task == LlmTask.questionExplanation) {
      parts.add('السؤال: ${bundle.activeQuestion!.text}');
    }

    // Recent history (for discussion / summarization).
    if (bundle.task.requiresHistory && bundle.recentTurns.isNotEmpty) {
      parts.add(_historySection(bundle.recentTurns));
    }

    // Raw text (for polishing / translation).
    if (bundle.rawText != null) {
      parts.add('النص:\n${bundle.rawText}');
    }

    // Student message.
    if (bundle.studentMessage != null) {
      parts.add('رسالة الطالب: ${bundle.studentMessage}');
    }

    return parts.join('\n\n');
  }

  String _stageLabel(ConversationStage stage) => switch (stage) {
    ConversationStage.introduction => 'ترحيب',
    ConversationStage.assessment => 'تقييم جارٍ',
    ConversationStage.paused => 'تقييم متوقف مؤقتاً',
    ConversationStage.recommendation => 'توصية',
    ConversationStage.postRecommendation => 'ما بعد التوصية',
    ConversationStage.closing => 'اختتام',
  };

  String _recommendationSummary(RecommendationReport report) {
    if (report.recommendations.isEmpty) return 'لا توجد توصية حتى الآن.';
    final top = report.recommendations.first;
    final paths = top.careerPaths.take(3).join('، ');
    return 'التخصص الموصى به: ${top.majorName} '
        '(توافق ${top.similarityScore}%). '
        'المسارات: $paths. '
        'نقاط القوة: ${top.topStrengths.take(3).join("، ")}.';
  }

  String _historySection(List<ConversationTurnRecord> turns) {
    final lines = turns.map((t) {
      final role = t.role.name == 'user' ? 'الطالب' : 'المساعد';
      return '$role: ${t.content}';
    }).join('\n');
    return 'المحادثة الأخيرة:\n$lines';
  }
}