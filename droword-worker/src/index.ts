export interface Env {
  ANTHROPIC_API_KEY: string;
  OPENAI_API_KEY: string;
}

// CORS headers for iOS app
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
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
  const { word, learningLanguage, nativeLanguage } = await request.json<{
    word: string;
    learningLanguage: string;
    nativeLanguage: string;
  }>();

  if (!word || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: word, learningLanguage, nativeLanguage", 400);
  }

  const prompt = `You are a linguist.

Translate and explain the word "${word}".

Source language: ${learningLanguage}
Target language: ${nativeLanguage}

STRICT RULES:
- translation → only ${nativeLanguage}
- type → only ${nativeLanguage}
- explanation → short and clear, only ${nativeLanguage}
- breakdown → only ${nativeLanguage} or null
- example → only ${learningLanguage}
- transcription → IPA or phonetic transcription using Latin letters only (ASCII), e.g., /…/ or […], or null
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
      model: "claude-sonnet-4-20250514",
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
  const { words, learningLanguage, nativeLanguage } = await request.json<{
    words: string[];
    learningLanguage: string;
    nativeLanguage: string;
  }>();

  if (!words || !learningLanguage || !nativeLanguage) {
    return errorResponse("Missing required fields: words, learningLanguage, nativeLanguage", 400);
  }

  const wordsList = words.join(", ");

  const prompt = `You are a vocabulary assistant.

Learning language: ${learningLanguage}
Native language: ${nativeLanguage}

Current words:
${wordsList}

TASK:
1. Detect the main topic (one short phrase).
2. Add exactly TWO new words in ${learningLanguage}:
   - related to the topic
   - not in the list
   - suitable for A2–B1
   - common in daily use
- Provide a short example sentence in the learning language.
- Provide a short one‑sentence explanation in the native language.
- Provide a brief breakdown/etymology in the native language if relevant (optional).
- Provide transcription in IPA or a common transcription if relevant (optional).

STRICT:
- word and example → only ${learningLanguage}
- translation, explanation, breakdown → only ${nativeLanguage}
- transcription → standard IPA or common Latin transcription
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
      model: "claude-sonnet-4-20250514",
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

    const url = new URL(request.url);

    try {
      switch (url.pathname) {
        case "/translate":
          return await handleTranslate(request, env);
        case "/suggest":
          return await handleSuggest(request, env);
        case "/tts":
          return await handleTTS(request, env);
        default:
          return errorResponse("Not found", 404);
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : "Internal error";
      return errorResponse(message, 500);
    }
  },
};
