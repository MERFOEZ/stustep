// ignore_for_file: unnecessary_brace_in_string_interps
/// SAIE LLM — LlmExplanationPromptBuilder
///
/// Builds the FULL CONTEXT MESSAGE sent to the LLM for every QUL turn.
///
/// Design philosophy:
///   Instead of 5 narrow intent-specific prompts, we send ONE rich context
///   block containing everything the LLM needs to reason like a human
///   academic advisor:
///     - Active assessment question (full metadata)
///     - Rich knowledge base annotations for this question (why it's asked,
///       examples, misconceptions, hints, key term definitions)
///     - Student profile summary (top cognitive dimensions if available)
///     - Assessment phase and progress
///     - Recent conversation history (last 8 turns)
///     - Student's raw message (verbatim)
///     - Clarification count (escalation signal)
///     - Detected language
///     - Soft intent note (not a constraint — the LLM reasons freely)
///
///   The LLM decides what the student needs. We only provide context.
///
/// HARD GUARANTEES (enforced by LlmTask gate in LlmService):
///   - No builder modifies assessment state.
///   - No builder selects or scores questions.
///   - No builder updates StudentCognitiveProfile.
///   - The assessment question is REPEATED at the end of every response.
library;

import 'package:stustep/features/saie/conversation/conversation_history.dart';
import 'package:stustep/features/saie/core/enums.dart';
import 'package:stustep/features/saie/knowledge/question_knowledge_base.dart';
import 'package:stustep/features/saie/llm/qul_intent.dart';
import 'package:stustep/features/saie/models/question.dart';
import 'package:stustep/features/saie/profile/student_cognitive_profile.dart';

// _____________________________________________________________________________
// LlmExplanationPromptBuilder
// _____________________________________________________________________________

/// Assembles a single rich context message for every QUL explanation request.
///
/// All methods are static — this is a pure data transformer.
final class LlmExplanationPromptBuilder {
  const LlmExplanationPromptBuilder._();

  // Maximum conversation turns to include in the prompt.
  static const int _maxHistoryTurns = 8;

  // Maximum profile dimensions to surface (highest-score first).
  static const int _maxProfileDimensions = 5;

  // Minimum evidence records before we include profile data in the prompt.
  static const int _minEvidenceForProfile = 3;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Build the user-turn context message for [intent].
  ///
  /// This single method replaces the 5 old intent-specific builders.
  /// The LLM receives everything and reasons freely about what the student
  /// needs — the [intent] is a soft hint, not a constraint.
  static String build({
    required QulIntent intent,
    required Question question,
    required String studentMessage,
    required bool isArabic,
    List<ConversationTurnRecord> recentHistory = const [],
    int clarificationCount = 0,
    StudentCognitiveProfile? profile,
    AssessmentPhase assessmentPhase = AssessmentPhase.onboarding,
  }) {
    final buf = StringBuffer();

    // ── 1. Assessment context ─────────────────────────────────────────────────
    _appendAssessmentContext(buf, assessmentPhase, profile, isArabic);

    // ── 2. Current question (full metadata) ───────────────────────────────────
    _appendQuestionContext(buf, question, isArabic);

    // ── 3. Academic knowledge for this question ───────────────────────────────
    _appendQuestionKnowledge(buf, question, isArabic);

    // ── 4. Student profile summary ────────────────────────────────────────────
    _appendProfileSummary(buf, profile, isArabic);

    // ── 5. Recent conversation history ────────────────────────────────────────
    _appendConversationHistory(buf, recentHistory, isArabic);

    // ── 6. Student's latest message ───────────────────────────────────────────
    _appendStudentMessage(buf, studentMessage, isArabic);

    // ── 7. Context notes (clarification count + intent hint) ──────────────────
    _appendContextNotes(buf, intent, clarificationCount, isArabic);

    // ── 8. Task instruction ───────────────────────────────────────────────────
    _appendTaskInstruction(buf, question, intent, isArabic);

    return buf.toString();
  }

  // ── Section builders ────────────────────────────────────────────────────────

  static void _appendAssessmentContext(
    StringBuffer buf,
    AssessmentPhase phase,
    StudentCognitiveProfile? profile,
    bool isArabic,
  ) {
    final phaseName = _phaseName(phase, isArabic);
    final answeredCount = profile?.evidence
            .where((e) => e.questionId != null)
            .map((e) => e.questionId!)
            .toSet()
            .length ??
        0;

    if (isArabic) {
      buf.writeln('=== سياق التقييم ===');
      buf.writeln('مرحلة التقييم الحالية: $phaseName');
      buf.writeln('عدد الأسئلة التي أجاب عليها الطالب حتى الآن: $answeredCount');
    } else {
      buf.writeln('=== ASSESSMENT CONTEXT ===');
      buf.writeln('Current assessment phase: $phaseName');
      buf.writeln('Questions answered so far: $answeredCount');
    }
    buf.writeln();
  }

  static void _appendQuestionContext(
    StringBuffer buf,
    Question q,
    bool isArabic,
  ) {
    final typeLabel = _typeLabel(q.type, isArabic);
    final diffLabel = _difficultyLabel(q.difficulty, isArabic);
    final domainLabel = _domainLabel(q.targetDomainIds, isArabic);
    final purposeLabel = _questionPurpose(q, isArabic);

    if (isArabic) {
      buf.writeln('=== السؤال الحالي في التقييم ===');
      buf.writeln('نص السؤال: "${q.text}"');
      if (q.hint != null && q.hint!.isNotEmpty) {
        buf.writeln('تلميح السؤال: ${q.hint}');
      }
      buf.writeln('نوع السؤال: $typeLabel');
      buf.writeln('مستوى الصعوبة: $diffLabel');
      buf.writeln('المجال الأكاديمي: $domainLabel');
      buf.writeln('ما الذي يقيسه هذا السؤال: $purposeLabel');
      if (q.options.isNotEmpty) {
        buf.writeln('الخيارات المتاحة للإجابة:');
        for (final opt in q.options) {
          buf.writeln('  - ${opt.label}');
        }
      }
    } else {
      buf.writeln('=== CURRENT ASSESSMENT QUESTION ===');
      buf.writeln('Question text: "${q.text}"');
      if (q.hint != null && q.hint!.isNotEmpty) {
        buf.writeln('Question hint: ${q.hint}');
      }
      buf.writeln('Question type: $typeLabel');
      buf.writeln('Difficulty: $diffLabel');
      buf.writeln('Academic domain(s): $domainLabel');
      buf.writeln('What this question measures: $purposeLabel');
      if (q.options.isNotEmpty) {
        buf.writeln('Available answer options:');
        for (final opt in q.options) {
          buf.writeln('  - ${opt.label}');
        }
      }
    }
    buf.writeln();
  }

  /// Injects the rich academic knowledge for this question from [QuestionKnowledgeBase].
  static void _appendQuestionKnowledge(
    StringBuffer buf,
    Question q,
    bool isArabic,
  ) {
    final summary = QuestionKnowledgeBase.buildKnowledgeSummary(
      q.id,
      isArabic: isArabic,
    );
    if (summary.isNotEmpty) {
      buf.writeln(summary);
      buf.writeln();
    }
  }

  static void _appendProfileSummary(
    StringBuffer buf,
    StudentCognitiveProfile? profile,
    bool isArabic,
  ) {
    if (profile == null || profile.evidence.length < _minEvidenceForProfile) {
      if (isArabic) {
        buf.writeln('=== ملخص ملف الطالب ===');
        buf.writeln('الملف لا يزال يُبنى — لم تُجمع بيانات كافية بعد.');
      } else {
        buf.writeln('=== STUDENT PROFILE SUMMARY ===');
        buf.writeln('Profile is still being established — not enough data yet.');
      }
      buf.writeln();
      return;
    }

    // Sort dimensions by score descending, take top N.
    final dims = profile.dimensions.values
        .where((d) => d.evidenceCount > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final top = dims.take(_maxProfileDimensions).toList();

    if (isArabic) {
      buf.writeln('=== ملخص ملف الطالب (أبرز الأبعاد المعرفية) ===');
      for (final d in top) {
        final score = (d.score * 100).round();
        final conf = (d.confidence * 100).round();
        buf.writeln('  - ${d.label}: $score% (ثقة: $conf%)');
      }
    } else {
      buf.writeln('=== STUDENT PROFILE SUMMARY (Top cognitive dimensions) ===');
      for (final d in top) {
        final score = (d.score * 100).round();
        final conf = (d.confidence * 100).round();
        buf.writeln('  - ${d.label}: $score% (confidence: $conf%)');
      }
    }
    buf.writeln();
  }

  static void _appendConversationHistory(
    StringBuffer buf,
    List<ConversationTurnRecord> history,
    bool isArabic,
  ) {
    if (history.isEmpty) return;

    final recent = history.length > _maxHistoryTurns
        ? history.sublist(history.length - _maxHistoryTurns)
        : history;

    if (isArabic) {
      buf.writeln('=== المحادثة الأخيرة ===');
    } else {
      buf.writeln('=== RECENT CONVERSATION ===');
    }

    for (final turn in recent) {
      if (turn.content.trim().isEmpty) continue;
      final role = isArabic
          ? (turn.isStudent ? 'الطالب' : 'المستشار')
          : (turn.isStudent ? 'Student' : 'Advisor');
      buf.writeln('$role: ${turn.content.trim()}');
    }
    buf.writeln();
  }

  static void _appendStudentMessage(
    StringBuffer buf,
    String studentMessage,
    bool isArabic,
  ) {
    if (isArabic) {
      buf.writeln('=== رسالة الطالب الأخيرة ===');
      buf.writeln('"$studentMessage"');
    } else {
      buf.writeln("=== STUDENT'S LATEST MESSAGE ===");
      buf.writeln('"$studentMessage"');
    }
    buf.writeln();
  }

  static void _appendContextNotes(
    StringBuffer buf,
    QulIntent intent,
    int clarificationCount,
    bool isArabic,
  ) {
    final intentHint = _intentHint(intent, isArabic);

    if (isArabic) {
      buf.writeln('=== ملاحظات السياق ===');
      buf.writeln('عدد مرات طلب المساعدة على هذا السؤال: $clarificationCount');
      if (clarificationCount >= 2) {
        buf.writeln(
          'تحذير: الطالب طلب المساعدة أكثر من مرة على هذا السؤال. '
          'اشرح من زاوية مختلفة تماماً عن المحاولات السابقة — '
          'استخدم أمثلة جديدة وأسلوباً مختلفاً.',
        );
      } else if (clarificationCount == 1) {
        buf.writeln(
          'ملاحظة: الطالب طلب المساعدة مرة سابقة على هذا السؤال. '
          'تأكد أن شرحك هذه المرة يضيف منظوراً مختلفاً.',
        );
      }
      buf.writeln('إشارة نية الطالب: $intentHint');
    } else {
      buf.writeln('=== CONTEXT NOTES ===');
      buf.writeln('Times student asked for help on this question: $clarificationCount');
      if (clarificationCount >= 2) {
        buf.writeln(
          'Warning: The student has asked for help multiple times on this question. '
          'Explain from a completely different angle than previous attempts — '
          'use fresh examples and a different approach.',
        );
      } else if (clarificationCount == 1) {
        buf.writeln(
          'Note: The student has asked for help once before on this question. '
          'Make sure your explanation this time adds a different perspective.',
        );
      }
      buf.writeln('Student intent signal: $intentHint');
    }
    buf.writeln();
  }

  static void _appendTaskInstruction(
    StringBuffer buf,
    Question q,
    QulIntent intent,
    bool isArabic,
  ) {
    if (isArabic) {
      buf.writeln('=== مهمتك ===');
      buf.writeln(
        'أنت مستشار أكاديمي يتحدث مع طالب يحتاج مساعدة لفهم سؤال التقييم أعلاه.\n'
        '\n'
        'اقرأ:\n'
        '١. رسالة الطالب بعناية — ماذا يسأل فعلاً؟\n'
        '٢. السؤال التقييمي كاملاً بكل تفاصيله\n'
        '٣. المعرفة الأكاديمية المرفقة لهذا السؤال\n'
        '٤. المحادثة السابقة (إن وجدت)\n'
        '\n'
        'ثم أجب:\n'
        '- كمستشار أكاديمي حقيقي: دافئ، طبيعي، مباشر\n'
        '- افهم ما يحتاجه الطالب بالفعل — لا تفترض أو تقدم ردوداً قالبية\n'
        '- استخدم المعرفة الأكاديمية المرفقة في شرحك\n'
        '- اكتشف اللغة المناسبة من رسالة الطالب وأجب بها\n'
        '- لا تكشف عن أي منطق تقييمي داخلي\n'
        '- لا تُجب عن سؤال التقييم نيابةً عن الطالب\n'
        '\n'
        'في نهاية ردك، أعِد السؤال الأصلي كما هو تماماً:\n'
        '"${q.text}"',
      );
    } else {
      buf.writeln('=== YOUR TASK ===');
      buf.writeln(
        'You are an academic advisor speaking with a student who needs help understanding the assessment question above.\n'
        '\n'
        'Read carefully:\n'
        '1. The student\'s message — what are they actually asking?\n'
        '2. The full assessment question with all its details\n'
        '3. The academic knowledge attached to this question\n'
        '4. The recent conversation (if any)\n'
        '\n'
        'Then respond:\n'
        '- As a real academic advisor: warm, natural, direct\n'
        '- Understand what the student actually needs — don\'t assume or give template responses\n'
        '- Use the academic knowledge in your explanation\n'
        '- Detect the appropriate language from the student\'s message and respond in it\n'
        '- Never reveal any internal assessment logic\n'
        '- Never answer the assessment question on behalf of the student\n'
        '\n'
        'At the end of your response, repeat the original question exactly as written:\n'
        '"${q.text}"',
      );
    }
  }

  // ── Metadata helpers ─────────────────────────────────────────────────────────

  static String _phaseName(AssessmentPhase phase, bool isArabic) {
    if (isArabic) {
      return switch (phase) {
        AssessmentPhase.onboarding  => 'التوجيه الأولي',
        AssessmentPhase.exploration => 'الاستكشاف',
        AssessmentPhase.deepening   => 'التعمق',
        AssessmentPhase.calibration => 'المعايرة',
        AssessmentPhase.synthesis   => 'الإنهاء',
        AssessmentPhase.completed   => 'مكتمل',
      };
    } else {
      return switch (phase) {
        AssessmentPhase.onboarding  => 'Onboarding',
        AssessmentPhase.exploration => 'Exploration',
        AssessmentPhase.deepening   => 'Deepening',
        AssessmentPhase.calibration => 'Calibration',
        AssessmentPhase.synthesis   => 'Synthesis',
        AssessmentPhase.completed   => 'Completed',
      };
    }
  }

  static String _typeLabel(QuestionType type, bool isArabic) {
    if (isArabic) {
      return switch (type) {
        QuestionType.openEnded           => 'سؤال مفتوح — يطلب وصفاً حراً بكلماتك',
        QuestionType.multipleChoice      => 'اختيار من متعدد — اختر الخيار الأنسب لك',
        QuestionType.likertScale         => 'مقياس ليكرت من 1 إلى 5 — مدى الاهتمام أو الموافقة',
        QuestionType.trueFalse           => 'صح أو خطأ — هل تنطبق الفكرة عليك أم لا؟',
        QuestionType.ranking             => 'ترتيب الأولويات — رتّب الخيارات من الأهم للأقل',
        QuestionType.multiSelect         => 'اختيار متعدد — يمكنك اختيار أكثر من خيار',
        QuestionType.situationalJudgment => 'حكم موقفي — كيف ستتصرف في الموقف المعطى؟',
      };
    } else {
      return switch (type) {
        QuestionType.openEnded           => 'Open-ended (describe freely in your own words)',
        QuestionType.multipleChoice      => 'Multiple choice (pick the option most like you)',
        QuestionType.likertScale         => 'Likert scale 1–5 (degree of interest or agreement)',
        QuestionType.trueFalse           => 'True / False (does this idea apply to you?)',
        QuestionType.ranking             => 'Priority ranking (order from most to least important)',
        QuestionType.multiSelect         => 'Multi-select (you can choose more than one option)',
        QuestionType.situationalJudgment => 'Situational judgment (how would you act in this scenario?)',
      };
    }
  }

  static String _difficultyLabel(QuestionDifficulty diff, bool isArabic) {
    if (isArabic) {
      return switch (diff) {
        QuestionDifficulty.basic        => 'تأسيسي (الأسئلة العامة الأولى)',
        QuestionDifficulty.intermediate => 'متوسط (يتطلب بعض التفكير)',
        QuestionDifficulty.advanced     => 'متقدم (يستدعي التأمل الجاد)',
        QuestionDifficulty.adaptive     => 'متكيف (يعتمد على إجاباتك السابقة)',
      };
    } else {
      return switch (diff) {
        QuestionDifficulty.basic        => 'Basic (opening general questions)',
        QuestionDifficulty.intermediate => 'Intermediate (requires some reflection)',
        QuestionDifficulty.advanced     => 'Advanced (invites serious contemplation)',
        QuestionDifficulty.adaptive     => 'Adaptive (adapts based on your previous answers)',
      };
    }
  }

  static String _questionPurpose(Question q, bool isArabic) {
    final domain = _domainLabel(q.targetDomainIds, isArabic);
    if (isArabic) {
      final typePurpose = switch (q.type) {
        QuestionType.openEnded           => 'كيف يفكر الطالب وكيف يعبّر عن نفسه بكلماته الخاصة',
        QuestionType.multipleChoice      => 'تفضيلات الطالب ومقارنة ميوله بين خيارات واضحة',
        QuestionType.likertScale         => 'مدى اهتمام الطالب أو ميله نحو موضوع محدد على مقياس من ١ لـ٥',
        QuestionType.trueFalse           => 'موقف الطالب من فكرة بعينها هل تنطبق عليه أم لا',
        QuestionType.ranking             => 'أولويات الطالب وما يهمه أكثر بين قيم أو خيارات متعددة',
        QuestionType.multiSelect         => 'المجالات المتعددة التي تثير اهتمام الطالب في نفس الوقت',
        QuestionType.situationalJudgment => 'أسلوب الطالب في التعامل مع المواقف الحقيقية وطريقة تفكيره',
      };
      return domain.isNotEmpty
          ? '$typePurpose في مجال $domain'
          : typePurpose;
    } else {
      final typePurpose = switch (q.type) {
        QuestionType.openEnded           => 'how the student thinks and expresses themselves in their own words',
        QuestionType.multipleChoice      => 'the student\'s preferences when comparing their inclinations across clear options',
        QuestionType.likertScale         => 'how strongly the student feels about a specific topic on a 1–5 scale',
        QuestionType.trueFalse           => 'whether a specific idea applies to the student or not',
        QuestionType.ranking             => 'what the student prioritizes most among multiple values or options',
        QuestionType.multiSelect         => 'the multiple fields that simultaneously interest the student',
        QuestionType.situationalJudgment => 'how the student handles real-world situations and their decision-making style',
      };
      return domain.isNotEmpty
          ? '$typePurpose (in $domain)'
          : typePurpose;
    }
  }

  static String _intentHint(QulIntent intent, bool isArabic) {
    if (isArabic) {
      return switch (intent) {
        QulIntent.clarification   => 'الطالب لم يفهم صياغة السؤال أو يريد إعادة شرحه بطريقة مختلفة',
        QulIntent.wordMeaning     => 'الطالب يسأل عن معنى كلمة أو مصطلح محدد في السؤال',
        QulIntent.whyThisQuestion => 'الطالب يريد أن يعرف لماذا يُطرح هذا السؤال وما فائدته',
        QulIntent.examples        => 'الطالب يريد أمثلة واقعية تساعده على فهم كيفية الإجابة',
        QulIntent.uncertainty     => 'الطالب يشعر بعدم اليقين ولا يعرف كيف يبدأ بالإجابة',
      };
    } else {
      return switch (intent) {
        QulIntent.clarification   => 'Student did not understand the question wording, or wants it re-explained differently',
        QulIntent.wordMeaning     => 'Student is asking about the meaning of a specific word or term in the question',
        QulIntent.whyThisQuestion => 'Student wants to know why this question is being asked and what it\'s for',
        QulIntent.examples        => 'Student wants real-world examples to understand how to approach their answer',
        QulIntent.uncertainty     => 'Student is uncertain and doesn\'t know how to begin answering',
      };
    }
  }

  static String _domainLabel(List<String> domainIds, bool isArabic) {
    if (domainIds.isEmpty) return isArabic ? 'غير محدد' : 'unspecified';
    final parts = domainIds.map((id) => _singleDomainLabel(id, isArabic)).toList();
    return parts.join(isArabic ? '، ' : ', ');
  }

  static String _singleDomainLabel(String id, bool isArabic) {
    // ── DimensionKeys exact matches (canonical — must come first) ───────────
    // These are the keys emitted by the new question pool. They map directly
    // to DimensionKeys constants and need human-readable Arabic/English labels.
    const arabicLabels = <String, String>{
      'logic':                   'التفكير المنطقي',
      'mathematics':             'الرياضيات',
      'creativity':              'الإبداع',
      'research':                'البحث العلمي',
      'critical_thinking':       'التفكير النقدي',
      'problem_solving':         'حل المشكلات',
      'teamwork':                'العمل الجماعي',
      'leadership':              'القيادة',
      'communication':           'التواصل والتعبير',
      'empathy':                 'التعاطف والتواصل الإنساني',
      'business':                'الأعمال والإدارة',
      'technology':              'التقنية والحاسب',
      'science':                 'العلوم التجريبية',
      'language':                'اللغة والأدب',
      'art':                     'الفن والتصميم',
      'medicine':                'الطب والصحة',
      'law':                     'القانون',
      'self_learning':           'التعلم الذاتي',
      'stress_preference':       'تحمّل الضغط',
      'decision_style':          'أسلوب اتخاذ القرار',
      'technology_affinity':     'الانجذاب للتقنية',
      'practical_vs_theoretical':'التطبيق مقابل النظرية',
      'academic_performance':    'الأداء الأكاديمي',
      'ambiguity_tolerance':     'تحمّل الغموض',
    };

    const englishLabels = <String, String>{
      'logic':                   'Logical Reasoning',
      'mathematics':             'Mathematics',
      'creativity':              'Creativity',
      'research':                'Research',
      'critical_thinking':       'Critical Thinking',
      'problem_solving':         'Problem Solving',
      'teamwork':                'Teamwork',
      'leadership':              'Leadership',
      'communication':           'Communication',
      'empathy':                 'Empathy & Human Connection',
      'business':                'Business & Management',
      'technology':              'Technology & Computing',
      'science':                 'Science',
      'language':                'Language & Literature',
      'art':                     'Art & Design',
      'medicine':                'Medicine & Health',
      'law':                     'Law',
      'self_learning':           'Self-Learning',
      'stress_preference':       'Stress Tolerance',
      'decision_style':          'Decision Style',
      'technology_affinity':     'Technology Affinity',
      'practical_vs_theoretical':'Practical vs Theoretical',
      'academic_performance':    'Academic Performance',
      'ambiguity_tolerance':     'Ambiguity Tolerance',
    };

    final labels = isArabic ? arabicLabels : englishLabels;
    if (labels.containsKey(id)) return labels[id]!;

    // ── Legacy substring matches (kept for backward compatibility) ──────────
    if (isArabic) {
      if (id.contains('stem'))        return 'العلوم والتقنية والهندسة والرياضيات';
      if (id.contains('arts'))        return 'الفنون والإبداع';
      if (id.contains('humanities'))  return 'الإنسانيات والعلوم الاجتماعية';
      if (id.contains('business'))    return 'الأعمال والإدارة';
      if (id.contains('medicine') || id.contains('health')) return 'الطب والصحة';
      if (id.contains('engineering')) return 'الهندسة';
      if (id.contains('cs') || id.contains('computer')) return 'علوم الحاسب';
      if (id.contains('law'))         return 'القانون';
      if (id.contains('education'))   return 'التعليم';
      if (id.contains('social'))      return 'العلوم الاجتماعية';
      if (id.contains('data'))        return 'علوم البيانات';
      if (id.contains('design'))      return 'التصميم';
      if (id.contains('finance') || id.contains('economics')) return 'الاقتصاد والمال';
      return id;
    } else {
      if (id.contains('stem'))        return 'STEM';
      if (id.contains('arts'))        return 'Arts & Creativity';
      if (id.contains('humanities'))  return 'Humanities & Social Sciences';
      if (id.contains('business'))    return 'Business & Management';
      if (id.contains('medicine') || id.contains('health')) return 'Medicine & Health';
      if (id.contains('engineering')) return 'Engineering';
      if (id.contains('cs') || id.contains('computer')) return 'Computer Science';
      if (id.contains('law'))         return 'Law';
      if (id.contains('education'))   return 'Education';
      if (id.contains('social'))      return 'Social Sciences';
      if (id.contains('data'))        return 'Data Science';
      if (id.contains('design'))      return 'Design';
      if (id.contains('finance') || id.contains('economics')) return 'Economics & Finance';
      return id;
    }
  }
}