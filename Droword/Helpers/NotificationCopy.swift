import Foundation

enum NotificationCopy {

    private static var languageCode: String {
        let preferred = Locale.preferredLanguages.first ?? Locale.current.identifier
        let id = preferred.replacingOccurrences(of: "_", with: "-")
        let lower = id.lowercased()
        if lower.hasPrefix("zh-hant") || lower.hasPrefix("zh-tw") || lower.hasPrefix("zh-hk") || lower.hasPrefix("zh-mo") {
            return "zh-Hant"
        }
        if lower.hasPrefix("zh") {
            return "zh-Hans"
        }
        if lower.hasPrefix("pt") {
            return "pt-PT"
        }
        return String(id.prefix(2))
    }

    private static func t(_ table: [String: String]) -> String {
        let code = languageCode
        if let exact = table[code] { return exact }
        let short = String(code.prefix(2))
        return table[short] ?? table["en"] ?? ""
    }

    private static var dayIndex: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
    }

    private static func L(
        _ en: String, ru: String, de: String, es: String, fr: String,
        ja: String, ko: String, ar: String, it: String,
        zhHans: String, zhHant: String, pt: String
    ) -> [String: String] {
        [
            "en": en, "ru": ru, "de": de, "es": es, "fr": fr,
            "ja": ja, "ko": ko, "ar": ar, "it": it,
            "zh-Hans": zhHans, "zh-Hant": zhHant, "pt-PT": pt
        ]
    }

    private static func pick(_ pairs: [([String: String], [String: String])]) -> (title: String, body: String) {
        let i = dayIndex % max(pairs.count, 1)
        return (t(pairs[i].0), t(pairs[i].1))
    }

    // MARK: - Daily

    static func pickDaily() -> (title: String, body: String) {
        pick([
            (
                L("Two minutes?", ru: "Две минуты?", de: "Zwei Minuten?", es: "¿Dos minutos?", fr: "Deux minutes ?",
                  ja: "2分だけ？", ko: "2분만?", ar: "دقيقتين؟", it: "Due minuti?",
                  zhHans: "两分钟？", zhHant: "兩分鐘？", pt: "Dois minutos?"),
                L("That’s the whole session. Then you’re free.",
                  ru: "Вот и вся сессия. Потом свободен.",
                  de: "Das ist die ganze Session. Dann bist du frei.",
                  es: "Esa es toda la sesión. Luego estás libre.",
                  fr: "C’est toute la session. Après tu es libre.",
                  ja: "それが全部。あとは自由。",
                  ko: "그게 전부야. 그다음엔 자유.",
                  ar: "هيدي كل الجلسة. بعدين حر.",
                  it: "Tutta la sessione è questa. Poi sei libero.",
                  zhHans: "整场练习就这样。然后随便你。",
                  zhHant: "整場練習就這樣。然後隨便你。",
                  pt: "É a sessão toda. Depois estás livre.")
            ),
            (
                L("Your words miss you", ru: "Твои слова соскучились", de: "Deine Wörter vermissen dich", es: "Tus palabras te echan de menos", fr: "Tes mots te manquent",
                  ja: "単語がさびしがってる", ko: "단어들이 보고 싶어해", ar: "كلماتك مشتاقتك", it: "Le tue parole ti mancano",
                  zhHans: "你的单词想你了", zhHant: "你的單字想你了", pt: "As tuas palavras sentem a tua falta"),
                L("Open for a tiny review.",
                  ru: "Зайди на короткое ревью.",
                  de: "Mach ein kleines Review auf.",
                  es: "Abre un repasito.",
                  fr: "Ouvre une mini révi.",
                  ja: "ちょっと復習して。",
                  ko: "짧게 복습 한 번.",
                  ar: "افتح مراجعة صغيرة.",
                  it: "Apri un mini ripasso.",
                  zhHans: "来个短复习。",
                  zhHant: "來個短複習。",
                  pt: "Abre uma mini revisão.")
            ),
            (
                L("Don’t skip today", ru: "Сегодня не пропускай", de: "Heute nicht skippen", es: "Hoy no te lo saltes", fr: "Ne saute pas aujourd’hui",
                  ja: "今日は飛ばさないで", ko: "오늘은 건너뛰지 마", ar: "لا تفوت اليوم", it: "Oggi non saltare",
                  zhHans: "今天别跳过", zhHant: "今天別跳過", pt: "Hoje não saltes"),
                L("One word and the streak stays.",
                  ru: "Одно слово — и серия на месте.",
                  de: "Ein Wort — und die Serie bleibt.",
                  es: "Una palabra y la racha sigue.",
                  fr: "Un mot et la série reste.",
                  ja: "1語で連続キープ。",
                  ko: "단어 하나면 연속 유지.",
                  ar: "كلمة والسلسلة بتضل.",
                  it: "Una parola e la serie resta.",
                  zhHans: "一个词，连续打卡就还在。",
                  zhHant: "一個詞，連續打卡就還在。",
                  pt: "Uma palavra e a sequência fica.")
            ),
            (
                L("Tiny session time", ru: "Короткая сессия", de: "Mini-Session", es: "Mini sesión", fr: "Mini session",
                  ja: "ちょっとセッション", ko: "짧은 세션", ar: "جلسة صغيرة", it: "Mini sessione",
                  zhHans: "来个短练习", zhHant: "來個短練習", pt: "Mini sessão"),
                L("Start small. That’s enough.",
                  ru: "Начни с малого. Этого хватит.",
                  de: "Fang klein an. Das reicht.",
                  es: "Empieza en pequeño. Basta.",
                  fr: "Commence petit. Ça suffit.",
                  ja: "小さく始めて。それで十分。",
                  ko: "작게 시작해. 그거면 돼.",
                  ar: "بلّش صغير. بكفي.",
                  it: "Inizia in piccolo. Basta così.",
                  zhHans: "从小处开始。够了。",
                  zhHant: "從小處開始。夠了。",
                  pt: "Começa aos poucos. Chega.")
            ),
            (
                L("Ready when you are", ru: "Когда будешь готов", de: "Bereit, wenn du bist", es: "Cuando estés listo", fr: "Quand tu es prêt",
                  ja: "準備できたら", ko: "준비되면", ar: "لما تكون جاهز", it: "Quando sei pronto",
                  zhHans: "准备好就来", zhHant: "準備好就來", pt: "Quando estiveres pronto"),
                L("No pressure — just a light nudge.",
                  ru: "Без давления — просто лёгкий пинок.",
                  de: "Kein Druck — nur ein leichter Schubs.",
                  es: "Sin presión — solo un empujoncito.",
                  fr: "Sans pression — juste un petit coup de pouce.",
                  ja: "プレッシャーなし。ちょっとだけ。",
                  ko: "부담 없이. 살짝만.",
                  ar: "بدون ضغط — دفعة خفيفة بس.",
                  it: "Niente pressione — solo una spintarella.",
                  zhHans: "不催你 — 只是轻轻推一把。",
                  zhHant: "不催你 — 只是輕輕推一把。",
                  pt: "Sem pressão — só um empurrãozinho.")
            ),
            (
                L("One word now", ru: "Сейчас — одно слово", de: "Jetzt ein Wort", es: "Una palabra ahora", fr: "Un mot maintenant",
                  ja: "今は1語", ko: "지금은 단어 하나", ar: "هلأ كلمة", it: "Una parola ora",
                  zhHans: "现在一个词", zhHant: "現在一個詞", pt: "Uma palavra agora"),
                L("The rest of the day can wait.",
                  ru: "Остальной день подождёт.",
                  de: "Der Rest des Tages kann warten.",
                  es: "El resto del día puede esperar.",
                  fr: "Le reste de la journée peut attendre.",
                  ja: "あとはあとでいい。",
                  ko: "하루의 나머지는 기다려도 돼.",
                  ar: "باقي اليوم فيو يستنى.",
                  it: "Il resto della giornata può aspettare.",
                  zhHans: "这一天的其他事可以等。",
                  zhHant: "這一天的其他事可以等。",
                  pt: "O resto do dia pode esperar.")
            ),
            (
                L("Future you will thank you", ru: "Завтрашний ты скажет спасибо", de: "Dein Zukunfts-Ich wird danken", es: "Tu yo del futuro te lo agradecerá", fr: "Ton toi du futur te remerciera",
                  ja: "未来の自分がありがとうと言う", ko: "미래의 네가 고마워할 거야", ar: "نفسك بالمستقبل رح تشكرك", it: "Il te del futuro ti ringrazierà",
                  zhHans: "未来的你会感谢现在的你", zhHant: "未來的你會感謝現在的你", pt: "O teu eu do futuro vai agradecer"),
                L("Two minutes now. Easier tomorrow.",
                  ru: "Две минуты сейчас. Завтра будет легче.",
                  de: "Zwei Minuten jetzt. Morgen leichter.",
                  es: "Dos minutos ahora. Mañana más fácil.",
                  fr: "Deux minutes maintenant. Demain plus facile.",
                  ja: "今2分。明日が楽になる。",
                  ko: "지금 2분. 내일이 더 쉬워져.",
                  ar: "دقيقتين هلأ. بكرا أسهل.",
                  it: "Due minuti ora. Domani è più facile.",
                  zhHans: "现在两分钟。明天会轻松些。",
                  zhHant: "現在兩分鐘。明天會輕鬆些。",
                  pt: "Dois minutos agora. Amanhã fica mais fácil.")
            ),
            (
                L("Soft reminder", ru: "Мягкое напоминание", de: "Sanfte Erinnerung", es: "Recordatorio suave", fr: "Douce piqûre de rappel",
                  ja: "やさしいリマインダー", ko: "부드러운 알림", ar: "تذكير لطيف", it: "Promemoria soft",
                  zhHans: "轻轻提醒一下", zhHant: "輕輕提醒一下", pt: "Lembrete suave"),
                L("Your dictionary kept a seat warm.",
                  ru: "Словарь место для тебя сохранил.",
                  de: "Dein Wörterbuch hat den Platz warmgehalten.",
                  es: "Tu diccionario guardó el sitio.",
                  fr: "Ton dico a gardé ta place.",
                  ja: "辞書が席を空けてるよ。",
                  ko: "사전이 자리를 남겨뒀어.",
                  ar: "قاموسك حفظلك المحل.",
                  it: "Il dizionario ha tenuto il posto.",
                  zhHans: "词典给你留着位子。",
                  zhHant: "詞典給你留著位子。",
                  pt: "O dicionário guardou o teu lugar.")
            ),
        ])
    }

    // MARK: - Inactivity

    static func inactivity(atIndex index: Int) -> (title: String, body: String) {
        let pairs: [([String: String], [String: String])] = [
            (
                L("Still here when you are", ru: "Мы на месте", de: "Wir sind da, wenn du bist", es: "Seguimos aquí", fr: "On est là quand tu es prêt",
                  ja: "いつでも待ってる", ko: "언제든 여기 있어", ar: "نحن هون لما تجي", it: "Siamo qui quando vuoi",
                  zhHans: "你来我们就在", zhHant: "你來我們就在", pt: "Estamos cá quando quiseres"),
                L("A few days away — your words kept a seat warm.",
                  ru: "Пара дней без практики — место сохранили.",
                  de: "Ein paar Tage weg — dein Platz ist warm.",
                  es: "Unos días fuera — tu sitio sigue guardado.",
                  fr: "Quelques jours d’absence — ta place est gardée.",
                  ja: "数日ぶりの語彙。席は空けてあるよ。",
                  ko: "며칠 자리비움 — 자리는 남겨뒀어.",
                  ar: "كم يوم غياب — مقعدك دافي.",
                  it: "Qualche giorno via — il posto è caldo.",
                  zhHans: "几天没来 — 位子给你留着。",
                  zhHant: "幾天沒來 — 位子給你留著。",
                  pt: "Alguns dias fora — o lugar ficou quente.")
            ),
            (
                L("Miss the rhythm?", ru: "Сбился ритм?", de: "Rhythmus weg?", es: "¿Perdiste el ritmo?", fr: "Tu as perdu le rythme ?",
                  ja: "リズム乱れた？", ko: "리듬 깨졌어?", ar: "ضاع الإيقاع؟", it: "Perso il ritmo?",
                  zhHans: "节奏乱了？", zhHant: "節奏亂了？", pt: "Perdeste o ritmo?"),
                L("A week without vocab. One word and you’re back.",
                  ru: "Неделя без слов. Одно слово — и ты снова в деле.",
                  de: "Eine Woche ohne Vokabeln. Ein Wort und du bist zurück.",
                  es: "Una semana sin vocabulario. Una palabra y vuelves.",
                  fr: "Une semaine sans vocab. Un mot et tu es de retour.",
                  ja: "1週間ぶりの語彙。1語で復帰。",
                  ko: "일주일 단어 공백. 하나만 하면 복귀.",
                  ar: "أسبوع بلا كلمات. كلمة وترجع.",
                  it: "Una settimana senza vocab. Una parola e sei di nuovo in.",
                  zhHans: "一周没碰单词。一个词就回来了。",
                  zhHant: "一週沒碰單字。一個詞就回來了。",
                  pt: "Uma semana sem vocabulário. Uma palavra e voltas.")
            ),
            (
                L("We kept your spot", ru: "Место сохранили", de: "Platz freigehalten", es: "Guardamos tu sitio", fr: "On a gardé ta place",
                  ja: "席は空けておいた", ko: "자리 남겨뒀어", ar: "حفظنا مكانك", it: "Abbiamo tenuto il posto",
                  zhHans: "位子留给你了", zhHant: "位子留給你了", pt: "Guardámos o teu lugar"),
                L("Two weeks away. No judgment — just open when ready.",
                  ru: "Две недели. Без осуждения — зайди, когда удобно.",
                  de: "Zwei Wochen weg. Kein Urteil — öffne, wenn’s passt.",
                  es: "Dos semanas fuera. Sin juicio — abre cuando quieras.",
                  fr: "Deux semaines absentes. Sans jugement — ouvre quand tu veux.",
                  ja: "2週間ぶり。責めないよ — 準備できたら開いて。",
                  ko: "2주 자리비움. 탓 안 해 — 준비되면 열어.",
                  ar: "أسبوعين برا. بدون حكم — افتح لما تكون جاهز.",
                  it: "Due settimane via. Nessun giudizio — apri quando vuoi.",
                  zhHans: "两周没来。不评判 — 准备好再打开。",
                  zhHant: "兩週沒來。不評判 — 準備好再打開。",
                  pt: "Duas semanas fora. Sem juízos — abre quando quiseres.")
            ),
            (
                L("Long break, soft restart", ru: "Долгий перерыв — мягкий рестарт", de: "Lange Pause, sanfter Neustart", es: "Pausa larga, reinicio suave", fr: "Longue pause, redémarrage doux",
                  ja: "長い休み、やさしく再開", ko: "긴 휴식, 부드러운 재시작", ar: "استراحة طويلة، بداية ناعمة", it: "Lunga pausa, ripartenza soft",
                  zhHans: "长假结束，温柔重启", zhHant: "長假結束，溫柔重啟", pt: "Pausa longa, reinício suave"),
                L("A month away. Start with one word. That’s enough.",
                  ru: "Месяц без практики. Начни с одного слова. Этого хватит.",
                  de: "Einen Monat weg. Fang mit einem Wort an. Das reicht.",
                  es: "Un mes fuera. Empieza con una palabra. Basta.",
                  fr: "Un mois d’absence. Commence par un mot. Ça suffit.",
                  ja: "1か月ぶり。1語からで十分。",
                  ko: "한 달 자리비움. 단어 하나로 시작해. 그거면 돼.",
                  ar: "شهر غياب. ابدأ بكلمة. بكفي.",
                  it: "Un mese via. Parti da una parola. Basta così.",
                  zhHans: "一个月没来。从一个词开始就够了。",
                  zhHant: "一個月沒來。從一個詞開始就夠了。",
                  pt: "Um mês fora. Começa com uma palavra. Chega.")
            ),
        ]
        let i = min(max(index, 0), pairs.count - 1)
        return (t(pairs[i].0), t(pairs[i].1))
    }

    // MARK: - Review

    static func pickReviewTitle() -> String {
        let titles: [[String: String]] = [
            L("Words are waiting", ru: "Слова ждут", de: "Wörter warten", es: "Las palabras esperan", fr: "Les mots attendent",
              ja: "単語が待ってる", ko: "단어들이 기다려", ar: "الكلمات مستنية", it: "Le parole aspettano",
              zhHans: "单词在等你", zhHant: "單字在等你", pt: "As palavras estão à espera"),
            L("Review time", ru: "Время ревью", de: "Review-Zeit", es: "Hora de repasar", fr: "C’est l’heure de réviser",
              ja: "復習タイム", ko: "복습 시간", ar: "وقت المراجعة", it: "Ora di ripasso",
              zhHans: "复习时间", zhHant: "複習時間", pt: "Hora de rever"),
            L("Memory check", ru: "Проверка памяти", de: "Gedächtnis-Check", es: "Chequeo de memoria", fr: "Check mémoire",
              ja: "記憶チェック", ko: "기억 체크", ar: "تفقد الذاكرة", it: "Check memoria",
              zhHans: "记忆打卡", zhHant: "記憶打卡", pt: "Check de memória"),
            L("Ready for a quick pass?", ru: "Готов к короткому заходу?", de: "Bereit für einen kurzen Durchlauf?", es: "¿Listo para un pase rápido?", fr: "Prêt pour un passage rapide ?",
              ja: "さっと一周する？", ko: "짧게 한 판 할래?", ar: "جاهز لفة سريعة؟", it: "Pronto per un passaggio veloce?",
              zhHans: "来个短短过一遍？", zhHant: "來個短短過一遍？", pt: "Pronto para uma passagem rápida?"),
        ]
        return t(titles[dayIndex % titles.count])
    }

    static func reviewBody(count: Int) -> String {
        if count == 1 {
            return t(L(
                "1 word is ready. Won’t take long.",
                ru: "1 слово готово. Много времени не займёт.",
                de: "1 Wort ist bereit. Dauert nicht lange.",
                es: "1 palabra lista. No tomará mucho.",
                fr: "1 mot est prêt. Ça ne prendra pas longtemps.",
                ja: "1語の準備OK。すぐ終わるよ。",
                ko: "단어 1개 준비됨. 오래 안 걸려.",
                ar: "كلمة وحدة جاهزة. ما رح يطول.",
                it: "1 parola pronta. Non ci vorrà molto.",
                zhHans: "1 个词准备好了。不会太久。",
                zhHant: "1 個詞準備好了。不會太久。",
                pt: "1 palavra pronta. Não demora."
            ))
        }
        return t(L(
            "{COUNT} words are ready. Quick and light.",
            ru: "{COUNT} слов готовы. Быстро и легко.",
            de: "{COUNT} Wörter sind bereit. Schnell und leicht.",
            es: "{COUNT} palabras listas. Rápido y ligero.",
            fr: "{COUNT} mots sont prêts. Rapide et léger.",
            ja: "{COUNT}語の準備OK。サクッと。",
            ko: "{COUNT}개 준비됨. 빠르고 가볍게.",
            ar: "{COUNT} كلمات جاهزة. سريع وخفيف.",
            it: "{COUNT} parole pronte. Veloce e leggero.",
            zhHans: "{COUNT} 个词准备好了。又快又轻。",
            zhHant: "{COUNT} 個詞準備好了。又快又輕。",
            pt: "{COUNT} palavras prontas. Rápido e leve."
        )).replacingOccurrences(of: "{COUNT}", with: "\(count)")
    }

    static func vocabBody(
        transcription: String?,
        translation: String?,
        showTranscription: Bool,
        showTranslation: Bool
    ) -> String {
        var parts: [String] = []
        if showTranscription, let transcription, !transcription.isEmpty {
            parts.append("[\(transcription)]")
        }
        if showTranslation, let translation, !translation.isEmpty {
            parts.append(translation)
        }
        if parts.isEmpty {
            return t(L(
                "Do you remember this one?",
                ru: "Помнишь это слово?",
                de: "Erinnerst du dich an dieses?",
                es: "¿Recuerdas esta?",
                fr: "Tu te souviens de celle-ci ?",
                ja: "これ、覚えてる？",
                ko: "이거 기억나?",
                ar: "بتتذكر هالكلمة؟",
                it: "Ti ricordi questa?",
                zhHans: "还记得这个吗？",
                zhHant: "還記得這個嗎？",
                pt: "Lembras-te desta?"
            ))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Streak

    static func streakMilestone(for streak: Int) -> (title: String, body: String) {
        switch streak {
        case 7:
            return (
                t(L("7 days in a row", ru: "7 дней подряд", de: "7 Tage am Stück", es: "7 días seguidos", fr: "7 jours d’affilée",
                    ja: "7日連続", ko: "7일 연속", ar: "٧ أيام متواصلة", it: "7 giorni di fila",
                    zhHans: "连续 7 天", zhHant: "連續 7 天", pt: "7 dias seguidos")),
                t(L("One week. That’s a real habit.",
                    ru: "Неделя. Уже привычка.",
                    de: "Eine Woche. Das ist eine echte Gewohnheit.",
                    es: "Una semana. Eso ya es hábito.",
                    fr: "Une semaine. C’est une vraie habitude.",
                    ja: "1週間。もう習慣。",
                    ko: "일주일. 이제 습관이야.",
                    ar: "أسبوع. صارت عادة.",
                    it: "Una settimana. È una vera abitudine.",
                    zhHans: "一周了。已经是习惯。",
                    zhHant: "一週了。已經是習慣。",
                    pt: "Uma semana. Isso já é hábito."))
            )
        case 30:
            return (
                t(L("30 days", ru: "30 дней", de: "30 Tage", es: "30 días", fr: "30 jours",
                    ja: "30日", ko: "30일", ar: "٣٠ يوم", it: "30 giorni",
                    zhHans: "30 天", zhHant: "30 天", pt: "30 dias")),
                t(L("A full month. Seriously impressive.",
                    ru: "Целый месяц. Серьёзно круто.",
                    de: "Ein ganzer Monat. Wirklich beeindruckend.",
                    es: "Un mes entero. Impresionante de verdad.",
                    fr: "Un mois entier. Vraiment impressionnant.",
                    ja: "まる1か月。本気ですごい。",
                    ko: "한 달 가득. 진짜 대단해.",
                    ar: "شهر كامل. رهيب جدًا.",
                    it: "Un mese intero. Davvero impressionante.",
                    zhHans: "整整一个月。真的很厉害。",
                    zhHant: "整整一個月。真的很厲害。",
                    pt: "Um mês inteiro. Mesmo impressionante."))
            )
        case 100:
            return (
                t(L("100 days", ru: "100 дней", de: "100 Tage", es: "100 días", fr: "100 jours",
                    ja: "100日", ko: "100일", ar: "١٠٠ يوم", it: "100 giorni",
                    zhHans: "100 天", zhHant: "100 天", pt: "100 dias")),
                t(L("Your consistency is unreal.",
                    ru: "Железная привычка.",
                    de: "Deine Konstanz ist irre.",
                    es: "Tu constancia es de otro nivel.",
                    fr: "Ta régularité est dingue.",
                    ja: "継続力、すごい。",
                    ko: "꾸준함이 대단해.",
                    ar: "ثباتك أسطوري.",
                    it: "La tua costanza è pazzesca.",
                    zhHans: "你的坚持太猛了。",
                    zhHant: "你的堅持太猛了。",
                    pt: "A tua consistência é de outro nível."))
            )
        case 365:
            return (
                t(L("365 days", ru: "365 дней", de: "365 Tage", es: "365 días", fr: "365 jours",
                    ja: "365日", ko: "365일", ar: "٣٦٥ يوم", it: "365 giorni",
                    zhHans: "365 天", zhHant: "365 天", pt: "365 dias")),
                t(L("A full year of showing up. Huge.",
                    ru: "Целый год практики. Это огромно.",
                    de: "Ein ganzes Jahr Dabeisein. Riesig.",
                    es: "Un año entero apareciendo. Enorme.",
                    fr: "Une année entière à être là. Énorme.",
                    ja: "まる1年続けた。でかい。",
                    ko: "꼬박 일 년. 진짜 크다.",
                    ar: "سنة كاملة من الالتزام. ضخم.",
                    it: "Un anno intero a esserci. Enorme.",
                    zhHans: "整整一年坚持下来。了不起。",
                    zhHant: "整整一年堅持下來。了不起。",
                    pt: "Um ano inteiro a aparecer. Enorme."))
            )
        default:
            return (
                t(L("New streak milestone", ru: "Новый рубеж серии", de: "Neuer Serien-Meilenstein", es: "Nuevo hito de racha", fr: "Nouveau jalon de série",
                    ja: "連続の節目", ko: "연속 마일스톤", ar: "محطة سلسلة جديدة", it: "Nuovo traguardo serie",
                    zhHans: "连续打卡新里程碑", zhHant: "連續打卡新里程碑", pt: "Novo marco da sequência")),
                t(L("{STREAK} days in a row. Keep going.",
                    ru: "{STREAK} дней подряд. Держи.",
                    de: "{STREAK} Tage am Stück. Weiter so.",
                    es: "{STREAK} días seguidos. Sigue así.",
                    fr: "{STREAK} jours d’affilée. Continue.",
                    ja: "{STREAK}日連続。この調子で。",
                    ko: "{STREAK}일 연속. 계속 가.",
                    ar: "{STREAK} يوم متواصل. كمّل.",
                    it: "{STREAK} giorni di fila. Continua così.",
                    zhHans: "连续 {STREAK} 天。保持住。",
                    zhHant: "連續 {STREAK} 天。保持住。",
                    pt: "{STREAK} dias seguidos. Continua."))
                    .replacingOccurrences(of: "{STREAK}", with: "\(streak)")
            )
        }
    }

    // MARK: - Daily goal

    static func pickGoal() -> (title: String, body: String) {
        pick([
            (
                L("Daily goal done", ru: "Дневная цель закрыта", de: "Tagesziel erledigt", es: "Meta diaria hecha", fr: "Objectif du jour atteint",
                  ja: "今日の目標クリア", ko: "오늘의 목표 완료", ar: "هدف اليوم خلص", it: "Obiettivo giornaliero fatto",
                  zhHans: "今日目标完成", zhHant: "今日目標完成", pt: "Objetivo diário feito"),
                L("You hit today’s word goal. Nice.",
                  ru: "Цель по словам на сегодня закрыта. Красиво.",
                  de: "Du hast das Wortziel von heute erreicht. Schön.",
                  es: "Cumpliste la meta de palabras de hoy. Bien.",
                  fr: "Tu as atteint l’objectif mots d’aujourd’hui. Nickel.",
                  ja: "今日の単語目標クリア。いいね。",
                  ko: "오늘 단어 목표 달성. 좋아.",
                  ar: "وصلت هدف كلمات اليوم. حلو.",
                  it: "Hai raggiunto l’obiettivo parole di oggi. Bene.",
                  zhHans: "今天的单词目标完成了。漂亮。",
                  zhHant: "今天的單字目標完成了。漂亮。",
                  pt: "Atingiste o objetivo de palavras de hoje. Fixe.")
            ),
            (
                L("That’s all for today", ru: "На сегодня всё", de: "Das war’s für heute", es: "Eso es todo por hoy", fr: "C’est tout pour aujourd’hui",
                  ja: "今日はここまで", ko: "오늘은 여기까지", ar: "لهون لليوم", it: "Per oggi è tutto",
                  zhHans: "今天到此为止", zhHant: "今天到此為止", pt: "Por hoje é tudo"),
                L("See you tomorrow.",
                  ru: "До завтра.",
                  de: "Bis morgen.",
                  es: "Hasta mañana.",
                  fr: "À demain.",
                  ja: "また明日。",
                  ko: "내일 봐.",
                  ar: "بشوفك بكرا.",
                  it: "A domani.",
                  zhHans: "明天见。",
                  zhHant: "明天見。",
                  pt: "Até amanhã.")
            ),
            (
                L("Goal cleared", ru: "Цель выполнена", de: "Ziel erreicht", es: "Meta cumplida", fr: "Objectif validé",
                  ja: "目標クリア", ko: "목표 달성", ar: "الهدف تحقق", it: "Obiettivo raggiunto",
                  zhHans: "目标已完成", zhHant: "目標已完成", pt: "Objetivo concluído"),
                L("Done for today. Streak is safe.",
                  ru: "На сегодня готово. Серия в безопасности.",
                  de: "Für heute fertig. Serie sicher.",
                  es: "Listo por hoy. Racha a salvo.",
                  fr: "Terminé pour aujourd’hui. Série en sécurité.",
                  ja: "今日は完了。連続セーフ。",
                  ko: "오늘 끝. 연속 안전.",
                  ar: "خلصت لليوم. السلسلة بأمان.",
                  it: "Fatto per oggi. Serie al sicuro.",
                  zhHans: "今天搞定。连续记录安全。",
                  zhHant: "今天搞定。連續紀錄安全。",
                  pt: "Feito por hoje. Sequência segura.")
            ),
        ])
    }

    // MARK: - Evening chat

    static func pickEveningChat(word: String, translation: String) -> (title: String, body: String) {
        let titles: [[String: String]] = [
            L("One line tonight", ru: "Одна фраза на вечер", de: "Eine Zeile für heute Abend", es: "Una línea esta noche", fr: "Une ligne ce soir",
              ja: "今夜ひとこと", ko: "오늘 밤 한 줄", ar: "سطر لهالليلة", it: "Una riga stasera",
              zhHans: "今晚一句", zhHant: "今晚一句", pt: "Uma linha esta noite"),
            L("Say this out loud", ru: "Скажи это вслух", de: "Sag das laut", es: "Dilo en voz alta", fr: "Dis-le à voix haute",
              ja: "声に出して", ko: "소리 내서 말해", ar: "قولها بصوت", it: "Dillo ad alta voce",
              zhHans: "大声说出来", zhHant: "大聲說出來", pt: "Diz isto em voz alta"),
            L("Tiny chat", ru: "Маленький чат", de: "Mini-Chat", es: "Mini chat", fr: "Mini chat",
              ja: "ちょっとチャット", ko: "작은 채팅", ar: "شات صغير", it: "Mini chat",
              zhHans: "小小聊天", zhHant: "小小聊天", pt: "Mini chat"),
        ]
        let bodies: [[String: String]] = [
            L("How would you use «\(word)» in a chat?",
              ru: "Как бы ты использовал «\(word)» в чате?",
              de: "Wie würdest du «\(word)» in einem Chat nutzen?",
              es: "¿Cómo usarías «\(word)» en un chat?",
              fr: "Comment tu utiliserais «\(word)» dans un chat ?",
              ja: "「\(word)」をチャットでどう使う？",
              ko: "채팅에서 «\(word)» 어떻게 쓸래?",
              ar: "كيف رح تستعمل «\(word)» بالشات؟",
              it: "Come useresti «\(word)» in chat?",
              zhHans: "你会怎么在聊天里用「\(word)」？",
              zhHant: "你會怎麼在聊天裡用「\(word)」？",
              pt: "Como usavas «\(word)» num chat?"),
            L("«\(word)» — \(translation). Use it once before bed.",
              ru: "«\(word)» — \(translation). Один раз до сна.",
              de: "«\(word)» — \(translation). Einmal vor dem Schlafen.",
              es: "«\(word)» — \(translation). Úsala una vez antes de dormir.",
              fr: "«\(word)» — \(translation). Une fois avant de dormir.",
              ja: "「\(word)」— \(translation)。寝る前に一回。",
              ko: "«\(word)» — \(translation). 자기 전에 한 번.",
              ar: "«\(word)» — \(translation). مرة قبل النوم.",
              it: "«\(word)» — \(translation). Una volta prima di dormire.",
              zhHans: "「\(word)」— \(translation)。睡前用一次。",
              zhHant: "「\(word)」— \(translation)。睡前用一次。",
              pt: "«\(word)» — \(translation). Uma vez antes de dormires."),
            L("Reply in your head: \(word).",
              ru: "Ответь в голове: \(word).",
              de: "Antworte im Kopf: \(word).",
              es: "Contesta en la cabeza: \(word).",
              fr: "Réponds dans ta tête : \(word).",
              ja: "頭の中で返信：\(word)。",
              ko: "머릿속으로 답해: \(word).",
              ar: "جاوب براسك: \(word).",
              it: "Rispondi in testa: \(word).",
              zhHans: "脑子里回一句：\(word)。",
              zhHant: "腦子裡回一句：\(word)。",
              pt: "Responde na cabeça: \(word)."),
        ]
        let i = dayIndex
        return (t(titles[i % titles.count]), t(bodies[i % bodies.count]))
    }
}
