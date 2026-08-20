/// SAIE — QuestionKnowledgeBase
///
/// A rich, per-question knowledge registry used by [LlmExplanationPromptBuilder]
/// to give the LLM everything an experienced academic advisor would know
/// about each assessment question.
///
/// For each question, this provides:
///   - [concepts]: the core concepts being probed
///   - [keyConcepts]: short definitions useful for word-meaning explanations
///   - [examples]: realistic, concrete examples tied to the question
///   - [misconceptions]: common student misunderstandings to preempt
///   - [hints]: softer nudges to help without giving the answer
///   - [relatedConcepts]: related domains to make connections
///   - [whyAsked]: plain-language rationale for why this question exists
///   - [learningOutcomes]: what the system learns from the answer
///
/// Design rules:
///   - No code should use this to make assessment decisions.
///   - No code should use this to score or rank answers.
///   - This is for EXPLANATION ONLY — it flows into LLM prompts.
///   - The Assessment Engine remains the single authority for all decisions.
library;

// ─────────────────────────────────────────────────────────────────────────────
// QuestionKnowledge
// ─────────────────────────────────────────────────────────────────────────────

/// Rich knowledge annotations for a single assessment question.
final class QuestionKnowledge {
  /// The question ID this knowledge entry corresponds to.
  final String questionId;

  /// Core concepts the question is probing (for contextual explanation).
  final List<String> concepts;

  /// Key terms and their plain-language definitions (Arabic and English).
  final Map<String, String> keyConceptsAr;
  final Map<String, String> keyConceptsEn;

  /// Concrete, realistic examples that illustrate how students might think
  /// about this question.
  final List<String> examplesAr;
  final List<String> examplesEn;

  /// Common misconceptions or confusions students have about this question.
  final List<String> misconceptionsAr;
  final List<String> misconceptionsEn;

  /// Soft guiding hints that don't give away the answer.
  final List<String> hintsAr;
  final List<String> hintsEn;

  /// Why this question is asked — the purpose in plain language.
  final String whyAskedAr;
  final String whyAskedEn;

  /// What the system learns from the answer — helps explain relevance.
  final String learningOutcomeAr;
  final String learningOutcomeEn;

  /// Related domains or fields that connect to this question.
  final List<String> relatedDomainsAr;
  final List<String> relatedDomainsEn;

  const QuestionKnowledge({
    required this.questionId,
    required this.concepts,
    required this.keyConceptsAr,
    required this.keyConceptsEn,
    required this.examplesAr,
    required this.examplesEn,
    required this.misconceptionsAr,
    required this.misconceptionsEn,
    required this.hintsAr,
    required this.hintsEn,
    required this.whyAskedAr,
    required this.whyAskedEn,
    required this.learningOutcomeAr,
    required this.learningOutcomeEn,
    required this.relatedDomainsAr,
    required this.relatedDomainsEn,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// QuestionKnowledgeBase
// ─────────────────────────────────────────────────────────────────────────────

/// Provides [QuestionKnowledge] by question ID.
///
/// Used exclusively by [LlmExplanationPromptBuilder] to enrich LLM prompts.
/// No other component should read from here.
final class QuestionKnowledgeBase {
  const QuestionKnowledgeBase._();

  /// Returns the knowledge entry for [questionId], or null if not found.
  static QuestionKnowledge? forQuestion(String questionId) {
    return _registry[questionId];
  }

  /// Returns a compact summary string for inclusion in LLM prompts.
  static String buildKnowledgeSummary(String questionId, {required bool isArabic}) {
    final k = _registry[questionId];
    if (k == null) return '';

    final buf = StringBuffer();
    if (isArabic) {
      buf.writeln('=== المعرفة الأكاديمية لهذا السؤال ===');
      buf.writeln('لماذا يُطرح هذا السؤال: ${k.whyAskedAr}');
      buf.writeln('ماذا نتعلم من الإجابة: ${k.learningOutcomeAr}');
      if (k.hintsAr.isNotEmpty) {
        buf.writeln('تلميحات للطالب:');
        for (final h in k.hintsAr) { buf.writeln('  • $h'); }
      }
      if (k.examplesAr.isNotEmpty) {
        buf.writeln('أمثلة واقعية:');
        for (final e in k.examplesAr) { buf.writeln('  • $e'); }
      }
      if (k.misconceptionsAr.isNotEmpty) {
        buf.writeln('أخطاء شائعة في الفهم:');
        for (final m in k.misconceptionsAr) { buf.writeln('  • $m'); }
      }
      if (k.keyConceptsAr.isNotEmpty) {
        buf.writeln('تعريفات المصطلحات الأساسية:');
        for (final entry in k.keyConceptsAr.entries) {
          buf.writeln('  • "${entry.key}": ${entry.value}');
        }
      }
      if (k.relatedDomainsAr.isNotEmpty) {
        buf.writeln('المجالات المرتبطة: ${k.relatedDomainsAr.join('، ')}');
      }
    } else {
      buf.writeln('=== ACADEMIC KNOWLEDGE FOR THIS QUESTION ===');
      buf.writeln('Why this question is asked: ${k.whyAskedEn}');
      buf.writeln('What we learn from the answer: ${k.learningOutcomeEn}');
      if (k.hintsEn.isNotEmpty) {
        buf.writeln('Hints for the student:');
        for (final h in k.hintsEn) { buf.writeln('  • $h'); }
      }
      if (k.examplesEn.isNotEmpty) {
        buf.writeln('Real-world examples:');
        for (final e in k.examplesEn) { buf.writeln('  • $e'); }
      }
      if (k.misconceptionsEn.isNotEmpty) {
        buf.writeln('Common misconceptions:');
        for (final m in k.misconceptionsEn) { buf.writeln('  • $m'); }
      }
      if (k.keyConceptsEn.isNotEmpty) {
        buf.writeln('Key term definitions:');
        for (final entry in k.keyConceptsEn.entries) {
          buf.writeln('  • "${entry.key}": ${entry.value}');
        }
      }
      if (k.relatedDomainsEn.isNotEmpty) {
        buf.writeln('Related fields: ${k.relatedDomainsEn.join(', ')}');
      }
    }

    return buf.toString().trim();
  }

  // ── Registry ───────────────────────────────────────────────────────────────

  static const _registry = <String, QuestionKnowledge>{
    // ════════════════════════════════════════════════════════════════════════
    // NEW QUESTION POOL — q_onboard_001 / q_onboard_002 / q_onboard_003
    //                     q_001  …  q_015
    // ════════════════════════════════════════════════════════════════════════

    // ────────────────────────────────────────────────────────────────────────
    // q_onboard_001 — Voluntary intellectual curiosity (multiSelect)
    // ────────────────────────────────────────────────────────────────────────
    'q_onboard_001': QuestionKnowledge(
      questionId: 'q_onboard_001',
      concepts: ['intrinsic interest', 'self-directed learning', 'academic domain preference'],
      keyConceptsAr: {
        'من تلقاء نفسك': 'أي بدون أن يطلبه منك أحد — باختيارك الحر',
        'الذكاء الاصطناعي': 'تقنيات تجعل الحاسب يتعلم ويتخذ قرارات كالإنسان',
        'الإنسانيات': 'دراسة الإنسان: تاريخه، فلسفته، قوانينه، ونفسيته',
      },
      keyConceptsEn: {
        'on your own': 'without anyone asking you — by your own free choice',
        'artificial intelligence': 'technology that allows computers to learn and make decisions like humans',
        'humanities': 'the study of human beings: history, philosophy, law, psychology',
      },
      examplesAr: [
        'طالب يقرأ مقالات عن الذكاء الاصطناعي من اهتمامه الشخصي — لا لأن هناك اختبار',
        'طالبة تتابع مقاطع عن القانون الجنائي لأنها تجدها مثيرة للاهتمام',
        'طالب يحل مسائل رياضية إضافية في وقت فراغه',
        'طالبة تصمم شعارات ومنشورات بمبادرتها الخاصة',
      ],
      examplesEn: [
        'A student who reads about AI out of personal interest — not for an exam',
        'A student who follows forensic law videos because they find them fascinating',
        'A student who solves extra math problems in their free time',
        'A student who designs logos and graphics on their own initiative',
      ],
      misconceptionsAr: [
        'هذا ليس سؤالاً عن ما تدرسه في المدرسة — بل عما تختار أنت أن تتعلمه',
        'لا يوجد إجابة "صح" — كل مجال اخترته يعطي النظام معلومة حقيقية عنك',
        'اختيار أكثر من مجال طبيعي تماماً',
      ],
      misconceptionsEn: [
        'This is not about what you study in school — it is about what you personally choose to learn',
        'There is no "correct" answer — every field you choose gives the system real information about you',
        'Selecting more than one field is completely normal',
      ],
      hintsAr: [
        'فكّر في آخر شيء بحثت عنه على الإنترنت لمجرد أنه أثار فضولك',
        'ما المواضيع التي تجد نفسك تقرأ فيها دون أن تشعر بالوقت؟',
      ],
      hintsEn: [
        'Think about the last thing you searched for online just because it sparked your curiosity',
        'What topics do you find yourself reading about without noticing time passing?',
      ],
      whyAskedAr: 'الفضول الطوعي هو أصدق مؤشر على الاهتمام الحقيقي — أقوى بكثير من ما تقوله عن نفسك مباشرةً.',
      whyAskedEn: 'Voluntary curiosity is the most honest indicator of genuine interest — far stronger than direct self-reporting.',
      learningOutcomeAr: 'يُحدّد النظام المجالات التي ينجذب إليها الطالب فعلاً، ويبني عليها أولويات التقييم.',
      learningOutcomeEn: 'The system identifies the domains the student is genuinely drawn to and builds assessment priorities on them.',
      relatedDomainsAr: ['جميع التخصصات الأكاديمية'],
      relatedDomainsEn: ['All academic majors'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_onboard_002 — Learning style through behavior (multipleChoice)
    // ────────────────────────────────────────────────────────────────────────
    'q_onboard_002': QuestionKnowledge(
      questionId: 'q_onboard_002',
      concepts: ['learning style', 'VARK model', 'knowledge acquisition preference'],
      keyConceptsAr: {
        'أسلوب التعلم': 'الطريقة التي يفضّلها دماغك لاستيعاب المعلومات الجديدة',
        'التجربة المباشرة': 'التعلم بالممارسة والخطأ — بدون قراءة طويلة مسبقاً',
        'النقاش': 'استكشاف الأفكار من خلال الحوار مع الآخرين',
      },
      keyConceptsEn: {
        'learning style': 'the way your brain prefers to absorb new information',
        'hands-on learning': 'learning by doing and making mistakes — without lengthy prior reading',
        'discussion': 'exploring ideas through dialogue with others',
      },
      examplesAr: [
        'طالب يفهم البرمجة عندما يجرب بنفسه، لا عندما يقرأ',
        'طالبة تفهم التاريخ بعد قراءة كتاب متعمق أكثر من مشاهدة مقطع',
        'طالب يفهم مفهوماً صعباً عندما يناقشه مع صديق',
      ],
      examplesEn: [
        'A student who understands programming when they try it themselves, not when they read',
        'A student who understands history better after reading an in-depth book than watching a video',
        'A student who grasps a difficult concept when they discuss it with a friend',
      ],
      misconceptionsAr: [
        'لا توجد طريقة تعلم أفضل من الأخرى — كل أسلوب يناسب شخصاً معيناً وبيئة دراسية معينة',
        'طريقة تعلمك تؤثر على نوع التخصص الذي ستنجح فيه',
      ],
      misconceptionsEn: [
        'No learning style is better than another — each suits a different person and academic environment',
        'Your learning style influences the type of major in which you will thrive',
      ],
      hintsAr: [
        'فكّر في آخر مرة تعلمت فيها شيئاً جديداً خارج المدرسة — ماذا فعلت؟',
        'ما الطريقة التي تجعلك تتذكر المعلومة لأطول وقت ممكن؟',
      ],
      hintsEn: [
        'Think about the last time you learned something new outside school — what did you do?',
        'Which method makes you remember information for the longest time?',
      ],
      whyAskedAr: 'أسلوب التعلم مؤشر على نوع البيئة الأكاديمية والتخصص الذي سيناسبك — نظري أم تطبيقي، فردي أم جماعي.',
      whyAskedEn: 'Learning style indicates the type of academic environment and major that will suit you — theoretical or applied, individual or collaborative.',
      learningOutcomeAr: 'يُعدّل النظام توصياته بناءً على أسلوب تعلمك لاقتراح بيئات دراسية مناسبة.',
      learningOutcomeEn: 'The system adjusts its recommendations based on your learning style to suggest suitable academic environments.',
      relatedDomainsAr: ['التعليم', 'النفس التربوي', 'الهندسة', 'العلوم التطبيقية'],
      relatedDomainsEn: ['Education', 'Educational Psychology', 'Engineering', 'Applied Sciences'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_onboard_003 — Relative academic performance (multiSelect)
    // ────────────────────────────────────────────────────────────────────────
    'q_onboard_003': QuestionKnowledge(
      questionId: 'q_onboard_003',
      concepts: ['academic performance', 'relative ability', 'subject strength'],
      keyConceptsAr: {
        'من الأوائل': 'ليس بالضرورة الأول — بل ممن يفهمون المادة أسرع وأعمق من معظم زملائهم',
        'الأداء النسبي': 'كيف مستواك مقارنةً بغيرك في نفس الفصل',
      },
      keyConceptsEn: {
        'top students': 'not necessarily first place — but among those who understand the subject faster and deeper than most classmates',
        'relative performance': 'your level compared to others in the same class',
      },
      examplesAr: [
        'طالب يُشرح لزملائه مسائل الرياضيات لأنه يفهمها بسرعة',
        'طالبة تنهي اختبار العلوم قبل الجميع وبدرجة مرتفعة باستمرار',
        'طالب يلاحظ أن الإنجليزية سهلة عليه بينما يجدها صعبة معظم زملائه',
      ],
      examplesEn: [
        'A student who explains math problems to classmates because they grasp them quickly',
        'A student who consistently finishes science tests first and scores highly',
        'A student who notices English comes easily to them while most classmates struggle',
      ],
      misconceptionsAr: [
        'لا تختار المادة التي تحبها — اختر المادة التي تتفوق فيها مقارنةً بالآخرين',
        'هذا ليس عن درجاتك بالأرقام — بل عن إحساسك بقدرتك النسبية',
        'يمكنك اختيار أكثر من مادة إذا كنت متفوقاً في أكثر من مجال',
      ],
      misconceptionsEn: [
        'Do not choose the subject you like — choose the subject where you outperform others',
        'This is not about your grades as numbers — it is about your sense of your relative ability',
        'You can select more than one subject if you excel in multiple areas',
      ],
      hintsAr: [
        'من أي مادة يطلب منك زملاؤك المساعدة؟',
        'في أي مادة تشعر أن الأمور تسير بسلاسة دون جهد كبير؟',
      ],
      hintsEn: [
        'In which subject do classmates ask you for help?',
        'In which subject do things flow smoothly for you without much effort?',
      ],
      whyAskedAr: 'الأداء الأكاديمي النسبي يساعد النظام على توصية تخصصات تتناسب مع متطلبات القبول ومستوى الصعوبة الدراسية الفعلي.',
      whyAskedEn: 'Relative academic performance helps the system recommend majors that align with admission requirements and your actual study difficulty level.',
      learningOutcomeAr: 'يُعدّل النظام ترتيب التوصيات ليُقدم تخصصات تتناسب مع قدراتك الأكاديمية الموثّقة بسلوكياتك.',
      learningOutcomeEn: 'The system adjusts recommendation rankings to present majors aligned with your documented academic abilities.',
      relatedDomainsAr: ['جميع التخصصات المتطلبة لقبول أكاديمي محدد'],
      relatedDomainsEn: ['All majors requiring specific academic admission standards'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_001 — Situational judgment: crisis response style
    // ────────────────────────────────────────────────────────────────────────
    'q_001': QuestionKnowledge(
      questionId: 'q_001',
      concepts: ['problem-solving style', 'decision-making under complexity', 'professional orientation'],
      keyConceptsAr: {
        'نموذج التوزيع': 'خوارزمية رياضية تُوزّع الموارد بكفاءة مثالية',
        'الإطار القانوني': 'القوانين والأنظمة التي تحكم قرارات المؤسسة',
        'الكوادر': 'الأشخاص المؤهلون للعمل في مجال محدد',
      },
      keyConceptsEn: {
        'distribution model': 'a mathematical algorithm for optimally allocating resources',
        'legal framework': 'the laws and regulations that govern institutional decisions',
        'cadres': 'qualified personnel for a specific field',
      },
      examplesAr: [
        'من يميل للخيار (أ) يفكر كمهندس بيانات أو مخطط استراتيجي',
        'من يميل للخيار (ب) يفكر كطبيب أو اختصاصي صحة عامة',
        'من يميل للخيار (ج) يفكر كمحامٍ أو مستشار حوكمة',
        'من يميل للخيار (د) يفكر كرائد أعمال أو مدير مشاريع',
      ],
      examplesEn: [
        'Someone drawn to option (a) thinks like a data engineer or strategic planner',
        'Someone drawn to option (b) thinks like a doctor or public health specialist',
        'Someone drawn to option (c) thinks like a lawyer or governance consultant',
        'Someone drawn to option (d) thinks like an entrepreneur or project manager',
      ],
      misconceptionsAr: [
        'لا يوجد حل صح أو غلط — المشكلة لها حلول متعددة وكلها صحيحة من زاوية مختلفة',
        'السؤال لا يقيس معرفتك بالنظام الصحي — بل أسلوب تفكيرك الطبيعي',
        'اختر ما يتبادر إلى ذهنك أولاً، لا ما تعتقد أنه "الإجابة المثالية"',
      ],
      misconceptionsEn: [
        'There is no right or wrong solution — the problem has multiple valid answers from different angles',
        'The question does not test your knowledge of healthcare — it reveals your natural thinking style',
        'Choose what comes to mind first, not what you think the "ideal" answer is',
      ],
      hintsAr: [
        'تخيّل أن هذا موقف حقيقي أمامك الآن — ما أول خطوة ستتخذها فعلاً؟',
        'فكّر في المرات التي واجهت فيها مشكلة معقدة — كيف تصرّفت عادةً؟',
      ],
      hintsEn: [
        'Imagine this is a real situation in front of you right now — what is the first step you would actually take?',
        'Think about times you faced complex problems — how did you typically respond?',
      ],
      whyAskedAr: 'أسلوب التعامل مع مشكلة حقيقية يكشف عن طريقة التفكير الطبيعية — منطقي-تحليلي، إنساني-تعاطفي، قانوني، أو قيادي.',
      whyAskedEn: 'How you approach a real-world problem reveals your natural thinking style — analytical-logical, empathetic-human, legal, or leadership-oriented.',
      learningOutcomeAr: 'يُحدّد النظام التوجه المهني الأصيل للطالب ويرتّب التخصصات المناسبة وفقاً لذلك.',
      learningOutcomeEn: 'The system identifies the student\'s authentic professional orientation and ranks suitable majors accordingly.',
      relatedDomainsAr: ['الهندسة', 'الطب', 'القانون', 'إدارة الأعمال', 'علوم البيانات'],
      relatedDomainsEn: ['Engineering', 'Medicine', 'Law', 'Business Administration', 'Data Science'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_002 — Free time behavior (multipleChoice)
    // ────────────────────────────────────────────────────────────────────────
    'q_002': QuestionKnowledge(
      questionId: 'q_002',
      concepts: ['intrinsic motivation', 'leisure behavior', 'authentic interest'],
      keyConceptsAr: {
        'وقت الفراغ الحقيقي': 'الوقت الذي لا يوجد فيه أي واجب أو التزام — اختيار حر بالكامل',
        'الألعاب الاستراتيجية': 'ألعاب تتطلب تخطيطاً مثل الشطرنج أو الألعاب الإلكترونية التكتيكية',
        'المبادرة': 'فعل شيء بدون أن يطلبه أحد',
      },
      keyConceptsEn: {
        'true free time': 'time with no duties or obligations — completely free choice',
        'strategy games': 'games requiring planning such as chess or tactical video games',
        'initiative': 'doing something without anyone asking',
      },
      examplesAr: [
        'طالب يمضي الإجازة يبني تطبيقاً صغيراً لمجرد أنه يريد تجربة برمجة',
        'طالبة تقرأ كتاب تاريخ خلال العطلة',
        'طالب يرسم ويصمم شعارات لمتعته الشخصية',
        'طالبة تتابع أخبار الأسواق المالية وتناقشها مع عائلتها',
      ],
      examplesEn: [
        'A student who spends vacation building a small app just to try programming',
        'A student who reads a history book during the holiday',
        'A student who draws and designs logos for personal enjoyment',
        'A student who follows financial market news and discusses it with family',
      ],
      misconceptionsAr: [
        'لا يوجد نشاط "أفضل" من الآخر — النظام يحتاج معرفة ما تختاره أنت فعلاً',
        'الألعاب والترفيه إذا كانت استراتيجية فهي معلومة قيّمة',
      ],
      misconceptionsEn: [
        'No activity is "better" than another — the system needs to know what you actually choose',
        'Games and entertainment, if strategic, are valuable information',
      ],
      hintsAr: [
        'تذكّر آخر إجازة طويلة — ماذا فعلت يوم ليس فيه واجبات؟',
        'ما الشيء الذي تفعله لمجرد أنه يسعدك، حتى لو لم يره أحد؟',
      ],
      hintsEn: [
        'Recall your last long holiday — what did you do on a day with no assignments?',
        'What do you do just because it makes you happy, even if no one sees it?',
      ],
      whyAskedAr: 'ما يختاره الطالب في وقت فراغه الكامل أصدق دليل على اهتمامه الحقيقي من أي سؤال مباشر.',
      whyAskedEn: 'What a student chooses in completely free time is the most honest evidence of genuine interest — stronger than any direct question.',
      learningOutcomeAr: 'يُضيف النظام هذا لدعم أو تعديل التوجه المُستنتج من الأسئلة الأولى.',
      learningOutcomeEn: 'The system uses this to support or adjust the orientation inferred from earlier questions.',
      relatedDomainsAr: ['التقنية', 'الأدب', 'الفن', 'الأعمال', 'البحث'],
      relatedDomainsEn: ['Technology', 'Literature', 'Art', 'Business', 'Research'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_003 — Priority ranking of work styles (ranking)
    // ────────────────────────────────────────────────────────────────────────
    'q_003': QuestionKnowledge(
      questionId: 'q_003',
      concepts: ['cognitive style', 'value hierarchy', 'professional identity'],
      keyConceptsAr: {
        'الترتيب': 'لا يوجد إجابة واحدة صحيحة — الترتيب يكشف أولوياتك أنت',
        'يُفكّك': 'يفهم شيئاً بتحليل أجزائه وكيف تعمل مع بعض',
        'الترتيب من الأهم للأقل': 'ضع الوصف الذي يشبهك أكثر في المرتبة الأولى',
      },
      keyConceptsEn: {
        'ranking': 'there is no single correct answer — the order reveals your personal priorities',
        'deconstruct': 'to understand something by analyzing its parts and how they work together',
        'from most to least': 'place the description that sounds most like you first',
      },
      examplesAr: [
        'طالب يضع (أ) أولاً يستمتع بفك الأجهزة وفهم عملها — يميل للهندسة والتقنية',
        'طالبة تضع (ب) أولاً تجيد النقاش والكتابة المقنعة — تميل للقانون أو الإعلام',
        'طالب يضع (ج) أولاً يبتكر حلولاً غير تقليدية — يميل للبحث أو التصميم',
        'طالبة تضع (د) أولاً تنظّم الفعاليات ومشاريع الفريق — تميل للإدارة أو ريادة الأعمال',
      ],
      examplesEn: [
        'A student ranking (a) first enjoys taking things apart to understand them — leans toward engineering or tech',
        'A student ranking (b) first excels at persuasive writing and debate — leans toward law or media',
        'A student ranking (c) first invents unconventional solutions — leans toward research or design',
        'A student ranking (d) first organizes events and team projects — leans toward management or entrepreneurship',
      ],
      misconceptionsAr: [
        'لا تحاول اختيار ما يبدو أحسن أو أذكى — اختر ما يصفك فعلاً',
        'الترتيب الصادق أكثر فائدة للنظام من الترتيب "المثالي"',
        'يمكنك أن تشعر أن أكثر من وصف ينطبق عليك — رتّبهم وفق ما هو أكثر تطابقاً',
      ],
      misconceptionsEn: [
        'Do not try to pick what sounds best or smartest — choose what genuinely describes you',
        'An honest ranking is more useful to the system than an "ideal" one',
        'You may feel more than one description applies — rank them by degree of fit',
      ],
      hintsAr: [
        'فكّر في المشاريع أو الأنشطة التي استمتعت بها حقاً — أي من هذه الأوصاف يصف ما فعلته؟',
        'ما الإنجاز الذي اعتزّ به أكثر شيء في حياتك — من أي نوع كان؟',
      ],
      hintsEn: [
        'Think about projects or activities you genuinely enjoyed — which description fits what you actually did?',
        'What achievement are you most proud of in your life — what type was it?',
      ],
      whyAskedAr: 'الترتيب يُجبر الطالب على التمييز بين قيم متقاربة، مما يُنتج نمطاً معرفياً مُركّباً يُفيد التوصية.',
      whyAskedEn: 'Ranking forces the student to differentiate between similar values, producing a nuanced cognitive pattern that informs recommendations.',
      learningOutcomeAr: 'يُبني ملف الأولويات المهنية للطالب ويُوجّه التوصيات نحو تخصصات تتوافق مع الأسلوب المعرفي المُكتشَف.',
      learningOutcomeEn: 'The system builds the student\'s professional priority profile and guides recommendations toward majors aligned with the discovered cognitive style.',
      relatedDomainsAr: ['الهندسة والتقنية', 'القانون والإعلام', 'البحث والتصميم', 'الإدارة وريادة الأعمال'],
      relatedDomainsEn: ['Engineering & Technology', 'Law & Media', 'Research & Design', 'Management & Entrepreneurship'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_004 — Spontaneous cognitive response to news (multipleChoice)
    // ────────────────────────────────────────────────────────────────────────
    'q_004': QuestionKnowledge(
      questionId: 'q_004',
      concepts: ['cognitive response', 'information processing style', 'spontaneous thinking'],
      keyConceptsAr: {
        'ردّة الفعل الأولى': 'أول فكرة تخطر ببالك قبل أن تُفكّر أو تُحلّل',
        'الاكتشاف الجديد': 'معلومة أو تقنية أو اختراع لم يكن معروفاً من قبل',
        'الجانب الأخلاقي': 'التساؤلات عن الصواب والخطأ، والآثار على المجتمع',
      },
      keyConceptsEn: {
        'first reaction': 'the first thought that comes to mind before you analyze or reflect',
        'new discovery': 'information, technology, or invention that was not previously known',
        'ethical dimension': 'questions about right and wrong, and societal impact',
      },
      examplesAr: [
        'عند سماع خبر لقاح جديد: من يفكر في "كيف يعمل الجزيء؟" يميل للعلوم الطبية',
        'من يفكر في "من سيستفيد منه؟" يميل للطب وعلم الأوبئة',
        'من يفكر في "هل هناك براءة اختراع؟" يميل للقانون أو الأعمال',
        'من يفكر في "ما فرصة الاستثمار؟" يميل لإدارة الأعمال والتمويل',
      ],
      examplesEn: [
        'Hearing about a new vaccine: someone thinking "how does the molecule work?" leans toward medical science',
        'Someone thinking "who will benefit from it?" leans toward medicine and epidemiology',
        'Someone thinking "is there a patent?" leans toward law or business',
        'Someone thinking "what is the investment opportunity?" leans toward business and finance',
      ],
      misconceptionsAr: [
        'لا يوجد ردّة فعل "صحيحة" — النظام يحتاج ردّتك الحقيقية الأولى',
        'هذا ليس اختبار معلومات عامة — بل كشف لطريقة تفكيرك الطبيعية',
      ],
      misconceptionsEn: [
        'There is no "correct" reaction — the system needs your genuine first response',
        'This is not a general knowledge test — it reveals your natural thinking pattern',
      ],
      hintsAr: [
        'تذكّر آخر مرة قرأت فيها خبراً مثيراً — ما أول شيء دار في ذهنك؟',
        'لا تفكّر — اختر الخيار الذي يصف ردّتك الأولى الأكثر تكراراً',
      ],
      hintsEn: [
        'Recall the last time you read an exciting piece of news — what was the first thing that went through your mind?',
        'Do not overthink — choose the option that best describes your most frequent first reaction',
      ],
      whyAskedAr: 'الاستجابة التلقائية للمعلومات الجديدة مؤشر أصيل على نوع التفكير السائد لدى الطالب.',
      whyAskedEn: 'Spontaneous response to new information is an authentic indicator of the student\'s dominant thinking type.',
      learningOutcomeAr: 'يُضاف هذا لتدعيم أو تعديل الأنماط المكتشفة من الأسئلة السابقة.',
      learningOutcomeEn: 'This is added to reinforce or adjust the patterns discovered from previous questions.',
      relatedDomainsAr: ['العلوم', 'الطب', 'القانون', 'الأعمال', 'التقنية'],
      relatedDomainsEn: ['Science', 'Medicine', 'Law', 'Business', 'Technology'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_005 — Hardest problem you solved (openEnded)
    // ────────────────────────────────────────────────────────────────────────
    'q_005': QuestionKnowledge(
      questionId: 'q_005',
      concepts: ['problem-solving behavior', 'self-efficacy', 'real-world evidence'],
      keyConceptsAr: {
        'المشكلة المعقدة': 'موقف لا يوجد له حل واضح وسهل — يتطلب جهداً وتفكيراً',
        'تصرّفت': 'ما الذي فعلته فعلاً — لا ما كنت ستتمنى أن تفعله',
      },
      keyConceptsEn: {
        'complex problem': 'a situation with no obvious easy solution — requires effort and thinking',
        'you acted': 'what you actually did — not what you wish you had done',
      },
      examplesAr: [
        'طالب أصلح خطأً في برنامجه الخاص لساعات — يكشف صبراً تقنياً وميلاً للتقنية',
        'طالبة أصلحت خلافاً في مجموعة عمل — تكشف قدرة على التواصل والقيادة',
        'طالب فهم مفهوماً رياضياً صعباً بنفسه بعد بحث طويل — يكشف عن تعلم ذاتي قوي',
        'طالبة نظّمت رحلة عائلية معقدة بنفسها — تكشف تخطيطاً وإدارة',
      ],
      examplesEn: [
        'A student who debugged their own program for hours — reveals technical patience and tech affinity',
        'A student who resolved a conflict in a group project — reveals communication and leadership ability',
        'A student who independently understood a hard math concept after extensive research — reveals strong self-learning',
        'A student who organized a complex family trip on their own — reveals planning and management',
      ],
      misconceptionsAr: [
        'المشكلة لا تحتاج أن تكون ضخمة أو مهمة للنظام — المهم كيف تعاملت معها',
        'الإجابة بالعامية مقبولة تماماً',
        'اكتب بصدق — لا يوجد إجابة "أحسن" من الأخرى هنا',
      ],
      misconceptionsEn: [
        'The problem does not need to be huge or important to the system — what matters is how you handled it',
        'Answering in informal language is completely acceptable',
        'Write honestly — there is no "better" answer here',
      ],
      hintsAr: [
        'فكّر في موقف شعرت فيه بالصعوبة الحقيقية ثم وجدت طريقة للتجاوز',
        'قد تكون المشكلة اجتماعية، درسية، تقنية، أو حتى شخصية',
      ],
      hintsEn: [
        'Think of a situation where you felt real difficulty and then found a way through',
        'The problem may be social, academic, technical, or even personal',
      ],
      whyAskedAr: 'الإجابة على هذا السؤال هي الدليل السلوكي الأقوى في التقييم — تُظهر كيف يتصرف الطالب فعلاً لا ما يقوله عن نفسه.',
      whyAskedEn: 'The answer to this question is the strongest behavioral evidence in the assessment — it shows how the student actually acts, not what they say about themselves.',
      learningOutcomeAr: 'يُحلّل النظام نوع المشكلة والأسلوب المُتّبع لاستخراج أبعاد معرفية متعددة في آنٍ واحد.',
      learningOutcomeEn: 'The system analyzes the type of problem and approach taken to extract multiple cognitive dimensions simultaneously.',
      relatedDomainsAr: ['جميع التخصصات'],
      relatedDomainsEn: ['All majors'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_006 — Research starting point (multipleChoice)
    // ────────────────────────────────────────────────────────────────────────
    'q_006': QuestionKnowledge(
      questionId: 'q_006',
      concepts: ['research orientation', 'inquiry approach', 'epistemic preference'],
      keyConceptsAr: {
        'المشروع البحثي': 'استكشاف منهجي لسؤال أو مشكلة تريد فهمها بعمق',
        'قابل للقياس': 'يمكن تحويله لأرقام وإثبات الإجابة بطريقة موضوعية',
        'الهامش': 'المواضيع الأقل شهرة التي لم يكتب عنها كثيرون',
      },
      keyConceptsEn: {
        'research project': 'systematic exploration of a question or problem you want to understand deeply',
        'measurable': 'can be converted to numbers and answered objectively',
        'the margin': 'lesser-known topics that few have written about',
      },
      examplesAr: [
        'الخيار (أ) يناسب: علوم البيانات، الاقتصاد الكمي، علم الأوبئة',
        'الخيار (ب) يناسب: الصحة العامة، علم الاجتماع، الخدمة الاجتماعية',
        'الخيار (ج) يناسب: الفلسفة، التاريخ، الدراسات الثقافية',
        'الخيار (د) يناسب: الهندسة التطبيقية، الطب السريري، ريادة الأعمال',
      ],
      examplesEn: [
        'Option (a) suits: data science, quantitative economics, epidemiology',
        'Option (b) suits: public health, sociology, social work',
        'Option (c) suits: philosophy, history, cultural studies',
        'Option (d) suits: applied engineering, clinical medicine, entrepreneurship',
      ],
      misconceptionsAr: [
        'لا يوجد موضوع بحثي أفضل من غيره — الاختلاف في النوع لا القيمة',
        'ليس شرطاً أن تكون باحثاً — أي شخص يتعلم يختار طريقة البحث التي تناسبه',
      ],
      misconceptionsEn: [
        'No research topic is better than another — the difference is in type, not value',
        'You do not need to be a researcher — everyone who learns chooses the research approach that suits them',
      ],
      hintsAr: [
        'فكّر في مشروع مدرسي اخترت موضوعه بنفسك — كيف بدأت؟',
        'ما الذي يُثيرك أكثر: إثبات شيء بالأرقام، أو فهم قصص الناس، أو اكتشاف زاوية جديدة؟',
      ],
      hintsEn: [
        'Think of a school project where you chose your own topic — how did you start?',
        'What excites you more: proving something with numbers, understanding people\'s stories, or discovering a new angle?',
      ],
      whyAskedAr: 'طريقة البدء بالبحث تكشف التوجه المعرفي الجوهري: كمي أم نوعي، تطبيقي أم نظري.',
      whyAskedEn: 'The research starting point reveals the fundamental cognitive orientation: quantitative or qualitative, applied or theoretical.',
      learningOutcomeAr: 'يُحدّد النظام البُعد "التطبيق مقابل النظرية" ويُعدّل توصياته وفقاً لذلك.',
      learningOutcomeEn: 'The system determines the "practical vs. theoretical" dimension and adjusts recommendations accordingly.',
      relatedDomainsAr: ['البحث العلمي', 'العلوم الاجتماعية', 'الهندسة التطبيقية', 'الإنسانيات'],
      relatedDomainsEn: ['Scientific Research', 'Social Sciences', 'Applied Engineering', 'Humanities'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_007 — Type of academic success that feels most rewarding (multipleChoice)
    // ────────────────────────────────────────────────────────────────────────
    'q_007': QuestionKnowledge(
      questionId: 'q_007',
      concepts: ['academic motivation', 'intrinsic reward', 'success definition'],
      keyConceptsAr: {
        'الرضا الحقيقي': 'الشعور الداخلي بالرضا — ليس التقدير أو رأي الآخرين',
        'حل المسألة المعقدة': 'إيجاد إجابة صحيحة لسؤال لم تكن إجابته واضحة',
        'الإنتاج المبتكر': 'خلق شيء لم يكن موجوداً من قبل بطريقة أصيلة',
      },
      keyConceptsEn: {
        'genuine satisfaction': 'inner feeling of fulfillment — not grades or others\' opinions',
        'solving a complex problem': 'finding a correct answer to a question without an obvious solution',
        'innovative output': 'creating something that did not previously exist in an original way',
      },
      examplesAr: [
        'من يُقدّر (أ): طلاب الرياضيات والفيزياء والبرمجة الخوارزمية',
        'من يُقدّر (ب): طلاب القانون والإعلام والعلاقات العامة',
        'من يُقدّر (ج): طلاب البحث العلمي والفن والأدب والتصميم',
        'من يُقدّر (د): طلاب الهندسة والطب التطبيقي وريادة الأعمال',
      ],
      examplesEn: [
        'Those who value (a): math, physics, and algorithmic programming students',
        'Those who value (b): law, media, and public relations students',
        'Those who value (c): scientific research, art, literature, and design students',
        'Those who value (d): engineering, applied medicine, and entrepreneurship students',
      ],
      misconceptionsAr: [
        'فكّر في ما يُشعرك فعلاً بالرضا — ليس ما يُرضي المجتمع أو والديك',
        'الإجابة الصادقة أكثر فائدة بكثير من الإجابة "الصواب"',
      ],
      misconceptionsEn: [
        'Think about what genuinely makes you feel satisfied — not what satisfies society or your parents',
        'The honest answer is far more useful than the "correct" answer',
      ],
      hintsAr: [
        'تذكّر آخر مرة شعرت فيها بإنجاز حقيقي — ماذا كان؟',
        'أي نوع من العمل يجعلك تنسى الوقت؟',
      ],
      hintsEn: [
        'Recall the last time you felt a genuine sense of accomplishment — what was it?',
        'What type of work makes you lose track of time?',
      ],
      whyAskedAr: 'نوع النجاح الأكاديمي الذي يُشعر الطالب بالرضا يكشف دافعيته الجوهرية ويوجّه التوصية نحو تخصصات تُلبّي هذه الدافعية.',
      whyAskedEn: 'The type of academic success that makes the student feel satisfied reveals their core motivation and guides recommendations toward majors that fulfill it.',
      learningOutcomeAr: 'يُبني النظام ملف الدافعية الجوهرية للطالب.',
      learningOutcomeEn: 'The system builds the student\'s core motivation profile.',
      relatedDomainsAr: ['الرياضيات', 'القانون', 'الإبداع والبحث', 'الهندسة والطب'],
      relatedDomainsEn: ['Mathematics', 'Law', 'Creativity & Research', 'Engineering & Medicine'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_008 — How you help a friend with a problem (situationalJudgment)
    // ────────────────────────────────────────────────────────────────────────
    'q_008': QuestionKnowledge(
      questionId: 'q_008',
      concepts: ['interpersonal style', 'empathy vs. logic', 'helping orientation'],
      keyConceptsAr: {
        'أُنصت أولاً': 'الاستماع بدون حكم قبل إعطاء أي رأي أو حل',
        'الخطة المنطقية': 'سلسلة من الخطوات العملية المبنية على تحليل المشكلة',
        'التوجيه لمتخصص': 'الاعتراف بحدود قدرتك وإرشاده لمن هو أقدر',
      },
      keyConceptsEn: {
        'listen first': 'hearing without judgment before offering any opinion or solution',
        'logical plan': 'a sequence of practical steps built on analyzing the problem',
        'refer to a specialist': 'recognizing your limits and directing them to someone more capable',
      },
      examplesAr: [
        'من يختار (أ): يفكر كمهندس أو مخطط — يميل للتحليل والحلول المنظّمة',
        'من يختار (ب): يفكر كمعالج نفسي أو طبيب — يُقدّم الاستماع والتعاطف',
        'من يختار (ج): يفكر كمصمم أو مبتكر — يُجرّب حتى يجد ما يناسب',
        'من يختار (د): يفكر كمنسّق أو مدير — يُدير الموارد بكفاءة',
      ],
      examplesEn: [
        'Who chooses (a): thinks like an engineer or planner — leans toward analysis and structured solutions',
        'Who chooses (b): thinks like a therapist or doctor — prioritizes listening and empathy',
        'Who chooses (c): thinks like a designer or innovator — experiments until finding what fits',
        'Who chooses (d): thinks like a coordinator or manager — manages resources efficiently',
      ],
      misconceptionsAr: [
        'لا يوجد طريقة مساعدة "صح" — الجميع يُساعد بطريقته الطبيعية',
        'فكّر في ما تفعله فعلاً لا ما تعتقد أنه "الصواب"',
      ],
      misconceptionsEn: [
        'There is no "correct" helping style — everyone helps in their natural way',
        'Think about what you actually do, not what you think is "right"',
      ],
      hintsAr: [
        'تذكّر آخر مرة ساعدت فيها أحداً بمشكلة — ما أول شيء فعلته؟',
      ],
      hintsEn: [
        'Recall the last time you helped someone with a problem — what was the first thing you did?',
      ],
      whyAskedAr: 'أسلوب المساعدة الطبيعي مؤشر على التوجه المهني: هل يُفضّل الطالب العمل مع الأنظمة أم مع البشر، ومع الأفكار أم مع الحلول التطبيقية.',
      whyAskedEn: 'Natural helping style indicates professional orientation: does the student prefer working with systems or people, with ideas or applied solutions.',
      learningOutcomeAr: 'يُعزّز أو يُعدّل النظام بُعد التعاطف والتوجه الإنساني في الملف المعرفي.',
      learningOutcomeEn: 'The system reinforces or adjusts the empathy and human orientation dimension in the cognitive profile.',
      relatedDomainsAr: ['الطب النفسي', 'الطب', 'الهندسة', 'الإدارة', 'التصميم'],
      relatedDomainsEn: ['Psychiatry', 'Medicine', 'Engineering', 'Management', 'Design'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_009 — Personal project you completed (openEnded)
    // ────────────────────────────────────────────────────────────────────────
    'q_009': QuestionKnowledge(
      questionId: 'q_009',
      concepts: ['self-initiative', 'project completion', 'domain signal'],
      keyConceptsAr: {
        'بمبادرتك': 'بدأت المشروع بنفسك دون أن يطلبه منك أحد',
        'أنهيته': 'وصلت لنتيجة — حتى لو لم تكن مثالية',
        'مشروع': 'أي إنجاز يحمل جهداً ووقتاً ونتيجة — لا يشترط أن يكون ضخماً',
      },
      keyConceptsEn: {
        'on your initiative': 'you started the project on your own without anyone asking',
        'you completed it': 'you reached a result — even if not perfect',
        'project': 'any achievement that required effort, time, and a result — does not have to be large',
      },
      examplesAr: [
        'برنامج صغير أو موقع إنترنت طورته بنفسك',
        'بحث أو مقال كتبته عن موضوع يستهويك',
        'عمل فني أو موسيقي أو تصميمي أنهيته',
        'مبادرة اجتماعية أو خيرية نظّمتها',
        'نموذج أو اختراع صغير بنيته',
      ],
      examplesEn: [
        'A small program or website you developed yourself',
        'A research paper or article you wrote on a topic that interests you',
        'An artistic, musical, or design work you completed',
        'A social or charitable initiative you organized',
        'A model or small invention you built',
      ],
      misconceptionsAr: [
        'المشروع لا يحتاج أن يكون "مثيراً للإعجاب" — المهم أنك أنهيته',
        'إذا لم يكن لديك مشروع بهذا الوصف، صِف شيئاً قربت الانتهاء منه',
      ],
      misconceptionsEn: [
        'The project does not need to be "impressive" — what matters is that you completed it',
        'If you have no project matching this description, describe something you came close to finishing',
      ],
      hintsAr: [
        'فكّر في ما تفخر به أنت — لا ما يستحق إعجاب الآخرين',
        'حتى الأشياء الصغيرة تُعطي النظام معلومة قيّمة عن توجهك',
      ],
      hintsEn: [
        'Think about what you are proud of yourself — not what impresses others',
        'Even small things give the system valuable information about your direction',
      ],
      whyAskedAr: 'نوع المشروع المكتمل أقوى دليل سلوكي على اهتمامات الطالب وقدراته الفعلية.',
      whyAskedEn: 'The type of completed project is the strongest behavioral evidence of the student\'s genuine interests and actual abilities.',
      learningOutcomeAr: 'يستخرج النظام إشارات متعددة: المجال، المهارة، الأسلوب، والمبادرة الذاتية.',
      learningOutcomeEn: 'The system extracts multiple signals: domain, skill, style, and self-initiative.',
      relatedDomainsAr: ['جميع التخصصات'],
      relatedDomainsEn: ['All majors'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_010 — Professional values ranking (ranking)
    // ────────────────────────────────────────────────────────────────────────
    'q_010': QuestionKnowledge(
      questionId: 'q_010',
      concepts: ['value hierarchy', 'career motivation', 'professional identity'],
      keyConceptsAr: {
        'الاستقرار المالي': 'الحصول على دخل كافٍ ومستقر يُؤمّن مستقبلك',
        'الابتكار': 'إنتاج أشياء جديدة لم تكن موجودة من قبل',
        'إحداث الأثر': 'تغيير حقيقي في حياة الآخرين بشكل ملموس',
        'الإنجازات الملموسة': 'نتائج يمكن قياسها: شركة، مبنى، منتج، فريق',
      },
      keyConceptsEn: {
        'financial stability': 'obtaining sufficient and stable income to secure your future',
        'innovation': 'producing new things that did not previously exist',
        'impact': 'real change in others\' lives in a tangible way',
        'tangible achievements': 'measurable results: a company, building, product, or team',
      },
      examplesAr: [
        'من يُقدّم (أ) أولاً: يميل للمهن ذات الدخل المرتفع والاستقرار — الطب، الهندسة، المالية',
        'من يُقدّم (ب) أولاً: يميل للبحث والتصميم وريادة الأعمال والفن',
        'من يُقدّم (ج) أولاً: يميل للطب، التعليم، الخدمة الاجتماعية، القانون الإنساني',
        'من يُقدّم (د) أولاً: يميل للقيادة، إدارة الأعمال، الهندسة التطبيقية',
      ],
      examplesEn: [
        'Those ranking (a) first: lean toward high-income stable professions — medicine, engineering, finance',
        'Those ranking (b) first: lean toward research, design, entrepreneurship, and art',
        'Those ranking (c) first: lean toward medicine, education, social work, humanitarian law',
        'Those ranking (d) first: lean toward leadership, business management, applied engineering',
      ],
      misconceptionsAr: [
        'لا تختار ما يبدو أنبل أو أذكى — اختر ما يمثّل قيمتك الحقيقية',
        'الاستقرار المالي قيمة محترمة تماماً مثل خدمة المجتمع',
      ],
      misconceptionsEn: [
        'Do not choose what sounds noblest or smartest — choose what represents your genuine value',
        'Financial stability is a perfectly respectable value, just like community service',
      ],
      hintsAr: [
        'تخيّل أن لديك وظيفتين براتب متساوٍ — أيهما ستختار؟ قيمة اخترها هي الأهم',
        'فكّر في ما ستندم على غيابه في عملك بعد عشر سنوات',
      ],
      hintsEn: [
        'Imagine you have two jobs with equal pay — which would you choose? The value behind that choice is your top priority',
        'Think about what you would regret missing in your work ten years from now',
      ],
      whyAskedAr: 'ترتيب القيم المهنية يكشف البوصلة الداخلية التي ستوجّه قرارات الطالب المهنية طوال حياته.',
      whyAskedEn: 'The professional values ranking reveals the internal compass that will guide the student\'s career decisions throughout their life.',
      learningOutcomeAr: 'يُبني النظام ملف القيم المهنية ويُعدّل التوصيات لتتوافق مع الأولويات المُختارة.',
      learningOutcomeEn: 'The system builds a professional values profile and adjusts recommendations to align with the chosen priorities.',
      relatedDomainsAr: ['جميع التخصصات'],
      relatedDomainsEn: ['All majors'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_011 — Career environment scenario (situationalJudgment)
    // ────────────────────────────────────────────────────────────────────────
    'q_011': QuestionKnowledge(
      questionId: 'q_011',
      concepts: ['career environment preference', 'work context fit', 'professional scenario'],
      keyConceptsAr: {
        'في مكانك الصحيح': 'الشعور بأنك تفعل ما خُلقت له — بدون إجهاد أو تكلّف',
        'أُشخّص حالته': 'أفهم المشكلة الطبية وأحدد سببها وعلاجها',
        'حجة قانونية': 'استدلال منطقي منظّم يُقنع القاضي أو الجمهور بموقف محدد',
      },
      keyConceptsEn: {
        'in your right place': 'feeling that you are doing what you were meant for — without strain or pretense',
        'diagnose': 'understand the medical problem and determine its cause and treatment',
        'legal argument': 'organized logical reasoning that convinces a judge or audience of a specific position',
      },
      examplesAr: [
        'من يختار (أ): يرتاح مع الأنظمة التقنية — يميل لعلوم الحاسب أو الهندسة البرمجية',
        'من يختار (ب): يجد معنى في صحة الآخرين — يميل للطب أو التمريض',
        'من يختار (ج): يزدهر في الإقناع العام — يميل للقانون أو الإعلام أو التدريس',
        'من يختار (د): يشحن بقيادة الفرق نحو أهداف — يميل لإدارة الأعمال أو ريادة الأعمال',
        'من يختار (هـ): يبدع في المساحة الانعزالية — يميل للكتابة أو التصميم أو الفن',
      ],
      examplesEn: [
        'Who chooses (a): comfortable with technical systems — leans toward CS or software engineering',
        'Who chooses (b): finds meaning in others\' health — leans toward medicine or nursing',
        'Who chooses (c): thrives in public persuasion — leans toward law, media, or teaching',
        'Who chooses (d): energized by leading teams toward goals — leans toward business management or entrepreneurship',
        'Who chooses (e): creative in isolated space — leans toward writing, design, or art',
      ],
      misconceptionsAr: [
        'تخيّل نفسك في الموقف فعلاً — لا تختر ما يبدو مثيراً من الخارج',
        'السؤال عن بيئة العمل لا عن صعوبة التخصص',
      ],
      misconceptionsEn: [
        'Actually imagine yourself in the scenario — do not choose what sounds exciting from the outside',
        'This question is about work environment, not about major difficulty',
      ],
      hintsAr: [
        'أيّ من هذه المشاهد يُشعرك بالطاقة لا بالتعب عند تخيّله؟',
        'ليس كل ما يبدو مثيراً يصلح بيئة عمل لك — فكّر في ما يُريحك بعد ساعات',
      ],
      hintsEn: [
        'Which of these scenarios energizes you rather than exhausting you when you imagine it?',
        'Not everything that sounds exciting makes a suitable work environment for you — think about what still feels comfortable after hours',
      ],
      whyAskedAr: 'بيئة العمل المفضّلة من أدق مؤشرات التوافق المهني — أدق من اسم التخصص نفسه.',
      whyAskedEn: 'Preferred work environment is one of the most precise indicators of professional fit — more precise than the major name itself.',
      learningOutcomeAr: 'يُحدّد النظام بيئة العمل المُفضَّلة ويرتّب التخصصات التي توفّر هذه البيئة.',
      learningOutcomeEn: 'The system identifies the preferred work environment and ranks majors that provide it.',
      relatedDomainsAr: ['جميع التخصصات'],
      relatedDomainsEn: ['All majors'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_012 — Free year behavioral aspiration (openEnded)
    // ────────────────────────────────────────────────────────────────────────
    'q_012': QuestionKnowledge(
      questionId: 'q_012',
      concepts: ['core aspiration', 'intrinsic motivation', 'unconstrained preference'],
      keyConceptsAr: {
        'بلا التزامات': 'لا دراسة، لا عمل، لا مسؤوليات — حرية كاملة',
        'ما ستفعله فعلاً': 'ليس ما يجب عليك فعله — بل ما تختاره أنت حين لا يراقبك أحد',
      },
      keyConceptsEn: {
        'no obligations': 'no study, no work, no responsibilities — complete freedom',
        'what you would actually do': 'not what you should do — what you would choose when no one is watching',
      },
      examplesAr: [
        'طالب يُجيب: "أبني تطبيقاً وأتعلم الذكاء الاصطناعي" — إشارة قوية للتقنية',
        'طالبة تُجيب: "أسافر وأتعلم لغات جديدة" — إشارة للإنسانيات والتواصل الثقافي',
        'طالب يُجيب: "أكتب رواية" — إشارة للأدب والإبداع',
        'طالبة تُجيب: "أبدأ مشروعاً صغيراً" — إشارة للأعمال وريادة الأعمال',
      ],
      examplesEn: [
        'A student answering: "I would build an app and learn AI" — strong signal for technology',
        'A student answering: "I would travel and learn new languages" — signal for humanities and cultural communication',
        'A student answering: "I would write a novel" — signal for literature and creativity',
        'A student answering: "I would start a small project" — signal for business and entrepreneurship',
      ],
      misconceptionsAr: [
        'لا تكتب ما يُرضي الآخرين — هذه إجابة بينك وبين نفسك',
        'لا يوجد إجابة "أشرف" من الأخرى — الصدق هو الإجابة الأفضل',
      ],
      misconceptionsEn: [
        'Do not write what pleases others — this answer is between you and yourself',
        'No answer is "more honorable" than another — honesty is the best answer',
      ],
      hintsAr: [
        'تخيّل أن أحداً لن يعرف إجابتك — ماذا ستختار؟',
        'ما الذي تحلم به لكنك تؤجّله دائماً بسبب الدراسة أو الالتزامات؟',
      ],
      hintsEn: [
        'Imagine no one will know your answer — what would you choose?',
        'What do you dream of but always postpone because of studies or obligations?',
      ],
      whyAskedAr: 'ما يختاره الطالب حين لا توجد قيود هو أصدق تعبير عن دوافعه الجوهرية غير المُشوَّهة.',
      whyAskedEn: 'What a student chooses when there are no constraints is the most honest expression of their unconditioned core motivations.',
      learningOutcomeAr: 'يُضيف النظام هذا كطبقة تحقق للتوجه المُستنتج من الأسئلة السابقة.',
      learningOutcomeEn: 'The system uses this as a verification layer for the orientation inferred from previous questions.',
      relatedDomainsAr: ['جميع التخصصات'],
      relatedDomainsEn: ['All majors'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_013 — Productive environment from experience (multipleChoice)
    // ────────────────────────────────────────────────────────────────────────
    'q_013': QuestionKnowledge(
      questionId: 'q_013',
      concepts: ['work environment preference', 'peak performance context', 'environmental fit'],
      keyConceptsAr: {
        'تُنتج وتُبدع': 'تشعر بالتدفق والطاقة والقدرة على الإنجاز',
        'مشاكل تقنية محددة': 'مسائل لها إجابة واحدة صحيحة يمكن التحقق منها',
        'مساحات مفتوحة': 'بيئات لا توجد فيها قواعد صارمة أو إجابة واحدة محددة',
      },
      keyConceptsEn: {
        'produce and create': 'feeling flow, energy, and the ability to achieve',
        'specific technical problems': 'problems with one correct verifiable answer',
        'open spaces': 'environments with no rigid rules or single defined answer',
      },
      examplesAr: [
        'من يختار (أ): يتفوق في حل المسائل — يناسبه الهندسة والتقنية والرياضيات التطبيقية',
        'من يختار (ب): يتفوق مع الناس — يناسبه الطب والنفس والخدمة الاجتماعية',
        'من يختار (ج): يتفوق في الحرية الإبداعية — يناسبه الفن والتصميم والكتابة',
        'من يختار (د): يتفوق في تحقيق الأهداف التنظيمية — يناسبه الإدارة والقيادة',
      ],
      examplesEn: [
        'Who chooses (a): excels in solving problems — suited for engineering, tech, applied math',
        'Who chooses (b): excels with people — suited for medicine, psychology, social work',
        'Who chooses (c): excels in creative freedom — suited for art, design, writing',
        'Who chooses (d): excels in achieving organizational goals — suited for management and leadership',
      ],
      misconceptionsAr: [
        'أجب بناءً على تجاربك الفعلية — لا على ما تتصوّره',
        'فكّر في الأوقات التي كنت فيها في "عنصرك" — ما طبيعة المهمة؟',
      ],
      misconceptionsEn: [
        'Answer based on your actual experiences — not your imagination',
        'Think about times you were "in your element" — what was the nature of the task?',
      ],
      hintsAr: [
        'ما الموقف الذي تقول فيه "هذا أنا" — حين تُنجز بسهولة وبهجة؟',
      ],
      hintsEn: [
        'What situation makes you say "this is me" — when you achieve easily and joyfully?',
      ],
      whyAskedAr: 'بيئة الأداء الأعلى مؤشر على نوع العمل والتخصص الذي سيُحقق للطالب أفضل نتائج.',
      whyAskedEn: 'Peak performance environment indicates the type of work and major that will yield the student\'s best results.',
      learningOutcomeAr: 'يُعزّز النظام التوصيات ذات البيئة المتوافقة ويُخفّض تقييم التوصيات التي تتعارض مع بيئة الطالب.',
      learningOutcomeEn: 'The system reinforces recommendations with compatible environments and reduces ratings of recommendations conflicting with the student\'s environment.',
      relatedDomainsAr: ['الهندسة', 'الطب', 'الإبداع', 'الإدارة'],
      relatedDomainsEn: ['Engineering', 'Medicine', 'Creativity', 'Management'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_014 — Tasks you enjoy without being asked (multipleChoice)
    // ────────────────────────────────────────────────────────────────────────
    'q_014': QuestionKnowledge(
      questionId: 'q_014',
      concepts: ['genuine enjoyment', 'voluntary engagement', 'intrinsic aptitude'],
      keyConceptsAr: {
        'بمتعة حقيقية': 'لا تشعر بعبء المهمة — بل تنجذب إليها طبيعياً',
        'بدون أن يطلبه أحد': 'تفعله باختيارك الحر دون أي إلزام خارجي',
        'تجربة أشياء علمياً': 'تطبيق المنهج العلمي: لاحِظ، جرّب، استنتج',
      },
      keyConceptsEn: {
        'genuine enjoyment': 'you do not feel the task as a burden — you are naturally drawn to it',
        'without being asked': 'you do it by free choice without any external obligation',
        'experiment scientifically': 'applying the scientific method: observe, test, conclude',
      },
      examplesAr: [
        'من يختار (أ): يحلّل جداول البيانات للمتعة — يميل لعلوم البيانات والاقتصاد',
        'من يختار (ب): يُجري تجارب في المنزل — يميل للعلوم التجريبية والبحث',
        'من يختار (ج): يُقنع الآخرين بأفكاره بسهولة — يميل للقانون والإعلام',
        'من يختار (د): يصمم حلولاً تعمل فعلاً — يميل للهندسة والتقنية',
      ],
      examplesEn: [
        'Who chooses (a): analyzes spreadsheets for fun — leans toward data science and economics',
        'Who chooses (b): conducts experiments at home — leans toward experimental science and research',
        'Who chooses (c): easily persuades others with their ideas — leans toward law and media',
        'Who chooses (d): designs solutions that actually work — leans toward engineering and technology',
      ],
      misconceptionsAr: [
        'المتعة الحقيقية تعني عدم الشعور بالوقت — لا مجرد الاستمتاع النسبي',
        'اختر ما تُفضّله على جميع الخيارات الأخرى',
      ],
      misconceptionsEn: [
        'Genuine enjoyment means not noticing time — not just relative preference',
        'Choose what you prefer over all other options',
      ],
      hintsAr: [
        'فكّر في ما تفعله بشكل متكرر دون أن تُدرك أنك تُعيد فعله',
        'ما المهمة التي تبدأها وتنسى الوقت حتى تنتهي؟',
      ],
      hintsEn: [
        'Think about what you repeatedly do without realizing you are repeating it',
        'What task do you start and then forget time until you finish?',
      ],
      whyAskedAr: 'ما يُنجزه الطالب بمتعة دون إجبار هو أكثر المؤشرات موثوقيةً على الميل الحقيقي.',
      whyAskedEn: 'What a student accomplishes with enjoyment without compulsion is the most reliable indicator of genuine inclination.',
      learningOutcomeAr: 'يُضيف النظام هذا لتقوية إشارات المجالات التي ظهرت في الأسئلة السابقة.',
      learningOutcomeEn: 'The system uses this to strengthen domain signals that appeared in previous questions.',
      relatedDomainsAr: ['علوم البيانات', 'العلوم التجريبية', 'القانون والإعلام', 'الهندسة والتقنية'],
      relatedDomainsEn: ['Data Science', 'Experimental Science', 'Law & Media', 'Engineering & Technology'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_015 — Self-assessed major fit (multipleChoice)
    // ────────────────────────────────────────────────────────────────────────
    'q_015': QuestionKnowledge(
      questionId: 'q_015',
      concepts: ['self-assessment', 'major alignment', 'calibration check'],
      keyConceptsAr: {
        'تبدع وتجد نفسك': 'تُنتج بجهد أقل، تشعر بالتدفق، وترى نتائج أفضل من غيرك',
        'بناءً على تجاربك': 'ليس بناءً على الصورة الخارجية للتخصص — بل ما عشته فعلاً',
        'لا على ما يبدو مثيراً': 'المهنة المثيرة للإعجاب قد لا تكون البيئة التي تُبدع فيها',
      },
      keyConceptsEn: {
        'thrive and find yourself': 'produce with less effort, feel flow, and see better results than others',
        'based on your experiences': 'not based on the external image of the major — but what you have actually lived',
        'not on what sounds exciting': 'an impressive-sounding profession may not be the environment where you thrive',
      },
      examplesAr: [
        'الخيار (أ) تقني: مناسب لمن يُبرمج بمتعة ويحب حل مسائل المنطق',
        'الخيار (ب) هندسة: مناسب لمن يُحب الرياضيات والتطبيق وبناء الأشياء',
        'الخيار (ج) طب: مناسب لمن يجمع بين العلوم القوية والرغبة الصادقة في مساعدة المرضى',
        'الخيار (د) أعمال: مناسب لمن يُفكر تجارياً ويُحب القيادة والتأثير الاقتصادي',
        'الخيار (هـ) إنسانيات: مناسب لمن يُجيد التعبير، يُحب اللغة، يهتم بالعدالة والأدب',
      ],
      examplesEn: [
        'Option (a) tech: suitable for those who enjoy programming and love solving logic problems',
        'Option (b) engineering: suitable for those who love math, application, and building things',
        'Option (c) medicine: suitable for those combining strong sciences with genuine desire to help patients',
        'Option (d) business: suitable for those who think commercially and love leadership and economic impact',
        'Option (e) humanities: suitable for those who excel at expression, love language, and care about justice and literature',
      ],
      misconceptionsAr: [
        'لا تختار التخصص الذي يُعجب الآخرين — اختر ما تُبدع فيه أنت',
        'كل تخصص يحتاج ميولاً ومهارات معينة — ليس كلها متساوية عندك',
        'الطب والهندسة مثيرا الإعجاب لكنهما يتطلبان ميولاً محددة جداً',
      ],
      misconceptionsEn: [
        'Do not choose the major that impresses others — choose where you actually excel',
        'Every major requires specific inclinations and skills — not all are equal in you',
        'Medicine and engineering are impressive but require very specific inclinations',
      ],
      hintsAr: [
        'فكّر في المواد التي تفهمها بسهولة وتُنجز فيها بجهد أقل',
        'ما التخصص الذي لو دخلت الجامعة غداً تشعر أنك ستُبدع فيه؟',
      ],
      hintsEn: [
        'Think about subjects you understand easily and accomplish with less effort',
        'If you started university tomorrow, which major do you feel you would excel in?',
      ],
      whyAskedAr: 'هذا سؤال المعايرة النهائي — يُقارن النظام إجابته بما استنتجه من الأسئلة السابقة ليُعدّل التوصية النهائية.',
      whyAskedEn: 'This is the final calibration question — the system compares its answer with what it inferred from previous questions to adjust the final recommendation.',
      learningOutcomeAr: 'يُعدّل النظام ترتيب التوصيات ليتوافق مع تقييم الطالب الذاتي الأخير.',
      learningOutcomeEn: 'The system adjusts recommendation rankings to align with the student\'s final self-assessment.',
      relatedDomainsAr: ['جميع التخصصات الجامعية'],
      relatedDomainsEn: ['All university majors'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_016 — AI Black Box: Theory vs Application (CS/AI vs SWE discriminator)
    // ────────────────────────────────────────────────────────────────────────
    'q_016': QuestionKnowledge(
      questionId: 'q_016',
      concepts: ['theoretical vs applied orientation', 'AI understanding', 'software engineering mindset'],
      keyConceptsAr: {
        'صندوق أسود': 'نظام ينتج نتائج لكن لا أحد يفهم سبب عمله داخلياً',
        'خوارزمية': 'مجموعة خطوات منطقية يتبعها الحاسب لحل مشكلة',
        'التحقق الإحصائي': 'استخدام الأرقام والبيانات للتأكد من صحة نتيجة',
      },
      keyConceptsEn: {
        'black box': 'a system that produces results but no one understands why it works internally',
        'algorithm': 'a set of logical steps a computer follows to solve a problem',
        'statistical validation': 'using numbers and data to verify the correctness of a result',
      },
      examplesAr: [
        'طالب CS يريد أن يفهم رياضيات الشبكات العصبية — يشتري كتاب Deep Learning ويقرأه',
        'طالب SWE يريد تطبيق AI في منتجه — يستخدم TensorFlow مباشرة دون دراسة نظريته',
        'طالب Data Science يتحقق من دقة النموذج بحساب precision وrecall قبل النشر',
      ],
      examplesEn: [
        'A CS student who wants to understand neural network mathematics buys a Deep Learning textbook',
        'A SWE student who wants AI in their product uses TensorFlow directly without studying the theory',
        'A Data Science student verifies model accuracy by computing precision and recall before deployment',
      ],
      misconceptionsAr: [
        'ليس هناك إجابة صح أو غلط — كل خيار يناسب تخصصاً مختلفاً',
        'الرغبة في الفهم النظري ليست أفضل من التطبيق العملي — كلاهما قيّم بطريقته',
      ],
      misconceptionsEn: [
        'There is no right or wrong answer — each option suits a different major',
        'Wanting theoretical understanding is not better than practical application — both are valuable',
      ],
      hintsAr: [
        'فكّر في آخر مرة تعلمت فيها شيئاً تقنياً — هل بدأت بالنظرية أم التطبيق؟',
        'تذكر ما يشغل ذهنك حين تسمع عن تقنية جديدة',
      ],
      hintsEn: [
        'Think about the last time you learned something technical — did you start with theory or practice?',
        'Remember what occupies your mind when you hear about a new technology',
      ],
      whyAskedAr: 'يُفرّق هذا السؤال بين الذكاء الاصطناعي (يحتاج فهم نظري عميق)، وهندسة البرمجيات (تطبيق عملي)، وعلوم البيانات (تحقق إحصائي).',
      whyAskedEn: 'This question distinguishes between AI (needs deep theoretical understanding), Software Engineering (practical application), and Data Science (statistical verification).',
      learningOutcomeAr: 'يُعدّل النظام الأولوية بين تخصصات التقنية الثلاثة بناءً على التوجه النظري أو التطبيقي للطالب.',
      learningOutcomeEn: 'The system adjusts priority among the three tech majors based on the student\'s theoretical vs applied orientation.',
      relatedDomainsAr: ['الذكاء الاصطناعي', 'هندسة البرمجيات', 'علوم البيانات', 'علوم الحاسب'],
      relatedDomainsEn: ['Artificial Intelligence', 'Software Engineering', 'Data Science', 'Computer Science'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_017 — Medical data project: role preference (Data Science vs SWE vs Medicine)
    // ────────────────────────────────────────────────────────────────────────
    'q_017': QuestionKnowledge(
      questionId: 'q_017',
      concepts: ['data modeling vs system building', 'empathy in technical work', 'research vs engineering'],
      keyConceptsAr: {
        'نموذج إحصائي': 'خوارزمية تتعلم من البيانات التاريخية للتنبؤ بأحداث مستقبلية',
        'نظام تنبيه': 'برنامج يُرسل إشعاراً تلقائياً حين يكتشف حالة خطرة',
        'بيانات المرضى': 'معلومات طبية محفوظة لكل مريض كالأعراض، التشخيص، والعلاج',
      },
      keyConceptsEn: {
        'statistical model': 'an algorithm that learns from historical data to predict future events',
        'alert system': 'a program that sends an automatic notification when it detects a dangerous case',
        'patient data': 'medical information stored for each patient: symptoms, diagnosis, treatment',
      },
      examplesAr: [
        'عالم بيانات يبني نموذج regression يتنبأ بخطر السكتة الدماغية بدقة 92%',
        'مهندس برمجيات يبني API يربط نظام التنبيه بهاتف الطبيب المناوب',
        'طبيب باحث يحلل البيانات لاكتشاف عوامل خطر جديدة وينشر ورقة علمية',
      ],
      examplesEn: [
        'A data scientist builds a regression model that predicts stroke risk with 92% accuracy',
        'A software engineer builds an API connecting the alert system to the on-call doctor\'s phone',
        'A physician researcher analyzes data to discover new risk factors and publishes a paper',
      ],
      misconceptionsAr: [
        'التحدث مع المرضى وفهم احتياجاتهم ليس أقل قيمة من بناء النماذج — هذا جوهر الطب',
        'بناء النظام التقني لا يعني عدم الاهتمام بالمريض — لكنه تخصص مختلف',
      ],
      misconceptionsEn: [
        'Talking to patients and understanding their needs is not less valuable than building models — it\'s the core of medicine',
        'Building the technical system doesn\'t mean not caring about the patient — it\'s just a different specialty',
      ],
      hintsAr: [
        'أيّ الأدوار يُشعرك أنك «في مكانك» — لا أيّها يبدو أكثر أهمية',
        'تخيّل يومك الكامل في كل دور — أيّها يُرهقك وأيّها يُنشّطك؟',
      ],
      hintsEn: [
        'Which role makes you feel «in your element» — not which seems more important',
        'Imagine your full day in each role — which exhausts you and which energizes you?',
      ],
      whyAskedAr: 'يُقيس هذا السؤال الفرق بين ميل الطالب لعلوم البيانات (نماذج إحصائية)، هندسة البرمجيات (بناء أنظمة)، البحث العلمي (نشر)، والطب (مريض محوري).',
      whyAskedEn: 'Measures the difference between data science inclination (statistical models), software engineering (system building), scientific research (publishing), and medicine (patient-centric).',
      learningOutcomeAr: 'يُحدد النظام أيّ من تخصصات التقنية أو الصحة يتوافق أكثر مع الدور المُفضَّل.',
      learningOutcomeEn: 'The system determines which tech or health major aligns most with the preferred role.',
      relatedDomainsAr: ['علوم البيانات', 'هندسة البرمجيات', 'الطب', 'البحث العلمي'],
      relatedDomainsEn: ['Data Science', 'Software Engineering', 'Medicine', 'Scientific Research'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_018 — Mathematics depth (key differentiator for AI/Data Science)
    // ────────────────────────────────────────────────────────────────────────
    'q_018': QuestionKnowledge(
      questionId: 'q_018',
      concepts: ['mathematical aptitude', 'self-directed problem solving', 'difficulty tolerance'],
      keyConceptsAr: {
        'الاحتمالات': 'فرع الرياضيات الذي يدرس درجة إمكانية حدوث أحداث',
        'التوزيعات الإحصائية': 'طريقة لوصف كيف تتوزع القيم في مجموعة بيانات',
        'المكتبة البرمجية': 'كود جاهز يحل مشكلة معينة يمكن استخدامه مباشرة',
      },
      keyConceptsEn: {
        'probability': 'the branch of mathematics studying how likely events are to occur',
        'statistical distributions': 'a description of how values are spread across a dataset',
        'programming library': 'pre-written code that solves a specific problem and can be used directly',
      },
      examplesAr: [
        'طالب AI يقضي ساعتين يفهم اشتقاق صيغة Bayes من الأساس',
        'طالب SWE يستخدم مكتبة scikit-learn لتدريب نموذج دون دراسة النظرية',
        'طالب يعترف بصدق أن الرياضيات تُصعّب عليه — هذه إجابة صادقة وقيّمة',
      ],
      examplesEn: [
        'An AI student spends two hours understanding the derivation of Bayes\' formula from scratch',
        'A SWE student uses scikit-learn library to train a model without studying the theory',
        'A student honestly admits that mathematics is difficult for them — this is a valid and valuable answer',
      ],
      misconceptionsAr: [
        'الاعتراف بصعوبة الرياضيات ليس ضعفاً — بل وعي ذاتي يساعدك على اختيار التخصص المناسب',
        'استخدام مكتبة جاهزة ليس كسلاً — المهندسون يفعلون ذلك يومياً',
      ],
      misconceptionsEn: [
        'Admitting difficulty with mathematics is not weakness — it\'s self-awareness that helps you choose the right major',
        'Using a ready-made library is not laziness — engineers do it every day',
      ],
      hintsAr: [
        'كن صادقاً — هذه الإجابة تساعد النظام على تجنّب توصيتك بتخصص يُتعبك',
        'فكّر في تجربتك الفعلية مع الرياضيات في المدرسة — لا في ما تتمناه',
      ],
      hintsEn: [
        'Be honest — this answer helps the system avoid recommending a major that will exhaust you',
        'Think about your actual experience with mathematics in school — not what you wish were true',
      ],
      whyAskedAr: 'يُحدد هذا السؤال ما إذا كان الطالب يتحمل الرياضيات المتقدمة — وهي شرط أساسي للذكاء الاصطناعي وعلوم البيانات.',
      whyAskedEn: 'Determines whether the student can tolerate advanced mathematics — a core prerequisite for AI and Data Science.',
      learningOutcomeAr: 'يُعدّل النظام وزن الذكاء الاصطناعي وعلوم البيانات في التوصية بناءً على العمق الرياضي المُكتشَف.',
      learningOutcomeEn: 'The system adjusts the weight of AI and Data Science in recommendations based on the discovered mathematical depth.',
      relatedDomainsAr: ['الذكاء الاصطناعي', 'علوم البيانات', 'الرياضيات', 'الهندسة'],
      relatedDomainsEn: ['Artificial Intelligence', 'Data Science', 'Mathematics', 'Engineering'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_019 — Medical emergency scenario (Medicine discriminator)
    // ────────────────────────────────────────────────────────────────────────
    'q_019': QuestionKnowledge(
      questionId: 'q_019',
      concepts: ['medical empathy', 'stress tolerance in clinical settings', 'patient-centered orientation'],
      keyConceptsAr: {
        'الطوارئ': 'قسم في المستشفى يعالج الحالات العاجلة التي لا تحتمل التأخير',
        'الضغط النفسي المهني': 'الشعور بالإجهاد الناتج عن مواقف العمل العالية الخطورة',
        'التشخيص': 'تحديد المرض أو السبب الطبي من خلال الأعراض والفحوصات',
      },
      keyConceptsEn: {
        'emergency': 'a hospital department treating urgent cases that cannot wait',
        'occupational stress': 'the feeling of pressure from high-risk work situations',
        'diagnosis': 'identifying the disease or medical cause through symptoms and tests',
      },
      examplesAr: [
        'طبيب يشعر بالتحدي والرغبة في المساعدة في كل حالة جديدة — يزداد تعلقاً بالمهنة كل يوم',
        'طالب يرى الدم أو يسمع البكاء فيشعر بقلق شديد — هذه إشارة مهمة',
        'باحث طبي يرى الحالة النادرة كفرصة لنشر ورقة علمية — يُركّز على الفضول لا الألم',
      ],
      examplesEn: [
        'A doctor who feels challenged and eager to help with every new case — growing more attached to the profession every day',
        'A student who sees blood or hears crying and feels intense anxiety — this is an important signal',
        'A medical researcher who sees a rare case as an opportunity to publish — focused on curiosity not pain',
      ],
      misconceptionsAr: [
        'الشعور بالضغط في الطوارئ لا يعني أنك لا تستطيع دراسة الطب — لكنه إشارة لاختصاصات أكثر هدوءاً',
        'الطب ليس فقط الطوارئ — هناك الأبحاث والمختبرات والطب الوقائي',
        'الاهتمام العلمي بالحالة دون التأثر العاطفي الزائد قد يعني ميلاً للبحث الطبي لا العلاج المباشر',
      ],
      misconceptionsEn: [
        'Feeling stressed in emergencies doesn\'t mean you can\'t study medicine — but it signals quieter specializations',
        'Medicine is not only emergency rooms — there\'s research, labs, and preventive medicine',
        'Scientific interest in the case without excessive emotional impact may indicate research inclination rather than direct treatment',
      ],
      hintsAr: [
        'تخيّل نفسك حقاً في الموقف — جسدك يعرف ردّة فعله الصحيحة',
        'لا تُجيب بما تتمناه — الصدق هنا يحميك من اختيار تخصص قد يُتعبك لاحقاً',
      ],
      hintsEn: [
        'Really imagine yourself in this situation — your body knows its genuine reaction',
        'Don\'t answer what you wish — honesty here protects you from choosing a major that may exhaust you later',
      ],
      whyAskedAr: 'يقيس هذا السؤال التحمل العاطفي والميل للعمل المريض-محوري — وهما شرطان أساسيان للطب والتمريض.',
      whyAskedEn: 'Measures emotional tolerance and patient-centered work orientation — both core prerequisites for medicine and nursing.',
      learningOutcomeAr: 'يُعدّل النظام وزن الطب وعلم النفس السريري بناءً على الاستجابة العاطفية المُكتشَفة.',
      learningOutcomeEn: 'The system adjusts the weight of medicine and clinical psychology based on the discovered emotional response.',
      relatedDomainsAr: ['الطب', 'التمريض', 'علم النفس السريري', 'العلوم الصحية'],
      relatedDomainsEn: ['Medicine', 'Nursing', 'Clinical Psychology', 'Health Sciences'],
    ),

    // ────────────────────────────────────────────────────────────────────────
    // q_020 — Solo vs team work in technical project (SWE discriminator)
    // ────────────────────────────────────────────────────────────────────────
    'q_020': QuestionKnowledge(
      questionId: 'q_020',
      concepts: ['teamwork preference', 'solo deep work', 'software engineering coordination'],
      keyConceptsAr: {
        'العمل العميق': 'التركيز المطوّل على مهمة واحدة دون انقطاع — يُفضّله مطورو الخوارزميات',
        'التنسيق': 'التأكد من أن أعضاء الفريق يعملون معاً بانسجام نحو هدف مشترك',
        'متطلبات العملاء': 'ما يريده الشخص أو المؤسسة من البرنامج أو الحل',
      },
      keyConceptsEn: {
        'deep work': 'sustained focus on one task without interruption — preferred by algorithm developers',
        'coordination': 'ensuring team members work harmoniously toward a shared goal',
        'client requirements': 'what a person or organization wants from a program or solution',
      },
      examplesAr: [
        'مطور CS يغلق الإشعارات لساعات ويكتب خوارزمية معقدة وحده',
        'مهندس SWE يُدير stand-up meeting يومياً ويتابع مهام الفريق على Jira',
        'محلل أعمال يلتقي بالعملاء أسبوعياً ويُترجم احتياجاتهم لمتطلبات تقنية',
      ],
      examplesEn: [
        'A CS developer turns off notifications for hours and writes a complex algorithm alone',
        'A SWE engineer runs a daily stand-up meeting and tracks team tasks on Jira',
        'A business analyst meets clients weekly and translates their needs into technical requirements',
      ],
      misconceptionsAr: [
        'تفضيل العمل الجماعي لا يعني أنك لن تُبرمج — هندسة البرمجيات تجمع الأمرين',
        'تفضيل العمل الفردي لا يعني أنك غير اجتماعي — بل أنك تُبدع أكثر بالتركيز',
      ],
      misconceptionsEn: [
        'Preferring teamwork doesn\'t mean you won\'t code — software engineering combines both',
        'Preferring solo work doesn\'t mean you\'re antisocial — it means you create more with focus',
      ],
      hintsAr: [
        'فكّر في المشاريع الجماعية التي شاركت فيها — هل كانت ممتعة أم مُرهقة؟',
        'أيّ دور تجد نفسك تشغله تلقائياً في أي مجموعة؟',
      ],
      hintsEn: [
        'Think about group projects you\'ve been in — were they enjoyable or exhausting?',
        'Which role do you naturally take in any group?',
      ],
      whyAskedAr: 'يُفرّق هذا السؤال بين ميل الطالب لهندسة البرمجيات (تنسيق جماعي)، وعلوم الحاسب/الذكاء الاصطناعي (عمل فردي عميق)، وإدارة الأعمال (تواصل مع العملاء).',
      whyAskedEn: 'Distinguishes between student inclination for Software Engineering (team coordination), CS/AI (solo deep work), and Business (client communication).',
      learningOutcomeAr: 'يُعدّل النظام الأولوية بين SWE وCS وAI وإدارة الأعمال بناءً على تفضيل العمل.',
      learningOutcomeEn: 'The system adjusts priority between SWE, CS, AI, and Business based on work preference.',
      relatedDomainsAr: ['هندسة البرمجيات', 'علوم الحاسب', 'الذكاء الاصطناعي', 'إدارة الأعمال'],
      relatedDomainsEn: ['Software Engineering', 'Computer Science', 'Artificial Intelligence', 'Business Administration'],
    ),
  };
}

