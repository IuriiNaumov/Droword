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
- example → only ${learningLanguage}. IMPORTANT: The example sentence MUST match the ${lvl.label} level. ${lvl.guideline}
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
- Do not mix languages inside fields.

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
  "mnemonic": null or "..."
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
- Provide a short example sentence in the learning language, appropriate for the ${lvl.label} level.
- Provide a short one‑sentence explanation in the native language.
- Provide a brief breakdown/etymology in the native language if relevant (optional).
- Provide transcription that helps the learner pronounce the word correctly.

STRICT:
- word and example → only ${learningLanguage}
- translation, explanation, breakdown → only ${nativeLanguage}
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
      "transcription": "string"
    },
    {
      "word": "string",
      "translation": "string",
      "type": "string",
      "example": "string",
      "explanation": "string",
      "breakdown": "string",
      "transcription": "string"
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
- Use at most 3 of the candidate words. 2 is better than 3. 0 is allowed if none fit.
- A word may appear only if a native speaker would say it in this scene.
- You may inflect words. Do not force a word into an awkward sentence.
- Never write one sentence per word. Never list. Never "and then they used X".
- If a word would make the story worse, drop it.
- Never mark the candidate words. No quotation marks, no guillemets, no asterisks, no markdown, no italics, no bold. Write them as plain words in the sentence.

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
    return jsonResponse(parsed);
  } catch {
    return errorResponse("Failed to parse Claude response", 502);
  }
}

async function handleExtractWords(request: Request, env: Env): Promise<Response> {
  const raw = await request.json<{
    image: string;
    learningLanguage: string;
    nativeLanguage: string;
  }>();

  const learningLanguage = clipText(raw.learningLanguage, 48);
  const nativeLanguage = clipText(raw.nativeLanguage, 48);

  if (imageTooLarge(raw.image) || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: image, learningLanguage, nativeLanguage", 400);
  }

  const image = raw.image;

  const prompt = `You are a vocabulary extraction assistant for a language-learning app.

Look at the image carefully. It may be a vocabulary list, a textbook or workbook page, a screenshot, or handwritten notes.

TASK: Extract vocabulary items in ${learningLanguage} together with a ${nativeLanguage} translation.

For every distinct ${learningLanguage} word or short phrase you can read, provide:
- word: the ${learningLanguage} word or phrase exactly as written (keep the original script; if it is shown in romaji/pinyin, keep that form). Fix only obvious OCR artifacts (broken or merged characters) using your knowledge of ${learningLanguage}.
- translation: a natural translation in ${nativeLanguage}. If the image already shows a translation but in another language, translate it into ${nativeLanguage} yourself.
- type: part of speech in ${nativeLanguage} (noun, verb, adjective, …), or null if unclear.
- transcription: a pronunciation guide suited to the language — IPA in /…/ for Latin-script languages, or romaji / pinyin / romanization for Japanese, Chinese, Korean, etc. Use null if it adds nothing.

RULES:
- Read in natural reading order and keep multi-word expressions together as a single item.
- Extract ONLY genuine ${learningLanguage} vocabulary. Skip page numbers, exercise numbers, headers, instructions, and any text that is actually in ${nativeLanguage}.
- Never repeat the same word twice.
- Return at most 60 items, prioritising the clearest, most useful vocabulary.
- Return ONLY valid JSON in exactly this shape, with no commentary:

{
  "words": [
    { "word": "...", "translation": "...", "type": "...", "transcription": "..." }
  ]
}

If you find no vocabulary, return { "words": [] }.`;

  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-sonnet-4-6",
      max_tokens: 4096,
      system: "You always return strictly valid JSON without explanations.",
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: "image/jpeg",
                data: image,
              },
            },
            {
              type: "text",
              text: prompt,
            },
          ],
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

async function handleScene(request: Request, env: Env): Promise<Response> {
  const raw = await request.json<{
    word: string;
    translation?: string;
    learningLanguage: string;
    nativeLanguage: string;
    level?: string;
    goal?: string;
    messages?: { role: string; text: string }[];
  }>();

  const word = clipText(raw.word, limits.word);
  const translation = clipText(raw.translation, limits.word);
  const learningLanguage = clipText(raw.learningLanguage, 48);
  const nativeLanguage = clipText(raw.nativeLanguage, 48);
  const level = clipText(raw.level, 8) ?? "";
  const goal = clipText(raw.goal, 80);

  if (!word || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: word, learningLanguage, nativeLanguage", 400);
  }

  const history = (Array.isArray(raw.messages) ? raw.messages : [])
    .slice(0, 8)
    .filter((m) => m?.text && (m.role === "assistant" || m.role === "user"))
    .map((m) => ({ role: m.role, text: m.text.trim().slice(0, 400) }));
  const userTurns = history.filter((m) => m.role === "user").length;
  const lvl = levelGuideline(learningLanguage, level);
  const transcript = history
    .map((m) => `${m.role === "user" ? "them" : "you"}: ${m.text}`)
    .join("\n");

  const prompt = `You are a friend helping them actually use one word. You are not a tutor and not a quiz app. You talk like a person on a sofa, not like an exercise.

Target word (they must SAY this, in the learning language): "${word}"${translation ? ` — meaning in ${nativeLanguage}: "${translation}"` : ""}
Learning language (their answers ONLY): ${learningLanguage}
Native language (YOUR questions ONLY): ${nativeLanguage}
Level: ${lvl.label}. ${lvl.guideline}
Scene flavor: ${goal || "everyday life"}

Transcript so far:
${transcript || "(empty — you ask first)"}

They have sent ${userTurns} of 3 replies.

If ${userTurns} === 0: ask ONE short question in ${nativeLanguage} about a real moment where "${word}" is the natural thing to say. Invent a tiny scene (doorway, café, phone, street). Do NOT mention "${word}". Do NOT speak ${learningLanguage}. Do NOT say the translation either if you can avoid it — describe the situation instead.
Vibe examples (write the actual question in ${nativeLanguage}):
- greeting → what do you say when you want to say hi / you walk into a café
- thanks → someone just held the door. what do you say?
- food/drink → you're at the counter. how do you ask for it?
- generic → what do you say when you mean [the idea], in a concrete moment

If ${userTurns} is 1 or 2: stay in ${nativeLanguage}. React in a few warm words like a friend, then ask a slightly different everyday situation for the SAME word. If they did not use "${word}" (any inflection counts), make the scene more concrete — still ${nativeLanguage}, still not naming the word.

If ${userTurns} >= 3: one last warm line in ${nativeLanguage} that ends it. Then stop.

RULES:
- reply → only ${nativeLanguage}. 1–2 short lines. Informal. No markdown. No quotation marks around the target word. No bullet lists.
- hint → the natural ${learningLanguage} answer that uses "${word}". A word or a tiny phrase. Always give this on the opening turn. Give it again if they missed the word.
- nudge → null
- usedWord → true if their last message used the word or a clear inflection
- done → true only when ${userTurns} >= 3

Return ONLY valid JSON:
{
  "reply": "...",
  "hint": "...",
  "nudge": null,
  "usedWord": false,
  "done": false
}`;

  return claudeJSON(env, prompt, 400);
}

async function handleTTS(request: Request, env: Env): Promise<Response> {
  const raw = await request.json<{
    text: string;
    voice?: string;
    format?: string;
    language?: string;
  }>();

  const text = clipText(raw.text, limits.tts);
  if (!text) {
    return errorResponse("Missing required field: text", 400);
  }

  const voice = clipText(raw.voice, 32) ?? "coral";
  const format = clipText(raw.format, 8) ?? "mp3";
  const language = clipText(raw.language, 48);

  const ttsBody: Record<string, unknown> = {
    model: "gpt-4o-mini-tts",
    input: text,
    voice: voice,
    format: format,
  };

  if (language) {
    const name = ttsLanguageName(language);
    ttsBody.instructions = `Read the text in ${name} using natural, native ${name} pronunciation, accent, and intonation. Do not read it with an English or American accent.`;
  }

  const openaiResponse = await fetch("https://api.openai.com/v1/audio/speech", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      Accept: "audio/mpeg",
    },
    body: JSON.stringify(ttsBody),
  });

  if (!openaiResponse.ok) {
    await openaiResponse.text();
    return errorResponse("Upstream error", 502);
  }

  return new Response(openaiResponse.body, {
    status: 200,
    headers: {
      "Content-Type": "audio/mpeg",
    },
  });
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
        case "/scene":
          return await handleScene(request, env);
        default:
          return errorResponse("Not found", 404);
      }
    } catch {
      return errorResponse("Internal error", 500);
    }
  },
};
