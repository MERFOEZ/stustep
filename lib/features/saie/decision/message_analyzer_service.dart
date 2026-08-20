/// SAIE — MessageAnalyzerService
///
/// Produces a [MessageAnalysis] from a raw student message string.
/// All signal detection happens here before any classification.
/// This is a pure function — no state, no side effects.
library;

import 'package:stustep/features/saie/decision/contextual_answer_interpreter.dart';
import 'package:stustep/features/saie/decision/conversation_context.dart';
import 'package:stustep/features/saie/decision/language_detector.dart';
import 'package:stustep/features/saie/decision/message_analyzer.dart';
import 'package:stustep/features/saie/decision/semantic_message_classifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// _Signal word banks (Arabic + English)
// Greatly expanded to cover colloquial Arabic dialects (Gulf, Levantine,
// Egyptian), typos, partial phrases, and natural English variations.
// ─────────────────────────────────────────────────────────────────────────────

const _greetingSignals = [
  // Arabic — formal
  'السلام عليكم', 'وعليكم السلام', 'مرحبا', 'مرحباً', 'أهلا', 'أهلاً',
  'تحية', 'حياك الله', 'أهلاً وسهلاً',
  // Arabic — Gulf colloquial
  'هلا', 'هلا والله', 'هلا بك', 'هلا وغلا', 'صباح الخير', 'مساء الخير',
  'صباح النور', 'مساء النور', 'يسعد صباحك', 'يسعد مساك',
  // Arabic — Levantine / Egyptian
  'كيفك', 'كيف حالك', 'شو بتعمل', 'عامل إيه', 'إزيك',
  // English
  'hello', 'hi', 'hey', 'good morning', 'good evening', 'good afternoon',
  'greetings', 'howdy', "what's up", 'sup', 'yo', 'hi there', 'hey there',
];

const _skipSignals = [
  // Arabic — explicit skip
  'تخطى', 'تخطي', 'تجاوز', 'انتقل', 'التالي', 'لا أريد الإجابة',
  'تجاهل', 'مرّر', 'اتركه', 'اتركها', 'مرر السؤال',
  // Arabic — implicit skip (colloquial)
  'ما ودي أجاوب', 'ما أبي أجاوب', 'خل نروح للتالي', 'ما عندي جواب',
  'اتركها جانباً', 'تجاوز السؤال', 'ننتقل لغيره',
  // English
  'skip', 'next', 'pass', 'skip this', 'move on', 'ignore this',
  'next question', 'skip question', 'move forward', 'go next', 'pass this one',
];

const _restartSignals = [
  // Arabic
  'ابدأ من جديد', 'إعادة', 'أعد', 'من البداية', 'ابتدأ', 'ابدأ مجدداً',
  'إعادة التشغيل', 'إعادة التقييم', 'أعد التقييم', 'ابدأ التقييم من أول',
  'نعيد من أول', 'من أول وجديد',
  // English
  'restart', 'start over', 'begin again', 'from the beginning', 'reset',
  'start again', 'redo', 'go back to the start', 'restart assessment',
];

const _recommendationSignals = [
  // Arabic
  'ما التخصص المناسب', 'أنصحني', 'ما رأيك', 'ما توصيتك', 'أخبرني بالنتيجة',
  'ما المسار المناسب', 'ما الكلية المناسبة', 'وش التخصص المناسب لي',
  'ابي أعرف نتيجتي', 'وش ينفعني', 'قولي وش أتخصص', 'أيش تنصحني',
  'ما أنسب تخصص', 'وش تقترح', 'وش اقترح', 'نتيجة التقييم',
  // English
  'recommend', 'what should i study', 'what major', 'give me results',
  'what do you recommend', 'suggest a major', 'my recommendation', 'results',
  'what major suits me', 'best major for me', 'my result', 'show results',
  'what would you suggest', 'best fit for me',
];

const _negationSignals = [
  // Arabic
  'لا', 'لن', 'لم', 'لست', 'ليس', 'ما', 'أكره', 'لا أحب', 'لا أريد',
  'ما أحب', 'ما أقدر', 'مو', 'مب', 'ماب', 'ما ودي', 'ما أبي',
  // English
  'not', 'no', 'never', 'hate', 'dislike', "don't", "doesn't", "can't",
  "won't", 'neither', 'nope', 'nah', 'negative', 'refuse',
];

const _affirmationSignals = [
  // Arabic
  'نعم', 'أجل', 'صح', 'صحيح', 'بالتأكيد', 'طبعاً', 'أحب', 'أستمتع',
  'ممتاز', 'رائع', 'إي', 'إيه', 'اي', 'وايد', 'صحيح',
  // English
  'yes', 'yeah', 'yep', 'sure', 'of course', 'absolutely', 'love', 'enjoy',
  'definitely', 'correct', 'true', 'right', 'indeed', 'certainly', 'agreed',
];

const _conceptQuestionPrefixes = [
  // Arabic — formal
  'ما هو', 'ما هي', 'ماذا يعني', 'ما معنى', 'ما الفرق بين', 'كيف يعمل',
  'شرح', 'اشرح لي', 'ما هي أهمية',
  // Arabic — colloquial / Gulf
  'وش هو', 'وش هي', 'ايش هو', 'ايش هي', 'شو هو', 'شو هي',
  'وش يعني', 'ايش يعني', 'شو يعني', 'كيف يشتغل', 'وش هي أهمية',
  // Arabic — هل interrogatives (yes/no questions directed at the system)
  // These are questions the student asks OF the advisor, not answers TO a question.
  'هل تعرف', 'هل يمكن', 'هل ينفع', 'هل يجوز', 'هل يصح',
  'هل تستطيع', 'هل يمكنك', 'هل تقدر', 'هل عندك', 'هل لديك',
  'هل يجب', 'هل من الضروري', 'هل هناك', 'هل يوجد', 'هل هذا',
  // English
  'what is', 'what are', 'what does', 'how does', 'explain', 'define',
  "what's the difference", 'tell me about', 'describe', 'can you explain',
  'how do you', 'what do you mean by', 'could you tell me',
  'do you know', 'can you', 'are you able to', 'do you have',
  'is it possible', 'is there a', 'could you tell',
];

const _clarificationPhrases = [
  // Arabic — explicit clarification/explanation requests for the current question
  'ماذا تعني ب', 'ماذا يقصد', 'ما المقصود ب', 'ما معنى كلمة',
  'ما الذي تقصد', 'هل تقصد', 'وضّح لي', 'لم أفهم',
  // Arabic — common student phrases requesting question clarification
  'أحتاج توضيحاً', 'أحتاج توضيح', 'أحتاج شرحاً', 'أحتاج شرح',
  'لا أفهم السؤال', 'لا أفهم', 'لم أفهم السؤال',
  'وضّح', 'وضح لي', 'اشرح لي', 'اشرح السؤال',
  'ما معنى السؤال', 'فسّر', 'فسر لي',
  'غير واضح', 'السؤال غير واضح', 'ما المقصود',
  // Arabic — colloquial Gulf/Levantine
  'ما فاهم', 'ما فهمت', 'وش يقصد', 'وش تقصد', 'ايش تقصد', 'ايش يقصد',
  'مو فاهم', 'مو واضح', 'مو بين', 'السؤال مو واضح',
  'وضحله', 'وضحلي', 'فهمني', 'اشرحلي', 'اشرح لي السؤال',
  'ما عرفت اجاوب', 'ما عرفت أجاوب', 'السؤال صعب الفهم',
  'ما واضح لي', 'مش واضح', 'ما وضح', 'ما أفهم',
  // Egyptian / Levantine
  'مش فاهم', 'مش فاهمة', 'إيه يعني', 'فسر لي',
  // English
  'what do you mean by', 'what does that mean', "i don't understand",
  'could you clarify', 'what is meant by', 'do you mean',
  'can you explain the question', 'clarify', 'not clear',
  "i'm confused", 'confusing', "can't understand", 'please explain',
  "what's this asking", 'unclear', 'rephrase', 'not following',
  "i don't get it", 'elaborate', 'what exactly', 'say that again',
];

// Word meaning — student asks what a specific word/term means.
const _wordMeaningSignals = [
  // Arabic — formal
  'ما معنى', 'ما تعني كلمة', 'ما تعني',
  // Arabic — Gulf colloquial
  'وش يعني', 'ما يعني', 'معناها ايش', 'ايش معنى',
  'شو يعني', 'يعني ايش', 'وش معنى', 'شو معنى',
  'وش تعني كلمة', 'وش تعني', 'ايش تعني',
  'معنى هذه الكلمة', 'ما معنى هذا المصطلح', 'ايش معنى المصطلح',
  // Arabic — asking about a specific term in the question
  'ما معنى كلمة', 'وش يقصد بـ', 'ما المقصود بـ', 'شرح المصطلح',
  'معنى المصطلح', 'وش يعني المصطلح',
  // English
  'what does', 'what is the meaning', 'meaning of', 'define the word',
  'what does the word', 'define', 'what is meant by',
  'what does this term mean', 'what is this term',
  'explain the word', 'explain this term', 'what is the definition of',
];

// Uncertainty — student says they don't know or aren't sure.
const _uncertaintySignals = [
  // Arabic — formal
  'لا أعرف', 'لست متأكداً', 'لست متأكد', 'ما عندي فكرة',
  // Arabic — Gulf colloquial
  'لا اعرف', 'ما أعرف', 'ما اعرف', 'مو عارف', 'مو متأكد', 'ما أدري',
  'ما ادري', 'صعب علي', 'مش عارف', 'ما فهمت وش أقول',
  'ما عندي رأي', 'ما أقدر أجاوب', 'ما أعرف وش أقول',
  'مو قادر أجاوب', 'يصعب علي الإجابة', 'مو عارف وش أقول',
  'ما عارف', 'صعبة عليّ', 'ما أدري وش أجاوب',
  'صراحة ما أعرف', 'والله ما أعرف', 'ما لي فكرة',
  // Levantine / Egyptian
  'مش عارف', 'ما عرفتش', 'مش قادر', 'صعب عليا',
  // English
  'not sure', 'no idea', "i'm unsure", 'uncertain', "don't know",
  "i don't know", 'no clue', "haven't thought about it",
  "can't decide", "can't answer", "don't know how to answer",
  "i have no idea", 'beats me', "not really sure", "hard to say",
  "i'm not certain", "i haven't decided", "i'm stuck",
];

// Why this question — student asks the purpose of the current question.
const _whyQuestionSignals = [
  // Arabic — formal
  'لماذا هذا السؤال', 'لماذا تسألني', 'ما الفائدة من هذا',
  'ما الهدف من السؤال', 'لماذا هذا مهم',
  // Arabic — Gulf colloquial
  'ليش سألتني', 'ليش هذا السؤال', 'وش الهدف', 'وش الغرض',
  'وش هدف السؤال', 'ايش الهدف من السؤال', 'وش فائدة هذا السؤال',
  'ليش تسألني', 'ليش محتاج هذا السؤال', 'وش علاقة هذا السؤال',
  // Egyptian / Levantine
  'ليه السؤال ده', 'ليه بسألني', 'شو الهدف', 'ليش هيك سؤال',
  // English
  'why this question', 'why do you ask', 'why are you asking',
  "what's the point", 'what is the purpose of this question',
  'why does this matter', 'why is this relevant',
  "what's the reason for this question", 'why ask about that',
  "what's this for", 'purpose of this question', 'why ask me this',
];

// Alternative question — student wants a different question.
const _alternativeQuestionSignals = [
  // Arabic — formal
  'سؤال آخر', 'أريد سؤالاً آخر', 'انتقل لسؤال آخر', 'سؤال مختلف',
  // Arabic — colloquial
  'غير السؤال', 'هذا السؤال صعب', 'غيّر السؤال', 'سؤال ثاني',
  'بدّل السؤال', 'حط سؤال ثاني', 'أبي سؤال ثاني', 'ودي سؤال ثاني',
  'ما أبي هذا السؤال', 'خل نروح لسؤال ثاني', 'حب أجاوب سؤال ثاني',
  'ما أحب هذا السؤال', 'سؤال أسهل',
  // English
  'change the question', 'another question', 'different question',
  'switch question', 'give me another question',
  'can we try a different question', 'change to another question',
  'different one', 'try another', 'swap this question',
];

// Examples — student wants examples related to the question.
const _examplesSignals = [
  // Arabic — formal
  'أعطني أمثلة', 'اذكر أمثلة', 'ما هي الأمثلة',
  // Arabic — colloquial Gulf
  'أمثلة', 'أعطني مثال', 'وش هي المجالات',
  'مثل ايش', 'مثل ماذا', 'وش الخيارات', 'اعطني امثلة',
  'ايش الخيارات', 'وش الأمثلة', 'مثال على ذلك',
  'أعطني مثالاً', 'أعطني مثال عن', 'أمثلة على ذلك',
  'اذكر لي أمثلة', 'وش يعني بمثال', 'يعني ايش بمثال',
  'اشرح بمثال', 'ايش مثال على ذلك', 'مثلاً ايش',
  // Egyptian / Levantine
  'بالمثال', 'مثلاً إيه', 'أعطيني مثال',
  // English
  'examples', 'give me an example', 'such as', 'like what',
  'what are the options', 'give examples', 'can you give examples',
  'show me examples', 'for example', 'like for instance',
  'can you illustrate', 'give an illustration', 'an example would help',
  'example please', 'what do you mean by example',
];

// Options / location request — student asking "where are the options/activities/fields".
// These messages mean: "the question mentioned something I can't see — show it to me".
const _optionsRequestSignals = [
  // Arabic — Gulf 'وين' (where is/are)
  'وين الخيارات', 'وين الانشطه', 'وين المجالات',
  'وين الامثله', 'وين الخيار', 'وين اللائحه',
  'وين الاسئله', 'وين البدائل', 'وين الاجوبه',
  'وين التخصصات', 'وين المسارات', 'وين الكليات',
  'وين السؤال', 'وين الفرص', 'وين هي',
  // Arabic — Levantine/Egyptian 'فين' / 'اين'
  'فين الخيارات', 'فين الانشطه', 'فين المجالات',
  'فين الامثله', 'فين اللائحه', 'فين البدائل',
  'اين الخيارات', 'اين الانشطه', 'اين المجالات',
  'اين الامثله', 'اين هي', 'اين البدائل',
  // Arabic — 'اريني' / 'حط' / 'بين'
  'اريني الخيارات', 'اريني الانشطه', 'اريني المجالات',
  'حط لي الخيارات', 'بين لي الخيارات',
  'اعطني الخيارات', 'اعطني الانشطه',
  'وش هي الخيارات', 'ايش هي الخيارات',
  'ما ذكرت الخيارات', 'ما ذكرت الانشطه',
  'ما حطيت الخيارات', 'ما شفت الخيارات',
  // English
  'where are the options', 'show me the options', 'where are the choices',
  'where are the activities', 'where are the fields', 'where are the examples',
  "i can't see the options", 'list the options', 'show options',
  'display options', 'show choices', 'list choices',
  "you didn't show the options", 'where is the list', 'where are they',
];

// Simplification request — student wants question restated more simply.
const _simplificationSignals = [
  // Arabic — formal
  'بعباره ابسط', 'بشكل ابسط', 'بسط لي', 'بسطه', 'بسط',
  'كيف اقولها بشكل ابسط', 'بثلاثه كلمات',
  // Arabic — Gulf colloquial
  'بسطها لي', 'بسط لي السؤال', 'وش يعني بكلام ابسط',
  'اشرحها بطريقه اسهل', 'سهلها علي', 'اجعلها اسهل',
  // English
  'simplify', 'simpler', 'easier', 'rephrase', 'say it differently',
  'in simpler words', 'in plain words', 'make it simpler',
  'easier version', 'break it down', 'put it simply',
  'in simple terms', 'simpler please',
];

// Meta-question suffixes — student asks a verification/permission question
// at the END of a message that also contains answer content.
// Pattern: [answer content] + [one of these trailing questions]
// This signals a COMPOUND message: partial answer + request for guidance.
const _metaQuestionSuffixes = [
  // Arabic — "is it okay if I mention them?", "can I say this?"
  'هل ينفع اذكرها', 'هل ينفع اذكرهم', 'هل ينفع اذكره',
  'هل يصح اذكر', 'هل يصح اقول', 'هل يجوز اذكر',
  'هل هذا صحيح', 'هل هذا يكفي', 'هل هذا مناسب', 'هل هذا جيد',
  'هل اجاوب صح', 'هل فهمت السؤال', 'هل فهمت صح',
  'هل هذا يعتبر', 'هل يحسب', 'هل تنفع', 'هل يصلح',
  'وش تقول', 'وش رأيك', 'صح وله لا', 'ايش تقول',
  'هل ينفع', 'ينفع اذكر', 'ينفع اقول', 'ينفع هذا',
  // English — "is this good?", "can I mention this?", "is that right?"
  'is that right', 'is this correct', 'is this ok', 'is that ok',
  'can i mention', 'can i say', 'is it valid', 'does that count',
  'is that enough', 'is this relevant', 'would that work',
  'is this a good answer', 'am i on the right track',
];

// ─────────────────────────────────────────────────────────────────────────────
// MessageAnalyzerService
// ─────────────────────────────────────────────────────────────────────────────

/// Stateless service that decomposes a raw message into a [MessageAnalysis].
final class MessageAnalyzerService {
  const MessageAnalyzerService();

  static const _semanticClassifier = SemanticMessageClassifier();
  static const _interpreter = ContextualAnswerInterpreter();

  /// Analyses [rawMessage] within [context] and produces a [MessageAnalysis].
  MessageAnalysis analyse(
    String rawMessage,
    ConversationContext context,
  ) {
    final now = DateTime.now().toUtc();
    final normalised = rawMessage.trim().replaceAll(RegExp(r'\s+'), ' ');
    // Normalize and lowercase for all signal matching.
    final lower = MessageAnalyzerService._normalizeArabic(normalised.toLowerCase());
    final words = normalised.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final wordCount = words.length;
    final qMarks = '?؟'.split('').fold(0, (n, c) => n + normalised.split(c).length - 1);

    final tokens = MessageTokens(
      raw: rawMessage,
      normalised: normalised,
      charCount: rawMessage.length,
      wordCount: wordCount,
      questionMarkCount: qMarks,
      endsWithQuestion: normalised.endsWith('?') || normalised.endsWith('؟'),
      isSingleWord: wordCount == 1,
      isVeryShort: wordCount <= 3,
      containsNegation: _anyMatch(lower, _negationSignals),
      containsAffirmation: _anyMatch(lower, _affirmationSignals),
    );

    final detectedLang = _detectLanguage(normalised);

    // Signal detection (all normalized + colloquial).
    final looksLikeGreeting = _anyMatch(lower, _greetingSignals);
    final containsSkip = _anyMatch(lower, _skipSignals);
    final containsRestart = _anyMatch(lower, _restartSignals);
    final containsRecommendation = _anyMatch(lower, _recommendationSignals);
    final looksLikeConcept = _anyMatch(lower, _conceptQuestionPrefixes) ||
        tokens.endsWithQuestion;
    final requestsClarification = _anyMatch(lower, _clarificationPhrases);
    final requestsWordMeaning = _anyMatch(lower, _wordMeaningSignals);
    final expressesUncertainty = _anyMatch(lower, _uncertaintySignals);
    final requestsWhyQuestion = _anyMatch(lower, _whyQuestionSignals);
    final requestsAlternative = _anyMatch(lower, _alternativeQuestionSignals);
    final requestsExamples = _anyMatch(lower, _examplesSignals);
    final requestsOptions = _anyMatch(lower, _optionsRequestSignals);
    final requestsSimplification = _anyMatch(lower, _simplificationSignals);

    // ── Compound message detection ──────────────────────────────────────────
    // A compound message contains BOTH answer-like content AND a trailing
    // meta-question ("is this okay?", "can I mention this?", "is that right?").
    // Example: "انا العب، واقرأ كتب احيانا، هل ينفع اذكرها؟"
    //
    // Detection criteria (all must be true):
    // 1. A pending question exists (we are in assessment).
    // 2. Message is moderately long (> 5 words — not just a question).
    // 3. Message ends with a question mark (has a trailing question).
    // 4. Message contains a known meta-question suffix (verification/permission).
    //
    // A compound message must NOT be treated as a pure answer (would advance
    // assessment incorrectly) NOR as a pure academic question (would ignore
    // the answer content). It needs special handling: acknowledge the content,
    // address the meta-question, then ask them to confirm the full answer.
    final looksLikeCompoundMessage = context.hasPendingQuestion &&
        wordCount > 5 &&
        (normalised.endsWith('?') || normalised.endsWith('؟')) &&
        _anyMatch(lower, _metaQuestionSuffixes);

    // Structural semantic inference for edge cases:
    // These boost signals based on conversational patterns even without
    // explicit keyword matches.
    final inferredClarification = !requestsClarification &&
        _infersClarification(lower, tokens, context);
    final inferredUncertainty = !expressesUncertainty &&
        _infersUncertainty(lower, tokens, context);
    final inferredExamples = !requestsExamples &&
        _infersExamplesRequest(lower, tokens, context);
    // Infer options request: short message starting with وين/فين/أين
    final inferredOptions = !requestsOptions &&
        context.hasPendingQuestion &&
        _infersOptionsRequest(lower, tokens);

    // Does message reference the current active question topic?
    final referencesCurrentTopic = _referencesActiveTopic(lower, context);

    // History reference: mentions something said before.
    final referencesHistory = _referencesHistory(lower, context);

    // Looks like answer: structural answer signals.
    final effectiveClarification =
        requestsClarification || inferredClarification;
    final effectiveUncertainty = expressesUncertainty || inferredUncertainty;
    final effectiveExamples = requestsExamples || inferredExamples;
    final effectiveOptions = requestsOptions || inferredOptions;

    final looksLikeAnswer = !looksLikeGreeting &&
        !looksLikeConcept &&
        !containsSkip &&
        !containsRestart &&
        !containsRecommendation &&
        !effectiveClarification &&
        !effectiveUncertainty &&
        !requestsWordMeaning &&
        !requestsWhyQuestion &&
        !requestsAlternative &&
        !effectiveExamples &&
        !effectiveOptions &&          // options request vetoes answer
        !requestsSimplification &&    // simplification vetoes answer
        !looksLikeCompoundMessage &&  // compound message vetoes pure answer
        context.hasPendingQuestion;

    // Contradiction: negation + prior affirmation or vice-versa in history.
    final looksLikeContradiction = _looksLikeContradiction(lower, context);

    // Build the analysis object (without semanticType yet — needed for classifier).
    final partialAnalysis = MessageAnalysis(
      tokens: tokens,
      detectedLanguage: detectedLang,
      looksLikeGreeting: looksLikeGreeting,
      looksLikeConceptQuestion: looksLikeConcept,
      looksLikeAnswer: looksLikeAnswer,
      looksLikeCompoundMessage: looksLikeCompoundMessage,
      referencesCurrentTopic: referencesCurrentTopic,
      referencesHistory: referencesHistory,
      containsSkipSignal: containsSkip,
      containsRestartSignal: containsRestart,
      containsRecommendationSignal: containsRecommendation,
      looksLikeContradiction: looksLikeContradiction,
      requestsQuestionClarification: effectiveClarification,
      requestsWordMeaning: requestsWordMeaning,
      expressesUncertainty: effectiveUncertainty,
      requestsWhyThisQuestion: requestsWhyQuestion,
      requestsAlternativeQuestion: requestsAlternative,
      requestsExamples: effectiveExamples,
      requestsOptions: effectiveOptions,
      requestsSimplification: requestsSimplification,
      semanticType: SemanticMessageType.unknown, // placeholder
      analysedAt: now,
      // ── Context-aware answer interpretation ──────────────────────────────
      // Only run the interpreter when no non-answer signal has already been
      // detected. If the message is already classified as a clarification
      // request, uncertainty, etc., there is no need to interpret it as an
      // answer — it cannot be one.
      answerInterpretation: _shouldRunInterpreter(
        looksLikeGreeting: looksLikeGreeting,
        containsSkip: containsSkip,
        containsRestart: containsRestart,
        containsRecommendation: containsRecommendation,
        effectiveClarification: effectiveClarification,
        effectiveUncertainty: effectiveUncertainty,
        requestsWordMeaning: requestsWordMeaning,
        requestsWhyQuestion: requestsWhyQuestion,
        requestsAlternative: requestsAlternative,
        effectiveExamples: effectiveExamples,
        effectiveOptions: effectiveOptions,
        requestsSimplification: requestsSimplification,
        looksLikeCompoundMessage: looksLikeCompoundMessage,
      )
          ? _interpreter.interpret(
              normalisedMessage: lower,
              activeQuestion: context.activeQuestion,
            )
          : null,
    );

    // Run the Message Understanding Layer (SemanticMessageClassifier).
    // This produces the authoritative SemanticMessageType used by the router.
    final semanticType = _semanticClassifier.classify(
      partialAnalysis,
      hasPendingQuestion: context.hasPendingQuestion,
    );

    return partialAnalysis.copyWith(semanticType: semanticType);
  }

  /// Returns true when the [ContextualAnswerInterpreter] should be invoked.
  ///
  /// The interpreter runs ONLY when no non-answer signal has been detected.
  /// This avoids wasting computation on messages that are definitively NOT
  /// answers, and prevents the interpreter from accidentally overriding a
  /// correctly identified non-answer signal.
  static bool _shouldRunInterpreter({
    required bool looksLikeGreeting,
    required bool containsSkip,
    required bool containsRestart,
    required bool containsRecommendation,
    required bool effectiveClarification,
    required bool effectiveUncertainty,
    required bool requestsWordMeaning,
    required bool requestsWhyQuestion,
    required bool requestsAlternative,
    required bool effectiveExamples,
    required bool effectiveOptions,
    required bool requestsSimplification,
    required bool looksLikeCompoundMessage,
  }) =>
      !looksLikeGreeting &&
      !containsSkip &&
      !containsRestart &&
      !containsRecommendation &&
      !effectiveClarification &&
      !effectiveUncertainty &&
      !requestsWordMeaning &&
      !requestsWhyQuestion &&
      !requestsAlternative &&
      !effectiveExamples &&
      !effectiveOptions &&
      !requestsSimplification &&
      !looksLikeCompoundMessage;

  // ─── Structural semantic inference ───────────────────────────────────────
  // These handle cases where students express intent without matching keywords
  // by reasoning about message structure and context.

  /// Infers a clarification request structurally.
  /// Triggered when:
  /// - Very short question message during active question (≤4 words ending with ?)
  /// - Message is a near-echo of the question (student repeating it back)
  bool _infersClarification(
    String lower,
    MessageTokens tokens,
    ConversationContext context,
  ) {
    if (!context.hasPendingQuestion) return false;

    // A very short message ending with question mark during assessment
    // strongly suggests they want the question restated or clarified.
    if (tokens.wordCount <= 4 && tokens.endsWithQuestion) {
      return true;
    }

    // Messages like "هه؟" "أيش؟" "هاه؟" express confusion.
    final confusionSounds = ['هه', 'هاه', 'ههه', 'آه', 'اه', 'what', 'huh', 'hmm'];
    if (tokens.wordCount <= 2 &&
        confusionSounds.any((s) => lower.contains(s))) {
      return true;
    }

    return false;
  }

  /// Infers uncertainty structurally.
  /// Triggered when messages express hesitation or difficulty without
  /// explicit keywords.
  bool _infersUncertainty(
    String lower,
    MessageTokens tokens,
    ConversationContext context,
  ) {
    if (!context.hasPendingQuestion) return false;

    // Hesitation sounds/filler words
    final hesitationPatterns = [
      'أممم', 'اممم', 'امم', 'هممم', 'همم', 'ممم', 'هم',
      'umm', 'uhh', 'hmm', 'uh', 'er', 'um',
    ];
    if (tokens.wordCount <= 3 &&
        hesitationPatterns.any((h) => lower.contains(h))) {
      return true;
    }

    // "صعب" or "hard" in isolation during active question = uncertainty
    if (tokens.wordCount <= 3 &&
        (lower.contains('صعب') ||
            lower.contains('صعبة') ||
            lower == 'hard' ||
            lower == 'difficult')) {
      return true;
    }

    return false;
  }

  /// Infers an examples request structurally.
  bool _infersExamplesRequest(
    String lower,
    MessageTokens tokens,
    ConversationContext context,
  ) {
    if (!context.hasPendingQuestion) return false;

    // Short messages containing "مثال" or "example" without full phrase match.
    // Also catches bare "مثل؟" ("like?" / "for example?").
    if (tokens.wordCount <= 3 &&
        (lower.contains('مثال') ||
            lower.contains('مثل') ||
            lower.contains('example'))) {
      return true;
    }

    return false;
  }

  /// Infers an options/location request structurally.
  /// Catches short messages starting with وين/فين/اين that don't
  /// match the full signal list (e.g. "وين الأنشطة" with diacritics removed).
  bool _infersOptionsRequest(String lower, MessageTokens tokens) {
    if (tokens.wordCount > 5) return false; // Long messages aren't location probes.

    // Starts with a location interrogative
    final locationPrefixes = ['وين', 'فين', 'اين', 'where'];
    if (locationPrefixes.any((p) => lower.startsWith(p))) {
      return true;
    }

    // Contains اريني (show me)
    if (lower.contains('اريني')) {
      return true;
    }

    return false;
  }

  // ─── Language Detection ───────────────────────────────────────────────────

  DetectedLanguage _detectLanguage(String text) {
    if (text.isEmpty) {
      return const DetectedLanguage(
        language: Language.unknown,
        confidence: 0.0,
        arabicRatio: 0.0,
        latinRatio: 0.0,
      );
    }

    int arabicChars = 0;
    int latinChars = 0;
    int totalChars = 0;

    for (final cp in text.runes) {
      final c = String.fromCharCode(cp);
      if (RegExp(r'[\u0600-\u06FF\u0750-\u077F]').hasMatch(c)) {
        arabicChars++;
        totalChars++;
      } else if (RegExp(r'[a-zA-Z]').hasMatch(c)) {
        latinChars++;
        totalChars++;
      }
    }

    if (totalChars == 0) {
      return const DetectedLanguage(
        language: Language.unknown,
        confidence: 0.5,
        arabicRatio: 0.0,
        latinRatio: 0.0,
      );
    }

    final arabicRatio = arabicChars / totalChars;
    final latinRatio = latinChars / totalChars;

    Language lang;
    double confidence;

    if (arabicRatio >= 0.7) {
      lang = Language.arabic;
      confidence = arabicRatio;
    } else if (latinRatio >= 0.7) {
      lang = Language.english;
      confidence = latinRatio;
    } else if (arabicRatio > 0 && latinRatio > 0) {
      lang = Language.mixed;
      confidence = 0.6;
    } else {
      lang = Language.unknown;
      confidence = 0.4;
    }

    return DetectedLanguage(
      language: lang,
      confidence: confidence,
      arabicRatio: arabicRatio,
      latinRatio: latinRatio,
    );
  }

  // ─── Topic Reference Detection ────────────────────────────────────────────

  bool _referencesActiveTopic(String lower, ConversationContext context) {
    if (!context.hasPendingQuestion) return false;
    final q = context.activeQuestion!;
    // Check if any word in the question text appears in the message.
    final qWords = _normalizeArabic(q.text.toLowerCase()).split(RegExp(r'\s+'));
    final significantWords = qWords.where((w) => w.length > 3).take(5);
    return significantWords.any((w) => lower.contains(w));
  }

  bool _referencesHistory(String lower, ConversationContext context) {
    // Check if current message references content from prior turns.
    final priorContent = context.lastNTurns(6)
        .where((t) => t.isStudent)
        .skip(1) // skip current turn
        .expand((t) => t.content.toLowerCase().split(RegExp(r'\s+')))
        .where((w) => w.length > 4)
        .toSet();
    return priorContent.any((w) => lower.contains(w));
  }

  bool _looksLikeContradiction(String lower, ConversationContext context) {
    if (!_anyMatch(lower, _negationSignals)) return false;
    final priorTurns = context.lastNTurns(6)
        .where((t) => t.isStudent)
        .skip(1)
        .toList();
    if (priorTurns.isEmpty) return false;
    final priorText = priorTurns.map((t) => t.content.toLowerCase()).join(' ');
    return _anyMatch(priorText, _affirmationSignals) &&
        _anyMatch(lower, _negationSignals);
  }

  static bool _anyMatch(String text, List<String> signals) {
    final normalizedText = _normalizeArabic(text.toLowerCase());
    return signals.any((s) => normalizedText.contains(_normalizeArabic(s.toLowerCase())));
  }

  /// Normalizes Arabic text for robust matching regardless of:
  ///  - Diacritics/tashkeel (ً ٌ ٍ َ ُ ِ ّ ْ)
  ///  - Hamza forms (أ إ آ ٱ → ا)
  ///  - Tatweel/kashida (ـ)
  ///  - Alef maqsura (ى → ي)
  ///  - Teh marbuta (ة → ه)
  static String _normalizeArabic(String text) {
    return text
        // Strip Arabic diacritics (tashkeel / harakat) and tatweel
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0671\u06D6-\u06DC\u06DF-\u06E4\u06E7\u06E8\u06EA-\u06ED\u0640]'), '')
        // Normalize hamza forms to bare alef
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        // Normalize alef maqsura to ya
        .replaceAll('ى', 'ي')
        // Normalize teh marbuta to ha (optional — common colloquial form)
        .replaceAll('ة', 'ه');
  }
}
