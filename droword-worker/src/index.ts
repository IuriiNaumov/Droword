import { allowIP, bodyTooLarge, clipText, imageTooLarge, keysEqual, limits, takeList } from "./guard";

export interface Env {
  ANTHROPIC_API_KEY: string;
  OPENAI_API_KEY: string;
  APP_KEY: string;
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function errorResponse(message: string, status = 500): Response {
  return jsonResponse({ error: message }, status);
}

function capitalizeFirst(value: string): string {
  const trimmed = value.trim();
  if (!trimmed) return value;
  const first = trimmed[0];
  const upper = first.toLocaleUpperCase();
  if (upper === first) return trimmed;
  return upper + trimmed.slice(1);
}

function ttsLanguageName(language: string): string {
  const map: Record<string, string> = {
    English: "English",
    "Español": "Spanish",
    "Русский": "Russian",
    "Français": "French",
    Deutsch: "German",
    Italiano: "Italian",
    "Português": "Portuguese",
    "한국어": "Korean",
    "中文": "Chinese",
    "日本語": "Japanese",
    "العربية": "Arabic",
    "हिन्दी": "Hindi",
    "Українська": "Ukrainian",
    "Türkçe": "Turkish",
    "Ελληνικά": "Greek",
    Nederlands: "Dutch",
    Polski: "Polish",
    Svenska: "Swedish",
    Norsk: "Norwegian",
    Dansk: "Danish",
    Suomi: "Finnish",
    "Tiếng Việt": "Vietnamese",
    "Bahasa Indonesia": "Indonesian",
    "ไทย": "Thai",
    "עברית": "Hebrew",
    "Čeština": "Czech",
    "Română": "Romanian",
    Magyar: "Hungarian",
  };
  return map[language] || language;
}

function levelGuideline(
  language: string,
  level: string
): { label: string; guideline: string } {
  const tiers = ["A1", "A2", "B1", "B2", "C1", "C2"];
  const tier = tiers.includes(level) ? level : "A1";

  const labels: Record<string, string> = {
    A1: "Beginner",
    A2: "Elementary",
    B1: "Pre-Intermediate",
    B2: "Intermediate",
    C1: "Upper-Intermediate",
    C2: "Advanced",
  };

  const cefr: Record<string, string> = {
    A1: "Use only the most basic vocabulary and very short sentences (3–5 words). Present tense only. No idioms or complex grammar.",
    A2: "Use simple everyday vocabulary and short sentences (5–8 words). Simple past and present tenses. No idioms.",
    B1: "Use intermediate vocabulary with compound sentences. Common tenses including future. Simple connectors (because, but, so).",
    B2: "Use varied vocabulary with natural, fluent sentences. All common tenses. Idiomatic expressions are OK.",
    C1: "Use advanced vocabulary, complex sentence structures, and natural idiomatic expressions.",
    C2: "Use sophisticated, native-level language with nuanced vocabulary, idioms, and complex grammar.",
  };

  const scripts: Record<string, Record<string, string>> = {
    "日本語": {
      A1: " Write ONLY in hiragana and katakana — do NOT use any kanji.",
      A2: " Use only the ~100 most basic kanji (JLPT N5–N4); write less common words in kana.",
      B1: " Use common jōyō kanji up to intermediate level (around JLPT N3).",
      B2: " Use most jōyō kanji naturally.",
      C1: " Use the full range of kanji, including less common ones.",
      C2: " Use the full range of kanji and advanced expressions.",
    },
    "中文": {
      A1: " Use only the simplest, most common characters (around HSK 1).",
      A2: " Use basic common characters (around HSK 2).",
      B1: " Use common everyday characters (around HSK 3).",
      B2: " Use a broad range of characters (around HSK 4); chengyu idioms sparingly.",
      C1: " Use advanced vocabulary and characters (around HSK 5).",
      C2: " Use the full range of characters and idioms (around HSK 6).",
    },
    "한국어": {
      A1: " Use basic hangul vocabulary with minimal Sino-Korean words (around TOPIK 1).",
      A2: " Use basic everyday vocabulary (around TOPIK 2).",
      B1: " Use everyday and some abstract vocabulary (around TOPIK 3).",
      B2: " Use a broad vocabulary and some idioms (around TOPIK 4).",
      C1: " Use advanced vocabulary and complex grammar (around TOPIK 5).",
      C2: " Use sophisticated vocabulary and grammar (around TOPIK 6).",
    },
  };

  const script = scripts[language]?.[tier] ?? "";
  return { label: labels[tier], guideline: cefr[tier] + script };
}

async function handleTranslate(request: Request, env: Env): Promise<Response> {
  const raw = await request.json<{
    word: string;
    learningLanguage: string;
    nativeLanguage: string;
    level?: string;
  }>();

  const word = clipText(raw.word, limits.word);
  const learningLanguage = clipText(raw.learningLanguage, 48);
  const nativeLanguage = clipText(raw.nativeLanguage, 48);
  const level = clipText(raw.level, 8) ?? "";

  if (!word || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: word, learningLanguage, nativeLanguage", 400);
  }

  const lvl = levelGuideline(learningLanguage, level || "");

  const prompt = `You are a friendly language tutor.

Translate and explain the word "${word}".

Source language: ${learningLanguage}
Target language: ${nativeLanguage}
Learner's level: ${lvl.label}

STRICT RULES:
- translation → only ${nativeLanguage}. Give the most common, natural translation.
- type → part of speech, only ${nativeLanguage} (e.g. "существительное", "глагол" for Russian).
- explanation → 1–2 short sentences in ${nativeLanguage}. Write like you're explaining to a friend — casual, clear, helpful. Focus on when and how the word is used, not a dictionary definition. Adapt to ${lvl.label} level.
- breakdown → only ${nativeLanguage} or null. Brief etymology or word structure if helpful.
- example → only ${learningLanguage}. IMPORTANT: The example sentence MUST match the ${lvl.label} level. ${lvl.guideline} Capitalize only the first letter of each sentence (and proper nouns). Do NOT capitalize the headword mid-sentence. Use a natural inflection or conjugation of "${word}" when that is how a native would say it.
- forms → array of every conjugated or inflected surface form of "${word}" that appears in "example" or "collocations", copied exactly from that text, including accents. The form may share no letters with the headword. Examples: saber → supe, supo, sé; ser → soy, fue; ir → voy, fui; ver → vi; go → went; être → suis. Do not include synonyms or unrelated words. Return [] only when no inflected form appears.
- collocations → an array of 2–4 short, very common collocations or set phrases built with "${word}", ONLY in ${learningLanguage} (no translation). Natural word combinations a native speaker actually uses (e.g. for English "make": ["make a decision", "make a mistake", "make friends"]). Keep them short. Return [] if none are natural.
- synonyms → an array of 0–3 common synonyms of "${word}", ONLY in ${learningLanguage} (no translation). Return [] if there are no close synonyms.
- antonyms → an array of 0–2 common antonyms of "${word}", ONLY in ${learningLanguage} (no translation). Return [] if the word has no natural opposite.
- mnemonic → one short, vivid memory hook in ${nativeLanguage} that helps the learner remember the word, linking its sound or shape to its meaning. Keep it to a single sentence. Return null if you can't make a genuinely helpful one.
- transcription → phonetic transcription that helps the learner pronounce the word correctly.
  For ${learningLanguage}, use the most practical transcription system:
  • Japanese → if the word contains kanji, show hiragana reading (e.g. "たべる" for 食べる). If the word is already in hiragana or katakana, show romaji (e.g. "kiku" for きく, "terebi" for テレビ)
  • Chinese → use pinyin with tones (e.g. "chī fàn")
  • Korean → use romanization (e.g. "meo-gda")
  • Arabic → use simplified transliteration (e.g. "akala")
  • For European languages (English, French, Spanish, German, Italian, Portuguese, etc.) → use IPA in slashes (e.g. /pəˈteɪtoʊ/, /ʃɛʁʃe/)
  • Hindi → use IAST or simplified transliteration
  Return null if not applicable.
- detectedLanguage → if the word is clearly not ${learningLanguage}, the language it actually belongs to, copied exactly from this list: English, Español, Русский, Français, Deutsch, Italiano, Português, 한국어, 中文, 日本語, العربية, हिन्दी, Українська, Türkçe, Ελληνικά, Nederlands, Polski, Svenska, Norsk, Dansk, Suomi, Tiếng Việt, Bahasa Indonesia, ไทย, עברית, Čeština, Română, Magyar. Return null when it matches ${learningLanguage} or you are not sure, including names, loanwords, and abbreviations.
- Do not mix languages inside fields.
- Capitalization: for scripts that have letter case (Latin, Cyrillic, Greek, etc.), always start "translation" with an uppercase letter. Keep the rest of the string as natural writing (do not Title Case every word). If the script has no case (e.g. Japanese, Chinese, Korean, Arabic), leave as-is.

Return ONLY valid JSON:

{
  "translation": "...",
  "example": "...",
  "type": "...",
  "explanation": "...",
  "breakdown": null or "...",
  "transcription": null or "...",
  "collocations": ["...", "..."],
  "synonyms": ["...", "..."],
  "antonyms": ["...", "..."],
  "mnemonic": null or "...",
  "forms": ["..."],
  "detectedLanguage": null or "..."
}`;

  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5",
      max_tokens: 1024,
      system: "You always return strictly valid JSON without explanations.",
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!anthropicResponse.ok) {
    await anthropicResponse.text();
    return errorResponse("Upstream error", 502);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse("Upstream error", 502);
  }

  const text = claude.content?.find((c) => c.type === "text")?.text;
  if (!text) {
    return errorResponse("Empty response from Claude", 502);
  }

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    return errorResponse("Invalid JSON from Claude", 502);
  }

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    if (typeof parsed.translation === "string") {
      parsed.translation = capitalizeFirst(parsed.translation);
    }
    return jsonResponse(parsed);
  } catch {
    return errorResponse("Failed to parse Claude response", 502);
  }
}

async function handleSuggest(request: Request, env: Env): Promise<Response> {
  const raw = await request.json<{
    words: string[];
    learningLanguage: string;
    nativeLanguage: string;
    level?: string;
    preferredTopics?: string[];
    learningGoal?: string;
  }>();

  const words = takeList(raw.words);
  const learningLanguage = clipText(raw.learningLanguage, 48);
  const nativeLanguage = clipText(raw.nativeLanguage, 48);
  const level = clipText(raw.level, 8) ?? "";
  const preferredTopics = takeList(raw.preferredTopics, 12, 48) ?? [];
  const learningGoal = clipText(raw.learningGoal, 80);

  if (!words || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: words, learningLanguage, nativeLanguage", 400);
  }

  const lvl = levelGuideline(learningLanguage, level);
  const wordsList = words.join(", ");
  const topicsLine =
    preferredTopics.length > 0
      ? `Learner's preferred topics: ${preferredTopics.join(", ")}. Bias suggestions toward these when natural.`
      : "";
  const goalLine = learningGoal
    ? `Learner's goal: ${learningGoal}. Prefer vocabulary useful for this goal.`
    : "";

  const prompt = `You are a vocabulary assistant.

Learning language: ${learningLanguage}
Native language: ${nativeLanguage}
Learner's level: ${lvl.label}
${goalLine}
${topicsLine}

Current words:
${wordsList}

TASK:
1. Detect the main topic (one short phrase). Prefer aligning with preferred topics / goal when provided.
2. Add exactly TWO new words in ${learningLanguage}:
   - related to the topic
   - not in the list
   - suitable for the ${lvl.label} level. ${lvl.guideline}
   - common in daily use
- Provide a short example sentence in the learning language, appropriate for the ${lvl.label} level. Natural sentence casing only (capitalize sentence start and proper nouns — never Title Case every word, and do not capitalize the headword mid-sentence). Use a natural inflection or conjugation when that is how a native would say the word.
- forms → array of every conjugated or inflected surface form of the headword that appears in the example or collocations, copied exactly from that text. The form may share no letters with the headword (saber → supe, ser → soy, ir → fui, go → went). Return [] only when no inflected form appears.
- Provide a short one‑sentence explanation in the native language.
- Provide a brief breakdown/etymology in the native language if relevant (optional).
- Provide transcription that helps the learner pronounce the word correctly.
- collocations → an array of 2–4 short, very common phrases built with the word, ONLY in ${learningLanguage}. Return [] if none are natural.
- synonyms → an array of 0–3 common synonyms, ONLY in ${learningLanguage}. Return [] if there are no close synonyms.
- antonyms → an array of 0–2 common antonyms, ONLY in ${learningLanguage}. Return [] if the word has no natural opposite.
- mnemonic → one short memory hook in ${nativeLanguage}, a single sentence, or null.

STRICT:
- word and example → only ${learningLanguage}
- translation, explanation, breakdown → only ${nativeLanguage}
- Capitalization: for scripts with letter case (Latin, Cyrillic, Greek, etc.), always start both "word" and "translation" with an uppercase letter. Do not Title Case every word. Scripts without case stay as-is.
- transcription → use the most practical system for ${learningLanguage}:
  • Japanese → if the word contains kanji, show hiragana reading. If already hiragana/katakana, show romaji
  • Chinese → pinyin with tones (e.g. "chī fàn")
  • Korean → romanization (e.g. "meo-gda")
  • Arabic → simplified transliteration
  • European languages (English, French, Spanish, German, Italian, Portuguese, etc.) → IPA in slashes (e.g. /pəˈteɪtoʊ/)
  • Hindi → IAST or simplified transliteration
- valid JSON only

{
  "topic": "string",
  "suggestions": [
    {
      "word": "string",
      "translation": "string",
      "type": "string",
      "example": "string",
      "explanation": "string",
      "breakdown": "string",
      "transcription": "string",
      "collocations": ["..."],
      "synonyms": ["..."],
      "antonyms": ["..."],
      "mnemonic": null,
      "forms": ["..."]
    },
    {
      "word": "string",
      "translation": "string",
      "type": "string",
      "example": "string",
      "explanation": "string",
      "breakdown": "string",
      "transcription": "string",
      "collocations": ["..."],
      "synonyms": ["..."],
      "antonyms": ["..."],
      "mnemonic": null,
      "forms": ["..."]
    }
  ]
}`;

  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5",
      max_tokens: 1800,
      system: "You always return strictly valid JSON without explanations.",
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!anthropicResponse.ok) {
    await anthropicResponse.text();
    return errorResponse("Upstream error", 502);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse("Upstream error", 502);
  }

  const text = claude.content?.find((c) => c.type === "text")?.text;
  if (!text) {
    return errorResponse("Empty response from Claude", 502);
  }

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    return errorResponse("Invalid JSON from Claude", 502);
  }

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    if (Array.isArray(parsed.suggestions)) {
      parsed.suggestions = parsed.suggestions.map((s: Record<string, unknown>) => {
        if (typeof s.word === "string") s.word = capitalizeFirst(s.word);
        if (typeof s.translation === "string") s.translation = capitalizeFirst(s.translation);
        return s;
      });
    }
    return jsonResponse(parsed);
  } catch {
    return errorResponse("Failed to parse Claude response", 502);
  }
}

async function handleStory(request: Request, env: Env): Promise<Response> {
  const raw = await request.json<{
    words: string[];
    learningLanguage: string;
    nativeLanguage: string;
    level?: string;
    goal?: string;
    topics?: string[];
  }>();

  const words = takeList(raw.words, 12);
  const learningLanguage = clipText(raw.learningLanguage, 48);
  const nativeLanguage = clipText(raw.nativeLanguage, 48);
  const level = clipText(raw.level, 8) ?? "";
  const goal = clipText(raw.goal, 80);
  const topics = takeList(raw.topics, 12, 48) ?? [];

  if (!words || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: words, learningLanguage, nativeLanguage", 400);
  }

  const lvl = levelGuideline(learningLanguage, level);
  const wordsList = words.join(", ");
  const vibe = [goal, ...topics].filter(Boolean).join(", ");

  const prompt = `You are a short-story writer for language learners. Plot comes first. Vocabulary is optional seasoning.

Learning language: ${learningLanguage}
Native language: ${nativeLanguage}
Level: ${lvl.label}. ${lvl.guideline}
Scene flavor (use lightly): ${vibe || "everyday life"}

Candidate words (a MENU, not a checklist): ${wordsList}

Write ONE tiny story with:
- one person, one place, one desire
- a beginning, a small problem, an ending
- 5–8 sentences that cause the next sentence
- a title that names the situation, not a vocab theme

WORD RULES:
- Use 2 of the candidate words. 2 is the target.
- A word may appear only if a native speaker would say it in this scene.
- You may inflect words. Do not force a word into an awkward sentence.
- Never write one sentence per word. Never list. Never "and then they used X".
- If a word would make the story worse, choose a different fitting candidate. Do not finish with fewer than 2 candidate words.
- Never mark the candidate words. No quotation marks, no guillemets, no asterisks, no markdown, no italics, no bold. Write them as plain words in the sentence.
- Capitalization: only capitalize sentence starts and proper nouns. Candidate words mid-sentence must use natural casing (usually lowercase), even if the candidate list shows a capitalized form.

LANGUAGE:
- title and story → only ${learningLanguage}
- translation → natural ${nativeLanguage} of the whole story
- usedWords → only the candidate words you actually used, spelled as given

Return ONLY valid JSON:
{
  "title": "...",
  "story": "...",
  "translation": "...",
  "usedWords": ["...", "..."]
}`;

  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5",
      max_tokens: 1500,
      system: "You always return strictly valid JSON without explanations.",
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!anthropicResponse.ok) {
    await anthropicResponse.text();
    return errorResponse("Upstream error", 502);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse("Upstream error", 502);
  }

  const text = claude.content?.find((c) => c.type === "text")?.text;
  if (!text) {
    return errorResponse("Empty response from Claude", 502);
  }

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    return errorResponse("Invalid JSON from Claude", 502);
  }

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    const used = Array.isArray(parsed.usedWords) ? parsed.usedWords : [];
    if (used.length >= 2) {
      return jsonResponse(parsed);
    }
    const retry = await requestStory(
      env,
      `${prompt}\n\nRewrite the story so exactly 2 candidate words appear naturally in the sentences. usedWords must list those 2 words.`
    );
    if (retry && Array.isArray(retry.usedWords) && retry.usedWords.length >= used.length) {
      return jsonResponse(retry);
    }
    return jsonResponse(parsed);
  } catch {
    return errorResponse("Failed to parse Claude response", 502);
  }
}

async function requestStory(env: Env, prompt: string): Promise<Record<string, unknown> | null> {
  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5",
      max_tokens: 1500,
      system: "You always return strictly valid JSON without explanations.",
      messages: [{ role: "user", content: prompt }],
    }),
  });
  if (!anthropicResponse.ok) {
    await anthropicResponse.text();
    return null;
  }
  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();
  if (claude.error) return null;
  const text = claude.content?.find((c) => c.type === "text")?.text;
  if (!text) return null;
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return null;
  try {
    return JSON.parse(jsonMatch[0]) as Record<string, unknown>;
  } catch {
    return null;
  }
}

async function handleExtractWords(request: Request, env: Env): Promise<Response> {
  const raw = await request.json<{
    image?: string;
    text?: string;
    learningLanguage: string;
    nativeLanguage: string;
    level?: string;
  }>();

  const learningLanguage = clipText(raw.learningLanguage, 48);
  const nativeLanguage = clipText(raw.nativeLanguage, 48);
  const level = clipText(raw.level, 8) ?? "";
  const pastedText = clipText(raw.text ?? "", 12000);
  const hasImage = typeof raw.image === "string" && raw.image.length > 0 && !imageTooLarge(raw.image);

  if ((!hasImage && !pastedText) || !learningLanguage || !nativeLanguage) {
    return errorResponse(
      "Missing required fields: learningLanguage, nativeLanguage, and either image or text",
      400
    );
  }

  const lvl = levelGuideline(learningLanguage, level || "");

  const sourceHint = hasImage
    ? "Look at the image carefully. It may be a vocabulary list, a textbook or workbook page, a screenshot, or handwritten notes."
    : "Read the pasted text carefully. It may be an article excerpt, chat message, subtitle block, textbook paragraph, or a list of words.";

  const prompt = `You are a vocabulary extraction assistant for a language-learning app.

${sourceHint}

Learning language: ${learningLanguage}
Native language: ${nativeLanguage}
Learner's level: ${lvl.label}

TASK: Extract vocabulary items in ${learningLanguage} and fill a complete dictionary card for each one.

For every distinct ${learningLanguage} word or short phrase worth learning, provide:
- word: the ${learningLanguage} word or phrase exactly as written (keep the original script; if it is shown in romaji/pinyin, keep that form). Fix only obvious OCR artifacts (broken or merged characters) using your knowledge of ${learningLanguage}.
- translation: a natural translation in ${nativeLanguage}. If a translation is already shown but in another language, translate it into ${nativeLanguage} yourself.
- type: part of speech, only ${nativeLanguage}.
- explanation: 1–2 short sentences in ${nativeLanguage}. Write like you're explaining to a friend — casual, clear, helpful. Focus on when and how the word is used, not a dictionary definition. Adapt to ${lvl.label} level.
- breakdown: only ${nativeLanguage} or null. Brief etymology or word structure if helpful.
- example: only ${learningLanguage}. One sentence. MUST match the ${lvl.label} level. ${lvl.guideline} Capitalize only the first letter of each sentence (and proper nouns). Do NOT capitalize the headword mid-sentence. Use a natural inflection or conjugation of the headword when that is how a native would say it.
- forms: array of every conjugated or inflected surface form of the headword that appears in "example" or "collocations", copied exactly from that text, including accents. The form may share no letters with the headword. Examples: saber → supe, supo, sé; ser → soy, fue; ir → voy, fui; ver → vi; go → went; être → suis. Do not include synonyms or unrelated words. Return [] only when no inflected form appears.
- collocations: an array of 2–4 short, very common collocations or set phrases built with the headword, ONLY in ${learningLanguage} (no translation). Return [] if none are natural.
- synonyms: an array of 0–3 common synonyms of the headword, ONLY in ${learningLanguage}. Return [] if there are no close synonyms.
- antonyms: an array of 0–2 common antonyms, ONLY in ${learningLanguage}. Return [] if the word has no natural opposite.
- mnemonic: one short, vivid memory hook in ${nativeLanguage}, a single sentence, or null.
- transcription: phonetic transcription that helps the learner pronounce the word correctly.
  For ${learningLanguage}, use the most practical transcription system:
  • Japanese → if the word contains kanji, show hiragana reading (e.g. "たべる" for 食べる). If the word is already in hiragana or katakana, show romaji
  • Chinese → use pinyin with tones (e.g. "chī fàn")
  • Korean → use romanization (e.g. "meo-gda")
  • Arabic → use simplified transliteration
  • For European languages (English, French, Spanish, German, Italian, Portuguese, etc.) → use IPA in slashes
  • Hindi → use IAST or simplified transliteration
  Return null if not applicable.

RULES:
- Read in natural reading order and keep multi-word expressions together as a single item.
- Extract ONLY genuine ${learningLanguage} vocabulary. Skip page numbers, exercise numbers, headers, instructions, URLs, and any text that is actually in ${nativeLanguage}.
- Prefer concrete, useful words and short phrases over function words alone.
- Never repeat the same word twice.
- Return at most 20 items, prioritising the clearest, most useful vocabulary.
- Do not mix languages inside fields.
- Capitalization: for scripts that have letter case (Latin, Cyrillic, Greek, etc.), always start "word" and "translation" with an uppercase letter. Do not Title Case every word. Scripts without case stay as-is.
- Return ONLY valid JSON in exactly this shape, with no commentary:

{
  "words": [
    {
      "word": "...",
      "translation": "...",
      "type": "...",
      "example": "...",
      "explanation": "...",
      "breakdown": null,
      "transcription": "...",
      "collocations": ["..."],
      "synonyms": ["..."],
      "antonyms": ["..."],
      "mnemonic": null,
      "forms": ["..."]
    }
  ]
}

If you find no vocabulary, return { "words": [] }.`;

  const userContent: unknown[] = [];
  if (hasImage && raw.image) {
    userContent.push({
      type: "image",
      source: {
        type: "base64",
        media_type: "image/jpeg",
        data: raw.image,
      },
    });
  }
  if (pastedText) {
    userContent.push({
      type: "text",
      text: hasImage ? `${prompt}\n\nAdditional text context:\n${pastedText}` : `${prompt}\n\nTEXT:\n${pastedText}`,
    });
  } else {
    userContent.push({ type: "text", text: prompt });
  }

  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-6",
      max_tokens: 8192,
      system: "You always return strictly valid JSON without explanations.",
      messages: [
        {
          role: "user",
          content: userContent,
        },
      ],
    }),
  });

  if (!anthropicResponse.ok) {
    await anthropicResponse.text();
    return errorResponse("Upstream error", 502);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse("Upstream error", 502);
  }

  const text = claude.content?.find((c) => c.type === "text")?.text;
  if (!text) {
    return errorResponse("Empty response from Claude", 502);
  }

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    return errorResponse("Invalid JSON from Claude", 502);
  }

  try {
    const parsed = JSON.parse(jsonMatch[0]);
    return jsonResponse(parsed);
  } catch {
    return errorResponse("Failed to parse Claude response", 502);
  }
}

async function claudeJSON(
  env: Env,
  prompt: string,
  maxTokens: number
): Promise<Response> {
  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5",
      max_tokens: maxTokens,
      system: "You always return strictly valid JSON without explanations.",
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!anthropicResponse.ok) {
    await anthropicResponse.text();
    return errorResponse("Upstream error", 502);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse("Upstream error", 502);
  }

  const text = claude.content?.find((c) => c.type === "text")?.text;
  if (!text) {
    return errorResponse("Empty response from Claude", 502);
  }

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    return errorResponse("Invalid JSON from Claude", 502);
  }

  try {
    return jsonResponse(JSON.parse(jsonMatch[0]));
  } catch {
    return errorResponse("Failed to parse Claude response", 502);
  }
}

async function handleForms(request: Request, env: Env): Promise<Response> {
  const raw = await request.json<{
    word: string;
    sentences: string[];
    learningLanguage: string;
  }>();

  const word = clipText(raw.word, limits.word);
  const learningLanguage = clipText(raw.learningLanguage, 48);
  const sentences = takeList(raw.sentences, 8, 500);

  if (!word || !learningLanguage || !sentences) {
    return errorResponse("Missing required fields: word, sentences, learningLanguage", 400);
  }

  const listed = sentences.map((sentence, index) => `${index + 1}. ${sentence}`).join("\n");
  const prompt = `Identify the conjugated or inflected forms of one headword inside the sentences.

Headword: "${word}"
Language: ${learningLanguage}
Sentences:
${listed}

Return every surface form in those sentences that is a grammatical form of "${word}".
Copy each form exactly as written, including accents and capitalization.
The form may look nothing like the headword. Irregular and suppletive forms count:
saber → supe, supo, sé; ser → soy, era, fue; ir → voy, fui; ver → vi; tener → tuve; go → went; be → was, were; être → suis, fut; sein → bin, war.
Do not include synonyms, translations, or unrelated words.
If the headword only appears unchanged, return an empty array.

Return ONLY valid JSON:
{ "forms": ["..."] }`;

  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5",
      max_tokens: 256,
      system: "You always return strictly valid JSON without explanations.",
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!anthropicResponse.ok) {
    await anthropicResponse.text();
    return errorResponse("Upstream error", 502);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse("Upstream error", 502);
  }

  const text = claude.content?.find((c) => c.type === "text")?.text;
  if (!text) {
    return errorResponse("Empty response from Claude", 502);
  }

  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    return errorResponse("Invalid JSON from Claude", 502);
  }

  try {
    const parsed = JSON.parse(jsonMatch[0]) as { forms?: unknown };
    const forms = Array.isArray(parsed.forms)
      ? parsed.forms.filter((form): form is string => typeof form === "string" && form.trim().length > 0)
      : [];
    return jsonResponse({ forms });
  } catch {
    return errorResponse("Failed to parse Claude response", 502);
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204 });
    }

    if (request.method !== "POST") {
      return errorResponse("Method not allowed", 405);
    }

    if (bodyTooLarge(request)) {
      return errorResponse("Payload too large", 413);
    }

    const appKey = request.headers.get("X-App-Key") ?? "";
    if (!env.APP_KEY || !keysEqual(appKey, env.APP_KEY)) {
      return errorResponse("Unauthorized", 401);
    }

    const url = new URL(request.url);
    const allowed = await allowIP(request, url.pathname);
    if (!allowed) {
      return new Response(JSON.stringify({ error: "Too many requests" }), {
        status: 429,
        headers: {
          "Content-Type": "application/json",
          "Retry-After": "60",
        },
      });
    }

    try {
      switch (url.pathname) {
        case "/translate":
          return await handleTranslate(request, env);
        case "/suggest":
          return await handleSuggest(request, env);
        case "/tts":
          return await handleTTS(request, env);
        case "/extract-words":
          return await handleExtractWords(request, env);
        case "/story":
          return await handleStory(request, env);
        case "/forms":
          return await handleForms(request, env);
        default:
          return errorResponse("Not found", 404);
      }
    } catch {
      return errorResponse("Internal error", 500);
    }
  },
};
