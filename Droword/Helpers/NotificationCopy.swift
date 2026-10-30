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

    static func pickDaily(dueCount: Int) -> (title: String, body: String) {
        let copy = pick(dailyReminderPairs)
        return (copy.title, fillDueCount(copy.body, count: dueCount))
    }

    private static var dailyReminderPairs: [([String: String], [String: String])] {
        [
            (
                L("Bestie, open the app",
                  ru: "Бести, открой апп",
                  de: "Bestie, mach die App auf",
                  es: "Bestie, abre la app",
                  fr: "Bestie, ouvre l'appli",
                  ja: "ねえ、アプリ開けて",
                  ko: "베프야, 앱 열어",
                  ar: "يا صديقي، افتح التطبيق",
                  it: "Bestie, apri l'app",
                  zhHans: "宝子，快打开App",
                  zhHant: "寶貝，快打開App",
                  pt: "Bestie, abre a app"),
                L("{COUNT} {WORDS} waiting for review.",
                  ru: "{COUNT} {WORDS} {AWAIT} повторения.",
                  de: "{COUNT} {WORDS} warten auf Wiederholung.",
                  es: "{COUNT} {WORDS} esperando repaso.",
                  fr: "{COUNT} {WORDS} à réviser.",
                  ja: "{COUNT}語が復習を待ってるよ。",
                  ko: "{COUNT}개 단어가 복습을 기다리고 있어.",
                  ar: "{COUNT} {WORDS} تنتظر المراجعة.",
                  it: "{COUNT} {WORDS} in attesa di ripasso.",
                  zhHans: "{COUNT}个词等你复习。",
                  zhHant: "{COUNT}個詞等你複習。",
                  pt: "{COUNT} {WORDS} à espera de revisão.")
            ),
            (
                L("I see the future",
                  ru: "Вижу будущее",
                  de: "Ich sehe die Zukunft",
                  es: "Veo el futuro",
                  fr: "Je vois l'avenir",
                  ja: "未来が見える",
                  ko: "미래가 보여",
                  ar: "أرى المستقبل",
                  it: "Vedo il futuro",
                  zhHans: "我看到了未来",
                  zhHant: "我看到了未來",
                  pt: "Vejo o futuro"),
                L("You're studying today! Just {COUNT} {WORDS} to review.",
                  ru: "Сегодня ты учишься! Всего {COUNT} {WORDS} к повторению.",
                  de: "Heute wird gelernt! Nur {COUNT} {WORDS} zu wiederholen.",
                  es: "¡Hoy sí estudias! Solo {COUNT} {WORDS} por repasar.",
                  fr: "Aujourd'hui, tu révises ! Plus que {COUNT} {WORDS}.",
                  ja: "今日は勉強する日！復習はたった{COUNT}語だけ。",
                  ko: "오늘은 공부하는 날! 복습은 딱 {COUNT}개.",
                  ar: "اليوم ستدرس! فقط {COUNT} {WORDS} للمراجعة.",
                  it: "Oggi si studia! Solo {COUNT} {WORDS} da ripassare.",
                  zhHans: "今天你要学习！只有{COUNT}个词要复习。",
                  zhHant: "今天你要學習！只有{COUNT}個詞要複習。",
                  pt: "Hoje vais estudar! Só {COUNT} {WORDS} para rever.")
            ),
            (
                L("Touch grass after reviewing",
                  ru: "Потрогаешь траву после повторения слов",
                  de: "Danach Gras anfassen",
                  es: "Toca pasto después de repasar",
                  fr: "Tu toucheras de l'herbe après",
                  ja: "復習したら草でも触ってきな",
                  ko: "복습하고 잔디나 밟고 와",
                  ar: "المس العشب بعد المراجعة",
                  it: "Tocca l'erba dopo il ripasso",
                  zhHans: "复习完再去摸草",
                  zhHant: "複習完再去摸草",
                  pt: "Vai tocar na relva depois de rever"),
                L("First, {COUNT} {WORDS}. Deal?",
                  ru: "Сначала {COUNT} {WORDS}. Договор?",
                  de: "Erst {COUNT} {WORDS}. Deal?",
                  es: "Primero {COUNT} {WORDS}. ¿Trato hecho?",
                  fr: "D'abord {COUNT} {WORDS}. Deal ?",
                  ja: "まず{COUNT}語。約束ね？",
                  ko: "먼저 {COUNT}개. 약속?",
                  ar: "أولاً {COUNT} {WORDS}. اتفقنا؟",
                  it: "Prima {COUNT} {WORDS}. Affare fatto?",
                  zhHans: "先复习{COUNT}个词，成交？",
                  zhHant: "先複習{COUNT}個詞，成交？",
                  pt: "Primeiro {COUNT} {WORDS}. Combinado?")
            ),
            (
                L("A gentle threat",
                  ru: "Мягкая угроза",
                  de: "Sanfte Drohung",
                  es: "Amenaza suave",
                  fr: "Une petite menace",
                  ja: "やさしい脅し",
                  ko: "살짝 협박",
                  ar: "تهديد لطيف",
                  it: "Minaccia gentile",
                  zhHans: "温柔的威胁",
                  zhHant: "溫柔的威脅",
                  pt: "Ameaça suave"),
                L("Open the dictionary or the notifications keep coming.",
                  ru: "Открой словарь или уведомления продолжатся.",
                  de: "Öffne das Wörterbuch, sonst hören die Benachrichtigungen nicht auf.",
                  es: "Abre el diccionario o seguirán las notificaciones.",
                  fr: "Ouvre le dico ou les notifs continuent.",
                  ja: "辞書を開かないと通知は止まらないよ。",
                  ko: "사전 안 열면 알림 계속 간다.",
                  ar: "افتح القاموس وإلا ستستمر الإشعارات.",
                  it: "Apri il dizionario o le notifiche continuano.",
                  zhHans: "打开词典，不然通知不会停。",
                  zhHant: "打開字典，不然通知不會停。",
                  pt: "Abre o dicionário ou as notificações continuam.")
            ),
            (
                L("I'm here to collect the debt!",
                  ru: "Я пришел забрать долг!",
                  de: "Ich komme, um die Schulden einzutreiben!",
                  es: "¡Vengo a cobrar la deuda!",
                  fr: "Je viens récupérer ma dette !",
                  ja: "借金を取り立てに来た！",
                  ko: "빚 받으러 왔다!",
                  ar: "جئت لأحصّل الدَّين!",
                  it: "Vengo a riscuotere il debito!",
                  zhHans: "我来讨债了！",
                  zhHant: "我來討債了！",
                  pt: "Vim cobrar a dívida!"),
                L("Debt: {COUNT} {WORDS} to review.",
                  ru: "Долг: {COUNT} {WORDS} к повторению.",
                  de: "Schulden: {COUNT} {WORDS} zur Wiederholung.",
                  es: "Deuda: {COUNT} {WORDS} por repasar.",
                  fr: "Dette : {COUNT} {WORDS} à réviser.",
                  ja: "借り：復習{COUNT}語。",
                  ko: "빚: 복습 {COUNT}개.",
                  ar: "الدَّين: {COUNT} {WORDS} للمراجعة.",
                  it: "Debito: {COUNT} {WORDS} da ripassare.",
                  zhHans: "欠债：{COUNT}个词待复习。",
                  zhHant: "欠債：{COUNT}個詞待複習。",
                  pt: "Dívida: {COUNT} {WORDS} para rever.")
            ),
            (
                L("Your words miss you 😭😭😭",
                  ru: "Твои слова соскучились 😭😭😭",
                  de: "Deine Wörter vermissen dich 😭😭😭",
                  es: "Tus palabras te extrañan 😭😭😭",
                  fr: "Tes mots te manquent 😭😭😭",
                  ja: "単語たちが寂しがってるよ 😭😭😭",
                  ko: "네 단어들이 보고 싶대 😭😭😭",
                  ar: "كلماتك اشتاقت لك 😭😭😭",
                  it: "Alle tue parole manchi 😭😭😭",
                  zhHans: "你的单词想你了 😭😭😭",
                  zhHant: "你的單字想你了 😭😭😭",
                  pt: "As tuas palavras têm saudades tuas 😭😭😭"),
                L("There are {COUNT} of them. Go visit.",
                  ru: "Их там {COUNT}. Зайди к ним.",
                  de: "Es sind {COUNT}. Besuch sie mal.",
                  es: "Son {COUNT}. Ve a verlas.",
                  fr: "Ils sont {COUNT}. Va les voir.",
                  ja: "全部で{COUNT}語。会いに行ってあげて。",
                  ko: "거기 {COUNT}개 있어. 만나러 가.",
                  ar: "عددها {COUNT}. اذهب لزيارتها.",
                  it: "Sono {COUNT}. Vai a trovarle.",
                  zhHans: "一共{COUNT}个，快去看看它们。",
                  zhHant: "一共{COUNT}個，快去看看它們。",
                  pt: "São {COUNT}. Vai visitá-las.")
            ),
        ]
    }

    private static func fillDueCount(_ template: String, count: Int) -> String {
        let n = max(count, 1)
        let one = n == 1
        let words: String
        let awaitVerb: String
        switch languageCode {
        case "ru":
            words = RussianPlural.words(n)
            awaitVerb = RussianPlural.form(count: n, one: "ждёт", few: "ждут", many: "ждут")
        case "de":
            words = one ? "Wort" : "Wörter"
            awaitVerb = one ? "wartet" : "warten"
        case "es":
            words = one ? "palabra" : "palabras"
            awaitVerb = one ? "espera" : "esperan"
        case "fr":
            words = one ? "mot" : "mots"
            awaitVerb = one ? "attend" : "attendent"
        case "it":
            words = one ? "parola" : "parole"
            awaitVerb = one ? "aspetta" : "aspettano"
        case "pt-PT":
            words = one ? "palavra" : "palavras"
            awaitVerb = one ? "espera" : "esperam"
        case "ar":
            if n == 1 {
                words = "كلمة"
                awaitVerb = "تنتظر"
            } else if n == 2 {
                words = "كلمتان"
                awaitVerb = "تنتظران"
            } else {
                words = "كلمات"
                awaitVerb = "تنتظر"
            }
        default:
            words = one ? "word" : "words"
            awaitVerb = "waiting"
        }
        return template
            .replacingOccurrences(of: "{COUNT}", with: "\(n)")
            .replacingOccurrences(of: "{WORDS}", with: words)
            .replacingOccurrences(of: "{AWAIT}", with: awaitVerb)
    }

    static func inactivity(atIndex index: Int) -> (title: String, body: String) {
        let pairs: [([String: String], [String: String])] = [
            (
                L("So you're ghosting me???",
                  ru: "Так ты меня гоустишь???",
                  de: "Ghostest du mich???",
                  es: "¿Me estás ghosteando???",
                  fr: "Tu me ghostes ???",
                  ja: "既読スルーしてる？？？",
                  ko: "나 읽씹하는 거야???",
                  ar: "هل تتجاهلني؟؟؟",
                  it: "Mi stai ghostando???",
                  zhHans: "你是想已读不回我吗？？？",
                  zhHant: "你是想已讀不回我嗎？？？",
                  pt: "Estás a fazer-me ghosting???"),
                L("Not mad. Kinda. Open Droword.",
                  ru: "Не обижаюсь. Почти. Открой Droword.",
                  de: "Bin nicht sauer. Fast. Öffne Droword.",
                  es: "No me enojo. Casi. Abre Droword.",
                  fr: "Je t'en veux pas. Enfin, presque. Ouvre Droword.",
                  ja: "怒ってないよ。ほぼね。Drowordを開いて。",
                  ko: "화 안 났어. 거의. Droword 열어봐.",
                  ar: "لست زعلان. تقريباً. افتح Droword.",
                  it: "Non mi offendo. Quasi. Apri Droword.",
                  zhHans: "没生气。才怪。打开Droword吧。",
                  zhHant: "沒生氣。才怪。打開Droword吧。",
                  pt: "Não estou chateado. Quase. Abre o Droword.")
            ),
            (
                L("Your words called you on Skype",
                  ru: "Звонили твои слова в Скайпе",
                  de: "Deine Wörter haben dich auf Skype angerufen",
                  es: "Tus palabras te llamaron por Skype",
                  fr: "Tes mots t'ont appelé sur Skype",
                  ja: "単語たちがLINEで電話してきたよ",
                  ko: "네 단어들이 카톡으로 전화했대",
                  ar: "كلماتك اتصلت بك على واتساب",
                  it: "Le tue parole ti hanno chiamato su Skype",
                  zhHans: "你的单词给你打微信视频了",
                  zhHant: "你的單字用LINE打給你了",
                  pt: "As tuas palavras ligaram-te no Skype"),
                L("They say you've stopped studying.",
                  ru: "Говорят, ты давно не учишься.",
                  de: "Sie sagen, du lernst nicht mehr.",
                  es: "Dicen que ya no estudias.",
                  fr: "Ils disent que tu ne révises plus.",
                  ja: "最近勉強してないって言ってる。",
                  ko: "요즘 공부 안 한다고 하던데.",
                  ar: "تقول إنك لم تعد تدرس.",
                  it: "Dicono che non studi più.",
                  zhHans: "说你好久没学习了。",
                  zhHant: "說你好久沒學習了。",
                  pt: "Dizem que já não estudas.")
            ),
            (
                L("I made you a latte",
                  ru: "Я тебе тут латтешку приготовил",
                  de: "Ich hab dir einen Latte gemacht",
                  es: "Te preparé un latte",
                  fr: "Je t'ai préparé un latte",
                  ja: "ラテ入れといたよ",
                  ko: "라떼 타놨어",
                  ar: "حضّرتُ لك لاتيه",
                  it: "Ti ho preparato un caffè",
                  zhHans: "我给你泡了杯拿铁",
                  zhHant: "我幫你泡了杯拿鐵",
                  pt: "Fiz-te um latte"),
                L("Coming over?",
                  ru: "Зайдёшь?",
                  de: "Kommst du?",
                  es: "¿Vienes?",
                  fr: "Tu passes ?",
                  ja: "来る？",
                  ko: "올래?",
                  ar: "هل ستأتي؟",
                  it: "Passi?",
                  zhHans: "来吗？",
                  zhHant: "要來嗎？",
                  pt: "Vens?")
            ),
            (
                L("Long break?",
                  ru: "Долгий перерыв?",
                  de: "Lange Pause?",
                  es: "¿Mucho tiempo sin venir?",
                  fr: "Longue pause ?",
                  ja: "久しぶり？",
                  ko: "오랜만이야?",
                  ar: "غياب طويل؟",
                  it: "Lunga pausa?",
                  zhHans: "好久没来了？",
                  zhHant: "好久沒來了？",
                  pt: "Grande pausa?"),
                L("Words are safe, come on in.",
                  ru: "Слова целы, заходи.",
                  de: "Die Wörter sind noch da, komm rein.",
                  es: "Las palabras siguen aquí, pásale.",
                  fr: "Les mots sont là, viens.",
                  ja: "単語は無事だよ、おいで。",
                  ko: "단어들 다 있어, 들어와.",
                  ar: "الكلمات بخير، تعال.",
                  it: "Le parole sono al sicuro, entra.",
                  zhHans: "单词都在，快进来。",
                  zhHant: "單字都在，快進來。",
                  pt: "As palavras estão aqui, entra.")
            ),
            (
                L("Scrolling?",
                  ru: "Скроллишь?",
                  de: "Scrollst du?",
                  es: "¿Scrolleando?",
                  fr: "Tu scrolles ?",
                  ja: "スクロール中？",
                  ko: "스크롤 중이야?",
                  ar: "تتصفح الهاتف؟",
                  it: "Stai scrollando?",
                  zhHans: "又在刷手机？",
                  zhHant: "又在滑手機？",
                  pt: "A fazer scroll?"),
                L("I do it too 😩 But I've got words here.",
                  ru: "Я тоже иногда 😩 Но у меня тут слова.",
                  de: "Ich manchmal auch 😩 Aber ich hab hier Wörter.",
                  es: "Yo también a veces 😩 Pero aquí tengo palabras.",
                  fr: "Moi aussi, parfois 😩 Mais ici j'ai des mots.",
                  ja: "私もたまにやる 😩 でもここには単語があるよ。",
                  ko: "나도 가끔 해 😩 근데 여기 단어가 있어.",
                  ar: "أنا أفعل ذلك أحياناً 😩 لكن عندي هنا كلمات.",
                  it: "Lo faccio anch'io 😩 Ma qui ho delle parole.",
                  zhHans: "我有时候也刷 😩 但我这儿有单词。",
                  zhHant: "我有時候也滑 😩 但我這裡有單字。",
                  pt: "Eu também às vezes 😩 Mas eu tenho palavras aqui.")
            ),
        ]
        let i = min(max(index, 0), pairs.count - 1)
        return (t(pairs[i].0), t(pairs[i].1))
    }

    static func pickReviewTitle() -> String {
        let titles: [[String: String]] = [
            L("There's a really cute word here, take a look",
              ru: "Там такое слово классненькое, глянь",
              de: "Hier ist ein richtig süßes Wort, schau mal",
              es: "Hay una palabrita bien linda aquí, échale un ojo",
              fr: "Y a un mot trop mignon ici, viens voir",
              ja: "めっちゃかわいい単語があるよ、見てみて",
              ko: "완전 귀여운 단어 있어, 한번 봐",
              ar: "هنا كلمة لطيفة جداً، ألقِ نظرة",
              it: "C'è una parola carinissima qui, dai un'occhiata",
              zhHans: "这里有个超可爱的单词，快来看",
              zhHant: "這裡有個超可愛的單字，快來看",
              pt: "Está aqui uma palavra giríssima, espreita"),
            L("Maybe a review? 🤔",
              ru: "Может ревью? 🤔",
              de: "Wie wär's mit einer Wiederholung? 🤔",
              es: "¿Y si repasamos? 🤔",
              fr: "Et si on révisait ? 🤔",
              ja: "ちょっと復習する？🤔",
              ko: "복습 한번 할래? 🤔",
              ar: "ما رأيك بمراجعة؟ 🤔",
              it: "Un ripasso? 🤔",
              zhHans: "要不复习一下？🤔",
              zhHant: "要不要複習一下？🤔",
              pt: "E se revíssemos? 🤔"),
            L("Oop! What are you up to?",
              ru: "Опа! А че ты делаешь?",
              de: "Hoppla! Was machst du da?",
              es: "¡Ey! ¿Qué estás haciendo?",
              fr: "Oups ! Tu fais quoi là ?",
              ja: "おっと！何してるの？",
              ko: "어라? 뭐 하는 거야?",
              ar: "أوه! ماذا تفعل؟",
              it: "Ehi! Che stai combinando?",
              zhHans: "哎哟！你在干嘛呢？",
              zhHant: "哎唷！你在幹嘛？",
              pt: "Opá! O que estás a fazer?"),
            L("Come in, pls, it'll be great",
              ru: "Зайди плиз, будет красота",
              de: "Komm, bitte, wird super",
              es: "Pásale, porfa, va a estar padre",
              fr: "Viens, stp, ça va être top",
              ja: "ねえお願い、絶対いい感じになるから",
              ko: "제발 와줘, 진짜 좋을 거야",
              ar: "تعال من فضلك، سيكون رائعاً",
              it: "Dai, entra, sarà top",
              zhHans: "快来嘛，会很棒的",
              zhHant: "快來嘛，會很棒的",
              pt: "Anda lá, por favor, vai ser fixe"),
            L("To review or not to review, that is the question",
              ru: "Повторить или не повторить, вот в чем вопрос",
              de: "Wiederholen oder nicht wiederholen, das ist hier die Frage",
              es: "Repasar o no repasar, esa es la cuestión",
              fr: "Réviser ou ne pas réviser, telle est la question",
              ja: "復習するか、しないか、それが問題だ",
              ko: "복습할까 말까, 그것이 문제로다",
              ar: "أراجع أم لا أراجع، تلك هي المسألة",
              it: "Ripassare o non ripassare, questo è il dilemma",
              zhHans: "复习，还是不复习，这是个问题",
              zhHant: "複習，還是不複習，這是個問題",
              pt: "Rever ou não rever, eis a questão"),
        ]
        return t(titles[dayIndex % titles.count])
    }

    static func reviewBody(count: Int) -> String {
        if count == 1 {
            return t(L(
                "Just one. Seriously, one.",
                ru: "Всего одно. Серьёзно, одно.",
                de: "Nur eins. Ehrlich, nur eins.",
                es: "Nomás una. En serio, una.",
                fr: "Juste un. Sérieux, un seul.",
                ja: "たった1語。ほんとに1語だけ。",
                ko: "딱 하나만. 진짜 하나만.",
                ar: "واحدة فقط. بجد، واحدة.",
                it: "Solo una. Giuro, una.",
                zhHans: "就一个。真的，就一个。",
                zhHant: "就一個。真的，就一個。",
                pt: "Só uma. A sério, só uma."
            ))
        }

        let ruWords = RussianPlural.words(count)
        return t(L(
            "There are like {COUNT} {WORDS} here. Pop in quick and you're free.",
            ru: "Тут вон {COUNT} \(ruWords). Зайди быстренько — и свободен",
            de: "Da warten {COUNT} {WORDS}. Kurz reinschauen und du bist frei.",
            es: "Hay como {COUNT} {WORDS}. Pásate rapidito y quedas libre.",
            fr: "Y a {COUNT} {WORDS} qui t'attendent. Passe vite fait et t'es libre.",
            ja: "{COUNT}語あるよ。さくっと来たら自由だよ。",
            ko: "여기 {COUNT}개 있어. 후딱 와서 하고 자유야.",
            ar: "هنا {COUNT} {WORDS}. مرّ بسرعة وتصبح حراً.",
            it: "Ci sono {COUNT} {WORDS}. Passa al volo e ti lascio in pace.",
            zhHans: "这儿有{COUNT}个词。快速来一下，然后就自由啦。",
            zhHant: "這裡有{COUNT}個詞。快速來一下，然後就自由囉。",
            pt: "Estão aqui {COUNT} {WORDS}. Passa rapidinho e ficas livre."
        )).replacingOccurrences(of: "{COUNT}", with: "\(count)")
            .replacingOccurrences(of: "{WORDS}", with: {
                let one = count == 1
                switch languageCode {
                case "de": return one ? "Wort" : "Wörter"
                case "es": return one ? "palabra" : "palabras"
                case "pt-PT": return one ? "palavra" : "palavras"
                case "fr": return one ? "mot" : "mots"
                case "it": return one ? "parola" : "parole"
                case "ar":
                    if count == 1 { return "كلمة" }
                    if count == 2 { return "كلمتان" }
                    return "كلمات"
                default: return one ? "word" : "words"
                }
            }())
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
                "How do you say this?",
                ru: "А как это говорится?",
                de: "Wie sagt man das?",
                es: "¿Cómo se dice esto?",
                fr: "Comment on dit ça ?",
                ja: "これ、何て言うんだっけ？",
                ko: "이건 뭐라고 말해?",
                ar: "كيف نقول هذا؟",
                it: "Come si dice?",
                zhHans: "这个怎么说？",
                zhHant: "這個怎麼說？",
                pt: "Como é que se diz isto?"
            ))
        }
        return parts.joined(separator: " · ")
    }

    static func pickGoal() -> (title: String, body: String) {
        let empty = L("", ru: "", de: "", es: "", fr: "", ja: "", ko: "", ar: "", it: "", zhHans: "", zhHant: "", pt: "")
        return pick([
            (
                L("Today's goal: you know, that thing. Studying.",
                  ru: "Цель дня: ну, это самое. Учить.",
                  de: "Tagesziel: du weißt schon, das Ding. Lernen.",
                  es: "Meta del día: ya sabes, eso. Estudiar.",
                  fr: "Objectif du jour : tu sais, le truc. Réviser.",
                  ja: "今日の目標：あれだよ、あれ。勉強。",
                  ko: "오늘의 목표: 그거 있잖아, 그거. 공부.",
                  ar: "هدف اليوم: تعرف، ذلك الشيء. الدراسة.",
                  it: "Obiettivo del giorno: sai, quella cosa. Studiare.",
                  zhHans: "今日目标：就那个，你懂的。学习。",
                  zhHant: "今日目標：就那個，你懂的。學習。",
                  pt: "Objetivo do dia: sabes, aquela coisa. Estudar."),
                empty
            ),
            (
                L("Whatcha doing? Your words are bored.",
                  ru: "Чем занят? Слова скучают.",
                  de: "Was machst du? Deine Wörter langweilen sich.",
                  es: "¿Qué haces? Tus palabras se aburren.",
                  fr: "Tu fais quoi ? Tes mots s'ennuient.",
                  ja: "何してるの？単語が退屈してるよ。",
                  ko: "뭐 해? 단어들이 심심하대.",
                  ar: "ماذا تفعل؟ كلماتك تشعر بالملل.",
                  it: "Che fai? Le tue parole si annoiano.",
                  zhHans: "在干嘛？单词无聊了。",
                  zhHant: "在幹嘛？單字無聊了。",
                  pt: "Que andas a fazer? As tuas palavras estão aborrecidas."),
                empty
            ),
            (
                L("Today's looking magical.",
                  ru: "Денек обещает быть волшебным.",
                  de: "Der Tag verspricht magisch zu werden.",
                  es: "El día promete ser mágico.",
                  fr: "La journée s'annonce magique.",
                  ja: "今日は魔法みたいな一日になりそう。",
                  ko: "오늘은 마법 같은 하루가 될 것 같아.",
                  ar: "يبدو أن اليوم سيكون ساحراً.",
                  it: "La giornata promette di essere magica.",
                  zhHans: "今天看起来会很神奇。",
                  zhHant: "今天看起來會很神奇。",
                  pt: "O dia promete ser mágico."),
                empty
            ),
        ])
    }

