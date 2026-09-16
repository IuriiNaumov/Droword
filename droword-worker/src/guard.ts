/** Request guards: size, rate, key compare. Native iOS ignores CORS; browsers should not call this API. */

const MAX_BODY_BYTES = 1_800_000;
const MAX_WORD = 200;
const MAX_TTS = 400;
const MAX_IMAGE_B64 = 1_600_000;
const MAX_LIST = 50;

export function clientIP(request: Request): string {
  return request.headers.get("CF-Connecting-IP") || request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() || "local";
}

export function keysEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mix = 0;
  for (let i = 0; i < a.length; i++) mix |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return mix === 0;
}

export function bodyTooLarge(request: Request): boolean {
  const raw = request.headers.get("content-length");
  if (!raw) return false;
  const n = Number(raw);
  return Number.isFinite(n) && n > MAX_BODY_BYTES;
}

export function clipText(value: unknown, max: number): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > max) return null;
  return trimmed;
}

/** Truncates oversized lists so a fat vocab dump cannot inflate the Claude prompt. */
export function takeList(value: unknown, maxItems = MAX_LIST, maxItem = MAX_WORD): string[] | null {
  if (!Array.isArray(value) || value.length === 0) return null;
  const out: string[] = [];
  for (const item of value) {
    if (out.length >= maxItems) break;
    if (typeof item !== "string") continue;
    const t = item.trim();
    if (!t || t.length > maxItem) continue;
    out.push(t);
  }
  return out.length ? out : null;
}

export function imageTooLarge(b64: unknown): boolean {
  return typeof b64 !== "string" || b64.length === 0 || b64.length > MAX_IMAGE_B64;
}

export const limits = {
  word: MAX_WORD,
  tts: MAX_TTS,
};

type Window = { max: number; seconds: number };

const PATH_LIMITS: Record<string, Window> = {
  "/translate": { max: 40, seconds: 60 },
  "/suggest": { max: 12, seconds: 60 },
  "/tts": { max: 12, seconds: 60 },
  "/extract-words": { max: 6, seconds: 60 },
  "/story": { max: 8, seconds: 60 },
  "/scene": { max: 20, seconds: 60 },
};

const DAY_LIMITS: Record<string, number> = {
  "/translate": 250,
  "/suggest": 40,
  "/tts": 80,
  "/extract-words": 20,
  "/story": 30,
  "/scene": 80,
};

async function bump(cache: Cache, key: string, max: number, ttl: number): Promise<boolean> {
  const req = new Request(key);
  const hit = await cache.match(req);
  const count = hit ? parseInt(await hit.text(), 10) || 0 : 0;
  if (count >= max) return false;
  await cache.put(
    req,
    new Response(String(count + 1), {
      headers: { "Cache-Control": `max-age=${ttl}` },
    })
  );
  return true;
}

/** Per-IP minute + day caps. Best-effort (edge cache); bursts can slightly overshoot. */
export async function allowIP(request: Request, path: string): Promise<boolean> {
  const ip = encodeURIComponent(clientIP(request));
  const window = PATH_LIMITS[path] ?? { max: 30, seconds: 60 };
  const dayMax = DAY_LIMITS[path] ?? 200;
  const cache = caches.default;
  const minute = Math.floor(Date.now() / (window.seconds * 1000));
  const day = Math.floor(Date.now() / 86_400_000);

  const minuteOk = await bump(
    cache,
    `https://droword.rate/m/${path}/${ip}/${minute}`,
    window.max,
    window.seconds
  );
  if (!minuteOk) return false;

  return bump(cache, `https://droword.rate/d/${path}/${ip}/${day}`, dayMax, 86_400);
}
