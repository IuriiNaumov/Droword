# Droword

Личный словарь для изучения языков: сохраняешь слова, ИИ дополняет карточки, повторяешь по spaced repetition.

## Что делает приложение

- **Словарь** — свои слова с переводом, примерами, тегами, реакциями-эмодзи (фильтр в ряду тегов и поиск), озвучкой, редактированием. Карточки в word packs, scan и suggested выглядят как в словаре и сразу кэшируют озвучку; packs кладут слова с тегами Basics / Food / Travel / Shopping

- **AI** — перевод / enrichment, подсказки слов, истории из своих слов с вопросом по значению (текст и квиз слева), мини-чат, scan с фото или вставленного текста  
- **Share карточки** — картинка как развёрнутая словарная карточка; в Instagram Stories — слева на градиенте темы  
- **Capture** — Share: фото → сразу скан слов (полные карточки как в словаре), короткий текст → Add, длинный → extract; в приложении — scan с камеры/галереи
- **Учёба** — один daily lesson на Home (due + новые в одной очереди), Practice-квизы (на итогах без tab bar), недельный календарь без серии и заморозки, бейджи с celebration  
- **Уведомления** — тексты на 12 локалях; напоминание о повторении ставит число на иконке; при входе в приложение число сбрасывается  
- **Tab bar** — обычная системная высота, без minimize и без урезания в `sizeThatFits`  
- **Завершения** — «слова добавлены», цель дня, удаление и другие подтверждения открываются одной и той же мягкой страницей, у каждой свой цвет. Soft-cover на Home (первые слова, тур, extras, suggested, Pro, paywall) идут одной очередью и не накладываются друг на друга. Серия и заморозка спрятаны (`FeatureGates.streakEnabled`); Home-чат выключен (`homeChatEnabled`). После 5 слов, если история, задания дня или паки ещё выключены, один раз открывается страница с этими переключателями. Без PRO раз в 4 дня, начиная со второго дня, открывается приглашение к подписке.  
- **Синк** — optional iCloud (`words.json`, entitlements включены); иначе local-first App Group  
- **Кастомизация** — темы (Droword / Зелёная сова / Жидкое стекло / Свой — названия локализованы), иконки (паттерны + wordmark + 8-bit / Green Owl / Crystal, без флагов и face-вариантов; в онбординге первой показывают 8-bit), голоса, вибрации (часть — PRO)  
- **CSV** — import/export со SRS-полями  

Bundle IDs: `com.droword` · Share `com.droword.share` · Widget `com.droword.widget`  
App Group: `group.com.droword.shared` · iCloud: `iCloud.com.droword`  
Support: `hello@droword.app`

## Структура репозитория

| Путь | За что отвечает |
|------|-----------------|
| **`Droword/`** | Основное SwiftUI-приложение |
| **`DrowordShare/`** | Share Extension |
| **`Droword​Widget/`** | Виджеты: плюс «Add a new word» (Home + lock circular), 3 последних слова, Today’s lesson (прямоугольный на lock) |
| **`droword-worker/`** | API-прокси к Claude + OpenAI TTS |
| **`docs/`** | Privacy / Terms / Support (URL для App Store) |
| **`marketing/app-store/`** | Постеры, listing-копирайт, `compose.py` для скринов |
| **`scripts/`** | Утилиты (иконки, one-shot скрипты) |
| **`AGENTS.md`** | Контекст для ИИ-агентов (главная карта) |

### Внутри `Droword/`

| Папка | Роль |
|-------|------|
| **`Home/`** | Оболочка: Home / Practice / Add / Dictionary, настройки, splash. На сплэше слово «droword» проявляется из размытия одним движением, вокруг разлетаются и мерцают семь звёздочек-стикеров, потом всё затухает. С Reduce Motion — просто появление, без звёздочек и размытия |
| **`Components/`** | UI-блоки: карточки, квизы, paywall, chat scene, packs, empty states… Иконки-стикеры (в `Components/Stickers/`) меняют стиль вместе с темой: Droword — объёмные с обводкой, Зелёная сова — плоские в цветах Duolingo с «губой» снизу, Жидкое стекло — полупрозрачные с бликом и светлым краем, 8 бит — пиксельные с тёмным контуром. Стикеры — в `Components/Stickers/`: пустые состояния, онбординг, splash все модалки (подсказки, Words added, Study extras, PRO invite, празднования, алерты), Well done, Scan words, сердечки-жизни в «Соедини пары» (`StickerHeart`), значки в Achievements (вместо эмодзи: росток, веточка, дерево, кубок, корона, бриллиант, мишень, блокнот, лампочка), флаги в выборе языков (`LanguageFlagView`: плоские, с тёмным контуром как у стикеров), пустой Home (карточка слова), пустой словарь (три карточки), плашка PRO на paywall (`StickerProBadge`, без звёздочек; иконки в списке возможностей PRO — обычные). `StickerSymbol` сам подбирает стикер по имени SF Symbol |
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
| Озвучка | 10/день, повтор бесплатный; при добавлении слова аудио префетчится в кэш | безлимит |
| Подсказки слов | 4 fetch/день | безлимит |
| Scan фото/текст | 3/день | безлимит |
| Story / chat scene | дневные caps | безлимит |
| Темы / seasonal / freeze | базовое | всё, 2 заморозки за 7 дней |

Подробнее для агентов: **[AGENTS.md](./AGENTS.md)**. Перед пушем агент обновляет этот файл и `AGENTS.md`, если поведение изменилось, убирает комментарии из кода и только потом пушит.

## Быстрый старт

1. Открой `Droword.xcodeproj` → схема **Droword**.  
2. **Signing:** платная команда Apple Developer; в App ID включи iCloud (`iCloud.com.droword`). Ключи уже активны в `Droword/Droword.entitlements`.  
3. Worker (опционально): `cd droword-worker && npm install && npm run dev`

## Релиз / TestFlight

- Листинг: [marketing/app-store/LISTING.md](./marketing/app-store/LISTING.md)  
- Юр. страницы: [docs/index.html](./docs/index.html)  
- Платный Apple Developer Program: Archive → Upload в App Store Connect → TestFlight. Перед заливкой поднимай **Build** (`CURRENT_PROJECT_VERSION`) выше прошлого.  
- Фичегейты: `FeatureGates.streakEnabled` = off (серия и заморозка спрятаны); `homeChatEnabled` = off до готовности Home-чата.
