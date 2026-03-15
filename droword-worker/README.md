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
```

### 3. Задеплой

```bash
npm run deploy
```

Worker будет доступен на `https://droword-api.<твой-аккаунт>.workers.dev`.

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
