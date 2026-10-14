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
        let copy = pick([
            (
                L("Bestie, open the app",
                  ru: "Бести, открой апп",
                  de: "Bestie, mach die App auf",
                  es: "Bestie, abre la app",
                  fr: "Bestie, ouvre l’app",
                  ja: "ベスティー、アプリ開けて",
                  ko: "베스티, 앱 열어",
                  ar: "بستّي افتح الأب",
                  it: "Bestie, apri l’app",
                  zhHans: "Bestie，打开 app",
                  zhHant: "Bestie，打開 app",
                  pt: "Bestie, abre a app"),
                L("{COUNT} {WORDS} waiting for review.",
                  ru: "{COUNT} {WORDS} {AWAIT} повторения.",
                  de: "{COUNT} {WORDS} {AWAIT} aufs Wiederholen.",
                  es: "{COUNT} {WORDS} {AWAIT} el repaso.",
                  fr: "{COUNT} {WORDS} {AWAIT} une révi.",
                  ja: "{COUNT}語が復習待ち。",
                  ko: "{COUNT}개 단어가 복습을 기다려.",
                  ar: "{COUNT} {WORDS} {AWAIT} المراجعة.",
                  it: "{COUNT} {WORDS} {AWAIT} il ripasso.",
                  zhHans: "{COUNT} 个词等着复习。",
                  zhHant: "{COUNT} 個詞等著複習。",
                  pt: "{COUNT} {WORDS} à espera de revisão.")
            ),
            (
                L("I see the future",
                  ru: "Вижу будущее",
                  de: "Ich seh die Zukunft",
                  es: "Veo el futuro",
                  fr: "Je vois le futur",
                  ja: "未来が見える",
                  ko: "미래가 보여",
                  ar: "بشوف المستقبل",
                  it: "Vedo il futuro",
                  zhHans: "我看见未来了",
                  zhHant: "我看見未來了",
                  pt: "Vejo o futuro"),
                L("Today you’re studying! Just {COUNT} {WORDS} to review.",
                  ru: "Сегодня ты учишься! Всего {COUNT} {WORDS} к повторению.",
                  de: "Heute lernst du! Nur {COUNT} {WORDS} zum Wiederholen.",
                  es: "¡Hoy estudias! Solo {COUNT} {WORDS} por repasar.",
                  fr: "Aujourd’hui tu étudies ! Juste {COUNT} {WORDS} à réviser.",
                  ja: "今日は勉強する！復習は{COUNT}語だけ。",
                  ko: "오늘 공부해! 복습은 {COUNT}개뿐.",
                  ar: "اليوم بتدرس! بس {COUNT} {WORDS} للمراجعة.",
                  it: "Oggi studi! Solo {COUNT} {WORDS} da ripassare.",
                  zhHans: "今天你学习！只要复习 {COUNT} 个词。",
                  zhHant: "今天你學習！只要複習 {COUNT} 個詞。",
                  pt: "Hoje estudas! Só {COUNT} {WORDS} para rever.")
            ),
            (
                L("Don’t ghost me",
                  ru: "Не гоусти меня",
                  de: "Ghost mich nicht",
                  es: "No me ghostees",
                  fr: "Me ghost pas",
                  ja: "ゴーストしないで",
                  ko: "나 고스트하지 마",
                  ar: "ما تغوستني",
                  it: "Non ghostarmi",
                  zhHans: "别 ghost 我",
                  zhHant: "別 ghost 我",
                  pt: "Não me ghostes"),
                L("Come review {COUNT} {WORDS}.",
                  ru: "Зайди повторить {COUNT} {WORDS}.",
                  de: "Komm {COUNT} {WORDS} wiederholen.",
                  es: "Pásate a repasar {COUNT} {WORDS}.",
                  fr: "Viens réviser {COUNT} {WORDS}.",
                  ja: "{COUNT}語を復習しに来て。",
                  ko: "{COUNT}개 단어 복습하러 와.",
                  ar: "فوت راجع {COUNT} {WORDS}.",
                  it: "Passa a ripassare {COUNT} {WORDS}.",
                  zhHans: "来复习 {COUNT} 个词。",
                  zhHant: "來複習 {COUNT} 個詞。",
                  pt: "Vem rever {COUNT} {WORDS}.")
            ),
            (
                L("You’ll touch grass after reviewing",
                  ru: "Потрогаешь траву после повторения слов",
                  de: "Gras anfassen nach dem Wiederholen",
                  es: "Tocas hierba después de repasar",
                  fr: "Tu touches l’herbe après la révi",
                  ja: "復習したあとに外に出て",
                  ko: "복습하고 나서 밖에 나가",
                  ar: "تلمّس العشب بعد المراجعة",
                  it: "Tocchi l’erba dopo il ripasso",
                  zhHans: "复习完再去摸摸草",
                  zhHant: "複習完再去摸摸草",
                  pt: "Tocas na relva depois de rever"),
                L("First {COUNT} {WORDS}. Deal?",
                  ru: "Сначала {COUNT} {WORDS}. Договор?",
                  de: "Zuerst {COUNT} {WORDS}. Deal?",
                  es: "Primero {COUNT} {WORDS}. ¿Trato?",
                  fr: "D’abord {COUNT} {WORDS}. Deal ?",
                  ja: "まず{COUNT}語。いい？",
                  ko: "먼저 {COUNT}개. 약속?",
                  ar: "أولًا {COUNT} {WORDS}. اتفاق؟",
                  it: "Prima {COUNT} {WORDS}. Affare?",
                  zhHans: "先 {COUNT} 个词。说好了？",
                  zhHant: "先 {COUNT} 個詞。說好了？",
                  pt: "Primeiro {COUNT} {WORDS}. Trato?")
            ),
            (
                L("Soft threat",
                  ru: "Мягкая угроза",
                  de: "Sanfte Drohung",
                  es: "Amenaza suave",
                  fr: "Menace douce",
                  ja: "やさしい脅し",
                  ko: "부드러운 협박",
                  ar: "تهديد لطيف",
                  it: "Minaccia morbida",
                  zhHans: "温柔威胁",
                  zhHant: "溫柔威脅",
                  pt: "Ameaça suave"),
                L("Open the dictionary or the notifications continue.",
                  ru: "Открой словарь или уведомления продолжатся.",
                  de: "Öffne das Wörterbuch oder die Notifications gehen weiter.",
                  es: "Abre el diccionario o siguen las notificaciones.",
                  fr: "Ouvre le dico ou les notifs continuent.",
                  ja: "辞書を開かないと通知は続くよ。",
                  ko: "사전 안 열면 알림 계속됨.",
                  ar: "افتح القاموس أو الإشعارات بنكمل.",
                  it: "Apri il dizionario o le notifiche continuano.",
                  zhHans: "打开词典，不然通知继续。",
                  zhHant: "打開詞典，不然通知繼續。",
                  pt: "Abre o dicionário ou as notificações continuam.")
            ),
            (
                L("It’s giving abandoned dictionary",
                  ru: "Итс гивинг заброшенный словарь",
                  de: "It’s giving verlassenes Wörterbuch",
                  es: "It’s giving diccionario abandonado",
                  fr: "It’s giving dico abandonné",
                  ja: "放置辞書って感じ",
                  ko: "방치된 사전 느낌이야",
                  ar: "إتس گيفينغ قاموس متروك",
                  it: "It’s giving dizionario abbandonato",
                  zhHans: "It’s giving 被丢下的词典",
                  zhHant: "It’s giving 被丟下的詞典",
                  pt: "It’s giving dicionário abandonado"),
                L("{COUNT} {WORDS} abandoned.",
                  ru: "Заброшено {COUNT} {WORDS}.",
                  de: "{COUNT} {WORDS} verlassen.",
                  es: "{COUNT} {WORDS} {LEFT}.",
                  fr: "{COUNT} {WORDS} {LEFT} de côté.",
                  ja: "{COUNT}語放置中。",
                  ko: "{COUNT}개 방치됨.",
                  ar: "{COUNT} {WORDS} متروكة.",
                  it: "{COUNT} {WORDS} {LEFT}.",
                  zhHans: "扔下了 {COUNT} 个词。",
                  zhHant: "扔下了 {COUNT} 個詞。",
                  pt: "{COUNT} {WORDS} {LEFT}.")
            ),
            (
                L("I came to collect a debt!",
                  ru: "Я пришел забрать долг!",
                  de: "Ich bin da, um die Schuld einzutreiben!",
                  es: "¡Vine a cobrar una deuda!",
                  fr: "Je viens chercher une dette !",
                  ja: "借りを取りに来た！",
                  ko: "빚 받으러 왔다!",
                  ar: "جيت آخذ الدين!",
                  it: "Sono venuto a riscuotere un debito!",
                  zhHans: "我来讨债了！",
                  zhHant: "我來討債了！",
                  pt: "Vim cobrar uma dívida!"),
                L("Debt: {COUNT} {WORDS} to review.",
                  ru: "Долг: {COUNT} {WORDS} к повторению.",
                  de: "Schuld: {COUNT} {WORDS} zum Wiederholen.",
                  es: "Deuda: {COUNT} {WORDS} por repasar.",
                  fr: "Dette : {COUNT} {WORDS} à réviser.",
                  ja: "借金：復習{COUNT}語。",
                  ko: "빚: 복습 {COUNT}개.",
                  ar: "الدين: {COUNT} {WORDS} للمراجعة.",
                  it: "Debito: {COUNT} {WORDS} da ripassare.",
                  zhHans: "欠账：复习 {COUNT} 个词。",
                  zhHant: "欠帳：複習 {COUNT} 個詞。",
                  pt: "Dívida: {COUNT} {WORDS} para rever.")
            ),
            (
                L("Bro, the streak is already crying",
                  ru: "Бро, серия уже плачет",
                  de: "Bro, die Serie weint schon",
                  es: "Bro, la racha ya está llorando",
                  fr: "Bro, la série pleure déjà",
                  ja: "連続、もう泣いてる",
                  ko: "브로, 연속이 벌써 울고 있음",
                  ar: "برو، السلسلة عم تبكي",
                  it: "Bro, la serie sta già piangendo",
                  zhHans: "兄弟，连续已经在哭了",
                  zhHant: "兄弟，連續已經在哭了",
                  pt: "Bro, a sequência já está a chorar"),
                L("Talk to it — there are {COUNT} {WORDS}.",
                  ru: "Поговори с ней — там {COUNT} {WORDS}.",
                  de: "Red mit ihr — da sind {COUNT} {WORDS}.",
                  es: "Habla con ella — hay {COUNT} {WORDS}.",
                  fr: "Parle-lui — il y a {COUNT} {WORDS}.",
                  ja: "話してあげて — {COUNT}語いるよ。",
                  ko: "말 걸어 줘 — 거기 {COUNT}개야.",
                  ar: "احكي معها — في {COUNT} {WORDS}.",
                  it: "Parlale — ci sono {COUNT} {WORDS}.",
                  zhHans: "跟它说说 — 那儿有 {COUNT} 个词。",
                  zhHant: "跟它說說 — 那兒有 {COUNT} 個詞。",
                  pt: "Fala com ela — há {COUNT} {WORDS}.")
            ),
            (
                L("Your words miss you 😭😭😭",
                  ru: "Твои слова соскучились 😭😭😭",
                  de: "Deine Wörter vermissen dich 😭😭😭",
                  es: "Tus palabras te extrañan 😭😭😭",
                  fr: "Tes mots s’ennuient de toi 😭😭😭",
                  ja: "単語たちが会いたがってる😭😭😭",
                  ko: "단어들이 보고 싶어해 😭😭😭",
                  ar: "كلماتك اشتاقتلك 😭😭😭",
                  it: "Le tue parole ti stanno mancando 😭😭😭",
                  zhHans: "你的词想你了 😭😭😭",
                  zhHant: "你的詞想你了 😭😭😭",
                  pt: "As tuas palavras sentem a tua falta 😭😭😭"),
                L("There are {COUNT} of them. Go see them.",
                  ru: "Их там {COUNT}. Зайди к ним.",
                  de: "Es sind {COUNT}. Schau vorbei.",
                  es: "Hay {COUNT}. Pásate.",
                  fr: "Il y en a {COUNT}. Passe les voir.",
                  ja: "{COUNT}語いるよ。会いに来て。",
                  ko: "{COUNT}개야. 들러 줘.",
                  ar: "في {COUNT}. فوت عليهم.",
                  it: "Ce ne sono {COUNT}. Passa a trovarle.",
                  zhHans: "有 {COUNT} 个。去看看它们。",
                  zhHant: "有 {COUNT} 個。去看看它們。",
                  pt: "São {COUNT}. Vai ter com elas.")
            ),
        ])
        return (copy.title, fillDueCount(copy.body, count: dueCount))
    }

    private static func fillDueCount(_ template: String, count: Int) -> String {
        let n = max(count, 1)
        let one = n == 1
        let words: String
        let awaitVerb: String
        let left: String
        switch languageCode {
        case "ru":
            words = RussianPlural.words(n)
            awaitVerb = RussianPlural.form(count: n, one: "ждёт", few: "ждут", many: "ждут")
            left = ""
        case "de":
            words = one ? "Wort" : "Wörter"
            awaitVerb = one ? "wartet" : "warten"
            left = "verlassen"
        case "es":
            words = one ? "palabra" : "palabras"
            awaitVerb = one ? "espera" : "esperan"
            left = one ? "abandonada" : "abandonadas"
        case "fr":
            words = one ? "mot" : "mots"
            awaitVerb = one ? "attend" : "attendent"
            left = one ? "laissé" : "laissés"
        case "it":
            words = one ? "parola" : "parole"
            awaitVerb = one ? "aspetta" : "aspettano"
            left = one ? "abbandonata" : "abbandonate"
        case "pt-PT":
            words = one ? "palavra" : "palavras"
            awaitVerb = one ? "espera" : "esperam"
            left = one ? "abandonada" : "abandonadas"
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
            left = ""
        default:
            words = one ? "word" : "words"
            awaitVerb = "waiting"
            left = "abandoned"
        }
        return template
            .replacingOccurrences(of: "{COUNT}", with: "\(n)")
            .replacingOccurrences(of: "{WORDS}", with: words)
            .replacingOccurrences(of: "{AWAIT}", with: awaitVerb)
            .replacingOccurrences(of: "{LEFT}", with: left)
    }

    static func inactivity(atIndex index: Int) -> (title: String, body: String) {
        let pairs: [([String: String], [String: String])] = [
            (
                L("So you’re ghosting me???",
                  ru: "Так ты меня гоустишь???",
                  de: "Also ghostest du mich???",
                  es: "¿Entonces me estás ghosteando???",
                  fr: "Donc tu me ghost ???",
                  ja: "じゃあゴーストしてるの？？？",
                  ko: "나 고스트하는 거야???",
                  ar: "يعني عم تغوستني؟؟؟",
                  it: "Quindi mi stai ghostando???",
                  zhHans: "所以你在 ghost 我？？？",
                  zhHant: "所以你在 ghost 我？？？",
                  pt: "Então estás a ghostar-me???"),
                L("Open droword",
                  ru: "Открой droword",
                  de: "Öffne droword",
                  es: "Abre droword",
                  fr: "Ouvre droword",
                  ja: "droword を開けて",
                  ko: "droword 열어",
                  ar: "افتح droword",
                  it: "Apri droword",
                  zhHans: "打开 droword",
                  zhHant: "打開 droword",
                  pt: "Abre o droword")
            ),
            (
                L("Your streak called on Skype",
                  ru: "Звонила твоя серия в Скайпе",
                  de: "Deine Serie hat auf Skype angerufen",
                  es: "Tu racha llamó por Skype",
                  fr: "Ta série a appelé sur Skype",
                  ja: "連続がSkypeに電話してきた",
                  ko: "연속이 스카이프로 전화함",
                  ar: "سلسلتك اتصلت ع سكايب",
                  it: "La tua serie ha chiamato su Skype",
                  zhHans: "你的连续在 Skype 上打过来了",
                  zhHant: "你的連續在 Skype 上打過來了",
                  pt: "A tua sequência ligou no Skype"),
                L("Says you’re not studying",
                  ru: "Гвоорит ты не учишься",
                  de: "Sagt, du lernst nicht",
                  es: "Dice que no estudias",
                  fr: "Elle dit que tu n’étudies pas",
                  ja: "勉強してないって",
                  ko: "너 공부 안 한대",
                  ar: "بتقول إنك مش عم تدرس",
                  it: "Dice che non stai studiando",
                  zhHans: "说你不学习",
                  zhHant: "說你不學習",
                  pt: "Diz que não estás a estudar")
            ),
            (
                L("I made you a little latte",
                  ru: "Я тебе тут латтешку приготовил",
                  de: "Hab dir hier ein kleines Latte gemacht",
                  es: "Te preparé un lattecito",
                  fr: "Je t’ai fait un petit latte",
                  ja: "ラテ作っといたよ",
                  ko: "라테 하나 만들어 놨어",
                  ar: "عملتلك لاتي صغير",
                  it: "Ti ho preparato un piccolo latte",
                  zhHans: "我给你做了杯小拿铁",
                  zhHant: "我給你做了杯小拿鐵",
                  pt: "Fiz-te um lattezinho"),
                L("You coming?",
                  ru: "Зайдешь?",
                  de: "Kommst du vorbei?",
                  es: "¿Pasas?",
                  fr: "Tu passes ?",
                  ja: "来る？",
                  ko: "올 거야?",
                  ar: "رح تفوت؟",
                  it: "Passi?",
                  zhHans: "过来吗？",
                  zhHant: "過來嗎？",
                  pt: "Vens?")
            ),
            (
                L("Long break?",
                  ru: "Долгий перерыв?",
                  de: "Lange Pause?",
                  es: "¿Pausa larga?",
                  fr: "Longue pause ?",
                  ja: "長い休み？",
                  ko: "긴 휴식?",
                  ar: "استراحة طويلة؟",
                  it: "Lunga pausa?",
                  zhHans: "休息很久了？",
                  zhHant: "休息很久了？",
                  pt: "Pausa longa?"),
                L("Got it.",
                  ru: "Понятно.",
                  de: "Verstanden.",
                  es: "Entendido.",
                  fr: "Compris.",
                  ja: "わかった。",
                  ko: "알겠어.",
                  ar: "فاهم.",
                  it: "Capito.",
                  zhHans: "明白了。",
                  zhHant: "明白了。",
                  pt: "Percebi.")
            ),
            (
                L("Scrolling again?",
                  ru: "Опять скроллишь?",
                  de: "Schon wieder am Scrollen?",
                  es: "¿Otra vez scrolleando?",
                  fr: "Encore en train de scroller ?",
                  ja: "またスクロール？",
                  ko: "또 스크롤해?",
                  ar: "عم تسكرول تاني؟",
                  it: "Di nuovo a scrollare?",
                  zhHans: "又在刷？",
                  zhHant: "又在刷？",
                  pt: "Outra vez a fazer scroll?"),
                L("What about me? 😩",
                  ru: "А как же я? 😩",
                  de: "Und ich? 😩",
                  es: "¿Y yo? 😩",
                  fr: "Et moi ? 😩",
                  ja: "じゃあ私は？😩",
                  ko: "나는? 😩",
                  ar: "وليش أنا؟ 😩",
                  it: "E io? 😩",
                  zhHans: "那我呢？😩",
                  zhHant: "那我呢？😩",
                  pt: "E eu? 😩")
            ),
        ]
        let i = min(max(index, 0), pairs.count - 1)
        return (t(pairs[i].0), t(pairs[i].1))
    }

    static func pickReviewTitle() -> String {
        let titles: [[String: String]] = [
            L("There’s such a cute word, look",
              ru: "Там такое слово классненькое, глянь",
              de: "Da ist so ein süßes Wort, schau",
              es: "Hay una palabrita mona, mira",
              fr: "Y a un mot trop chou, regarde",
              ja: "かわいい単語ある、見て",
              ko: "거기 단어 하나 귀여워, 봐봐",
              ar: "في كلمة لطيفة هناك، شوف",
              it: "C’è una parolina carina, guarda",
              zhHans: "那儿有个超可爱的词，看一眼",
              zhHant: "那兒有個超可愛的詞，看一眼",
              pt: "Há uma palavrinha fofa, olha"),
            L("Maybe a review? 🤔",
              ru: "Может ревью? 🤔",
              de: "Vielleicht ein Review? 🤔",
              es: "¿Un review? 🤔",
              fr: "Un p’tit review ? 🤔",
              ja: "復習する？🤔",
              ko: "리뷰 할까? 🤔",
              ar: "يمكن ريفيو؟ 🤔",
              it: "Un review? 🤔",
              zhHans: "要不要复习一下？🤔",
              zhHant: "要不要複習一下？🤔",
              pt: "Um review? 🤔"),
            L("Whoa! What are you doing?",
              ru: "Опа! А че ты делаешь?",
              de: "Oha! Was machst du da?",
              es: "¡Opa! ¿Y tú qué haces?",
              fr: "Ola ! Tu fais quoi là ?",
              ja: "おっ！何してるの？",
              ko: "어라! 뭐 하는 거야?",
              ar: "أوبا! شو عم تعمل؟",
              it: "Opa! Che stai facendo?",
              zhHans: "哎！你在干嘛？",
              zhHant: "哎！你在幹嘛？",
              pt: "Opa! O que estás a fazer?"),
            L("The streak needs your attention",
              ru: "Серия нуждается в твоем внимании",
              de: "Die Serie braucht deine Aufmerksamkeit",
              es: "La racha necesita tu atención",
              fr: "La série a besoin de toi",
              ja: "連続が構ってほしがってる",
              ko: "연속이 네 관심이 필요해",
              ar: "السلسلة بدها انتباهك",
              it: "La serie ha bisogno della tua attenzione",
              zhHans: "连续需要你看看它",
              zhHant: "連續需要你看看它",
              pt: "A sequência precisa da tua atenção"),
            L("Cutie come in pls",
              ru: "Красотулька зайди плиз",
              de: "Schönheit, komm rein pls",
              es: "Preciosura entra pls",
                  fr: "Ma belle, passe pls",
              ja: "かわいいの、入って pls",
              ko: "예쁜이 들어와 플리즈",
              ar: "يا حلو فوت بليز",
              it: "Bellezza entra pls",
              zhHans: "小可爱进来一下 pls",
              zhHant: "小可愛進來一下 pls",
              pt: "Fofura entra pls"),
            L("To review or not to review, that is the question",
              ru: "Повторить или не повторить, вот в чем вопрос",
              de: "Wiederholen oder nicht wiederholen, das ist hier die Frage",
              es: "Repasar o no repasar, esa es la cuestión",
              fr: "Réviser ou ne pas réviser, telle est la question",
              ja: "復習するべきか、せざるべきか、それが問題だ",
              ko: "복습할 것인가 말 것인가, 그것이 문제로다",
              ar: "نراجع ولا ما نراجع، هذا هو السؤال",
              it: "Ripassare o non ripassare, questo è il problema",
              zhHans: "复习还是不复习，这是个问题",
              zhHant: "複習還是不複習，這是個問題",
              pt: "Rever ou não rever, eis a questão"),
        ]
        return t(titles[dayIndex % titles.count])
    }

    static func reviewBody(count: Int) -> String {
        if count == 1 {
            return t(L(
                "ONE WORD",
                ru: "ОДНО СЛОВО",
                de: "EIN WORT",
                es: "UNA PALABRA",
                fr: "UN MOT",
                ja: "単語ひとつ",
                ko: "단어 하나",
                ar: "كلمة واحدة",
                it: "UNA PAROLA",
                zhHans: "一个词",
                zhHant: "一個詞",
                pt: "UMA PALAVRA"
            ))
        }

        let ruWords = russianWordsReady(count)
        return t(L(
            "There are {COUNT} words here. Pop in real quick — then you’re free",
            ru: "Тут вон \(count) \(ruWords). Зайди быстренько — и свободен",
            de: "Hier sind {COUNT} Wörter. Kurz reinschauen — dann bist du frei",
            es: "Aquí hay {COUNT} palabras. Pásate rapidito — y libre",
            fr: "Y a {COUNT} mots là. Passe vite fait — et t’es libre",
            ja: "{COUNT}語あるよ。ちょっと来て — そしたら自由",
            ko: "여기 {COUNT}개 있어. 잠깐 들렀다 가 — 그럼 자유",
            ar: "في هون {COUNT} كلمات. فوت بسرعة — وبعدين حر",
            it: "Qui ci sono {COUNT} parole. Passa in un attimo — e sei libero",
            zhHans: "这儿有 {COUNT} 个词。进来一下 — 然后就自由了",
            zhHant: "這兒有 {COUNT} 個詞。進來一下 — 然後就自由了",
            pt: "Aqui há {COUNT} palavras. Entra já — e ficas livre"
        )).replacingOccurrences(of: "{COUNT}", with: "\(count)")
    }

    private static func russianWordsReady(_ count: Int) -> String {
        RussianPlural.words(count)
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
                "How do you say this one?",
                ru: "А как это говорится?",
                de: "Wie sagt man das nochmal?",
                es: "¿Y esto cómo se dice?",
                fr: "Et ça se dit comment ?",
                ja: "これ、どう言うんだっけ？",
                ko: "이거 어떻게 말해?",
                ar: "وهيدي كيف بتنقال؟",
                it: "E questo come si dice?",
                zhHans: "这个怎么说来着？",
                zhHant: "這個怎麼說的？",
                pt: "E isto como se diz?"
            ))
        }
        return parts.joined(separator: " · ")
    }

    static func streakMilestone(for streak: Int) -> (title: String, body: String) {
        switch streak {
        case 7:
            return (
                t(L("7-day something unlocked",
                    ru: "7-дневная че то там открыта",
                    de: "7-Tage-irgendwas freigeschaltet",
                    es: "Algo de 7 días desbloqueado",
                    fr: "Le truc de 7 jours est débloqué",
                    ja: "7日のなんか解除",
                    ko: "7일짜리 그거 해금됨",
                    ar: "شي السبع أيام انفتح",
                    it: "Quella cosa di 7 giorni sbloccata",
                    zhHans: "7 天那个啥已解锁",
                    zhHant: "7 天那個啥已解鎖",
                    pt: "Aquela coisa de 7 dias desbloqueada")),
                t(L("A week’s on!",
                    ru: "Неделя пошла!",
                    de: "Eine Woche ist an!",
                    es: "¡Ya va una semana!",
                    fr: "Une semaine de lancée !",
                    ja: "1週間スタート！",
                    ko: "일주일 시작!",
                    ar: "أسبوع بلّش!",
                    it: "È partita una settimana!",
                    zhHans: "一周开始了！",
                    zhHant: "一週開始了！",
                    pt: "Uma semana a andar!"))
            )
        case 30:
            return (
                t(L("30 days!",
                    ru: "30 дней!",
                    de: "30 Tage!",
                    es: "¡30 días!",
                    fr: "30 jours !",
                    ja: "30日！",
                    ko: "30일!",
                    ar: "٣٠ يوم!",
                    it: "30 giorni!",
                    zhHans: "30 天！",
                    zhHant: "30 天！",
                    pt: "30 dias!")),
                t(L("Even I can’t do that",
                    ru: "Даже я так не могу",
                    de: "Nicht mal ich schaff das",
                    es: "Ni yo puedo eso",
                    fr: "Même moi j’y arrive pas",
                    ja: "わたしでも無理",
                    ko: "나도 그건 못 해",
                    ar: "حتى أنا ما بقدر",
                    it: "Neanche io ci riesco",
                    zhHans: "连我都做不到",
                    zhHant: "連我都做不到",
                    pt: "Nem eu consigo isso"))
            )
        case 100:
            return (
                t(L("100 days.",
                    ru: "100 дней.",
                    de: "100 Tage.",
                    es: "100 días.",
                    fr: "100 jours.",
                    ja: "100日。",
                    ko: "100일.",
                    ar: "١٠٠ يوم.",
                    it: "100 giorni.",
                    zhHans: "100 天。",
                    zhHant: "100 天。",
                    pt: "100 dias.")),
                t(L("You’re such a good kid!",
                    ru: "Ты такая умничка ваще!",
                    de: "Du bist echt so ein Schatz!",
                    es: "Eres un sol, de verdad!",
                    fr: "T’es trop un amour, sérieux !",
                    ja: "ほんとえらい！",
                    ko: "진짜 대단하다 너!",
                    ar: "يا ذكي أنت!",
                    it: "Sei un tesoro, davvero!",
                    zhHans: "你好聪明啊！",
                    zhHant: "你好聰明啊！",
                    pt: "És um amor, a sério!"))
            )
        case 365:
            return (
                t(L("365. A whole year.",
                    ru: "365. Целый год.",
                    de: "365. Ein ganzes Jahr.",
                    es: "365. Un año entero.",
                    fr: "365. Une année entière.",
                    ja: "365。まる1年。",
                    ko: "365. 꼬박 일 년.",
                    ar: "٣٦٥. سنة كاملة.",
                    it: "365. Un anno intero.",
                    zhHans: "365。整整一年。",
                    zhHant: "365。整整一年。",
                    pt: "365. Um ano inteiro.")),
                t(L("I’m speechless",
                    ru: "Я вообще без слов",
                    de: "Ich bin echt sprachlos",
                    es: "Me quedé sin palabras",
                    fr: "Je suis à court de mots",
                    ja: "もう言葉ない",
                    ko: "말문이 막혀",
                    ar: "والله ما معي كلام",
                    it: "Sono senza parole",
                    zhHans: "我彻底没词了",
                    zhHant: "我徹底沒詞了",
                    pt: "Fiquei sem palavras"))
            )
        default:
            return (
                t(L("Already — {STREAK} days in",
                    ru: "Тут уже — {STREAK} дней прошло",
                    de: "Schon — {STREAK} Tage rum",
                    es: "Ya van — {STREAK} días",
                    fr: "Déjà — {STREAK} jours",
                    ja: "もう{STREAK}日経ってる",
                    ko: "벌써 — {STREAK}일째야",
                    ar: "هون صار — {STREAK} يوم",
                    it: "Già — {STREAK} giorni",
                    zhHans: "已经 — {STREAK} 天了",
                    zhHant: "已經 — {STREAK} 天了",
                    pt: "Já vão — {STREAK} dias"))
                    .replacingOccurrences(of: "{STREAK}", with: "\(streak)"),
                t(L("They’re playing you on every channel. That’s how cool you are, my little human ✨",
                    ru: "Тебя уже по всем каналам крутят. Вот такой ты крутой, мой человечек ✨",
                    de: "Dich spielen sie schon auf allen Kanälen. So cool bist du, mein Menschlein ✨",
                    es: "Ya te están pasando por todos los canales. Así de crack eres, humanito mío ✨",
                    fr: "On te passe déjà sur toutes les chaînes. T’es trop fort, mon petit humain ✨",
                    ja: "もう全局で君を流してる。そんなにかっこいいんだよ、私の人間さん ✨",
                    ko: "이미 모든 채널에서 너를 틀어. 그렇게 멋진 거야, 내 작은 사람 ✨",
                    ar: "عم يعرضوك على كل القنوات. هيك أنت قوي، يا إنساني الصغير ✨",
                    it: "Ti stanno già passando su tutti i canali. Sei così figo, mio ometto ✨",
                    zhHans: "已经在所有频道播你了。你就这么酷，我的小人儿 ✨",
                    zhHant: "已經在所有頻道播你了。你就這麼酷，我的小人兒 ✨",
                    pt: "Já te andam a passar em todos os canais. És assim tão fixe, meu humaninho ✨"))
                    .replacingOccurrences(of: "{STREAK}", with: "\(streak)")
            )
        }
    }

    static func pickGoal() -> (title: String, body: String) {
        let empty = L("", ru: "", de: "", es: "", fr: "", ja: "", ko: "", ar: "", it: "", zhHans: "", zhHant: "", pt: "")
        return pick([
            (
                L("The goal of that thing, you know.",
                  ru: "Цель того самого, ну, это.",
                  de: "Das Ziel von dem Dings, na ja.",
                  es: "La meta de eso, ya sabes.",
                  fr: "L’objectif de ce truc, voilà.",
                  ja: "あの目標、ほら、あれ。",
                  ko: "그거, 그 목표, 알지.",
                  ar: "هدف هيدا الشي، يعني.",
                  it: "L’obiettivo di quella cosa, insomma.",
                  zhHans: "那个目标，嗯，那个。",
                  zhHant: "那個目標，嗯，那個。",
                  pt: "O objetivo daquela coisa, pois."),
                empty
            ),
            (
                L("Streak is safe. I’m gonna go eat.",
                  ru: "Серия в безопасности. Пойду поем.",
                  de: "Serie ist safe. Ich geh essen.",
                  es: "La racha está a salvo. Me voy a comer.",
                  fr: "La série est safe. Je vais manger.",
                  ja: "連続は大丈夫。ご飯行ってくる。",
                  ko: "연속 안전해. 나 밥 먹으러 감.",
                  ar: "السلسلة بأمان. رح روح آكل.",
                  it: "La serie è al sicuro. Vado a mangiare.",
                  zhHans: "连续没事了。我去吃饭。",
                  zhHant: "連續沒事了。我去吃飯。",
                  pt: "A sequência está segura. Vou comer."),
                empty
            ),
            (
                L("What are you even doing.",
                  ru: "Что вытворяешь ваще.",
                  de: "Was treibst du da eigentlich.",
                  es: "Qué estás haciendo, en serio.",
                  fr: "Mais qu’est-ce que tu fabriques.",
                  ja: "何やってんのほんと。",
                  ko: "뭐 하는 거야 진짜.",
                  ar: "شو عم تسوي والله.",
                  it: "Ma che stai combinando.",
                  zhHans: "你这是在搞什么。",
                  zhHant: "你這是在搞什麼。",
                  pt: "O que estás tu a fazer."),
                empty
            ),
            (
                L("The day’s looking magical.",
                  ru: "Денек обещает быть волшебным.",
                  de: "Der Tag verspricht, magisch zu werden.",
                  es: "El día promete ser mágico.",
                  fr: "La journée s’annonce magique.",
                  ja: "素敵な一日になりそう。",
                  ko: "오늘 마법 같은 하루가 될 듯.",
                  ar: "اليوم واعد وسحري.",
                  it: "La giornata promette di essere magica.",
                  zhHans: "今天看起来会很神奇。",
                  zhHant: "今天看起來會很神奇。",
                  pt: "O dia promete ser mágico."),
                empty
            ),
        ])
    }

    static func pickEveningChat(word: String, translation: String) -> (title: String, body: String) {
        let titles: [[String: String]] = [
            L("You sleeping?",
              ru: "Спишь?",
              de: "Schläfst du?",
              es: "¿Estás durmiendo?",
              fr: "Tu dors ?",
              ja: "寝てる？",
              ko: "자?",
              ar: "نايم؟",
              it: "Dormi?",
              zhHans: "睡了吗？",
              zhHant: "睡了嗎？",
              pt: "Estás a dormir?"),
            L("Say «\(word)» or my cat will scratch you",
              ru: "Скажи «\(word)» или мой кот тебя поцарапает",
              de: "Sag «\(word)» oder meine Katze zerkratzt dich",
              es: "Di «\(word)» o mi gato te araña",
              fr: "Dis «\(word)» ou mon chat te griffe",
              ja: "「\(word)」って言って、言わないと猫が引っかくよ",
              ko: "«\(word)» 말해, 안 하면 우리 고양이가 할퀴어",
              ar: "قول «\(word)» أو قطتي بتخربشك",
              it: "Di’ «\(word)» o il mio gatto ti graffia",
              zhHans: "说「\(word)」，不然我家猫挠你",
              zhHant: "說「\(word)」，不然我家貓抓你",
              pt: "Diz «\(word)» ou o meu gato arranha-te"),
            L("I saw you on TikTok today",
              ru: "Я тебя сегодня видел в Тика Токе",
              de: "Hab dich heute auf TikTok gesehen",
              es: "Te vi hoy en TikTok",
              fr: "Je t’ai vu sur TikTok aujourd’hui",
              ja: "今日TikTokで見たよ",
              ko: "오늘 틱톡에서 봤어",
              ar: "شفتك اليوم ع تيك توك",
              it: "Ti ho visto su TikTok oggi",
              zhHans: "今天在 TikTok 上看到你了",
              zhHant: "今天在 TikTok 上看到你了",
              pt: "Vi-te hoje no TikTok"),
            L("Wanna generate a fairy tale from all your added words?",
              ru: "А хочешь сгенерировать себе сказку из всех добавленных слов?",
              de: "Willst du dir ein Märchen aus all deinen Wörtern generieren?",
              es: "¿Quieres generarte un cuento con todas las palabras que añadiste?",
              fr: "Tu veux te générer un conte avec tous tes mots ajoutés ?",
              ja: "追加した単語全部でおとぎ話作る？",
              ko: "넣은 단어 전부로 동화 만들어 볼래?",
              ar: "بدك تولّد قصة من كل الكلمات اللي ضفتها؟",
              it: "Vuoi generarti una fiaba con tutte le parole che hai aggiunto?",
              zhHans: "要用你加过的词给自己编个童话吗？",
              zhHant: "要用你加過的詞給自己編個童話嗎？",
              pt: "Queres gerar um conto com todas as palavras que adicionaste?"),
            L("One word two words. What’s that?",
              ru: "Одно слово два слова. Что это?",
              de: "Ein Wort zwei Wörter. Was ist das?",
              es: "Una palabra dos palabras. ¿Qué es eso?",
              fr: "Un mot deux mots. C’est quoi ça ?",
              ja: "単語ひとつ、ふたつ。なにそれ？",
              ko: "단어 하나 단어 둘. 이게 뭐야?",
              ar: "كلمة وحدة كلمتين. شو هيدا؟",
              it: "Una parola due parole. Cos’è?",
              zhHans: "一个词两个词。这是什么？",
              zhHant: "一個詞兩個詞。這是什麼？",
              pt: "Uma palavra duas palavras. O que é isto?"),
            L("Once there was a little cutie who reviewed all the words before bed. Is that you?",
              ru: "Жил был один пупсик, который все слова перед сном повторил. Это ты?",
              de: "Es war einmal ein Pupsik, der vor dem Schlafen alle Wörter wiederholt hat. Bist du das?",
              es: "Había una vez un pupsik que repasó todas las palabras antes de dormir. ¿Eres tú?",
              fr: "Il était une fois un pupsik qui a révisé tous les mots avant de dormir. C’est toi ?",
              ja: "昔々、寝る前に全部復習したププシクがいました。あなた？",
              ko: "옛날에 자기 전에 단어를 다 복습한 푸프식이 있었어. 너야?",
              ar: "كان يا مكان بوبسيك راجع كل الكلمات قبل النوم. أنت؟",
              it: "C’era una volta un pupsik che ha ripassato tutte le parole prima di dormire. Sei tu?",
              zhHans: "从前有个小宝贝，睡前把词都复习完了。是你吗？",
              zhHant: "從前有個小寶貝，睡前把詞都複習完了。是你嗎？",
              pt: "Era uma vez um pupsik que reviu todas as palavras antes de dormir. És tu?"),
            L("Streak is safe. Now nighty-night",
              ru: "Серия в безопасности. Теперь спатки",
              de: "Serie ist safe. Jetzt nachti-nacht",
              es: "La racha está a salvo. Ahora a mimir",
              fr: "La série est safe. Maintenant dodo",
              ja: "連続は大丈夫。おやすみ",
              ko: "연속 안전해. 이제 잘 시간",
              ar: "السلسلة بأمان. هلق ننو",
              it: "La serie è al sicuro. Ora nanna",
              zhHans: "连续没事了。现在睡觉觉",
              zhHant: "連續沒事了。現在睡覺覺",
              pt: "A sequência está segura. Agora nani"),
        ]
        let bodies: [[String: String]] = [
            L("So how do you translate «\(word)»?",
              ru: "А ну ка как переводится «\(word)»?",
              de: "Na los, wie heißt «\(word)»?",
              es: "A ver, ¿cómo se traduce «\(word)»?",
              fr: "Allez, ça se traduit comment «\(word)» ?",
              ja: "さあ、「\(word)」って何て訳す？",
              ko: "자, «\(word)» 어떻게 번역해?",
              ar: "يلا، كيف بتنترجم «\(word)»؟",
              it: "Su, come si traduce «\(word)»?",
              zhHans: "来，「\(word)」怎么翻译？",
              zhHant: "來，「\(word)」怎麼翻譯？",
              pt: "Vamos lá, como se traduz «\(word)»?"),
            L("«\(word)» — \(translation)",
              ru: "«\(word)» — \(translation)",
              de: "«\(word)» — \(translation)",
              es: "«\(word)» — \(translation)",
              fr: "«\(word)» — \(translation)",
              ja: "「\(word)」— \(translation)",
              ko: "«\(word)» — \(translation)",
              ar: "«\(word)» — \(translation)",
              it: "«\(word)» — \(translation)",
              zhHans: "「\(word)」— \(translation)",
              zhHant: "「\(word)」— \(translation)",
              pt: "«\(word)» — \(translation)"),
            L("Were all the words reviewed?",
              ru: "Все слова были повторены?",
              de: "Sind alle Wörter wiederholt?",
              es: "¿Se repasaron todas las palabras?",
              fr: "Tous les mots ont été révisés ?",
              ja: "単語、全部復習した？",
              ko: "단어 다 복습했어?",
              ar: "كل الكلمات تراجعت؟",
              it: "Tutte le parole sono state ripassate?",
              zhHans: "词都复习完了吗？",
              zhHant: "詞都複習完了嗎？",
              pt: "Todas as palavras foram revistas?"),
            L("«\(word)» — \(translation)",
              ru: "«\(word)» — \(translation)",
              de: "«\(word)» — \(translation)",
              es: "«\(word)» — \(translation)",
              fr: "«\(word)» — \(translation)",
              ja: "「\(word)」— \(translation)",
              ko: "«\(word)» — \(translation)",
              ar: "«\(word)» — \(translation)",
              it: "«\(word)» — \(translation)",
              zhHans: "「\(word)」— \(translation)",
              zhHant: "「\(word)」— \(translation)",
              pt: "«\(word)» — \(translation)"),
            L("",
              ru: "",
              de: "",
              es: "",
              fr: "",
              ja: "",
              ko: "",
              ar: "",
              it: "",
              zhHans: "",
              zhHant: "",
              pt: ""),
            L("",
              ru: "",
              de: "",
              es: "",
              fr: "",
              ja: "",
              ko: "",
              ar: "",
              it: "",
              zhHans: "",
              zhHant: "",
              pt: ""),
            L("",
              ru: "",
              de: "",
              es: "",
              fr: "",
              ja: "",
              ko: "",
              ar: "",
              it: "",
              zhHans: "",
              zhHant: "",
              pt: ""),
        ]
        let i = dayIndex
        return (t(titles[i % titles.count]), t(bodies[i % bodies.count]))
    }
}
