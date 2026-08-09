export interface Env {
  ANTHROPIC_API_KEY: string;
  OPENAI_API_KEY: string;
  APP_KEY: string;
}

// CORS headers for iOS app
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-App-Key",
};

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

function errorResponse(message: string, status = 500): Response {
  return jsonResponse({ error: message }, status);
}

// Maps the app's endonym language names to English names for TTS instructions.
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

// Maps a proficiency tier (CEFR code A1–C2) to a descriptive label plus
// difficulty guidance, layering language-specific script rules on top (e.g.
// kana-only for a beginner in Japanese).
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

  // Language-specific writing-system rules layered on top of the difficulty tier.
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

// ─── /translate ───
async function handleTranslate(request: Request, env: Env): Promise<Response> {
  const { word, learningLanguage, nativeLanguage, level } = await request.json<{
    word: string;
    learningLanguage: string;
    nativeLanguage: string;
    level?: string;
  }>();

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
    const text = await anthropicResponse.text();
    return errorResponse(`Anthropic API error: ${text}`, anthropicResponse.status);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse(`Claude error: ${claude.error.message}`, 502);
  }

  const text = claude.content?.find((c) => c.type === "text")?.text;
  if (!text) {
    return errorResponse("Empty response from Claude", 502);
  }

  // Extract JSON from response
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

// ─── /suggest ───
async function handleSuggest(request: Request, env: Env): Promise<Response> {
  const { words, learningLanguage, nativeLanguage, level } = await request.json<{
    words: string[];
    learningLanguage: string;
    nativeLanguage: string;
    level?: string;
  }>();

  if (!words || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: words, learningLanguage, nativeLanguage", 400);
  }

  const lvl = levelGuideline(learningLanguage, level || "");
  const wordsList = words.join(", ");

  const prompt = `You are a vocabulary assistant.

Learning language: ${learningLanguage}
Native language: ${nativeLanguage}
Learner's level: ${lvl.label}

Current words:
${wordsList}

TASK:
1. Detect the main topic (one short phrase).
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
    const text = await anthropicResponse.text();
    return errorResponse(`Anthropic API error: ${text}`, anthropicResponse.status);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse(`Claude error: ${claude.error.message}`, 502);
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

// ─── /story ───
async function handleStory(request: Request, env: Env): Promise<Response> {
  const { words, learningLanguage, nativeLanguage, level } = await request.json<{
    words: string[];
    learningLanguage: string;
    nativeLanguage: string;
    level?: string;
  }>();

  if (!words || words.length === 0 || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: words, learningLanguage, nativeLanguage", 400);
  }

  const lvl = levelGuideline(learningLanguage, level || "");
  const wordsList = words.join(", ");

  const prompt = `You are a creative language tutor writing a mini reading exercise.

Learning language: ${learningLanguage}
Native language: ${nativeLanguage}
Learner's level: ${lvl.label}

Target words to weave in (use as many as fit naturally): ${wordsList}

TASK:
Write a SHORT, coherent, engaging story or everyday dialogue of 4–6 sentences in ${learningLanguage} that naturally uses the target words in context. It must read smoothly — comprehensible input, not a list of sentences.

STRICT RULES:
- title and story → ONLY ${learningLanguage}. The story MUST match the ${lvl.label} level. ${lvl.guideline}
- Use the target words in their natural forms; you may inflect them.
- translation → a faithful, natural ${nativeLanguage} translation of the whole story.
- usedWords → the subset of the target words you actually used, exactly as given.
- Keep it warm and interesting, not a dry grammar drill.

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
    const text = await anthropicResponse.text();
    return errorResponse(`Anthropic API error: ${text}`, anthropicResponse.status);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse(`Claude error: ${claude.error.message}`, 502);
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

// ─── /extract-words ───
async function handleExtractWords(request: Request, env: Env): Promise<Response> {
  const { image, learningLanguage, nativeLanguage } = await request.json<{
    image: string;
    learningLanguage: string;
    nativeLanguage: string;
  }>();

  if (!image || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: image, learningLanguage, nativeLanguage", 400);
  }

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
    const text = await anthropicResponse.text();
    return errorResponse(`Anthropic API error: ${text}`, anthropicResponse.status);
  }

  const claude = await anthropicResponse.json<{
    content?: { type: string; text?: string }[];
    error?: { message: string };
  }>();

  if (claude.error) {
    return errorResponse(`Claude error: ${claude.error.message}`, 502);
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

// ─── /tts ───
async function handleTTS(request: Request, env: Env): Promise<Response> {
  const { text, voice, format, language } = await request.json<{
    text: string;
    voice?: string;
    format?: string;
    language?: string;
  }>();

  if (!text) {
    return errorResponse("Missing required field: text", 400);
  }

  const ttsBody: Record<string, unknown> = {
    model: "gpt-4o-mini-tts",
    input: text,
    voice: voice || "coral",
    format: format || "mp3",
  };

  // Steer pronunciation toward a native accent for the learning language.
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
    const errorText = await openaiResponse.text();
    return errorResponse(`OpenAI API error: ${errorText}`, openaiResponse.status);
  }

  // Stream audio back to client
  return new Response(openaiResponse.body, {
    status: 200,
    headers: {
      "Content-Type": "audio/mpeg",
      ...corsHeaders,
    },
  });
}

// ─── Router ───
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (request.method !== "POST") {
      return errorResponse("Method not allowed", 405);
    }

    // Validate app key
    const appKey = request.headers.get("X-App-Key");
    if (!env.APP_KEY || appKey !== env.APP_KEY) {
      return errorResponse("Unauthorized", 401);
    }

    const url = new URL(request.url);

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
        default:
          return errorResponse("Not found", 404);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : "Internal error";
      return errorResponse(message, 500);
    }
  },
};
