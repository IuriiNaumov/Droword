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
                L("bestie open the app",
                  ru: "Бести, открой апп",
                  de: "bestie öffne die app",
                  es: "bestie abre la app",
                  fr: "bestie ouvre l’app",
                  ja: "ベスティー、アプリ開けて",
                  ko: "베스티 앱 열어",
                  ar: "بستّي افتح الأب",
                  it: "bestie apri l’app",
                  zhHans: "bestie 打开 app",
                  zhHant: "bestie 打開 app",
                  pt: "bestie abre a app"),
                L("{COUNT} {WORDS} waiting for review.",
                  ru: "{COUNT} {WORDS} {AWAIT} повторения.",
                  de: "{COUNT} {WORDS} {AWAIT} aufs Review.",
                  es: "{COUNT} {WORDS} {AWAIT} repaso.",
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
                L("plot twist: you study today",
                  ru: "Вижу будущее",
                  de: "plot twist: du lernst heute",
                  es: "plot twist: estudias hoy",
                  fr: "plot twist: tu étudies aujourd’hui",
                  ja: "どんでん返し：今日勉強する",
                  ko: "반전: 오늘 공부함",
                  ar: "تويست: اليوم بتدرس",
                  it: "plot twist: studi oggi",
                  zhHans: "剧情反转：你今天学",
                  zhHant: "劇情反轉：你今天學",
                  pt: "plot twist: estudas hoje"),
                L("Today you study! Just {COUNT} {WORDS} to review.",
                  ru: "Сегодня ты учишься! Всего {COUNT} {WORDS} к повторению.",
                  de: "Heute lernst du! Nur {COUNT} {WORDS} zum Review.",
                  es: "¡Hoy estudias! Solo {COUNT} {WORDS} por repasar.",
                  fr: "Aujourd’hui tu étudies ! Juste {COUNT} {WORDS} à réviser.",
                  ja: "今日は勉強！復習は{COUNT}語だけ。",
                  ko: "오늘 공부해! 복습은 {COUNT}개뿐.",
                  ar: "اليوم بتدرس! بس {COUNT} {WORDS} للمراجعة.",
                  it: "Oggi studi! Solo {COUNT} {WORDS} da ripassare.",
                  zhHans: "今天你学习！只要复习 {COUNT} 个词。",
                  zhHant: "今天你學習！只要複習 {COUNT} 個詞。",
                  pt: "Hoje estudas! Só {COUNT} {WORDS} para rever.")
            ),
            (
                L("we’re not ghosting you",
                  ru: "Не гоусти меня",
                  de: "wir ghosten dich nicht",
                  es: "no te estamos ghosteando",
                  fr: "on te ghost pas",
                  ja: "ゴーストしてないよ",
                  ko: "우리가 널 고스트한 게 아냐",
                  ar: "مو نحن عم نغوستك",
                  it: "non ti stiamo ghostando",
                  zhHans: "不是我们在 ghost 你",
                  zhHant: "不是我們在 ghost 你",
                  pt: "não te estamos a ghostar"),
                L("Come review {COUNT} {WORDS}.",
                  ru: "Зайди повторить {COUNT} {WORDS}.",
                  de: "Komm und wiederhole {COUNT} {WORDS}.",
                  es: "Ven a repasar {COUNT} {WORDS}.",
                  fr: "Viens réviser {COUNT} {WORDS}.",
                  ja: "{COUNT}語を復習しに来て。",
                  ko: "{COUNT}개 단어 복습하러 와.",
                  ar: "تعال راجع {COUNT} {WORDS}.",
                  it: "Vieni a ripassare {COUNT} {WORDS}.",
                  zhHans: "来复习 {COUNT} 个词。",
                  zhHant: "來複習 {COUNT} 個詞。",
                  pt: "Vem rever {COUNT} {WORDS}.")
            ),
            (
                L("main character energy check",
                  ru: "Потрогаешь траву после повторения слов",
                  de: "main character energy check",
                  es: "check de energía main character",
                  fr: "check main character energy",
                  ja: "メインキャラ能量チェック",
                  ko: "메인 캐릭터 에너지 체크",
                  ar: "تشيك طاقة البروتاغونيست",
                  it: "check energia main character",
                  zhHans: "主角光环点名",
                  zhHant: "主角光環點名",
                  pt: "check de energia main character"),
                L("First {COUNT} {WORDS}. Deal?",
                  ru: "Сначала {COUNT} {WORDS}. Договор?",
                  de: "Zuerst {COUNT} {WORDS}. Deal?",
                  es: "Primero {COUNT} {WORDS}. ¿Trato?",
                  fr: "D’abord {COUNT} {WORDS}. Deal ?",
                  ja: "まず{COUNT}語。いい？",
                  ko: "먼저 {COUNT}개. 딜?",
                  ar: "أولًا {COUNT} {WORDS}. صفقة؟",
                  it: "Prima {COUNT} {WORDS}. Affare?",
                  zhHans: "先 {COUNT} 个词。成交？",
                  zhHant: "先 {COUNT} 個詞。成交？",
                  pt: "Primeiro {COUNT} {WORDS}. Trato?")
            ),
            (
                L("touch grass… after one word",
                  ru: "Мягкая угроза",
                  de: "touch grass… nach einem wort",
                  es: "touch grass… después de una palabra",
                  fr: "touch grass… après un mot",
                  ja: "touch grass…でも1語のあとで",
                  ko: "touch grass… 단어 하나 하고",
                  ar: "touch grass… بعد كلمة",
                  it: "touch grass… dopo una parola",
                  zhHans: "touch grass…先学一个词",
                  zhHant: "touch grass…先學一個詞",
                  pt: "touch grass… depois de uma palavra"),
                L("Open the dictionary or the notifications continue.",
                  ru: "Открой словарь или уведомления продолжатся.",
                  de: "Öffne das Wörterbuch oder die Notifs gehen weiter.",
                  es: "Abre el diccionario o siguen las notifs.",
                  fr: "Ouvre le dico ou les notifs continuent.",
                  ja: "辞書を開かないと通知は続くよ。",
                  ko: "사전 안 열면 알림 계속됨.",
                  ar: "افتح القاموس أو الإشعارات بنكمل.",
                  it: "Apri il dizionario o le notif continuano.",
                  zhHans: "打开词典，不然通知继续。",
                  zhHant: "打開詞典，不然通知繼續。",
                  pt: "Abre o dicionário ou as notifs continuam.")
            ),
            (
                L("your words left on read",
                  ru: "Итс гивинг заброшенный словарь",
                  de: "deine wörter left on read",
                  es: "tus palabras left on read",
                  fr: "tes mots left on read",
                  ja: "単語が既読スルーされてる",
                  ko: "단어들이 읽씹당함",
                  ar: "كلماتك left on read",
                  it: "le tue parole left on read",
                  zhHans: "单词已读不回",
                  zhHant: "單字已讀不回",
                  pt: "as tuas palavras left on read"),
                L("{COUNT} {WORDS} left behind.",
                  ru: "Заброшено {COUNT} {WORDS}.",
                  de: "{COUNT} {WORDS} vernachlässigt.",
                  es: "{COUNT} {WORDS} {LEFT}.",
                  fr: "{COUNT} {WORDS} {LEFT} de côté.",
                  ja: "{COUNT}語放置中。",
                  ko: "{COUNT}개 방치됨.",
                  ar: "{COUNT} {WORDS} متروكة.",
                  it: "{COUNT} {WORDS} {LEFT}.",
                  zhHans: "落下了 {COUNT} 个词。",
                  zhHant: "落下了 {COUNT} 個詞。",
                  pt: "{COUNT} {WORDS} {LEFT}.")
            ),
            (
                L("soft threat unlocked",
                  ru: "Я пришел забрать долг!",
                  de: "soft threat freigeschaltet",
                  es: "amenaza soft desbloqueada",
                  fr: "soft threat débloqué",
                  ja: "やさしい脅し解放",
                  ko: "소프트 협박 해금",
                  ar: "تهديد لطيف مفتوح",
                  it: "soft threat sbloccata",
                  zhHans: "温柔威胁已解锁",
                  zhHant: "溫柔威脅已解鎖",
                  pt: "soft threat desbloqueada"),
                L("Debt: {COUNT} {WORDS} to review.",
                  ru: "Долг: {COUNT} {WORDS} к повторению.",
                  de: "Schuld: {COUNT} {WORDS} zum Review.",
                  es: "Deuda: {COUNT} {WORDS} por repasar.",
                  fr: "Dette : {COUNT} {WORDS} à réviser.",
                  ja: "借金：復習{COUNT}語。",
                  ko: "빚: 복습 {COUNT}개.",
                  ar: "الدين: {COUNT} {WORDS} للمراجعة.",
                  it: "Debito: {COUNT} {WORDS} da ripassare.",
                  zhHans: "欠债：复习 {COUNT} 个词。",
                  zhHant: "欠債：複習 {COUNT} 個詞。",
                  pt: "Dívida: {COUNT} {WORDS} para rever.")
            ),
            (
                L("bro the streak is dramatizing",
                  ru: "Бро, серия уже плачет",
                  de: "bro die serie macht drama",
                  es: "bro la racha está dramatizando",
                  fr: "bro la série fait du drama",
                  ja: "連続がドラマ化してる",
                  ko: "브로 연속이 드라마 치는 중",
                  ar: "برو السلسلة عم تعمل دراما",
                  it: "bro la serie sta dramatizzando",
                  zhHans: "连续打卡开始演了",
                  zhHant: "連續打卡開始演了",
                  pt: "bro a sequência está a dramatizar"),
                L("Talk to it — {COUNT} {WORDS} waiting.",
                  ru: "Поговори с ней — там {COUNT} {WORDS}.",
                  de: "Rede mit ihr — da sind {COUNT} {WORDS}.",
                  es: "Habla con ella — hay {COUNT} {WORDS}.",
                  fr: "Parle-lui — il y a {COUNT} {WORDS}.",
                  ja: "話して — {COUNT}語待ってる。",
                  ko: "말해 줘 — {COUNT}개 기다려.",
                  ar: "احكي معها — في {COUNT} {WORDS}.",
                  it: "Parlale — ci sono {COUNT} {WORDS}.",
                  zhHans: "跟它说说 — 有 {COUNT} 个词。",
                  zhHant: "跟它說說 — 有 {COUNT} 個詞。",
                  pt: "Fala com ela — há {COUNT} {WORDS}.")
            ),
            (
                L("it’s giving neglected dictionary",
                  ru: "Твои слова соскучились 😭😭😭",
                  de: "it’s giving vernachlässigtes wörterbuch",
                  es: "it’s giving diccionario abandonado",
                  fr: "it’s giving dico négligé",
                  ja: "放置辞書感出てる",
                  ko: "방치된 사전 vibes",
                  ar: "it’s giving قاموس مهمل",
                  it: "it’s giving dizionario abbandonato",
                  zhHans: "it’s giving 被冷落的词典",
                  zhHant: "it’s giving 被冷落的詞典",
                  pt: "it’s giving dicionário abandonado"),
                L("There are {COUNT} of them. Come say hi.",
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
            left = "vernachlässigt"
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
            left = "left behind"
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
                L("ok so you’re ghosting",
                  ru: "Так ты меня гоустишь???",
                  de: "ok also du ghostest",
                  es: "ok así que estás ghosteando",
                  fr: "ok donc tu ghost",
                  ja: "なるほどゴーストしてる",
                  ko: "오케이 너 고스트 중이구나",
                  ar: "طيب يعني عم تغوست",
                  it: "ok quindi stai ghostando",
                  zhHans: "所以你在 ghost",
                  zhHant: "所以你在 ghost",
                  pt: "ok então estás a ghostar"),
                L("a few days silent. we noticed. soft threat: open.",
                  ru: "Открой droword",
                  de: "ein paar tage still. wir haben’s gemerkt. soft threat: öffne.",
                  es: "unos días en silencio. lo notamos. amenaza soft: abre.",
                  fr: "quelques jours de silence. on a vu. soft threat: ouvre.",
                  ja: "数日沈黙。気づいたよ。やさしい脅し：開けて。",
                  ko: "며칠 침묵. 우리가 봄. 소프트 협박: 열어.",
                  ar: "كم يوم صمت. انتبهنا. تهديد لطيف: افتح.",
                  it: "qualche giorno di silenzio. l’abbiamo notato. soft threat: apri.",
                  zhHans: "安静几天了。我们看见了。温柔威胁：打开。",
                  zhHant: "安靜幾天了。我們看見了。溫柔威脅：打開。",
                  pt: "uns dias de silêncio. notámos. soft threat: abre.")
            ),
            (
                L("streak is in the group chat crying",
                  ru: "Звонила твоя серия в Скайпе",
                  de: "die serie weint im gruppenchat",
                  es: "la racha llora en el group chat",
                  fr: "la série pleure dans le group chat",
                  ja: "連続がグループチャットで泣いてる",
                  ko: "연속이 단톡에서 울고 있음",
                  ar: "السلسلة عم تبكي بالجروب",
                  it: "la serie piange nel group chat",
                  zhHans: "连续打卡在群聊里哭",
                  zhHant: "連續打卡在群聊裡哭",
                  pt: "a sequência está a chorar no group chat"),
                L("a week without vocab. one word = comeback lore.",
                  ru: "Гвоорит ты не учишься",
                  de: "eine woche ohne vokabeln. ein wort = comeback lore.",
                  es: "una semana sin vocab. una palabra = comeback lore.",
                  fr: "une semaine sans vocab. un mot = comeback lore.",
                  ja: "1週間ぶりの語彙。1語＝カムバックlore。",
                  ko: "일주일 단어 공백. 하나 = 컴백 lore.",
                  ar: "أسبوع بلا كلمات. كلمة = كومباك lore.",
                  it: "una settimana senza vocab. una parola = comeback lore.",
                  zhHans: "一周没碰单词。一个词 = 回归 lore。",
                  zhHant: "一週沒碰單字。一個詞 = 回歸 lore。",
                  pt: "uma semana sem vocab. uma palavra = comeback lore.")
            ),
            (
                L("we kept your seat warm (creepy)",
                  ru: "Я тебе тут латтешку приготовил",
                  de: "wir hielten deinen platz warm (creepy)",
                  es: "guardamos tu asiento (creepy)",
                  fr: "on a gardé ta place (creepy)",
                  ja: "席温めてたよ(ちょい不気味)",
                  ko: "자리 따뜻하게 지켜둠 (좀 소름)",
                  ar: "دفّينا مقعدك (كريبي)",
                  it: "abbiamo tenuto il posto caldo (creepy)",
                  zhHans: "座位给你捂热了(有点诡异)",
                  zhHant: "座位給你捂熱了(有點詭異)",
                  pt: "aqueciemos o teu lugar (creepy)"),
                L("two weeks away. no judgment. just… open before we escalate.",
                  ru: "Зайдешь?",
                  de: "zwei wochen weg. kein urteil. einfach… öffne bevor wir eskalieren.",
                  es: "dos semanas fuera. sin juicio. solo… abre antes de que escalemos.",
                  fr: "deux semaines absentes. sans jugement. juste… ouvre avant qu’on scale.",
                  ja: "2週間ぶり。責めない。ただ…エスカレート前に開けて。",
                  ko: "2주 자리비움. 탓 안 해. 그냥… 에스컬레이트 전에 열어.",
                  ar: "أسبوعين برا. بدون حكم. بس… افتح قبل ما نصعّد.",
                  it: "due settimane via. nessun giudizio. solo… apri prima che scalaimo.",
                  zhHans: "两周没来。不评判。只是…升级前打开。",
                  zhHant: "兩週沒來。不評判。只是…升級前打開。",
                  pt: "duas semanas fora. sem juízos. só… abre antes de escalarmos.")
            ),
            (
                L("long break? soft reboot unlocked",
                  ru: "Долгий перерыв?",
                  de: "lange pause? soft reboot freigeschaltet",
                  es: "¿pausa larga? soft reboot desbloqueado",
                  fr: "longue pause ? soft reboot débloqué",
                  ja: "長い休み？soft reboot解放",
                  ko: "긴 휴식? soft reboot 해금",
                  ar: "استراحة طويلة؟ soft reboot مفتوح",
                  it: "lunga pausa? soft reboot sbloccata",
                  zhHans: "长假？温柔重启已解锁",
                  zhHant: "長假？溫柔重啟已解鎖",
                  pt: "pausa longa? soft reboot desbloqueado"),
                L("a month offline. start with one word. we won’t rat you out.",
                  ru: "Понятно.",
                  de: "einen monat offline. fang mit einem wort an. wir verpetzen dich nicht.",
                  es: "un mes offline. empieza con una palabra. no te delatamos.",
                  fr: "un mois offline. commence par un mot. on te balance pas.",
                  ja: "1か月オフ。1語から。チクらないよ。",
                  ko: "한 달 오프라인. 단어 하나로 시작. 고자질 안 함.",
                  ar: "شهر أوفلاين. ابدأ بكلمة. مش هنفضحك.",
                  it: "un mese offline. parti da una parola. non ti spiattelliamo.",
                  zhHans: "离线一个月。从一个词开始。我们不告密。",
                  zhHant: "離線一個月。從一個詞開始。我們不告密。",
                  pt: "um mês offline. começa com uma palavra. não te denunciamos.")
            ),
            (
                L("scrolling again? we see you",
                  ru: "Опять скроллишь?",
                  de: "wieder am scrollen? wir sehen dich",
                  es: "¿scrolleando otra vez? te vemos",
                  fr: "encore en train de scroller ? on te voit",
                  ja: "またスクロール？見てるよ",
                  ko: "또 스크롤? 우리가 봄",
                  ar: "عم تسكرول تاني؟ عم نشوفك",
                  it: "di nuovo a scrollare? ti vediamo",
                  zhHans: "又在刷？我们看见了",
                  zhHant: "又在刷？我們看見了",
                  pt: "outra vez a fazer scroll? vemos-te"),
                L("touch grass later. open droword first. deal or more notifs.",
                  ru: "А как же я? 😩",
                  de: "touch grass später. erst droword. deal oder mehr notifs.",
                  es: "touch grass después. primero droword. trato o más notifs.",
                  fr: "touch grass plus tard. droword d’abord. deal ou plus de notifs.",
                  ja: "touch grassは後で。先にdroword。取引か通知増。",
                  ko: "touch grass는 나중에. 먼저 droword. 딜 아니면 알림 더.",
                  ar: "touch grass بعدين. droword أول. صفقة أو إشعارات زيادة.",
                  it: "touch grass dopo. prima droword. affare o più notif.",
                  zhHans: "touch grass 稍后。先打开 droword。成交还是更多通知。",
                  zhHant: "touch grass 稍後。先打開 droword。成交還是更多通知。",
                  pt: "touch grass depois. droword primeiro. trato ou mais notifs.")
            ),
        ]
        let i = min(max(index, 0), pairs.count - 1)
        return (t(pairs[i].0), t(pairs[i].1))
    }



    static func pickReviewTitle() -> String {
        let titles: [[String: String]] = [
            L("words are in your dms",
              ru: "Там такое слово классненькое, глянь",
              de: "wörter sind in deinen dms",
              es: "las palabras están en tus dms",
              fr: "les mots sont dans tes dms",
              ja: "単語がDMに来てる",
              ko: "단어들이 DM에 있음",
              ar: "الكلمات بـ dms تبعك",
              it: "le parole sono nelle tue dm",
              zhHans: "单词在你私信里",
              zhHant: "單字在你私訊裡",
              pt: "as palavras estão nas tuas dms"),
            L("review or we escalate",
              ru: "Может ревью? 🤔",
              de: "review oder wir eskalieren",
              es: "repasa o escalamos",
              fr: "révise ou on scale",
              ja: "復習しないとエスカレート",
              ko: "복습 안 하면 에스컬레이트",
              ar: "راجع أو منصعّد",
              it: "ripassa o scalaimo",
              zhHans: "复习不然我们升级",
              zhHant: "複習不然我們升級",
              pt: "revisa ou escalamos"),
            L("memory check (no cap)",
              ru: "Опа! А че ты делаешь?",
              de: "gedächtnis-check (no cap)",
              es: "chequeo de memoria (no cap)",
              fr: "check mémoire (no cap)",
              ja: "記憶チェック(マジ)",
              ko: "기억 체크 (노캡)",
              ar: "تشيك ذاكرة (no cap)",
              it: "check memoria (no cap)",
              zhHans: "记忆点名(认真)",
              zhHant: "記憶點名(認真)",
              pt: "check de memória (no cap)"),
            L("your streak wants receipts",
              ru: "Серия нуждается в твоем внимании",
              de: "deine serie will receipts",
              es: "tu racha quiere receipts",
              fr: "ta série veut des receipts",
              ja: "連続が証拠求めてる",
              ko: "연속이 영수증 원함",
              ar: "سلسلتك بدها إثبات",
              it: "la serie vuole receipts",
              zhHans: "连续打卡要收据",
              zhHant: "連續打卡要收據",
              pt: "a sequência quer receipts"),
            L("soft threat: open the deck",
              ru: "Красотулька зайди плиз",
              de: "soft threat: öffne das deck",
              es: "amenaza soft: abre el mazo",
              fr: "soft threat: ouvre le deck",
              ja: "やさしい脅し：デッキ開けて",
              ko: "소프트 협박: 덱 열어",
              ar: "تهديد لطيف: افتح الدك",
              it: "soft threat: apri il mazzo",
              zhHans: "温柔威胁：打开牌组",
              zhHant: "溫柔威脅：打開牌組",
              pt: "soft threat: abre o baralho"),
            L("they’re due and they’re dramatic",
              ru: "Повторить или не повторить, вот в чем вопрос",
              de: "sie sind fällig und dramatisch",
              es: "están due y están dramatic",
              fr: "ils sont due et dramatiques",
              ja: "期限切れでドラマチック",
              ko: "due인데 드라마틱함",
              ar: "due ودراميين",
              it: "sono due e sono dramatic",
              zhHans: "到期了而且很戏剧",
              zhHant: "到期了而且很戲劇",
              pt: "estão due e estão dramatic"),
        ]
        return t(titles[dayIndex % titles.count])
    }

    static func reviewBody(count: Int) -> String {
        if count == 1 {
            return t(L(
                "1 word due. won’t take long. we’re watching.",
                ru: "ОДНО СЛОВО",
                de: "1 wort due. dauert nicht. wir schauen zu.",
                es: "1 palabra due. no toma mucho. te miramos.",
                fr: "1 mot due. ça prendra pas longtemps. on regarde.",
                ja: "1語 due。すぐ終わる。見てるよ。",
                ko: "단어 1개 due. 오래 안 걸려. 보고 있어.",
                ar: "كلمة due. ما رح يطول. عم نراقب.",
                it: "1 parola due. non ci vuole molto. stiamo guardando.",
                zhHans: "1 个词 due。不会久。我们看着。",
                zhHant: "1 個詞 due。不會久。我們看著。",
                pt: "1 palavra due. não demora. estamos a ver."
            ))
        }

        let ruWords = russianWordsReady(count)
        return t(L(
            "{COUNT} words due. quick hit then you’re free (for now).",
            ru: "Тут вон \(count) \(ruWords). Зайди быстренько — и свободен",
            de: "{COUNT} wörter due. quick hit dann frei (erstmal).",
            es: "{COUNT} palabras due. golpe rápido y libre (por ahora).",
            fr: "{COUNT} mots due. quick hit puis libre (pour l’instant).",
            ja: "{COUNT}語 due。サクッとやって自由(今のところ)。",
            ko: "{COUNT}개 due. 빠르게 하고 자유 (일단).",
            ar: "{COUNT} كلمات due. ضربة سريعة وبعدين حر (هلأ).",
            it: "{COUNT} parole due. colpo veloce e poi libero (per ora).",
            zhHans: "{COUNT} 个词 due。速通然后自由(暂时)。",
            zhHant: "{COUNT} 個詞 due。速通然後自由(暫時)。",
            pt: "{COUNT} palavras due. hit rápido e depois livre (por agora)."
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
                "be honest… do you remember this one? soft threat.",
                ru: "А как это говорится?",
                de: "sei ehrlich… erinnerst du dich? soft threat.",
                es: "sé honesto… ¿recuerdas esta? amenaza soft.",
                fr: "sois honnête… tu te souviens ? soft threat.",
                ja: "正直に…覚えてる？やさしい脅し。",
                ko: "솔직히… 이거 기억나? 소프트 협박.",
                ar: "بصراحة… بتتذكر هيدي؟ تهديد لطيف.",
                it: "onesto… ti ricordi questa? soft threat.",
                zhHans: "说实话…还记得这个吗？温柔威胁。",
                zhHant: "說實話…還記得這個嗎？溫柔威脅。",
                pt: "sê honesto… lembras-te desta? soft threat."
            ))
        }
        return parts.joined(separator: " · ")
    }



    static func streakMilestone(for streak: Int) -> (title: String, body: String) {
        switch streak {
        case 7:
            return (
                t(L("7-day arc unlocked",
                    ru: "7-дневная че то там открыта",
                    de: "7-tage-arc freigeschaltet",
                    es: "arco de 7 días desbloqueado",
                    fr: "arc 7 jours débloqué",
                    ja: "7日アーク解放",
                    ko: "7일 아크 해금",
                    ar: "قوس ٧ أيام مفتوح",
                    it: "arco 7 giorni sbloccato",
                    zhHans: "7 日弧线已解锁",
                    zhHant: "7 日弧線已解鎖",
                    pt: "arco de 7 dias desbloqueado")),
                t(L("one week main character. the streak is thriving.",
                    ru: "Неделя пошла!",
                    de: "eine woche main character. die serie thrived.",
                    es: "una semana main character. la racha thrives.",
                    fr: "une semaine main character. la série thrives.",
                    ja: "1週間メインキャラ。連続が輝いてる。",
                    ko: "일주일 메인 캐릭터. 연속 thriving.",
                    ar: "أسبوع بروتاغونيست. السلسلة thrives.",
                    it: "una settimana main character. la serie thrives.",
                    zhHans: "一周主角。连续打卡在发光。",
                    zhHant: "一週主角。連續打卡在發光。",
                    pt: "uma semana main character. a sequência thrives."))
            )
        case 30:
            return (
                t(L("30 days. no cap.",
                    ru: "30 дней!",
                    de: "30 tage. no cap.",
                    es: "30 días. no cap.",
                    fr: "30 jours. no cap.",
                    ja: "30日。マジ。",
                    ko: "30일. 노캡.",
                    ar: "٣٠ يوم. no cap.",
                    it: "30 giorni. no cap.",
                    zhHans: "30 天。认真的。",
                    zhHant: "30 天。認真的。",
                    pt: "30 dias. no cap.")),
                t(L("full month lore. the group chat is screaming.",
                    ru: "Даже я так не могу",
                    de: "voller monats-lore. der gruppenchat schreit.",
                    es: "lore de un mes. el group chat grita.",
                    fr: "lore d’un mois. le group chat hurle.",
                    ja: "まる1か月のlore。グループチャットが叫んでる。",
                    ko: "한 달 lore. 단톡이 비명 중.",
                    ar: "lore شهر كامل. الجروب عم يصرخ.",
                    it: "lore di un mese. il group chat urla.",
                    zhHans: "整月 lore。群聊在尖叫。",
                    zhHant: "整月 lore。群聊在尖叫。",
                    pt: "lore de um mês. o group chat está a gritar."))
            )
        case 100:
            return (
                t(L("100 days. legend behavior",
                    ru: "100 дней.",
                    de: "100 tage. legend behavior",
                    es: "100 días. legend behavior",
                    fr: "100 jours. legend behavior",
                    ja: "100日。レジェンド挙動",
                    ko: "100일. 레전드 행동",
                    ar: "١٠٠ يوم. سلوك أسطوري",
                    it: "100 giorni. legend behavior",
                    zhHans: "100 天。传奇行为",
                    zhHant: "100 天。傳奇行為",
                    pt: "100 dias. legend behavior")),
                t(L("your consistency is unhinged (in a good way).",
                    ru: "Ты такая умничка ваще!",
                    de: "deine konstanz ist unhinged (im guten sinne).",
                    es: "tu constancia está unhinged (en el buen sentido).",
                    fr: "ta régularité est unhinged (dans le bon sens).",
                    ja: "継続力やばい(いい意味で)。",
                    ko: "꾸준함이 언힌지드 (좋은 뜻으로).",
                    ar: "ثباتك مجنون (بمعنى حلو).",
                    it: "la tua costanza è unhinged (in senso buono).",
                    zhHans: "你的坚持有点疯(褒义)。",
                    zhHant: "你的堅持有點瘋(褒義)。",
                    pt: "a tua consistência está unhinged (no bom sentido)."))
            )
        case 365:
            return (
                t(L("365. full year. we’re obsessed",
                    ru: "365. Целый год.",
                    de: "365. volles jahr. wir sind obsessed",
                    es: "365. año completo. estamos obsessed",
                    fr: "365. année pleine. on est obsessed",
                    ja: "365。まる1年。沼ってる",
                    ko: "365. 꼬박 일 년. 우리가 obsessed",
                    ar: "٣٦٥. سنة كاملة. نحن obsessed",
                    it: "365. anno pieno. siamo obsessed",
                    zhHans: "365。整年。我们上头了",
                    zhHant: "365。整年。我們上頭了",
                    pt: "365. ano completo. estamos obsessed")),
                t(L("you didn’t skip the lore. plot armor permanent. huge.",
                    ru: "Я вообще без слов",
                    de: "du hast den lore nicht geskippt. plot armor permanent. riesig.",
                    es: "no saltaste el lore. plot armor permanente. enorme.",
                    fr: "tu n’as pas skip le lore. plot armor permanent. énorme.",
                    ja: "loreスキップしなかった。plot armor永久。でかい。",
                    ko: "lore 안 스킵함. plot armor 영구. 거대.",
                    ar: "ما فوتّ الـ lore. plot armor دائم. ضخم.",
                    it: "non hai skippato il lore. plot armor permanente. enorme.",
                    zhHans: "你没跳过 lore。永久护体。巨大。",
                    zhHant: "你沒跳過 lore。永久護體。巨大。",
                    pt: "não saltaste o lore. plot armor permanente. enorme."))
            )
        default:
            return (
                t(L("new streak milestone unlocked",
                    ru: "Тут уже — {STREAK} дней прошло",
                    de: "neuer serien-meilenstein freigeschaltet",
                    es: "nuevo hito de racha desbloqueado",
                    fr: "nouveau jalon de série débloqué",
                    ja: "連続マイルストーン解放",
                    ko: "연속 마일스톤 해금",
                    ar: "محطة سلسلة جديدة مفتوحة",
                    it: "nuovo traguardo serie sbloccato",
                    zhHans: "连续打卡新里程碑已解锁",
                    zhHant: "連續打卡新里程碑已解鎖",
                    pt: "novo marco da sequência desbloqueado"))
                    .replacingOccurrences(of: "{STREAK}", with: "\(streak)"),
                t(L("{STREAK} days. the arc continues. don’t drop the bag.",
                    ru: "Тебя уже по всем каналам крутят. Вот такой ты крутой, мой человечек ✨",
                    de: "{STREAK} tage. der arc geht weiter. drop the bag nicht.",
                    es: "{STREAK} días. el arco sigue. no drops the bag.",
                    fr: "{STREAK} jours. l’arc continue. drop pas the bag.",
                    ja: "{STREAK}日。アーク続く。bag落とすな。",
                    ko: "{STREAK}일. 아크 계속. bag 드롭 마.",
                    ar: "{STREAK} يوم. القوس مستمر. ما تفلّت الـ bag.",
                    it: "{STREAK} giorni. l’arco continua. non droppare the bag.",
                    zhHans: "{STREAK} 天。剧情继续。别掉包。",
                    zhHant: "{STREAK} 天。劇情繼續。別掉包。",
                    pt: "{STREAK} dias. o arco continua. não drops the bag."))
                    .replacingOccurrences(of: "{STREAK}", with: "\(streak)")
            )
        }
    }



    static func pickGoal() -> (title: String, body: String) {
        let empty = L("", ru: "", de: "", es: "", fr: "", ja: "", ko: "", ar: "", it: "", zhHans: "", zhHant: "", pt: "")
        return pick([
            (
                L("goal done. soft threat cancelled",
                  ru: "Цель того самого, ну, это.",
                  de: "ziel erledigt. soft threat cancelled",
                  es: "meta hecha. amenaza soft cancelled",
                  fr: "objectif fait. soft threat cancelled",
                  ja: "目標クリア。やさしい脅し解除",
                  ko: "목표 완료. 소프트 협박 취소",
                  ar: "الهدف خلص. التهديد اللطيف ملغي",
                  it: "obiettivo fatto. soft threat cancelled",
                  zhHans: "目标完成。温柔威胁取消",
                  zhHant: "目標完成。溫柔威脅取消",
                  pt: "objetivo feito. soft threat cancelled"),
                empty
            ),
            (
                L("streak safe. vibes restored. go touch grass.",
                  ru: "Серия в безопасности. Пойду поем.",
                  de: "serie sicher. vibes restored. geh touch grass.",
                  es: "racha a salvo. vibes restored. ve a touch grass.",
                  fr: "série safe. vibes restored. va touch grass.",
                  ja: "連続セーフ。バイブス回復。touch grassして。",
                  ko: "연속 안전. 바이브 복구. touch grass 해.",
                  ar: "السلسلة بأمان. الفايبس رجعت. روح touch grass.",
                  it: "serie al sicuro. vibes restored. vai a touch grass.",
                  zhHans: "连续安全。氛围恢复。去 touch grass。",
                  zhHant: "連續安全。氛圍恢復。去 touch grass。",
                  pt: "sequência segura. vibes restored. vai touch grass."),
                empty
            ),
            (
                L("what are you even doing",
                  ru: "Что вытворяешь ваще.",
                  de: "was machst du da eigentlich",
                  es: "qué estás haciendo",
                  fr: "mais qu’est-ce que tu fabriques",
                  ja: "何してるの",
                  ko: "뭐 하는 거야",
                  ar: "شو عم تعمل",
                  it: "ma che stai combinando",
                  zhHans: "你在搞什么",
                  zhHant: "你在搞什麼",
                  pt: "o que estás a fazer"),
                empty
            ),
            (
                L("the day looks magical",
                  ru: "Денек обещает быть волшебным.",
                  de: "der tag verspricht magisch zu werden",
                  es: "el día promete ser mágico",
                  fr: "la journée s’annonce magique",
                  ja: "素敵な一日になりそう",
                  ko: "마법 같은 하루가 될 듯",
                  ar: "اليوم واعد وسحري",
                  it: "la giornata promette di essere magica",
                  zhHans: "今天看起来会很神奇",
                  zhHant: "今天看起來會很神奇",
                  pt: "o dia promete ser mágico"),
                empty
            ),
        ])
    }



    static func pickEveningChat(word: String, translation: String) -> (title: String, body: String) {
        let titles: [[String: String]] = [
            L("night quest: one line",
              ru: "Спишь?",
              de: "nacht-quest: eine zeile",
              es: "misión nocturna: una línea",
              fr: "quête de nuit: une ligne",
              ja: "ナイトクエスト：ひとこと",
              ko: "나이트 퀘스트: 한 줄",
              ar: "مهمة ليلية: سطر",
              it: "quest notturna: una riga",
              zhHans: "夜间任务：一句",
              zhHant: "夜間任務：一句",
              pt: "quest noturna: uma linha"),
            L("say it before you doomscroll",
              ru: "Скажи «\(word)» или мой кот тебя поцарапает",
              de: "sag’s vor dem doomscroll",
              es: "dilo antes del doomscroll",
              fr: "dis-le avant le doomscroll",
              ja: "ドゥームスクロール前に言って",
              ko: "둠스크롤 전에 말해",
              ar: "قولها قبل الدومسكرول",
              it: "dillo prima del doomscroll",
              zhHans: "刷到抑郁前说出来",
              zhHant: "刷到抑鬱前說出來",
              pt: "diz antes do doomscroll"),
            L("soft threat bedtime edition",
              ru: "Я тебя сегодня видел в Тика Токе",
              de: "soft threat bedtime edition",
              es: "amenaza soft bedtime edition",
              fr: "soft threat bedtime edition",
              ja: "やさしい脅し：就寝版",
              ko: "소프트 협박 취침판",
              ar: "تهديد لطيف نسخة نوم",
              it: "soft threat bedtime edition",
              zhHans: "温柔威胁：睡前版",
              zhHant: "溫柔威脅：睡前版",
              pt: "soft threat bedtime edition"),
            L("main character night scene",
              ru: "А хочешь сгенерировать себе сказку из всех добавленных слов?",
              de: "main character night scene",
              es: "escena nocturna main character",
              fr: "scène de nuit main character",
              ja: "メインキャラ夜シーン",
              ko: "메인 캐릭터 나이트 씬",
              ar: "مشهد ليلي بروتاغونيست",
              it: "scena notturna main character",
              zhHans: "主角夜戏",
              zhHant: "主角夜戲",
              pt: "cena noturna main character"),
            L("one word before lights out",
              ru: "Одно слово два слова. Что это?",
              de: "ein wort vor lights out",
              es: "una palabra antes de lights out",
              fr: "un mot avant lights out",
              ja: "消灯前に1語",
              ko: "불 끄기 전 단어 하나",
              ar: "كلمة قبل إطفاء الأنوار",
              it: "una parola prima di lights out",
              zhHans: "熄灯前一个词",
              zhHant: "熄燈前一個詞",
              pt: "uma palavra antes de lights out"),
            L("once upon a pupsik",
              ru: "Жил был один пупсик, который все слова перед сном повторил. Это ты?",
              de: "es war einmal ein pupsik",
              es: "había una vez un pupsik",
              fr: "il était une fois un pupsik",
              ja: "あるところにププシクが",
              ko: "옛날에 푸프식이",
              ar: "كان يا مكان بوبسيك",
              it: "c’era una volta un pupsik",
              zhHans: "从前有个小宝贝",
              zhHant: "從前有個小寶貝",
              pt: "era uma vez um pupsik"),
            L("streak safe bedtime",
              ru: "Серия в безопасности. Теперь спатки",
              de: "serie sicher. jetzt schlafen",
              es: "racha a salvo. ahora a dormir",
              fr: "série safe. maintenant dodo",
              ja: "連続セーフ。おやすみ",
              ko: "연속 안전. 이제 잘 시간",
              ar: "السلسلة بأمان. هلق نوم",
              it: "serie al sicuro. ora nanna",
              zhHans: "连续安全。该睡了",
              zhHant: "連續安全。該睡了",
              pt: "sequência segura. agora dormir"),
        ]
        let bodies: [[String: String]] = [
            L("how would you drop «\(word)» in a chat? we’re listening.",
              ru: "А ну ка как переводится «\(word)»?",
              de: "wie würdest du «\(word)» im chat droppen? wir hören zu.",
              es: "¿cómo dropearías «\(word)» en un chat? escuchamos.",
              fr: "comment tu dropperais «\(word)» dans un chat ? on écoute.",
              ja: "チャットで「\(word)」どう落とす？聞いてるよ。",
              ko: "채팅에 «\(word)» 어떻게 드롭할래? 듣고 있어.",
              ar: "كيف بترمي «\(word)» بالشات؟ عم نسمع.",
              it: "come dropperesti «\(word)» in chat? stiamo ascoltando.",
              zhHans: "你会怎么在聊天里甩出「\(word)」？我们听着。",
              zhHant: "你會怎麼在聊天裡甩出「\(word)」？我們聽著。",
              pt: "como dropavas «\(word)» num chat? estamos a ouvir."),
            L("«\(word)» — \(translation). use it once or we soft-threat again.",
              ru: "«\(word)» — \(translation)",
              de: "«\(word)» — \(translation). einmal nutzen oder soft threat wieder.",
              es: "«\(word)» — \(translation). úsala una vez o amenaza soft otra vez.",
              fr: "«\(word)» — \(translation). une fois ou soft threat encore.",
              ja: "「\(word)」— \(translation)。一回使わないとまた脅す。",
              ko: "«\(word)» — \(translation). 한 번 쓰거나 소프트 협박 다시.",
              ar: "«\(word)» — \(translation). مرة أو تهديد لطيف تاني.",
              it: "«\(word)» — \(translation). usala una volta o soft threat di nuovo.",
              zhHans: "「\(word)」— \(translation)。用一次，不然再温柔威胁。",
              zhHant: "「\(word)」— \(translation)。用一次，不然再溫柔威脅。",
              pt: "«\(word)» — \(translation). usa uma vez ou soft threat outra vez."),
            L("reply in your head: \(word). scrolling can wait. no cap.",
              ru: "Все слова были повторены?",
              de: "antworte im kopf: \(word). scrollen kann warten. no cap.",
              es: "responde en la cabeza: \(word). el scroll puede esperar. no cap.",
              fr: "réponds dans ta tête : \(word). le scroll peut attendre. no cap.",
              ja: "頭の中で返信：\(word)。スクロールは待てる。マジ。",
              ko: "머릿속으로 답해: \(word). 스크롤은 기다려. 노캡.",
              ar: "جاوب براسك: \(word). السكرول فيو يستنى. no cap.",
              it: "rispondi in testa: \(word). lo scroll può aspettare. no cap.",
              zhHans: "脑子里回：\(word)。刷手机可以等。认真。",
              zhHant: "腦子裡回：\(word)。刷手機可以等。認真。",
              pt: "responde na cabeça: \(word). o scroll pode esperar. no cap."),
            L("plot twist night: use «\(word)» before bed. streak is watching.",
              ru: "«\(word)» — \(translation)",
              de: "nacht-plot-twist: nutz «\(word)» vor dem schlafen. serie schaut zu.",
              es: "plot twist nocturno: usa «\(word)» antes de dormir. la racha mira.",
              fr: "plot twist de nuit : utilise «\(word)» avant de dormir. la série regarde.",
              ja: "夜のどんでん返し：「\(word)」を寝る前に。連続が見てる。",
              ko: "밤 반전: 자기 전에 «\(word)» 써. 연속이 보고 있음.",
              ar: "تويست ليلي: استعمل «\(word)» قبل النوم. السلسلة عم تراقب.",
              it: "plot twist notturno: usa «\(word)» prima di dormire. la serie guarda.",
              zhHans: "夜间反转：睡前用「\(word)」。连续打卡在看。",
              zhHant: "夜間反轉：睡前用「\(word)」。連續打卡在看。",
              pt: "plot twist noturno: usa «\(word)» antes de dormires. a sequência está a ver."),
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
