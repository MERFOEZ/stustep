/// SAIE LLM — LocalExplanationFallback
///
/// Generates natural, context-aware QUL responses from structured question
/// data when the LLM is unavailable (offline mode).
///
/// Design philosophy:
///   Responses should sound like a real human academic advisor talking to a
///   student — warm, direct, and context-specific. No template headers,
///   no robotic formatting.
///
/// CRITICAL: This class NEVER modifies assessment state, student profile, or
/// question selection. It is a pure string generator.
library;

import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/llm/qul_intent.dart';
import 'package:stustep/features/saie/models/question.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LocalExplanationFallback
// ─────────────────────────────────────────────────────────────────────────────

/// Generates rich offline QUL responses derived solely from [Question] metadata.
///
/// No hardcoded per-question logic. All outputs are derived from:
///   - [Question.type]       → purpose phrase
///   - [Question.targetDomainIds] → domain name
///   - [Question.options]    → example options (if multiple-choice)
final class LocalExplanationFallback {
  const LocalExplanationFallback();

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Generate an explanation for [intent] in the context of [question].
  ///
  /// [studentMessage] is used to extract the requested term for [wordMeaning].
  /// [isArabic] controls the response language.
  /// [clarificationCount] escalates response richness on repeated requests.
  ///
  /// Returns the explanation text only — the caller appends the question repeat.
  String generate({
    required QulIntent intent,
    required Question question,
    required String studentMessage,
    required bool isArabic,
    int clarificationCount = 0,
  }) =>
      switch (intent) {
        QulIntent.clarification =>
          _explainQuestion(question, isArabic, clarificationCount),
        QulIntent.wordMeaning =>
          _explainWordInQuestion(question, studentMessage, isArabic),
        QulIntent.whyThisQuestion =>
          _explainQuestionPurpose(question, isArabic),
        QulIntent.examples =>
          _provideQuestionExamples(question, isArabic),
        QulIntent.uncertainty =>
          _simplifyQuestion(question, isArabic, clarificationCount),
      };

  // ── Intent handlers ─────────────────────────────────────────────────────────

  String _explainQuestion(Question q, bool isArabic, int clarificationCount) {
    final domainName = _primaryDomainName(q.targetDomainIds, isArabic);
    final examples = _exampleAnswersForType(q, isArabic);
    final isRepeat = clarificationCount > 0;

    if (isArabic) {
      final intro = isRepeat
          ? 'خلّني أحاول أشرح بطريقة مختلفة هذه المرة.'
          : 'أوضّح لك هذا السؤال.';
      final domainHint = domainName.isNotEmpty
          ? 'هذا السؤال عن مجال $domainName'
          : 'هذا السؤال';
      return '$intro\n\n'
          '"${q.text}"\n\n'
          '$domainHint — يحاول يعرف ${_questionTypePurpose(q, isArabic)}.\n\n'
          'بعض الإجابات الممكنة:\n$examples';
    } else {
      final intro = isRepeat
          ? "Let me try a different angle this time."
          : "Here's what this question is asking.";
      final domainHint = domainName.isNotEmpty
          ? 'This question is about $domainName'
          : 'This question';
      return '$intro\n\n'
          '"${q.text}"\n\n'
          "$domainHint — it's trying to understand ${_questionTypePurpose(q, isArabic)}.\n\n"
          'Some possible answers:\n$examples';
    }
  }

  String _explainWordInQuestion(
    Question q,
    String studentMessage,
    bool isArabic,
  ) {
    final extracted = _extractTerm(studentMessage);
    final examples = _exampleAnswersForType(q, isArabic);
    final domainName = _primaryDomainName(q.targetDomainIds, isArabic);

    if (isArabic) {
      final term = extracted ?? 'المصطلح الذي ذكرته';
      final domainContext = domainName.isNotEmpty ? ' في مجال $domainName' : '';
      return '"$term"$domainContext يعني: ${_inferTermMeaning(term, q, isArabic)}\n\n'
          'للمساعدة في الإجابة، إليك بعض الأمثلة:\n$examples';
    } else {
      final term = extracted ?? 'the term you mentioned';
      final domainContext = domainName.isNotEmpty ? ' in $domainName' : '';
      return '"$term"$domainContext means: ${_inferTermMeaning(term, q, isArabic)}\n\n'
          'To help you answer, here are some examples:\n$examples';
    }
  }

  String _simplifyQuestion(Question q, bool isArabic, int clarificationCount) {
    final examples = _exampleAnswersForType(q, isArabic);
    final domainName = _primaryDomainName(q.targetDomainIds, isArabic);
    final isSecondTime = clarificationCount >= 1;

    if (isArabic) {
      final intro = isSecondTime
          ? 'بعض الأسئلة صعبة — وهذا طبيعي تماماً. خلّني أبسّطها أكثر.'
          : 'هذه الأسئلة أحياناً تحتاج وقفة تفكير.';
      final topic = domainName.isNotEmpty ? domainName : 'هذا الموضوع';
      return '$intro\n\n'
          'بعبارة أبسط: "${q.text}"\n\n'
          'يعني: ما علاقتك بـ$topic؟ هل تحبه؟ تتجنبه؟ محايد تجاهه؟\n\n'
          'إليك بعض الأمثلة على ما قد يقوله طلاب آخرون:\n$examples\n\n'
          'أيّ هذه الأمثلة يشبه شعورك أكثر؟';
    } else {
      final intro = isSecondTime
          ? "Some questions are genuinely tricky — that's completely fine. Let me simplify it further."
          : "Some questions take a moment to think about.";
      final topic = domainName.isNotEmpty ? domainName : 'this topic';
      return '$intro\n\n'
          'In simpler terms: "${q.text}"\n\n'
          'Basically: How do you feel about $topic? Enjoy it? Avoid it? Feel neutral?\n\n'
          "Here are some examples of what other students might say:\n$examples\n\n"
          'Which of these sounds most like you?';
    }
  }

  String _explainQuestionPurpose(Question q, bool isArabic) {
    final domainName = _primaryDomainName(q.targetDomainIds, isArabic);
    final typePurpose = _questionTypePurpose(q, isArabic);
    final examples = _exampleAnswersForType(q, isArabic);

    if (isArabic) {
      final domainMention = domainName.isNotEmpty
          ? ' في مجال $domainName'
          : '';
      return 'هذا السؤال يساعدني أفهم $typePurpose$domainMention.\n\n'
          'كل إجابة تعطيني صورة أوضح عن ميولك وأسلوب تفكيرك — '
          'وهذا ما يساعدني أقترح عليك التخصص الأنسب لك حقاً.\n\n'
          'أمثلة على إجابات:\n$examples';
    } else {
      final domainMention = domainName.isNotEmpty ? ' in $domainName' : '';
      return 'This question helps me understand $typePurpose$domainMention.\n\n'
          'Every answer gives me a clearer picture of how you think and what drives you — '
          "that's what helps me suggest the majors that would genuinely suit you.\n\n"
          'Example answers:\n$examples';
    }
  }

  String _provideQuestionExamples(Question q, bool isArabic) {
    if (isArabic) {
      if (q.options.isNotEmpty) {
        final opts = q.options.map((o) => '• ${o.label}').join('\n');
        return 'إليك الخيارات المتاحة لهذا السؤال:\n\n$opts\n\n'
            'اختر الخيار الذي يعكس شعورك أو رأيك الحقيقي.';
      }
      return 'إليك بعض الأمثلة على الإجابات الممكنة:\n\n'
          '${_exampleAnswersForType(q, isArabic)}\n\n'
          'لا توجد إجابة صح أو غلط — فقط أجب بصدق.';
    } else {
      if (q.options.isNotEmpty) {
        final opts = q.options.map((o) => '• ${o.label}').join('\n');
        return 'Here are the available options for this question:\n\n$opts\n\n'
            'Choose the option that best reflects how you genuinely feel or think.';
      }
      return 'Here are some example answers:\n\n'
          '${_exampleAnswersForType(q, isArabic)}\n\n'
          'There are no right or wrong answers — just answer honestly.';
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────────────

  /// Attempts to extract the term the student is asking about from their message.
  String? _extractTerm(String message) {
    final arTriggers = [
      'ما معنى', 'وش يعني', 'ما يعني', 'معناها ايش', 'شو يعني',
      'يعني ايش', 'وش معنى', 'ما تعني', 'شو معنى', 'ما تعني كلمة',
    ];
    final enTriggers = [
      'what does', 'what is the meaning of', 'meaning of',
      'define the word', 'define',
    ];

    final lower = message.toLowerCase();
    for (final trigger in [...arTriggers, ...enTriggers]) {
      final idx = lower.indexOf(trigger);
      if (idx >= 0) {
        final after = message.substring(idx + trigger.length).trim();
        if (after.isNotEmpty) {
          return after
              .split(RegExp(r'\s+'))
              .take(4)
              .join(' ')
              .replaceAll(RegExp(r'[؟?!,.]+'), '');
        }
      }
    }
    return null;
  }

  String _inferTermMeaning(String term, Question q, bool isArabic) {
    final domainName = _primaryDomainName(q.targetDomainIds, isArabic);
    final typePurpose = _questionTypePurpose(q, isArabic);
    return isArabic
        ? 'القدرة أو الميل المرتبط بـ${domainName.isNotEmpty ? domainName : term}. '
          'يُستخدم هذا المصطلح في قياس $typePurpose.'
        : 'the ability or tendency related to '
          '${domainName.isNotEmpty ? domainName : term}. '
          'It is used to measure $typePurpose.';
  }

  /// Maps a domain id to a human-readable name.
  ///
  /// Handles both canonical DimensionKeys (new question pool) and legacy
  /// substring-based domain IDs without ever exposing raw key strings.
  String _primaryDomainName(List<String> domainIds, bool isArabic) {
    if (domainIds.isEmpty) return '';
    final primary = domainIds.first;

    // ── Canonical DimensionKeys (new question pool) ──────────────────────────
    // Must come BEFORE substring checks to avoid partial mismatches.
    const arabicDimLabels = <String, String>{
      'logic':                    'التفكير المنطقي',
      'mathematics':              'الرياضيات',
      'creativity':               'الإبداع',
      'research':                 'البحث العلمي',
      'critical_thinking':        'التفكير النقدي',
      'problem_solving':          'حل المشكلات',
      'teamwork':                 'العمل الجماعي',
      'leadership':               'القيادة',
      'communication':            'التواصل والتعبير',
      'empathy':                  'التواصل الإنساني',
      'business':                 'الأعمال والإدارة',
      'technology':               'التقنية والحاسب',
      'science':                  'العلوم التجريبية',
      'language':                 'اللغة والأدب',
      'art':                      'الفن والتصميم',
      'medicine':                 'الطب والصحة',
      'law':                      'القانون',
      'self_learning':            'التعلم الذاتي',
      'stress_preference':        'تحمّل ضغط العمل',
      'decision_style':           'أسلوب اتخاذ القرار',
      'technology_affinity':      'الانجذاب للتقنية',
      'practical_vs_theoretical': 'التطبيق مقابل النظرية',
      'academic_performance':     'الأداء الأكاديمي',
      'ambiguity_tolerance':      'تحمّل الغموض',
    };
    const englishDimLabels = <String, String>{
      'logic':                    'Logical Reasoning',
      'mathematics':              'Mathematics',
      'creativity':               'Creativity',
      'research':                 'Research',
      'critical_thinking':        'Critical Thinking',
      'problem_solving':          'Problem Solving',
      'teamwork':                 'Teamwork',
      'leadership':               'Leadership',
      'communication':            'Communication',
      'empathy':                  'Empathy & Human Connection',
      'business':                 'Business & Management',
      'technology':               'Technology & Computing',
      'science':                  'Science',
      'language':                 'Language & Literature',
      'art':                      'Art & Design',
      'medicine':                 'Medicine & Health',
      'law':                      'Law',
      'self_learning':            'Self-Learning',
      'stress_preference':        'Stress Tolerance',
      'decision_style':           'Decision Style',
      'technology_affinity':      'Technology Affinity',
      'practical_vs_theoretical': 'Practical vs Theoretical',
      'academic_performance':     'Academic Performance',
      'ambiguity_tolerance':      'Ambiguity Tolerance',
    };

    final labels = isArabic ? arabicDimLabels : englishDimLabels;
    if (labels.containsKey(primary)) return labels[primary]!;

    // ── Legacy substring matches ─────────────────────────────────────────────
    if (isArabic) {
      if (primary.contains('stem')) return 'العلوم والتقنية والهندسة والرياضيات';
      if (primary.contains('arts')) return 'الفنون والإبداع';
      if (primary.contains('humanities')) return 'الإنسانيات والعلوم الاجتماعية';
      if (primary.contains('business')) return 'الأعمال والإدارة';
      if (primary.contains('medicine') || primary.contains('health')) return 'الطب والصحة';
      if (primary.contains('engineering')) return 'الهندسة';
      if (primary.contains('cs') || primary.contains('computer')) return 'علوم الحاسب';
      if (primary.contains('law')) return 'القانون';
      if (primary.contains('education')) return 'التعليم';
      if (primary.contains('data')) return 'علوم البيانات';
      if (primary.contains('design')) return 'التصميم';
      if (primary.contains('social')) return 'العلوم الاجتماعية';
      if (primary.contains('finance') || primary.contains('economics')) return 'الاقتصاد والمال';
      // Final safety net — never expose raw key
      return 'الأكاديمي';
    } else {
      if (primary.contains('stem')) return 'STEM';
      if (primary.contains('arts')) return 'Arts & Creativity';
      if (primary.contains('humanities')) return 'Humanities & Social Sciences';
      if (primary.contains('business')) return 'Business & Management';
      if (primary.contains('medicine') || primary.contains('health')) return 'Medicine & Health';
      if (primary.contains('engineering')) return 'Engineering';
      if (primary.contains('cs') || primary.contains('computer')) return 'Computer Science';
      if (primary.contains('law')) return 'Law';
      if (primary.contains('education')) return 'Education';
      if (primary.contains('data')) return 'Data Science';
      if (primary.contains('design')) return 'Design';
      if (primary.contains('social')) return 'Social Sciences';
      if (primary.contains('finance') || primary.contains('economics')) return 'Economics & Finance';
      // Final safety net — never expose raw key
      return 'academic';
    }
  }

  /// Maps question type to a conversational purpose phrase.
  String _questionTypePurpose(Question q, bool isArabic) {
    if (isArabic) {
      return switch (q.type) {
        QuestionType.openEnded           => 'طريقة تفكيرك وكيف تعبّر عن نفسك',
        QuestionType.multipleChoice      => 'تفضيلاتك بين الخيارات المختلفة',
        QuestionType.likertScale         => 'مدى اهتمامك أو ميلك نحو موضوع معين',
        QuestionType.trueFalse           => 'موقفك تجاه فكرة بعينها',
        QuestionType.ranking             => 'ترتيب الأولويات بالنسبة لك',
        QuestionType.multiSelect         => 'المجالات التي تهمك من عدة خيارات',
        QuestionType.situationalJudgment => 'كيف تتعامل مع مواقف حقيقية',
      };
    } else {
      return switch (q.type) {
        QuestionType.openEnded           => 'how you think and express yourself',
        QuestionType.multipleChoice      => 'your preference among different options',
        QuestionType.likertScale         => 'how strongly you feel about a particular topic',
        QuestionType.trueFalse           => 'your stance on a specific idea',
        QuestionType.ranking             => 'what you prioritize most',
        QuestionType.multiSelect         => 'which fields interest you among several options',
        QuestionType.situationalJudgment => 'how you handle real-life situations',
      };
    }
  }

  /// Generates example answers based on question type and domain.
  ///
  /// Always uses the question's actual answer options when available.
  /// Falls back to question-type-appropriate generic examples only when
  /// no options are defined (i.e. open-ended questions).
  String _exampleAnswersForType(Question q, bool isArabic) {
    // Always prefer the question's own defined options over generic templates.
    if (q.options.isNotEmpty) {
      return q.options.map((o) => '• ${o.label}').join('\n');
    }
    final domainName = _primaryDomainName(q.targetDomainIds, isArabic);
    if (isArabic) {
      return switch (q.type) {
        QuestionType.likertScale =>
            '• 1 — لا يهمني على الإطلاق\n'
            '• 2 — لا يهمني كثيراً\n'
            '• 3 — محايد، ما لي رأي قاطع\n'
            '• 4 — يهمني نوعاً ما\n'
            '• 5 — يهمني جداً وأتحمس له',
        QuestionType.trueFalse =>
            '• نعم، هذا ينطبق عليّ\n• لا، لا ينطبق عليّ بشكل عام',
        QuestionType.openEnded =>
            '• أستمتع بـ${domainName.isNotEmpty ? domainName : "هذا المجال"} وأتعلم منه كثيراً\n'
            '• أجد نفسي مهتماً لكن ما جرّبته بشكل جدي\n'
            '• ما أعرف إن كنت مناسباً له\n'
            '• أفضّل مجالاً آخر يتيح لي ...',
        QuestionType.ranking =>
            '• الأول: المجال الذي يشغل تفكيري أكثر\n• الأخير: المجال الأقل جذباً لي',
        QuestionType.multiSelect =>
            '• اختر كل مجال تشعر أنه قريب من اهتماماتك',
        QuestionType.situationalJudgment =>
            '• أحاول أحل الموقف بشكل مباشر وعملي\n'
            '• أفضل أستشير شخصاً ذا خبرة أولاً\n'
            '• أتروّى وأفكر قبل أي خطوة',
        QuestionType.multipleChoice =>
            '• اختر الخيار الأقرب لشخصيتك وتفكيرك',
      };
    } else {
      return switch (q.type) {
        QuestionType.likertScale =>
            '• 1 — Not at all interested\n'
            '• 2 — Not really interested\n'
            '• 3 — Neutral, no strong opinion\n'
            '• 4 — Somewhat interested\n'
            '• 5 — Very interested and enthusiastic',
        QuestionType.trueFalse =>
            '• Yes, this applies to me\n• No, it generally doesn\'t apply to me',
        QuestionType.openEnded =>
            '• I enjoy ${domainName.isNotEmpty ? domainName : "this field"} and learn a lot from it\n'
            '• I\'m somewhat interested but haven\'t explored it seriously\n'
            '• I\'m not sure if I\'m a good fit for it\n'
            '• I\'d prefer a different field that lets me ...',
        QuestionType.ranking =>
            '• First: the field that occupies my mind most\n• Last: the field that interests me least',
        QuestionType.multiSelect =>
            '• Select every field that feels close to your interests',
        QuestionType.situationalJudgment =>
            '• I try to address the situation directly and practically\n'
            '• I prefer consulting someone experienced first\n'
            '• I take my time and think before acting',
        QuestionType.multipleChoice =>
            '• Choose the option that best fits your personality and thinking',
      };
    }
  }
}