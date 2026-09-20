# App Store listing copy

Use these strings in App Store Connect. Support email: **hello@droword.app**  
After GitHub Pages (or any host) is live, set:

- Privacy: `…/privacy-policy.html`
- Terms / EULA (or custom): `…/terms-of-use.html`
- Support / Marketing: `…/` or `…/support.html`

---

## English

**Name:** Droword  
**Subtitle:** Words that actually stick  
**Category:** Education  
**Secondary:** Reference / Productivity (optional)

**Promotional text** (up to 170 chars, editable anytime):  
Build a personal dictionary, review with spaced repetition, and let AI fill in translations, examples, and voice.

**Description:**

Droword is your personal language dictionary — not another endless course.

Save words you actually meet. Get AI translations, examples, and pronunciation. Review with a short daily lesson and spaced practice so vocabulary sticks.

• Add words by typing, Share Sheet, or photo scan  
• AI-enriched cards: translation, examples, transcription  
• Daily lesson + quizzes (multiple choice, typing, matching, and more)  
• Stories and tiny chat scenes with your own words  
• Streaks, challenges, themes, and custom app icons  
• Free daily limits (generous starter week, then a soft cap); Droword PRO unlocks more

Local-first: your dictionary lives on your device. AI features need a network connection.

**Keywords** (100 chars max, comma-separated, no spaces after commas preferred):  
vocabulary,dictionary,language,learn,flashcards,SRS,translate,words,study,AI,quiz,spanish,japanese

**What's New (1.0):**  
Welcome to Droword — your dictionary, daily lesson, and smart reviews in one place.

---

## Русский

**Название:** Droword  
**Подзаголовок:** Слова, которые остаются  

**Промотекст:**  
Свой словарь, умные повторения и ИИ-карточки: перевод, примеры и произношение.

**Описание:**

Droword — личный словарь для языков, а не бесконечный курс.

Сохраняй слова, которые реально встретил. ИИ добавит перевод, примеры и озвучку. Короткие уроки и интервальные повторения помогают словам закрепиться.

• Добавление вручную, через Share и со скана фото  
• Карточки с переводом, примерами и транскрипцией  
• Урок дня и квизы (выбор, ввод, матчинг и др.)  
• Истории и мини-диалоги на твоих словах  
• Стрики, челленджи, темы и иконки  
• Бесплатные дневные лимиты (мягче в первую неделю); PRO открывает больше

Словарь хранится на устройстве. Для ИИ нужен интернет.

**Ключевые слова:**  
словарь,слова,язык,учить,карточки,перевод,повторение,квиз,ИИ,испанский,японский,английский

**Что нового (1.0):**  
Знакомьтесь с Droword — словарь, урок дня и умные повторения в одном приложении.

---

## Connect checklist (you)

- [ ] Create App IDs: `com.droword`, `com.droword.share`, `com.droword.widget` + App Group `group.com.droword.shared`
- [ ] Host `docs/` (GitHub Pages) and paste URLs
- [ ] Create IAP `com.droword.pro.monthly` / `com.droword.pro.yearly`
- [ ] Drop real screenshots into `marketing/app-store/raw/` → run `compose.py`
- [ ] Confirm support email inbox for `hello@droword.app` (or replace everywhere)
