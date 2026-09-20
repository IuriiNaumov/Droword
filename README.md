# Droword

Личный словарь для изучения языков: сохраняешь слова, ИИ дополняет карточки, повторяешь по spaced repetition.

## Что делает приложение

- **Словарь** — свои слова с переводом, примерами, тегами, озвучкой  
- **AI** — перевод / enrichment, подсказки слов, истории, мини-чат, scan с фото  
- **Учёба** — daily lesson на Home, Practice-квизы, стрики и челленджи  
- **Кастомизация** — темы, иконки, голоса (часть — PRO)  
- **Local-first** — словарь на устройстве; AI ходит в Cloudflare Worker  

Bundle IDs: `com.droword` · Share `com.droword.share` · Widget `com.droword.widget`  
Support: `hello@droword.app`

## Структура репозитория

| Путь | За что отвечает |
|------|-----------------|
| **`Droword/`** | Основное SwiftUI-приложение |
| **`DrowordShare/`** | Share Extension — «Поделиться» словом в словарь |
| **`DrowordWidget/`** | Home Screen Widget |
| **`droword-worker/`** | API-прокси к Claude + OpenAI TTS |
| **`docs/`** | Privacy / Terms / Support (URL для App Store) |
| **`marketing/app-store/`** | Постеры, listing-копирайт, `compose.py` для скринов |
| **`scripts/`** | Утилиты (иконки, one-shot скрипты) |
| **`AGENTS.md`** | Контекст для ИИ-агентов |

### Внутри `Droword/`

| Папка | Роль |
|-------|------|
| **`Home/`** | Оболочка: Home / Practice / Add / Dictionary, настройки, splash |
| **`Components/`** | UI-блоки: карточки, квизы, paywall, chat scene, packs… |
| **`Components/Quiz/`** | Упражнения квиза (choice, typing, matching…) |
| **`Domain/`** | Чистая логика: SRS, due, стрик, лимиты переводов |
| **`Store/`** | Состояние и персистенс: слова, языки, IAP, бейджи |
| **`Helpers/`** | Ключи, design tokens, builders, TTS, хаптики, daily limits |
| **`Claude/`** | Клиенты API (translate, suggest, scene, extract, TTS) |
| **`ViewModels/`** | ViewModel’и (сейчас chat scene) |
| **`Onboarding/`** | Первый запуск + иллюстрации |
| **`Skeleton/`** | Скелетоны загрузки (shimmer-плейсхолдеры, пока нет данных) |
| **`Fonts/`** · **`Assets.xcassets/`** | Poppins, цвета, иконки, empty-art |
| **`AlternateIcons/`** | Альтернативные иконки приложения |

## Free vs PRO (кратко)

| | Free | PRO / trial |
|--|------|-------------|
| AI-переводы | 10/день → после недели 5/день | безлимит |
| Озвучка | 10/день | безлимит |
| Подсказки слов | 4 fetch/день | безлимит |
| Scan фото | 1/день | безлимит |
| Темы / seasonal / freeze | базовое | всё |

Подробнее для агентов: **[AGENTS.md](./AGENTS.md)**.

## Быстрый старт

1. Открой `Droword.xcodeproj` → схема **Droword**.  
2. Worker (опционально): `cd droword-worker && npm install && npm run dev`

## Релиз

- Листинг: [marketing/app-store/LISTING.md](./marketing/app-store/LISTING.md)  
- Юр. страницы: [docs/index.html](./docs/index.html)  