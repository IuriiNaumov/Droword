# Droword — context for AI agents

Language-learning iOS app: personal dictionary + SRS reviews + AI enrichment (translate, suggest, story, chat scene, photo/text extract, TTS). Local-first data; Claude/OpenAI go through a Cloudflare Worker.

Use this file as the default project map. Prefer reading real code over inventing architecture.

---

## Product in one paragraph

User picks native + learning language (CEFR A1–C2). Adds words (manual, Share, camera scan). AI fills translation, examples, transcription, etc. Home shows **one primary CTA**: today’s daily lesson (due reviews + new/weak words in one queue). Practice is optional extra quizzes. Progress: streaks, badges (+ celebration overlays), study time, daily challenges. Optional iCloud sync for the dictionary file. Monetization: free daily caps vs Pro (StoreKit).

Tone: friendly tutor, Duolingo-adjacent energy (`DuoChaosCopy`, soft chaos), not corporate.

---

## Repo layout

| Path | Role |
|------|------|
| `Droword/` | Main SwiftUI app |
| `Droword.xcodeproj/` | Xcode project |
| `droword-worker/` | Cloudflare Worker API (`src/index.ts`, `src/guard.ts`) |
| `DrowordShare/` | Share extension → short text = Add; long text = extract |
| `DrowordWidget/` | Home-screen widget (lightweight launcher) |
| `docs/` | Privacy / terms / support HTML |
| `marketing/app-store/` | Listing copy, poster compose helpers |
| `scripts/` | Icon / preview helpers |

Bundle IDs: `com.droword`, share `com.droword.share`, widget `com.droword.widget`.  
App Group: `group.com.droword.shared` (words + language prefs shared with extensions/widget).  
iCloud container: `iCloud.com.droword` (optional sync of `words.json`).

---

## App architecture (SwiftUI)

### Entry

- `DrowordApp.swift` — wires stores, appearance, trial, notifications, enrichment retry, study-time session, Share deep links (`pendingSharedWord` / `pendingSharedText` → extract).
- `ContentView` — splash → onboarding **or** `HomeView`.

### Environment objects (injected from app root)

- `WordsStore` — dictionary + SRS fields, persistence, widget reload, optional iCloud push/pull
- `SuggestedWordsStore` — AI word suggestions
- `LanguageStore` — native/learning language, CEFR level, learning score / auto-level
- `ThemeStore` — palettes (free = default colorful; Pro unlocks others / glass / Green Owl)
- `BadgeStore` — achievements + `pendingCelebration`
- `StudyTimeTracker` — session timing for challenges/stats

Other notable stores (often `.shared`): `LearningProfileStore`, `StudyActivityStore`, `TagStore`, `StoreKitManager`.

### Folder map (`Droword/`)

| Folder | What belongs here |
|--------|-------------------|
| `Home/` | Tabs shell, dictionary, settings, stats, add-word |
| `Components/` | UI building blocks, practice, quiz, chat scene, premium, packs, empty states |
| `Components/Quiz/` | Multiple choice, typing, matching, listening, cloze, sentence building |
| `Domain/` | Pure logic: SRS, due checks, streak, limits, scene models |
| `Store/` | Observable persistence / IAP / badges |
| `Helpers/` | Keys, design tokens, builders, TTS, haptics, iCloud sync, notifications copy |
| `Claude/` | API client wrappers (translate, suggest, scene, extract, TTS) |
| `Droword/Claude/` | Story generation (`ClaudeStory.swift`) |
| `Onboarding/` | First-run flow + illustrations |
| `ViewModels/` | `ChatSceneViewModel` |
| `Skeleton/` | Loading placeholders |

### Navigation / tabs (`HomeView`)

Tabs: **home** · **practice** · **add** · **list** (dictionary).  
Home hero = **`DailyLessonCard` only** (no separate due-review / next-review cards). Practice = optional extra drills.

---

## Core domain

### `StoredWord` (`WordsStore.swift`)

Identity + copy: `word`, `type`, `translation`, `example`/`examples`, `explanation`, `breakdown`, `transcription`, `comment`, `tag`, languages, dates.  
SRS: `easeFactor`, `intervalDays`, `repetitions`, `lapses`, `dueDate`, `introduced`.  
Enrichment extras: `collocations`, `synonyms`, `antonyms`, `mnemonic`, `reaction`, `needsEnrichment`.

Persistence: App Group file storage (migrated from UserDefaults). Call `flushPendingSave()` on background; `reloadFromDisk()` on foreground.  
Edit existing cards via `EditWordView` (from `WordCardView`). Tag delete clears `StoredWord.tag` via `WordsStore.clearTag`.

New cards stay `introduced == false` until a lesson introduces them (daily new-word cap). Offline add without AI is allowed when the free translate quota is spent (`needsEnrichment` / local save path in `AddWordView`).

### SRS (`Domain/SRSScheduler.swift`, `WordDue.swift`)

SM-2–inspired. Grades: hard / good / easy (reviews) and quiz correct/almost/strong.  
Hard → short delay (~10 min) + reinsert. Due only if `introduced` and `dueDate <= now`.  
`WordDue.isUpcoming` used for “next review” copy on a completed lesson card.

### Daily lesson (`DailyLessonBuilder` + `DailyLessonCard`)

**Single Home learning surface.** Queue order: carryover → **due (fill up to `maxWords`)** → new (capped by `DailyLimitsManager.newWordsRemainingToday`) → weak → topical → rest.  
`minWords = 4`, `maxWords = 8`. New words/day cap: `DailyLimitsManager.maxNewWordsPerDay` (12).

Card states:
- Locked (< 4 eligible words) → CTA opens add-word (`onAddWords`)
- Ready → start `DailyLessonSessionView` (quiz mix)
- Done → score + next-review countdown (or tomorrow word preview); dismissible for the calendar day

Do **not** reintroduce separate Home due-review / quick-review CTAs next to the lesson.

### Practice / quiz

Directions L1↔L2. Modes include typing, matching, multiple choice, listening, cloze, sentence building (`QuizSessionManager` + `Components/Quiz/`). Results feed SRS + learning score. Skipping listening must not count as a correct SRS grade.

Feedback colors: Practice correct/wrong use `successStrong` / `errorStrong` = theme `accentGreen` / `accentRed` (same as word toasts «Красава» / errors). Duo soft pastel fills stay Green Owl only.

Empty Practice / not-enough / locked lesson use `PracticeEmptyContent` with a strong **Add a word** CTA (`NotificationCenter.openAddWord`).

### Capture / Scan

- **Scan toolbar**: camera / library (`ScanWordsView`).
- Share: short → Add; long / `pendingSharedText` → extract (`droword://extract`, `/extract-words` text).
- Dedup: words already in the dictionary are not re-added; UI shows them as **Saved**.
- No in-app clipboard paste → extract (removed).

### Chat scene

Role-play dialogue using user’s words (`ClaudeScene`, `ChatSceneView`, `ChatSceneViewModel`). Can launch from notifications (`ChatSceneLaunch`). Gated by `DailyLimitsManager.canStartScene`.

### Story

`generateStory` / `/story` — short story from a handful of dictionary words (`ClaudeStory.swift`). Gated by `DailyLimitsManager.canGenerateStory`.

### Streaks, badges, challenges

`DayStreak` (+ Pro streak freeze), `DailyChallengeManager`.  
Home shows `MilestoneCelebrationView` for word-count / streak / daily-goal milestones.  
`BadgeStore.checkForNewUnlocks` celebrates **all** badge categories; word/streak milestone overlays call `markCelebrated` so they don’t double-fire with badge popups.

### CSV / dictionary settings

Import/export in `DictionarySettingsView` (includes SRS fields). Clear dictionary requires confirm. Optional **iCloud Sync** toggle.

### iCloud (`Helpers/WordsICloudSync.swift`)

- Container `iCloud.com.droword`, file `Documents/words.json`.
- Pull-if-newer on reload; push after local save when enabled + signed into iCloud.
- Still local-first: App Group file is source of truth on device.
- **Signing note:** iCloud entitlement keys in `Droword/Droword.entitlements` may be **XML-commented** so Personal Team can run on device. Re-enable after paid Apple Developer Program + App ID iCloud capability. Do not delete the sync code when commenting entitlements.

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
| `ClaudeExtractWords` | `POST /extract-words` | Words from photo and/or pasted text |
| `fetchWordForms` (`ClaudeTranslate.swift`) | `POST /forms` | Inflected forms of one headword that appear in its example / collocations |
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
| Photo / text scan | **1/day** | Unlimited |
| Story / chat scene | Daily caps via `canGenerateStory` / `canStartScene` | Unlimited |
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
- Theme-aware radii: `themeStore.cardRadius` (blocks), `controlRadius` (primary buttons), `chipRadius` (tags/chips). Prefer these over hard-coded `DesignRadius.*` on content cards.
- Buttons: `duo3DStyle` / `duo3DSecondaryStyle` + `Duo3DButtonStyle` (`Helpers/DuoButtonStyle.swift`) for primary/secondary CTAs; tags via `TagBadge` / `TagsView` Duo chips. `PressableButtonStyle` only where Duo chrome does not apply.
- Empty states: `EmptyListView` / `PracticeEmptyContent` — include tip + **Add** CTA when the user can fix emptiness by adding words.
- Localization: `Localizable.xcstrings` + `String(localized:)` / `LocalizedStringKey`. Many locales in Share extension `.lproj`.
- Settings keys: always add to `AppStorageKeys` — do not scatter raw string keys.
- iPad: `iPadContentWidth` for readable width.

### Green Owl (Duolingo) palette (`.duolingo`)

Only this palette uses the Duo surface language:

| Token | Light | Notes |
|-------|-------|--------|
| `appBg` | `#FFFFFF` | Page background |
| `cardBg` | `#F7F7F7` | Content blocks / cards |
| `controlFace` | white (`appBg`) | Outlined buttons/chips on gray cards |
| `dividerColor` | `#E5E5E5` | Borders / lips |
| Accents | `#58CC02` green, `#FF4B4B` red, `#1CB0F6` blue, … | Buttons, toasts, and quiz correct/wrong |
| Quiz feedback | `successStrong` / `errorStrong` | Always theme `accentGreen` / `accentRed` (toast match) |
| Radii | card/control **16**, chips **12** | Match Duo feed cards |

Sheets stay on `appBg` (white). Duo content cards use gray fill **without** a stroke border. Do not apply `#F7F7F7` card fill to other themes. When previewing Green Owl in `ThemePickerView`, use `duo3DStyle(..., force3D: true)` so **Choose** matches Add.

Match neighboring screen patterns (sheet chrome, close/back buttons, toast/coach marks) before inventing new layout systems.

### Language pair

`LanguageCatalog.availableLanguages` is the source for onboarding and settings. Names are endonyms. After the original 12 (English, Español, Русский, Français, Deutsch, Italiano, Português, 한국어, 中文, 日本語, العربية, हिन्दी) the catalog also includes Українська, Türkçe, Ελληνικά, Nederlands, Polski, Svenska, Norsk, Dansk, Suomi, Tiếng Việt, Bahasa Indonesia, ไทย, עברית, Čeština, Română, Magyar. `LanguageLevels` is the same CEFR list for every language. Word packs still cover only some pairs and fall back.

Picker flags are drawn illustrations (`LanguageFlagView`), used by `LanguageCube` and `LanguagePairHero`. Do not switch them back to emoji, and do not put a `DragGesture(minimumDistance: 0)` on language cards — that gesture blocks scrolling over the icons. Glass on those cards is non-interactive for the same reason.

### App icons

`AppIconStyle.customizationCases` is what App Customization and the icon picker show. It excludes every language/flag case (English through Hungarian, including the later country flags). Those cases and their `Info.plist` alternate-icon entries can stay for artwork fallback, but do not put flag icons back in the customization row. Customization alternates use original patterned artwork with a bold `D`, the quote mark, or the Poppins `Droword` wordmark (`word*` cases); keep `Main` aligned with the primary App Store icon. The tab bar uses the custom monoline artwork in `MenuBarIcons` (home, page for dictionary, lightbulb for practice, plus), with thicker selected strokes and `themeStore.mainAccentColor` tint. Keep the system bar height; do not shrink it repeatedly in `sizeThatFits`. The rest of the app uses SF Symbols.

### Page indicators and theme picker

Onboarding, the Home & Practice tour, replay, and the theme picker use `PageCapsules` (`Components/PageCapsules.swift`). Do not bring back `UIPageControl`. Capsules are liquid glass when the app theme is glass, and also when the theme picker is previewing the glass page. Theme-picker capsule color otherwise follows the previewed palette (Green Owl green, Custom = chosen accent, Droword blue).

Theme preview cards hug their content (equal inset, leftover space is sheet background). The Custom accent control is the color circle in the preview header, opposite the avatar, with no “Accent color” label. Green Owl **Choose** uses `duo3DStyle` `verticalPadding: 14` so face + 4pt lip matches the flat buttons’ 32pt. Gap from Choose to the capsules is 16.

### PRO mark

`ProPillBadge` (settings and paywall) and `ProPlusMark` keep a static sparkle. Do not add `symbolEffect` bounce/pulse or a `TimelineView` twinkle. The App Customization settings row does not show a PRO badge.

### Irregular forms

Highlight conjugated/inflected forms only inside the example sentence. The worker returns `forms` on translate/suggest and on `POST /forms`; `HighlightedExample` paints those strings. Do not highlight the headword itself or forms outside the example.

---

## Important behaviors to preserve

1. **Local-first** — dictionary must work offline; AI features degrade with clear copy (`SceneOfflineCopy`, network monitor). Saving a word must still work when the free AI quota is spent.
2. **Enrichment** — `WordEnrichmentService` retries `needsEnrichment` words when online. Scan/import should not force enrichment if a translation already exists.
3. **App Group** — word/language changes must remain visible to Share/Widget.
4. **Home vs Practice** — Home = one daily lesson hero; don’t dump quiz UI or a second review CTA onto Home.
5. **Non-Pro theme lock** — on active scene, non-premium forced back to `.colorful`.
6. **Secrets** — never commit real `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `APP_KEY`; local worker uses `.dev.vars`.
7. **Don’t rewrite worker prompts** casually — they encode CEFR + Japanese/Chinese/Korean script rules.
8. **node_modules** under `droword-worker/` — ignore; not app source.
9. **Capture** — Share long text opens extract (`ScanWordsView`, `/extract-words` text). Short Share still opens Add. Photo scan on Scan. Dedup against existing dictionary words. No clipboard-paste extract UI.
10. **iCloud** — optional via `WordsICloudSync` + Dictionary settings; still local-first App Group file. Personal Team cannot ship iCloud entitlements — comment them in entitlements, keep Swift code.
11. **Empty states** — prefer a strong Add CTA over text-only emptiness (Dictionary, Practice, filter/search, locked lesson).
12. **Badges** — unlocks should surface via Home celebration (`MilestoneCelebrationView` / `pendingCelebration`); don’t silently unlock without UX.
13. **Language flags** — illustrated `LanguageFlagView` in the language picker; scrolling must work when the drag starts on a language card.
14. **App icon picker** — `customizationCases` only. No language/flag icons in App Customization. Tab bar artwork lives in `MenuBarIcons`.
15. **PRO sparkle** — static. No bounce or pulse.

---

## Typical change map

| Task | Start here |
|------|------------|
| Dictionary / word card UI | `DictionaryView`, `WordCardView`, `EditWordView`, `AddWordView` |
| SRS / due logic | `SRSScheduler`, `WordDue`, `WordsStore` |
| Daily lesson (Home hero) | `DailyLessonBuilder`, `DailyLessonSessionView`, `DailyLessonCard` |
| Quiz / Practice | `PracticeView`, `QuizSessionManager`, `Components/Quiz/*` |
| Empty / Add CTAs | `EmptyListView`, `PracticeEmptyContent`, `QuizNotEnoughView` |
| Scan / capture / dedup | `ScanWordsView`, `ClaudeExtractWords`, Share extension, `DrowordApp` deep links |
| iCloud sync | `WordsICloudSync`, `DictionarySettingsView`, `Droword.entitlements` |
| CSV import/export | `DictionarySettingsView` |
| Badges / celebrations | `BadgeStore`, `HomeView`, `MilestoneCelebrationView`, `AchievementsView` |
| AI translate/suggest | `Claude/*.swift` + worker handlers |
| Chat scene | `ChatSceneView`, `ChatSceneViewModel`, `ClaudeScene` |
| Paywall / limits | `PremiumView`, `DailyLimitsManager`, `StoreKitManager` |
| Onboarding | `Onboarding/*` |
| Settings / flags | `SettingsView`, `FeatureFlagsView`, `AppStorageKeys` |
| Notifications | `NotificationManager`, `NotificationCopy`, `DrowordApp` |
| Themes / Duo chrome | `ThemeStore`, `ThemePickerView`, `PageCapsules`, `DuoButtonStyle`, `TagBadge`, `DesignTokens` |
| Language pair / flags | `LanguageCatalog`, `LanguageFlagView`, `LanguageCube` |
| App icons | `AppIconStyle.customizationCases`, `AppCustomizationView` |
| Seasonal | `SeasonalOverlayView`, season components |
| Worker API | `droword-worker/src/index.ts`, `guard.ts` |

---

## Dev commands

```bash
# iOS: open Droword.xcodeproj in Xcode, run the Droword scheme
# Personal Team: keep iCloud keys commented in Droword.entitlements

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
