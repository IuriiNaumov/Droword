import Foundation

enum SceneOfflineCopy {
    static func opening(word: String, translation: String, nativeLanguage: String) -> SceneTurn {
        let meaning = translation.isEmpty ? word : translation
        let kind = SceneKind.detect(word: word, translation: translation)
        let reply = pick(lines(nativeLanguage, meaning: meaning, kind: kind).open, seed: word + "0")
        return SceneTurn(reply: reply, hint: word, nudge: nil, usedWord: false, done: false)
    }

    static func reply(word: String, translation: String, userTurns: Int, usedWord: Bool, nativeLanguage: String) -> SceneTurn {
        let meaning = translation.isEmpty ? word : translation
        let kind = SceneKind.detect(word: word, translation: translation)
        let pack = lines(nativeLanguage, meaning: meaning, kind: kind)
        if userTurns >= 3 {
            return SceneTurn(reply: pick(pack.close, seed: word + "c"), hint: nil, nudge: nil, usedWord: usedWord, done: true)
        }
        if usedWord {
            return SceneTurn(reply: pick(pack.follow, seed: word + "\(userTurns)"), hint: nil, nudge: nil, usedWord: true, done: false)
        }
        return SceneTurn(
            reply: pick(pack.nudge, seed: word + "n\(userTurns)"),
            hint: word,
            nudge: nil,
            usedWord: false,
            done: false
        )
    }

    private static func pick(_ items: [String], seed: String) -> String {
        guard !items.isEmpty else { return "" }
        let sum = seed.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return items[abs(sum) % items.count]
    }

    private static func lines(_ native: String, meaning: String, kind: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        switch native {
        case "Русский": return ru(meaning, kind)
        case "Español": return es(meaning, kind)
        case "Français": return fr(meaning, kind)
        case "Deutsch": return de(meaning, kind)
        case "Italiano": return it(meaning, kind)
        case "Português": return pt(meaning, kind)
        case "한국어": return ko(meaning, kind)
        case "日本語": return ja(meaning, kind)
        case "中文": return zh(meaning, kind)
        default: return en(meaning, kind)
        }
    }

    // MARK: - RU

    private static func ru(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["ок, на сегодня хватит.", "ладно, поймал. на сегодня всё.", "супер. завтра продолжим."]
        switch k {
        case .greeting:
            return (
                [
                    "что ты говоришь, когда хочешь поздороваться?",
                    "заходишь к друзьям. первое слово?",
                    "утром кого-то встретил — что скажешь?"
                ],
                [
                    "есть. а если это друг, которого давно не видел?",
                    "ок. а продавцу в магазине?",
                    "а поздно вечером, коротко?"
                ],
                [
                    "ну как поздороваться одним словом?",
                    "зайди в кафе. что скажешь на входе?"
                ],
                close
            )
        case .farewell:
            return (
                [
                    "что ты говоришь, когда уходишь?",
                    "собираешься домой. последнее слово друзьям?",
                    "разговор закончился — как попрощаешься?"
                ],
                ["есть. а если уезжаешь надолго?", "ок. а вечером, коротко?"],
                ["как попрощаться одним словом?", "встаёшь из-за стола. что скажешь?"],
                close
            )
        case .thanks:
            return (
                [
                    "кто-то тебе помог. что скажешь?",
                    "тебе держат дверь. какое слово?",
                    "что ты говоришь, когда хочешь поблагодарить?"
                ],
                ["есть. а если это правда выручило?", "ок. а бармену после кофе?"],
                ["одно слово благодарности?", "тебе передали салфетку. что скажешь?"],
                close
            )
        case .apology:
            return (
                [
                    "наступил кому-то на ногу. что скажешь?",
                    "что ты говоришь, когда хочешь извиниться?",
                    "опоздал на пять минут — первое слово?"
                ],
                ["есть. а если это другу?", "ок. а совсем мелочь, в толпе?"],
                ["как извиниться коротко?", "толкнул незнакомца. что скажешь?"],
                close
            )
        case .howAreYou:
            return (
                [
                    "встретил друга. как спросить, как у него дела?",
                    "что ты говоришь вместо скучного «как жизнь»?",
                    "созвонились. первый вопрос какой?"
                ],
                ["есть. а если давно не виделись?", "ок. а коротко, на бегу?"],
                ["как спросить, как дела, одним выражением?", "друг пишет первым. что ответишь вопросом?"],
                close
            )
        case .please:
            return (
                [
                    "просишь передать соль. какое вежливое слово?",
                    "что добавляешь, когда о чём-то просишь?",
                    "в кафе хочешь ещё воды — как спросить вежливо?"
                ],
                ["есть. а если просишь незнакомого?", "ок. а совсем коротко?"],
                ["какое слово делает просьбу вежливой?", "просишь подвинуться. что добавишь?"],
                close
            )
        case .generic:
            return (
                [
                    "что ты говоришь, когда хочешь сказать «\(m)»?",
                    "представь обычный день. в какой момент тебе нужно «\(m)» — и что тогда говоришь?",
                    "короткая сцена: тебе как раз про «\(m)». какое слово?"
                ],
                [
                    "есть. а в другой ситуации?",
                    "ок. а если это друзьям, неформально?",
                    "поймай. а вечером, в другой обстановке?"
                ],
                [
                    "а как это сказать одним словом — «\(m)»?",
                    "нужно именно «\(m)». какое слово?"
                ],
                close
            )
        }
    }

    // MARK: - ES

    private static func es(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["vale, por hoy ya.", "ok, lo pillaste. hasta mañana.", "bien. lo dejamos aquí."]
        switch k {
        case .greeting:
            return (
                ["¿qué dices cuando quieres saludar?", "entras a ver a tus amigos. ¿primera palabra?", "por la mañana te cruzas con alguien. ¿qué dices?"],
                ["va. ¿y si es un amigo que no veías?", "ok. ¿y al dependiente?"],
                ["¿cómo saludas en una palabra?", "entras a un café. ¿qué dices?"],
                close
            )
        case .farewell:
            return (
                ["¿qué dices cuando te vas?", "te vas a casa. ¿última palabra?", "se acaba la charla. ¿cómo te despides?"],
                ["va. ¿y si te vas mucho tiempo?", "ok. ¿y por la noche, corto?"],
                ["¿cómo te despides en una palabra?", "te levantas de la mesa. ¿qué dices?"],
                close
            )
        case .thanks:
            return (
                ["alguien te acaba de ayudar. ¿qué dices?", "te sostienen la puerta. ¿qué palabra?", "¿qué dices cuando quieres dar las gracias?"],
                ["va. ¿y si te salvó el día?", "ok. ¿y al barista?"],
                ["¿una palabra de gracias?", "te pasan una servilleta. ¿qué dices?"],
                close
            )
        case .apology:
            return (
                ["le pisas a alguien. ¿qué dices?", "¿qué dices cuando quieres disculparte?", "llegas cinco minutos tarde. ¿primera palabra?"],
                ["va. ¿y si es un amigo?", "ok. ¿y en la calle, rápido?"],
                ["¿cómo te disculpas corto?", "chocas con alguien. ¿qué dices?"],
                close
            )
        case .howAreYou:
            return (
                ["ves a un amigo. ¿cómo le preguntas qué tal?", "¿qué dices en vez de un «cómo estás» aburrido?", "cogéis el teléfono. ¿primer pregunta?"],
                ["va. ¿y si hace mucho que no os veis?", "ok. ¿y corriendo?"],
                ["¿cómo preguntas qué tal, en corto?", "un amigo escribe primero. ¿qué preguntas?"],
                close
            )
        case .please:
            return (
                ["pides la sal. ¿qué palabra educada?", "¿qué añades cuando pides algo?", "en el café quieres más agua. ¿cómo lo pides?"],
                ["va. ¿y si es un desconocido?", "ok. ¿y bien corto?"],
                ["¿qué palabra hace la petición educada?", "pides que se aparten. ¿qué añades?"],
                close
            )
        case .generic:
            return (
                ["¿qué dices cuando quieres decir «\(m)»?", "piensa en un día normal. ¿cuándo te hace falta «\(m)» — y qué dices?", "escena corta: va de «\(m)». ¿qué palabra?"],
                ["va. ¿y en otra situación?", "ok. ¿y con amigos, informal?", "pillado. ¿y por la noche, en otro sitio?"],
                ["¿y cómo se dice eso en una palabra — «\(m)»?", "hace falta justo «\(m)». ¿qué palabra?"],
                close
            )
        }
    }

    // MARK: - FR

    private static func fr(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["ok, on s'arrête là.", "nickel. à demain.", "ça suffit pour aujourd'hui."]
        switch k {
        case .greeting:
            return (
                ["tu dis quoi, quand tu veux dire bonjour ?", "tu rentres chez des potes. premier mot ?", "le matin tu croises quelqu'un. tu dis quoi ?"],
                ["ok. et si c'est un pote que t'as pas vu ?", "ouais. et au vendeur ?"],
                ["comment tu salues, en un mot ?", "tu entres dans un café. tu dis quoi ?"],
                close
            )
        case .farewell:
            return (
                ["tu dis quoi quand tu pars ?", "tu rentres. dernier mot ?", "la conversation est finie. tu dis au revoir comment ?"],
                ["ok. et si tu pars longtemps ?", "ouais. et le soir, court ?"],
                ["comment tu dis au revoir, en un mot ?", "tu te lèves de table. tu dis quoi ?"],
                close
            )
        case .thanks:
            return (
                ["quelqu'un vient de t'aider. tu dis quoi ?", "on te tient la porte. quel mot ?", "tu dis quoi quand tu veux remercier ?"],
                ["ok. et si ça t'a vraiment sauvé ?", "ouais. et au barista ?"],
                ["un mot pour dire merci ?", "on te passe une serviette. tu dis quoi ?"],
                close
            )
        case .apology:
            return (
                ["tu marches sur un pied. tu dis quoi ?", "tu dis quoi quand tu veux t'excuser ?", "t'as cinq minutes de retard. premier mot ?"],
                ["ok. et si c'est un pote ?", "ouais. et dans la rue, vite ?"],
                ["comment tu t'excuses, court ?", "tu bouscules quelqu'un. tu dis quoi ?"],
                close
            )
        case .howAreYou:
            return (
                ["tu vois un pote. tu lui demandes comment ça va comment ?", "tu dis quoi à la place d'un « ça va » plat ?", "vous vous appelez. première question ?"],
                ["ok. et si ça fait longtemps ?", "ouais. et en speed ?"],
                ["comment tu demandes des nouvelles, court ?", "un pote écrit en premier. tu demandes quoi ?"],
                close
            )
        case .please:
            return (
                ["tu demandes le sel. mot poli ?", "t'ajoutes quoi quand tu demandes un truc ?", "au café tu veux encore de l'eau. tu demandes comment ?"],
                ["ok. et si c'est un inconnu ?", "ouais. et très court ?"],
                ["quel mot rend la demande polie ?", "tu demandes de se pousser. t'ajoutes quoi ?"],
                close
            )
        case .generic:
            return (
                ["tu dis quoi, quand tu veux dire « \(m) » ?", "journée normale : à quel moment t'as besoin de « \(m) » — et tu dis quoi ?", "mini scène : ça parle de « \(m) ». quel mot ?"],
                ["ok. et dans une autre situation ?", "ouais. et avec des potes, à l'aise ?", "vu. et le soir, ailleurs ?"],
                ["et ça se dit comment, pour « \(m) » ?", "il faut pile « \(m) ». quel mot ?"],
                close
            )
        }
    }

    // MARK: - DE

    private static func de(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["ok, reicht für heute.", "sitzt. bis morgen.", "gut. für heute Schluss."]
        switch k {
        case .greeting:
            return (
                ["was sagst du, wenn du jemanden begrüßen willst?", "du kommst zu Freunden. erstes wort?", "morgens triffst du wen. was sagst du?"],
                ["sitzt. und wenn's ein alter freund ist?", "ok. und zum verkäufer?"],
                ["wie begrüßt du in einem wort?", "du gehst ins café. was sagst du?"],
                close
            )
        case .farewell:
            return (
                ["was sagst du, wenn du gehst?", "du willst nach hause. letztes wort?", "gespräch vorbei — wie verabschiedest du dich?"],
                ["sitzt. und wenn du lange weg bist?", "ok. und abends, kurz?"],
                ["wie sagst du tschüss in einem wort?", "du stehst vom tisch auf. was sagst du?"],
                close
            )
        case .thanks:
            return (
                ["jemand hat dir geholfen. was sagst du?", "jemand hält dir die tür. welches wort?", "was sagst du, wenn du danken willst?"],
                ["sitzt. und wenn's dich echt gerettet hat?", "ok. und zum barista?"],
                ["ein wort zum danken?", "dir wird eine serviette gereicht. was sagst du?"],
                close
            )
        case .apology:
            return (
                ["du trittst wem auf den fuß. was sagst du?", "was sagst du, wenn du dich entschuldigen willst?", "fünf minuten zu spät — erstes wort?"],
                ["sitzt. und wenn's ein freund ist?", "ok. und auf der straße, schnell?"],
                ["wie entschuldigst du dich kurz?", "du rempelst wen an. was sagst du?"],
                close
            )
        case .howAreYou:
            return (
                ["du triffst einen freund. wie fragst du, wie's ihm geht?", "was sagst du statt einem steifen „wie geht's“?", "ihr telefoniert. erste frage?"],
                ["sitzt. und wenn ihr euch lange nicht saht?", "ok. und auf die schnelle?"],
                ["wie fragst du nach dem leben, kurz?", "ein freund schreibt zuerst. was fragst du?"],
                close
            )
        case .please:
            return (
                ["du willst das salz. höfliches wort?", "was hängt du an, wenn du um etwas bittest?", "im café willst du noch wasser. wie fragst du?"],
                ["sitzt. und wenn's ein fremder ist?", "ok. und ganz kurz?"],
                ["welches wort macht die bitte höflich?", "du bittest, Platz zu machen. was hängt du an?"],
                close
            )
        case .generic:
            return (
                ["was sagst du, wenn du „\(m)“ meinst?", "normaler tag: wann brauchst du „\(m)“ — und was sagst du dann?", "kurze szene: es geht um „\(m)“. welches wort?"],
                ["sitzt. und in einer anderen lage?", "ok. und mit freunden, locker?", "klar. und abends, woanders?"],
                ["und wie sagst du „\(m)“ in einem wort?", "es muss genau „\(m)“ sein. welches wort?"],
                close
            )
        }
    }

    // MARK: - IT / PT / KO / JA / ZH / EN

    private static func it(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["ok, per oggi basta.", "ci sei. a domani.", "bene. chiudiamo qui."]
        switch k {
        case .greeting:
            return (
                ["cosa dici quando vuoi salutare?", "entri dagli amici. prima parola?", "al mattino incontri qualcuno. cosa dici?"],
                ["ok. e se è un amico che non vedevi?", "va. e al commesso?"],
                ["come saluti in una parola?", "entri in un caffè. cosa dici?"],
                close
            )
        case .generic:
            return (
                ["cosa dici quando vuoi dire «\(m)»?", "giornata normale: quando ti serve «\(m)» — e cosa dici?", "scena breve: si tratta di «\(m)». quale parola?"],
                ["ok. e in un'altra situazione?", "va. e con gli amici, informale?"],
                ["e come si dice «\(m)» in una parola?", "serve proprio «\(m)». quale parola?"],
                close
            )
        default:
            return genericFallback(m, close, style: .it)
        }
    }

    private static func pt(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["ok, chega por hoje.", "está. até amanhã.", "bom. ficamos por aqui."]
        switch k {
        case .greeting:
            return (
                ["o que dizes quando queres cumprimentar?", "entras em casa dos amigos. primeira palavra?", "de manhã cruzas-te com alguém. o que dizes?"],
                ["está. e se é um amigo que não vias?", "ok. e ao empregado?"],
                ["como cumprimentas numa palavra?", "entras num café. o que dizes?"],
                close
            )
        case .generic:
            return (
                ["o que dizes quando queres dizer «\(m)»?", "um dia normal: quando precisas de «\(m)» — e o que dizes?", "cena curta: é sobre «\(m)». que palavra?"],
                ["está. e noutra situação?", "ok. e com amigos, informal?"],
                ["e como se diz «\(m)» numa palavra?", "precisas mesmo de «\(m)». que palavra?"],
                close
            )
        default:
            return genericFallback(m, close, style: .pt)
        }
    }

    private static func ko(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["오늘은 여기까지.", "알겠어. 내일 이어가자.", "좋아. 오늘은 그만."]
        switch k {
        case .greeting:
            return (
                ["인사하고 싶을 때 뭐라고 말해?", "친구 집에 들어가. 첫 마디?", "아침에 누구 만났을 때 뭐 해?"],
                ["좋아. 오래 못 본 친구면?", "오케이. 가게 직원한테는?"],
                ["한 마디로 인사하면?", "카페 들어갈 때 뭐라고 해?"],
                close
            )
        case .generic:
            return (
                ["«\(m)» 하고 싶을 때 뭐라고 말해?", "평범한 하루. «\(m)»가 필요한 순간엔 뭐라고 해?", "짧은 장면: «\(m)» 이야기야. 어떤 단어?"],
                ["좋아. 다른 상황에선?", "오케이. 친구들이랑, 편하게?"],
                ["«\(m)» 한 마디면?", "딱 «\(m)»가 필요해. 무슨 단어?"],
                close
            )
        default:
            return genericFallback(m, close, style: .ko)
        }
    }

    private static func ja(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["今日はここまで。", "OK、また明日。", "いいね。今日はおしまい。"]
        switch k {
        case .greeting:
            return (
                ["挨拶したいとき、なんて言う？", "友達の家に入る。最初の一言は？", "朝、誰かと会ったら何て言う？"],
                ["いいね。久しぶりな友達なら？", "OK。店員さんには？"],
                ["一言で挨拶すると？", "カフェに入るとき、何て言う？"],
                close
            )
        case .generic:
            return (
                ["「\(m)」って言いたいとき、なんて言う？", "いつもの一日。「\(m)」が必要な瞬間、何て言う？", "短い場面：「\(m)」の話。どの単語？"],
                ["いいね。別の場面なら？", "OK。友達と、くだけて？"],
                ["「\(m)」を一言で言うと？", "まさに「\(m)」。どの単語？"],
                close
            )
        default:
            return genericFallback(m, close, style: .ja)
        }
    }

    private static func zh(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["今天就到这。", "行，明天见。", "好。今天先这样。"]
        switch k {
        case .greeting:
            return (
                ["想打招呼的时候你说什么？", "进朋友家，第一句？", "早上碰到人，你会说什么？"],
                ["对。要是很久没见的朋友呢？", "行。对店员呢？"],
                ["用一个词怎么打招呼？", "进咖啡馆你会说什么？"],
                close
            )
        case .generic:
            return (
                ["想表达「\(m)」的时候，你会说什么？", "平常的一天，什么时候需要「\(m)」——那时你说什么？", "小场景：跟「\(m)」有关。哪个词？"],
                ["对。换个场合呢？", "行。跟朋友、随便一点呢？"],
                ["「\(m)」用一个词怎么说？", "就要「\(m)」。哪个词？"],
                close
            )
        default:
            return genericFallback(m, close, style: .zh)
        }
    }

    private static func en(_ m: String, _ k: SceneKind) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        let close = ["ok, that's enough for today.", "nice. see you tomorrow.", "that's the scene. we're good."]
        switch k {
        case .greeting:
            return (
                ["what do you say when you want to say hi?", "you walk into your friends' place. first word?", "you bump into someone in the morning. what do you say?"],
                ["that works. and if it's a friend you haven't seen?", "ok. and to the person at the shop?"],
                ["how do you say hi in one word?", "you walk into a café. what do you say?"],
                close
            )
        case .farewell:
            return (
                ["what do you say when you're leaving?", "you're heading home. last word?", "the chat's over — how do you say bye?"],
                ["that works. and if you're gone a long time?", "ok. and at night, short?"],
                ["how do you say bye in one word?", "you get up from the table. what do you say?"],
                close
            )
        case .thanks:
            return (
                ["someone just helped you. what do you say?", "they hold the door. which word?", "what do you say when you want to thank someone?"],
                ["that works. and if they really saved you?", "ok. and to the barista?"],
                ["one word for thanks?", "they pass you a napkin. what do you say?"],
                close
            )
        case .apology:
            return (
                ["you step on someone's foot. what do you say?", "what do you say when you want to apologize?", "you're five minutes late. first word?"],
                ["that works. and if it's a friend?", "ok. and on the street, fast?"],
                ["how do you say sorry, short?", "you bump into someone. what do you say?"],
                close
            )
        case .howAreYou:
            return (
                ["you see a friend. how do you ask how they're doing?", "what do you say instead of a stiff “how are you”?", "you're on a call. first question?"],
                ["that works. and if it's been ages?", "ok. and in a rush?"],
                ["how do you ask how they are, short?", "a friend texts first. what do you ask?"],
                close
            )
        case .please:
            return (
                ["you want the salt. polite word?", "what do you add when you ask for something?", "at a café you want more water. how do you ask?"],
                ["that works. and if it's a stranger?", "ok. and super short?"],
                ["which word makes the ask polite?", "you ask someone to move. what do you add?"],
                close
            )
        case .generic:
            return (
                ["what do you say when you mean “\(m)”?", "normal day: when do you need “\(m)” — and what do you say then?", "tiny scene: it's about “\(m)”. which word?"],
                ["that works. and in another situation?", "ok. and with friends, casual?", "got it. and at night, somewhere else?"],
                ["and the one word for “\(m)”?", "you need exactly “\(m)”. which word?"],
                close
            )
        }
    }

    private enum FallbackStyle { case it, pt, ko, ja, zh }

    private static func genericFallback(_ m: String, _ close: [String], style: FallbackStyle) -> (open: [String], follow: [String], nudge: [String], close: [String]) {
        switch style {
        case .it:
            return (
                ["cosa dici quando vuoi dire «\(m)»?"],
                ["ok. e in un'altra situazione?"],
                ["e come si dice «\(m)» in una parola?"],
                close
            )
        case .pt:
            return (
                ["o que dizes quando queres dizer «\(m)»?"],
                ["está. e noutra situação?"],
                ["e como se diz «\(m)» numa palavra?"],
                close
            )
        case .ko:
            return (
                ["«\(m)» 하고 싶을 때 뭐라고 말해?"],
                ["좋아. 다른 상황에선?"],
                ["«\(m)» 한 마디면?"],
                close
            )
        case .ja:
            return (
                ["「\(m)」って言いたいとき、なんて言う？"],
                ["いいね。別の場面なら？"],
                ["「\(m)」を一言で言うと？"],
                close
            )
        case .zh:
            return (
                ["想表达「\(m)」的时候，你会说什么？"],
                ["对。换个场合呢？"],
                ["「\(m)」用一个词怎么说？"],
                close
            )
        }
    }
}
