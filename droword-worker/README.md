# Droword API Worker

Cloudflare Worker, проксирующий запросы к Anthropic Claude и OpenAI TTS.

## Эндпоинты

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/translate` | Перевод слова через Claude |
| POST | `/suggest` | Подсказки слов через Claude |
| POST | `/tts` | Озвучка через OpenAI TTS |

## Установка

```bash
cd droword-worker
npm install
```

## Локальная разработка

```bash
npm run dev
```

Worker будет доступен на `http://localhost:8787`.

Для локальной разработки создай файл `.dev.vars`:

```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-proj-...
APP_KEY=...
```

## Деплой

### 1. Залогинься в Cloudflare

```bash
npx wrangler login
```

### 2. Установи секреты

```bash
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put APP_KEY
```

### 3. Задеплой

```bash
npm run deploy
```

Worker будет доступен на `https://droword-api.<твой-аккаунт>.workers.dev`.

## Защита

Ключ в приложении не секрет: его достают из IPA. На воркере это компенсируется лимитами, а не «прятанием» ключа.

- `X-App-Key` обязателен. Без него — 401.
- CORS закрыт: браузерный `fetch` с сайта не пройдёт. Нативное iOS-приложение CORS не использует.
- Тело больше ~1.8 MB — 413. TTS/слова/списки обрезаются.
- Лимиты по IP (минута / день): translate 40/250, suggest 12/40, tts 12/80, extract-words 6/20, story 8/30, scene 20/80. Счётчик — Cache API, небольшой овершут возможен.
- Ошибки Anthropic/OpenAI наружу не светятся.

Лимиты free/PRO по-прежнему живут в приложении. Обогнать paywall прямым вызовом API всё ещё можно, но жечь Claude пачкой запросов — уже нет.

## Формат запросов

### /translate

```json
{
  "word": "hello",
  "learningLanguage": "English",
  "nativeLanguage": "Русский"
}
```

### /suggest

```json
{
  "words": ["hello", "world", "cat"],
  "learningLanguage": "English",
  "nativeLanguage": "Русский"
}
```

### /tts

```json
{
  "text": "Hello world",
  "voice": "coral",
  "format": "mp3"
}
```

Возвращает `audio/mpeg` данные.
