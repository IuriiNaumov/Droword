# Droword — context for AI agents

Language-learning iOS app: personal dictionary + SRS reviews + AI enrichment (translate, suggest, story, chat scene, photo extract, TTS). Local-first data; Claude/OpenAI go through a Cloudflare Worker.

Use this file as the default project map. Prefer reading real code over inventing architecture.

---

## Product in one paragraph

User picks native + learning language (CEFR A1–C2). Adds words (manual, share extension, camera scan). AI fills translation, examples, transcription, etc. Home runs a short **daily lesson**; Practice is extra quizzes. Progress: streaks, badges, study time, daily challenges. Monetization: free daily caps vs Pro (StoreKit).

Tone: friendly tutor, Duolingo-adjacent energy (`DuoChaosCopy`, soft chaos), not corporate.

---

## Repo layout

| Path | Role |
|------|------|
| `Droword/` | Main SwiftUI app |
| `Droword.xcodeproj/` | Xcode project |
| `droword-worker/` | Cloudflare Worker API (`src/index.ts`, `src/guard.ts`) |
| `DrowordShare/` | Share extension → add word into app |
| `DrowordWidget/` | Home-screen widget (lightweight launcher) |
| `docs/` | Privacy / terms HTML |
| `scripts/` | Icon generation helpers |

Bundle IDs: `com.droword`, share `com.droword.share`, widget `com.droword.widget`.  
App Group: `group.com.droword.shared` (words + language prefs shared with extensions/widget).

---

## App architecture (SwiftUI)

### Entry

- `DrowordApp.swift` — wires stores, appearance, trial, notifications, enrichment retry, study-time session.
- `ContentView` — splash → onboarding **or** `HomeView`.

### Environment objects (injected from app root)

- `WordsStore` — dictionary + SRS fields, persistence, widget reload
- `SuggestedWordsStore` — AI word suggestions
- `LanguageStore` — native/learning language, CEFR level, learning score / auto-level
- `ThemeStore` — palettes (free = default colorful; Pro unlocks others / glass)
- `BadgeStore` — achievements
- `StudyTimeTracker` — session timing for challenges/stats

Other notable stores (often `.shared`): `LearningProfileStore`, `StudyActivityStore`, `TagStore`, `StoreKitManager`.

### Folder map (`Droword/`)

| Folder | What belongs here |
|--------|-------------------|
| `Home/` | Tabs shell, dictionary, settings, stats, add-word |
| `Components/` | UI building blocks, practice, quiz, chat scene, premium, packs |
| `Components/Quiz/` | Multiple choice, typing, matching exercises |
| `Domain/` | Pure logic: SRS, due checks, streak, limits, scene models |
| `Store/` | Observable persistence / IAP |
| `Helpers/` | Keys, design tokens, builders, TTS, haptics, notifications copy |
| `Claude/` | API client wrappers (translate, suggest, scene, extract, TTS) |
| `Droword/Claude/` | Story generation (`ClaudeStory.swift`) |
| `Onboarding/` | First-run flow + illustrations |
| `ViewModels/` | `ChatSceneViewModel` |
| `Skeleton/` | Loading placeholders |

### Navigation / tabs (`HomeView`)

Tabs: **home** · **practice** · **add** · **list** (dictionary).  
Home focuses on today’s lesson + recent words; Practice is optional extra drills.

---

## Core domain

### `StoredWord` (`WordsStore.swift`)

Identity + copy: `word`, `type`, `translation`, `example`/`examples`, `explanation`, `breakdown`, `transcription`, `comment`, `tag`, languages, dates.  
SRS: `easeFactor`, `intervalDays`, `repetitions`, `lapses`, `dueDate`, `introduced`.  
Enrichment extras: `collocations`, `synonyms`, `antonyms`, `mnemonic`, `reaction`, `needsEnrichment`.

Persistence: App Group file storage (migrated from UserDefaults). Call `flushPendingSave()` on background; `reloadFromDisk()` on foreground.

### SRS (`Domain/SRSScheduler.swift`, `WordDue.swift`)

SM-2–inspired. Grades: hard / good / easy (reviews) and quiz correct/almost/strong.  
Hard → short delay (~10 min) + reinsert. Due only if `introduced` and `dueDate <= now`.

### Daily lesson (`DailyLessonBuilder`)

Picks due + topic/weak words into a short session plan (goal/topics from learning preferences). Cap on new words/day: `DailyLimitsManager.maxNewWordsPerDay` (12).

### Practice / quiz

Directions L1↔L2. Modes include typing, matching, multiple choice (`QuizSessionManager` + `Components/Quiz/`). Results feed SRS + learning score.

### Chat scene

Role-play dialogue using user’s words (`ClaudeScene`, `ChatSceneView`, `ChatSceneViewModel`). Can launch from notifications (`ChatSceneLaunch`).

### Story

`generateStory` / `/story` — short story from a handful of dictionary words (`ClaudeStory.swift`).

### Streaks & challenges

`DayStreak` (+ Pro streak freeze), `DailyChallengeManager`, badges via `BadgeStore`, milestones/celebrations on Home.

---

## AI / backend

### Client

`Claude/APIClient.swift`  
- Base URL: `https://droword-api.droword.workers.dev`  
- Auth header: `X-App-Key` (obfuscated in app; **not** a real secret)  
- Helpers: `makeRequest`, `perform`, `validateResponse` (maps 429, offline)

Wrappers:

| Swift | Worker path | Purpose |
|-------|-------------|---------|
| `ClaudeTranslate` | `POST /translate` | Word card enrichment |
| `ClaudeSuggestedWord` | `POST /suggest` | Suggested vocabulary |
| `ClaudeStory` | `POST /story` | Story from words |
| `ClaudeScene` | `POST /scene` | Chat scene turns |
| `ClaudeExtractWords` | `POST /extract-words` | Words from photo/OCR payload |
| `AudioManager` | `POST /tts` | OpenAI TTS audio |

Prompts and CEFR/script rules live in **`droword-worker/src/index.ts`**. Rate limits / body size / key check in `guard.ts`. Worker README: `droword-worker/README.md`.

### Free vs Pro limits (client-side)

`DailyLimitsManager` + `TranslationLimits` (local UserDefaults, reset each calendar day).  
Free checks are always `isPremium || DailyLimitsManager.can…`.

| Feature | Free | Pro / active trial |
|---------|------|--------------------|
| AI translations | **10/day** first 7 days after install, then **5/day** | Unlimited |
| TTS | **10/day** | Unlimited |
| Suggestion fetches | **4/day** | Unlimited |
| Photo scan | **1/day** | Unlimited |
| New words into lesson | **12/day** (all users) | same |
| Themes / seasonal / streak freeze | Default theme only | Unlocked |

Optional **7-day PRO trial** (button on paywall) sets `isPremium` via `hasUsedTrial` + `trialStartDate` (+ Keychain). That is separate from the soft translation ramp above.

IAP: `com.droword.pro.monthly`, `com.droword.pro.yearly`. Flag: `AppStorageKeys.isPremium`.

Worker IP limits in `guard.ts` are abuse protection only — not the product paywall.

---

## UI / design conventions

- Fonts: bundled **Poppins** (registered in `DrowordApp`).
- Spacing / radius: `Helpers/DesignTokens.swift` (`DesignSpacing`, `DesignRadius`).
- Themes: `ThemeStore` palettes; prefer `themeStore.mainAccentColor`, `cleanCard(themeStore:)`, `modernSheet()`.
- Buttons: `PressableButtonStyle`, `DuoButtonStyle` where existing screens use them.
- Localization: `Localizable.xcstrings` + `String(localized:)` / `LocalizedStringKey`. Many locales in Share extension `.lproj`.
- Settings keys: always add to `AppStorageKeys` — do not scatter raw string keys.
- iPad: `iPadContentWidth` for readable width.

Match neighboring screen patterns (sheet chrome, close/back buttons, toast/coach marks) before inventing new layout systems.

---

## Important behaviors to preserve

1. **Local-first** — dictionary must work offline; AI features degrade with clear copy (`SceneOfflineCopy`, network monitor).
2. **Enrichment** — `WordEnrichmentService` retries `needsEnrichment` words when online.
3. **App Group** — word/language changes must remain visible to Share/Widget.
4. **Home vs Practice** — Home = today’s lesson; don’t dump all quiz UI onto Home.
5. **Non-Pro theme lock** — on active scene, non-premium forced back to `.colorful`.
6. **Secrets** — never commit real `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `APP_KEY`; local worker uses `.dev.vars`.
7. **Don’t rewrite worker prompts** casually — they encode CEFR + Japanese/Chinese/Korean script rules.
8. **node_modules** under `droword-worker/` — ignore; not app source.

---

## Typical change map

| Task | Start here |
|------|------------|
| Dictionary / word card UI | `DictionaryView`, `WordCardView`, `AddWordView` |
| SRS / due logic | `SRSScheduler`, `WordDue`, `WordsStore` |
| Daily lesson | `DailyLessonBuilder`, `DailyLessonSessionView`, `DailyLessonCard` |
| Quiz | `PracticeView`, `QuizSessionManager`, `Components/Quiz/*` |
| AI translate/suggest | `Claude/*.swift` + worker handlers |
| Chat scene | `ChatSceneView`, `ChatSceneViewModel`, `ClaudeScene` |
| Paywall / limits | `PremiumView`, `DailyLimitsManager`, `StoreKitManager` |
| Onboarding | `Onboarding/*` |
| Settings / flags | `SettingsView`, `FeatureFlagsView`, `AppStorageKeys` |
| Notifications | `NotificationManager`, `NotificationCopy`, `DrowordApp` |
| Themes / seasonal | `ThemeStore`, `SeasonalOverlayView`, season components |
| Worker API | `droword-worker/src/index.ts`, `guard.ts` |

---

## Dev commands

```bash
# iOS: open Droword.xcodeproj in Xcode, run the Droword scheme

cd droword-worker && npm install && npm run dev    # http://localhost:8787
cd droword-worker && npm run deploy                # after wrangler secrets
```

---

## Agent working agreements

- Keep diffs focused; no drive-by refactors or unrelated markdown.
- Prefer existing helpers/stores over new parallel state.
- When adding user-facing strings, update `Localizable.xcstrings` (or use `String(localized:)` consistently).
- Commit only when the user asks; never force-push or rewrite git history.
- If unsure where a feature lives, search `Droword/` and this map before creating new top-level folders.
