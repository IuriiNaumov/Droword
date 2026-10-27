# App Store posters — copy & layout

Layout: **headline on a color field, phone below, sticker accents.**  
Size: **1320 × 2868** (iPhone 6.9"). Also works as 6.7" (1290 × 2796) if you scale.

Headline: **3–6 words**, one benefit per frame. Gold (or purple on yellow) marks the punch word.

## English (primary listing)

| # | File | Headline | Screen |
|---|------|----------|--------|
| 1 | `poster-01-en.png` | Words that actually **stick** | Home — daily lesson |
| 2 | `poster-02-en.png` | **5 minutes.** One lesson. Every day. | Today's lesson quiz |
| 3 | `poster-03-en.png` | AI fills **the whole card** | Dictionary + zoomed card |
| 4 | `poster-04-en.png` | Snap a page. **Keep the words.** | Scan words |
| 5 | `poster-05-en.png` | Practice that **feels like a game** | Practice quiz |
| 6 | `poster-06-en.png` | Make it **yours** | Home in Green Owl / Glass / 8-bit |

## Русский

| # | File | Headline |
|---|------|----------|
| 1 | `poster-01-ru.png` | Слова, которые **остаются** |
| 2 | `poster-02-ru.png` | **5 минут.** Один урок. Каждый день. |
| 3 | `poster-03-ru.png` | ИИ заполнит **всю карточку** |
| 4 | `poster-04-ru.png` | Сфоткай страницу — **слова в словаре** |
| 5 | `poster-05-ru.png` | Практика, **как игра** |
| 6 | `poster-06-ru.png` | Сделай **под себя** |

## Colors (Droword stickers)

Purple `#5452E6` · Pink `#E8457A` · Blue `#2E6BF2` · Gold `#FFB82E` · Green `#2DB46A` · Ink `#1E1A3C`

Stickers are rendered from `Components/Stickers/` (star, sparkles, heart, bulb, check, book, tag, trophy, target).

## How to rebuild

1. Seed demo words and capture portrait screens into `marketing/app-store/raw/en/` and `raw/ru/` (`home`, `lesson`, `dictionary`, `scan`, `practice`, `home-duolingo`, `home-glass`, `home-pixel`).
2. Sticker PNGs live in `raw/stickers/` (from the Mac render harness).
3. Run:

```bash
python3 marketing/app-store/compose.py
python3 marketing/app-store/compose.py --lang ru
```

Upload `out/poster-0N-en.png` (and `-ru.png` for the Russian listing) in App Store Connect.
