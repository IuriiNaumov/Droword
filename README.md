# Droword

Личный словарь для изучения языков: сохраняешь слова, ИИ дополняет карточки, повторяешь по spaced repetition.

## Что делает приложение

- **Словарь** — свои слова с переводом, примерами, тегами, озвучкой, редактированием  
- **AI** — перевод / enrichment, подсказки слов, истории, мини-чат, scan с фото или вставленного текста  
- **Capture** — Share (короткий → Add, длинный → extract), scan фото  
- **Учёба** — один daily lesson на Home (due + новые в одной очереди), Practice-квизы, стрики, бейджи с celebration  
- **Синк** — optional iCloud (`words.json`); иначе local-first App Group  
- **Кастомизация** — темы (в т.ч. Green Owl), иконки, голоса (часть — PRO)  
- **CSV** — import/export со SRS-полями  

Bundle IDs: `com.droword` · Share `com.droword.share` · Widget `com.droword.widget`  
App Group: `group.com.droword.shared` · iCloud: `iCloud.com.droword`  
Support: `hello@droword.app`

## Структура репозитория

| Путь | За что отвечает |
|------|-----------------|
| **`Droword/`** | Основное SwiftUI-приложение |
| **`DrowordShare/`** | Share Extension |
| **`DrowordWidget/`** | Home Screen Widget |
| **`droword-worker/`** | API-прокси к Claude + OpenAI TTS |
| **`docs/`** | Privacy / Terms / Support (URL для App Store) |
| **`marketing/app-store/`** | Постеры, listing-копирайт, `compose.py` для скринов |
| **`scripts/`** | Утилиты (иконки, one-shot скрипты) |
| **`AGENTS.md`** | Контекст для ИИ-агентов (главная карта) |

### Внутри `Droword/`

| Папка | Роль |
|-------|------|
| **`Home/`** | Оболочка: Home / Practice / Add / Dictionary, настройки, splash |
| **`Components/`** | UI-блоки: карточки, квизы, paywall, chat scene, packs, empty states… |
| **`Components/Quiz/`** | Упражнения квиза |
| **`Domain/`** | Чистая логика: SRS, due, стрик, лимиты |
| **`Store/`** | Состояние и персистенс: слова, языки, IAP, бейджи |
| **`Helpers/`** | Ключи, design tokens, builders, TTS, iCloud sync, daily limits |
| **`Claude/`** | Клиенты API (translate, suggest, scene, extract, TTS) |
| **`ViewModels/`** | ViewModel’и (chat scene) |
| **`Onboarding/`** | Первый запуск + иллюстрации |
| **`Skeleton/`** | Скелетоны загрузки |
| **`Fonts/`** · **`Assets.xcassets/`** | Poppins, цвета, иконки, empty-art |
| **`AlternateIcons/`** | Альтернативные иконки |

## Free vs PRO (кратко)

| | Free | PRO / trial |
|--|------|-------------|
| AI-переводы | 10/день → после недели 5/день | безлимит |
| Озвучка | 10/день | безлимит |
| Подсказки слов | 4 fetch/день | безлимит |
| Scan фото/текст | 1/день | безлимит |
| Story / chat scene | дневные caps | безлимит |
| Темы / seasonal / freeze | базовое | всё |

Подробнее для агентов: **[AGENTS.md](./AGENTS.md)**.

## Быстрый старт

1. Открой `Droword.xcodeproj` → схема **Droword**.  
2. **Personal Team:** iCloud-ключи в `Droword/Droword.entitlements` закомментированы — иначе signing error. После оплаты Developer Program — раскомментировать + включить iCloud на App ID.  
3. Worker (опционально): `cd droword-worker && npm install && npm run dev`

## Релиз

- Листинг: [marketing/app-store/LISTING.md](./marketing/app-store/LISTING.md)  
- Юр. страницы: [docs/index.html](./docs/index.html)  
- Нужен платный Apple Developer Program для TestFlight / iCloud / кастомных capabilities  
