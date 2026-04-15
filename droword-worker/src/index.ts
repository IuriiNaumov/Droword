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

  const cefrLevel = level || "A1";

  const levelGuidelines: Record<string, string> = {
    A1: "Use only the most basic vocabulary and very short sentences (3–5 words). Present tense only. No idioms or complex grammar.",
    A2: "Use simple everyday vocabulary and short sentences (5–8 words). Simple past and present tenses. No idioms.",
    B1: "Use intermediate vocabulary with compound sentences. Common tenses including future. Simple connectors (because, but, so).",
    B2: "Use varied vocabulary with natural, fluent sentences. All common tenses. Idiomatic expressions are OK.",
    C1: "Use advanced vocabulary, complex sentence structures, and natural idiomatic expressions.",
    C2: "Use sophisticated, native-level language with nuanced vocabulary, idioms, and complex grammar.",
  };

  const exampleGuideline = levelGuidelines[cefrLevel] || levelGuidelines["A1"];

  const prompt = `You are a linguist.

Translate and explain the word "${word}".

Source language: ${learningLanguage}
Target language: ${nativeLanguage}
Learner's CEFR level: ${cefrLevel}

STRICT RULES:
- translation → only ${nativeLanguage}
- type → only ${nativeLanguage}
- explanation → short and clear, only ${nativeLanguage}. Adapt complexity to ${cefrLevel} level.
- breakdown → only ${nativeLanguage} or null
- example → only ${learningLanguage}. IMPORTANT: The example sentence MUST match CEFR ${cefrLevel} level. ${exampleGuideline}
- transcription → IPA phonemic transcription in slashes, e.g., /paˈlaβɾa/. Always use /…/ format (never square brackets). Use only standard IPA symbols. Return null if not applicable.
- Do not mix languages inside fields.

Return ONLY valid JSON:

{
  "translation": "...",
  "example": "...",
  "type": "...",
  "explanation": "...",
  "breakdown": null or "...",
  "transcription": null or "..."
}`;

  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-3-5-haiku-20241022",
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

  const cefrLevel = level || "A1";
  const wordsList = words.join(", ");

  const prompt = `You are a vocabulary assistant.

Learning language: ${learningLanguage}
Native language: ${nativeLanguage}
Learner's CEFR level: ${cefrLevel}

Current words:
${wordsList}

TASK:
1. Detect the main topic (one short phrase).
2. Add exactly TWO new words in ${learningLanguage}:
   - related to the topic
   - not in the list
   - suitable for ${cefrLevel} level
   - common in daily use
- Provide a short example sentence in the learning language, appropriate for ${cefrLevel} level.
- Provide a short one‑sentence explanation in the native language.
- Provide a brief breakdown/etymology in the native language if relevant (optional).
- Provide transcription in IPA using /…/ slashes if relevant (optional).

STRICT:
- word and example → only ${learningLanguage}
- translation, explanation, breakdown → only ${nativeLanguage}
- transcription → IPA phonemic transcription in slashes /…/ format only (never square brackets)
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
      model: "claude-3-5-haiku-20241022",
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

  const prompt = `You are a vocabulary extraction assistant.

Look at this image carefully. It contains words, a vocabulary list, a textbook page, or handwritten notes.

TASK:
Extract all word–translation pairs you can find in the image.

The words are in ${learningLanguage} with translations in any language.
Translate each word into ${nativeLanguage}.

For each word provide:
- word: the word in ${learningLanguage} (if the word is in a different script like romaji/pinyin, keep it as shown)
- translation: translation in ${nativeLanguage}
- type: part of speech in ${nativeLanguage} (noun, verb, adjective, etc.) or null
- transcription: IPA transcription in /…/ format if applicable, or null

STRICT RULES:
- Return ONLY valid JSON
- translation must be in ${nativeLanguage}
- If a word already has a translation visible in the image but it's not in ${nativeLanguage}, translate it to ${nativeLanguage}
- Skip headers, numbers, and non-word content
- If no words are found, return empty array

{
  "words": [
    { "word": "...", "translation": "...", "type": "...", "transcription": "..." }
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
      model: "claude-sonnet-4-20250514",
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
  const { text, voice, format } = await request.json<{
    text: string;
    voice?: string;
    format?: string;
  }>();

  if (!text) {
    return errorResponse("Missing required field: text", 400);
  }

  const openaiResponse = await fetch("https://api.openai.com/v1/audio/speech", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      Accept: "audio/mpeg",
    },
    body: JSON.stringify({
      model: "gpt-4o-mini-tts",
      input: text,
      voice: voice || "coral",
      format: format || "mp3",
    }),
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
        default:
          return errorResponse("Not found", 404);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : "Internal error";
      return errorResponse(message, 500);
    }
  },
};
