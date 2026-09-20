# App Store posters — copy & layout

Layout lock: **text top / device bottom**  
Headline: **3–5 words**, one benefit per frame.

## English (primary listing)

| # | File | Headline | Screen to shoot |
|---|------|----------|-----------------|
| 1 | `poster-01-hero.png` | Words that stick | Home — daily lesson + recent words |
| 2 | `poster-02-dictionary.png` | Build your dictionary | Dictionary or open word card |
| 3 | `poster-03-practice.png` | Smart spaced reviews | Practice / quiz mid-session |
| 4 | `poster-04-ai.png` | AI fills the card | Add word result / enriched card |
| 5 | `poster-05-yours.png` | Make it yours | Icon / theme picker |

## Русский (локализация листинга)

| # | Headline |
|---|----------|
| 1 | Слова, которые остаются |
| 2 | Свой словарь |
| 3 | Умные повторения |
| 4 | ИИ собирает карточку |
| 5 | Под себя |

Alt (ещё короче):  
1. Запоминай слова · 2. Твой словарь · 3. Повторяй умно · 4. Карточка с ИИ · 5. Как тебе нравится

## Shoot checklist (симулятор / устройство)

1. iPhone 15 Pro / 16 Pro, light mode, colorful theme.
2. Onboarding done, 8–12 sample words, streak ≥ 3 if possible.
3. Hide coach marks / paywalls / debug banners.
4. Capture **portrait** full screen (no status-bar clutter if possible).
5. Export PNG → drop into `marketing/app-store/raw/` as:
   - `01-home.png`
   - `02-dictionary.png`
   - `03-practice.png`
   - `04-ai-card.png`
   - `05-themes.png`

Then run:

```bash
python3 marketing/app-store/compose.py          # EN → out/
python3 marketing/app-store/compose.py --lang ru
```

Concept mocks (AI UI, not real screenshots) live next to this file:
`poster-01-…png` (EN) and `poster-01-…-ru.png` (RU).  
Final Connect uploads should come from `out/` after you drop real captures into `raw/`.

## Target export size

- iPhone 6.7": **1290 × 2796**
- iPhone 6.9": **1320 × 2868** (preferred if available)
