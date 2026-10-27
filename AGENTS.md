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
| `Droword​Widget/` | Widgets: **Add a new word** (plus → `droword://add`; home small + lock circular), **Recent words** (last 3 → dictionary), **Today's lesson** (home small/medium + lock rectangular) |
| `docs/` | Privacy / terms / support HTML |
| `marketing/app-store/` | Listing copy, EN/RU posters in `out/`, `compose.py` |
| `scripts/` | Icon / preview helpers |

Bundle IDs: `com.droword`, share `com.droword.share`, widget `com.droword.widget`.  
App Group: `group.com.droword.shared` (words + language prefs shared with extensions/widget).  
iCloud container: `iCloud.com.droword` (optional sync of `words.json`).

---

## App architecture (SwiftUI)

### Entry

- `DrowordApp.swift` — wires stores, appearance, trial, notifications, enrichment retry, study-time session, Share deep links (`pendingSharedWord` / `pendingSharedText` → extract).
- `ContentView` — splash → onboarding **or** `HomeView`.
- Splash: `SplashView` resolves the `DrowordWordmark` out of a blur in one motion (blur + slight scale + fade, `.smooth`). Seven `StickerStar`s (purple / pink / gold / blue) spring out around it and twinkle, then everything fades. No letter-by-letter animation, bursts, or rings. Reduce Motion shows the wordmark with no stars and no blur.

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

Practice results (`QuizCompletionView` via `PracticeView.showingResults`) hide the tab bar (`TabBarVisibility.hide`); closing or starting another round shows it again.

### Dictionary tags and reactions

`TagsView` on Dictionary shows tag chips, then circular chips for every `StoredWord.reaction` in use. Tap a reaction to filter; search also matches `reaction` (and `tag`). Sort / edit / add controls are the same height as tags (`DesignChip.circle`) but stay circular. Card-corner reactions use the same `DesignChip` diameter and emoji size. Glass shapes include `.circle`.

### Capture / Scan

- **Scan toolbar**: camera / library (`ScanWordsView`).
- Share: short → Add; long / `pendingSharedText` → extract (`droword://extract`, `/extract-words` text).
- Dedup: words already in the dictionary are not re-added; UI shows them as **Saved**.
- No in-app clipboard paste → extract (removed).

### Chat scene

Role-play dialogue using user’s words (`ClaudeScene`, `ChatSceneView`, `ChatSceneViewModel`). Can launch from notifications (`ChatSceneLaunch`). Gated by `DailyLimitsManager.canStartScene`.

### Story

`generateStory` / `/story` — short story from a handful of dictionary words (`ClaudeStory.swift`). The worker asks for 2 of the offered words and retries once if fewer land. Today's story is kept (`StoryArchive`) and shown again until New story. Tapping a highlighted word, including an inflected form, shows its dictionary translation and can play it. Each highlighted word gets a meaning question in turn. After the last answer, correct pairs sit above the missed ones, in the same rows as Practice results. A right answer pulls an introduced card's review to tomorrow when it was further out, a miss brings it back in about 10 minutes. Gated by `DailyLimitsManager.canGenerateStory` (2/day free). If fewer than 3 seed words are available, show copy only (no Try Again); retries stay for offline / generation failures.

### Streaks, badges, challenges

`DayStreak` (+ Pro streak freeze: up to 2 missed days in a rolling 7-day window, only when the gap sits between study days), `DailyChallengeManager`.  
`FeatureGates.streakEnabled` is `false`: day streak, freeze, fire badge, streak badges, streak notifications, streak stats, and streak milestones stay in code and stay off screen. The Home week strip opens the calendar (studied days only, no streak count and no freeze). Quiz combo streaks are separate and still show.  
`FeatureGates.homeChatEnabled` stays `false` until Home chat is ready to ship; scene/chat code remains.  
Home shows `MilestoneCelebrationView` for word-count / daily-goal milestones as a full page in the same soft-wash layout as `StudyExtrasPromptPage` (each page keeps its own accent). Streak milestones do not present while the gate is off. Alerts (delete, copy, language switch, import) use that same layout. Adding every word from a scan or word pack opens `WordsAddedPage`. Soft covers on Home (first words, coach marks, study extras, suggested intro, Pro invite, motivational paywall) go through one queue (`HomeSoftCover` + `enqueueSoftCover` / `presentNextSoftCoverIfNeeded` in `HomeView`) so they do not stack. Once the dictionary reaches 5 words, `StudyExtrasPromptPage` offers any Home extras that are still off (reading, daily challenges, word packs, chat when enabled). If every one of those is already on, the page stays hidden. `ProInvitePage` appears from day 2, then every 4 days, for people without PRO. Feature Flags pushes these pages, plus alerts and onboarding screens.  
`BadgeStore.checkForNewUnlocks` celebrates **all** badge categories; word/streak milestone overlays call `markCelebrated` so they don’t double-fire with badge popups.

### CSV / dictionary settings

Import/export in `DictionarySettingsView` (includes SRS fields). Clear dictionary requires confirm. Optional **iCloud Sync** toggle.

### iCloud (`Helpers/WordsICloudSync.swift`)

- Container `iCloud.com.droword`, file `Documents/words.json`.
- Pull-if-newer on reload; push after local save when enabled + signed into iCloud.
- Still local-first: App Group file is source of truth on device.
- **Signing:** iCloud keys are **active** in `Droword/Droword.entitlements` (`iCloud.com.droword`, CloudDocuments). Requires paid Apple Developer Program + iCloud capability on the App ID. Do not delete `WordsICloudSync` if you temporarily comment entitlements for a Personal Team device run.

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
| `AudioManager` | `POST /tts` | OpenAI TTS audio (`TTSCache` on disk by text+voice; replay is instant) |

Prompts and CEFR/script rules live in **`droword-worker/src/index.ts`**. Rate limits / body size / key check in `guard.ts`. Worker README: `droword-worker/README.md`.

### Free vs Pro limits (client-side)

`DailyLimitsManager` + `TranslationLimits` (local UserDefaults, reset each calendar day).  
Free checks are always `isPremium || DailyLimitsManager.can…`.

| Feature | Free | Pro / active trial |
|---------|------|--------------------|
| AI translations | **10/day** first 7 days after install, then **5/day** | Unlimited |
| TTS | **10/day**. Replaying the same text the same day does not spend another play. `WordsStore.add` calls `TTSPlayer.prefetch` (fetch+cache, no play, no quota) so the first tap is usually instant | Unlimited |
| Suggestion fetches | **4/day** | Unlimited |
| Photo / text scan | **3/day** | Unlimited |
| Story / chat scene | Daily caps via `canGenerateStory` / `canStartScene` | Unlimited |
| New words into lesson | **12/day** (all users) | same |
| Themes / seasonal / streak freeze | Default theme only | Themes and seasonal unlocked. Streak freeze stays hidden while `FeatureGates.streakEnabled` is false |

Optional **7-day PRO trial** (button on paywall) sets `isPremium` via `hasUsedTrial` + `trialStartDate` (+ Keychain). That is separate from the soft translation ramp above.

IAP: `com.droword.pro.monthly`, `com.droword.pro.yearly`. Flag: `AppStorageKeys.isPremium`.

Worker IP limits in `guard.ts` are abuse protection only — not the product paywall.

---

## UI / design conventions

- Fonts: bundled **Poppins** (registered in `DrowordApp`).
- Spacing / radius: `Helpers/DesignTokens.swift` (`DesignSpacing`, `DesignRadius`, `DesignChip` for tag-row circles / reaction emoji size).
- Themes: `ThemeStore` palettes; prefer `themeStore.mainAccentColor` for CTAs. Palette titles (`Droword`, `Green Owl`, `Liquid Glass`, `Custom`) and subtitles are localized via `String(localized:)` — brand name **Droword** stays Droword in every locale. **Liquid Glass** (`requiresIOS26`) only appears in the picker when `ThemeStore.glassAPIAvailable` (iOS 26+); on older OS it falls back to Droword and `glassEffect` goes through `drowordGlassEffect` / `GlassCardModifier` with a material fallback. Large empty/soft-cover heroes are stickers (`StickerTone`). Stickers follow the theme through `\.stickerStyle` (set at the app root from `ThemeStore.stickerStyle`): `.droword` (Droword + Custom: side block, thin outline, shine), `.duo` (Green Owl: Duo colors, flat face + bottom lip, no outline; white parts get a light gray outline), `.glass` (Liquid Glass: Apple system colors, translucent gradient, white top sheen + rim, blurred soft shadow — not `.shadow`, which draws a box on iOS), `.pixel` (8-bit: ink outline + hard ink shadow, then `StickerPixelFrame` renders the sticker small with `ImageRenderer` and scales it up with `.interpolation(.none)`). Colors come from `StickerPalette`; `StickerTone.face/side/highlight/line` are `StickerPaint` shape styles that resolve against the environment. Every root sticker view wraps its art in `StickerPixelFrame`. No Metal shader: the Metal toolchain is not installed. `StickerProBadge` is not pixelated, so the PRO text stays readable. Only a hero that falls back to an SF Symbol uses `themeStore.iconAccent` (Droword `#6A3AC4`, Green Owl blue, Glass purple, Custom purple). Small settings/menu icons stay `mainText` or the rainbow `iconBlue` / `iconGreen` / … tokens. Soft-cover pages: content vertically centered, CTAs pinned to the bottom. `cleanCard(themeStore:)`, `modernSheet()`.
- Theme-aware radii: `themeStore.cardRadius` (blocks), `controlRadius` (primary buttons), `chipRadius` (tags/chips). Prefer these over hard-coded `DesignRadius.*` on content cards.
- Buttons: `duo3DStyle` / `duo3DSecondaryStyle` + `Duo3DButtonStyle` (`Helpers/DuoButtonStyle.swift`) for primary/secondary CTAs; tags via `TagBadge` / `TagsView` Duo chips. `PressableButtonStyle` only where Duo chrome does not apply.
- Empty states: `EmptyListView` / `PracticeEmptyContent` — include tip + **Add** CTA when the user can fix emptiness by adding words.
- Localization: `Localizable.xcstrings` + `String(localized:)` / `LocalizedStringKey`. Locales: en, ru, de, es, fr, it, pt-PT, ja, ko, ar, zh-Hans, zh-Hant. When adding UI copy, translate all of them in the same change. Count-based strings need catalog `plural` variants with correct declension (see `.cursor/rules/localization.mdc`). Share extension also has `.lproj` files.
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

Sheets stay on `appBg` (white). Duo content cards use gray fill **without** a stroke border. Do not apply `#F7F7F7` card fill to other themes. When previewing Green Owl in `ThemePickerView`, **Choose** is the Duo lip button. Do not route it through `duo3DStyle`, which follows the active theme.

Match neighboring screen patterns (sheet chrome, close/back buttons, toast/coach marks) before inventing new layout systems.

### Language pair

`LanguageCatalog.availableLanguages` is the source for onboarding and settings. Names are endonyms. After the original 12 (English, Español, Русский, Français, Deutsch, Italiano, Português, 한국어, 中文, 日本語, العربية, हिन्दी) the catalog also includes Українська, Türkçe, Ελληνικά, Nederlands, Polski, Svenska, Norsk, Dansk, Suomi, Tiếng Việt, Bahasa Indonesia, ไทย, עברית, Čeština, Română, Magyar. `LanguageLevels` is the same CEFR list for every language. Word packs still cover only some pairs and fall back.

Picker flags are drawn illustrations (`LanguageFlagView`), used by `LanguageCube` and `LanguagePairHero`. They are flat with a `StickerTone.flagLine` outline (1–2pt): no side block, shine, gradient, or drop shadow. Do not switch them back to emoji, and do not put a `DragGesture(minimumDistance: 0)` on language cards — that gesture blocks scrolling over the icons. Glass on those cards is non-interactive for the same reason.

### App icons

`AppIconStyle.customizationCases` is what App Customization and the icon picker show (`allCases` order). Language/flag and face-style alternate icons are gone (no enum cases, no `Info.plist` entries, no PNGs). Customization alternates use original patterned artwork with a bold `D`, the quote mark, or the Poppins `Droword` wordmark (`word*` cases), plus theme-matched quote icons: `pixel` (8-bit red), `owl` (Green Owl, no bottom lip), `crystal` (liquid-glass sheen). Onboarding `CustomizeIllustration` previews `[.pixel, .classic, .wordLime]` so 8-bit is first there only — do not reorder the picker. Keep `Main` aligned with the primary App Store icon. The tab bar uses the custom monoline artwork in `MenuBarIcons` (home, page for dictionary, lightbulb for practice, plus), with thicker selected strokes and `themeStore.mainAccentColor` tint. Keep the system bar height: `.tabBarMinimizeBehavior(.never)` and do not shrink height in `SlidingTabBar.sizeThatFits`. The rest of the app uses SF Symbols.

### Page indicators and theme picker

Onboarding, the Home & Practice tour, replay, and the theme picker use `PageCapsules` (`Components/PageCapsules.swift`). Do not bring back `UIPageControl`. Capsules are liquid glass when the app theme is glass, and also when the theme picker is previewing the glass page. In the theme picker, pass `usesThemeGlass: false` so the active Liquid Glass theme does not glass every page indicator. Glass there only when the previewed page is Liquid Glass. Theme-picker capsule color otherwise follows the previewed palette (Green Owl green, Custom = chosen accent, Droword blue), with inactive dots in `MainGrey`.

Theme preview cards hug their content (equal inset, leftover space is sheet background). The Custom accent control is the color circle in the preview header, opposite the avatar, with no “Accent color” label. Green Owl **Choose** uses a 14pt vertical pad so face + 4pt lip matches the flat buttons’ 32pt. Gap from Choose to the capsules is 16. **Choose** always looks as it does when the app theme is Droword: flat accent fill, Duo lip only on the Green Owl page, glass only on the Liquid Glass page. The active theme must not turn every **Choose** into glass or Duo. Each preview card has a 1.5pt stroke: Droword uses `AccentPurple`; every other palette uses its `mainAccentColor`.

The pager opens on the saved palette (`initialPalette`, otherwise `themeStore.palette` / `ThemeStore.rememberedPalette()`), not the first page. Mount the page `TabView` only after that selection is set (`showPager`). Setting the selection after the pager exists leaves it on Droword. The App Customization theme strip scrolls to the current palette.

### PRO mark

Next to the name on Home, PRO is a plain `MenuSymbol` sparkle in `accentBlue`. Do not replace it with `ProPillBadge` or a themed 3D/glass star.

The paywall plaque is `StickerProBadge`: a purple sticker capsule with white `PRO` and no stars. It follows the theme like other stickers, but is not pixelated so the PRO text stays readable (52pt in the offer header, 40pt next to “is yours”). The paywall feature rows and the “PRO is active” sparkle stay plain SF Symbols, not stickers. `ProPillBadge(prominent: true)` stays in code but is no longer on the paywall.

Small `ProPillBadge()` chips in settings and App Customization stay a flat accent capsule. `ProPlusMark` and every PRO sparkle stay static: no `symbolEffect` bounce/pulse and no `TimelineView` twinkle. The App Customization settings row does not show a PRO badge.

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
10. **iCloud** — optional via `WordsICloudSync` + Dictionary settings; entitlements are on; still local-first App Group file.
11. **Empty states** — prefer a strong Add CTA over text-only emptiness (Dictionary, Practice, filter/search, locked lesson). Home is the `addWord` sticker (word card + plus; dark mode uses `StickerTone.slate` so the card is not paper-white). The empty dictionary is `StickerQuestion`, Practice and the locked lesson are `StickerBulb`, an empty tag filter is `StickerTag`. Stickers live in `Components/Stickers/`, drawn from `StickerShape` + `StickerTone` (`Helpers/`): Droword style is a soft 3D fill and thin outline; Green Owl, Liquid Glass, and 8-bit restyle through `StickerStyle`. The splash sparkles are `StickerStar`. Onboarding pages use the same stickers (book + tag, bulb + check, stars around the app icons). Soft-cover modals (coach marks, first words, suggested words, Words added, Study extras, PRO invite, celebrations, alerts) draw their hero through `SoftCoverHero` → `StickerSymbol`, which maps the SF Symbol name to a sticker via `StickerArt(systemName:)` and falls back to the SF Symbol for unknown names. Row icons in those pages use `StickerSymbol` at 28pt. Also stickers: the Home empty state (`text.badge.plus` → `addWord`; `EmptyListView` / `PracticeEmptyContent` use a sticker whenever `StickerArt(systemName:)` knows the icon, otherwise `HaloIcon`), the Scan words hero (`scan`), the Practice matching lives (`StickerHeart`: `.red` left, `.ash` lost), Achievements badge cards (`BadgeCardView` → `StickerArt(badgeEmoji:)`: sprout, herb, tree, trophy, crown, diamond, target, notepad, bulb, flame, bolt, sparkles; glyphs in `StickerGlyph+Badges.swift`; locked = grayscale + faded; unknown emoji falls back to the emoji), Well done (colored `StickerStar` sparkles on the finish splash, correct / missed / best-streak / Perfect lesson icons). A new modal icon gets a `StickerArt` case + glyphs in `StickerGlyph+Modals.swift`. Do not put SF Symbols back in those spots.
12. **Badges** — unlocks should surface via Home celebration (`MilestoneCelebrationView` / `pendingCelebration`); don’t silently unlock without UX.
13. **Language flags** — illustrated `LanguageFlagView` in the language picker; scrolling must work when the drag starts on a language card.
14. **App icon picker** — `customizationCases` only. No language/flag app icons in the product. Tab bar artwork lives in `MenuBarIcons`.
15. **PRO sparkle** — static. No bounce or pulse. Home keeps the plain blue sparkle. The paywall plaque is the sticker `StickerProBadge` (static, no animation).
16. **Notification voice** — Russian lines in `NotificationCopy` are the source of meaning. Other locales (en, de, es, fr, it, pt-PT, ja, ko, ar, zh-Hans, zh-Hant) translate that Russian, including the short and odd lines. Streak notification pool only when `FeatureGates.streakEnabled`. Do not put back English slang that says something else. Onboarding notifications start **off** (`notifGlobalEnabled` false for new installs); the iOS permission prompt fires only when the user turns Enable notifications on.
17. **Icon badge** — review-due notifications set `content.badge` to that day’s due count. Opening the app (`scenePhase` `.active`) calls `NotificationManager.clearBadge()`: badge `0` and delivered notifications removed. Pending future reminders stay.
18. **Dictionary reactions** — used card reactions appear as circular filter chips after tags; searching an emoji finds those cards.
19. **Widgets** — **Add a new word** is plus-only (`droword://add`): home-screen `systemSmall` and lock-screen `accessoryCircular`. Recent words shows the last 3 as mini dictionary cards (small = stack, medium = three tiles; `droword://dictionary`). **Today’s lesson** is small/medium + lock-screen `accessoryRectangular` only (no circular). Lesson widget has no streak copy while streak is gated off. Gallery copy lives in `Droword​Widget/Localizable.xcstrings`. Edit the live target in `Droword​Widget/` (ZWSP folder), not `DrowordWidget/`.
20. **Word packs** — pack word cards use normal `cardBg` (no tinted pack colors). Adding a word tags it Basics / Food / Travel / Shopping / Daily life and `ensureTag`s custom ones into `TagStore` (Travel stays built-in). Skip matches Cancel: `secondaryButtonBg` + `mainText`, no icon.

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
| Home soft covers | `HomeSoftCover`, `HomeView` queue (`enqueueSoftCover`) |
| Haptics copy | `HapticFeel`, `HapticSettingsView`, `Localizable.xcstrings` |
| Share word image | `ShareWordCardView` / `ShareWordPosterView` (looks like expanded dictionary card; Stories left-pinned on gradient) |
| Reading story | `StoryView` — title, body, quiz left-aligned |
| Language pair / flags | `LanguageCatalog`, `LanguageFlagView`, `LanguageCube` |
| App icons | `AppIconStyle.customizationCases`, `AppCustomizationView` |
| Seasonal | `SeasonalOverlayView`, season components |
| Worker API | `droword-worker/src/index.ts`, `guard.ts` |

---

## Dev commands

```bash
# iOS: open Droword.xcodeproj in Xcode, run the Droword scheme
# Signing: paid Apple Developer team; iCloud.com.droword on App ID + entitlements

cd droword-worker && npm install && npm run dev    # http://localhost:8787
cd droword-worker && npm run deploy                # after wrangler secrets
```

---

## Agent working agreements

- Keep diffs focused; no drive-by refactors or unrelated markdown.
- Prefer existing helpers/stores over new parallel state.
- When adding user-facing strings, update `Localizable.xcstrings` for every locale and plural form (see `.cursor/rules/localization.mdc`).
- Commit only when the user asks; never force-push or rewrite git history.
- Before a push the user asked for: update this file and `README.md` if behavior or the map changed, remove code comments from the diff, then push. Do not push with comments left in source. Keep iCloud entitlement keys in `Droword.entitlements` (do not re-comment them for Personal Team unless the user asks).
- After substantive edits, follow `.cursor/rules/self-review.mdc`: re-read the diff, fix issues, and for larger changes spawn a review agent. Bugbot only when the user asks.
- If unsure where a feature lives, search `Droword/` and this map before creating new top-level folders.
