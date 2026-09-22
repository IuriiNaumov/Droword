import Foundation

enum DuoChaosCopy {

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

    private static func line(_ tables: [[String: String]]) -> String {
        guard !tables.isEmpty else { return "" }
        let i = Int.random(in: 0..<tables.count)
        return t(tables[i])
    }

    private static var dayIndex: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
    }

    static func correct() -> String {
        line([
        [
            "en": "Nice one",
            "ru": "Молодец",
            "de": "Gut gemacht",
            "es": "Muy bien",
            "fr": "Bravo",
            "ja": "すごい",
            "ko": "잘했어",
            "ar": "برابو",
            "it": "Bravo",
            "zh-Hans": "真棒",
            "zh-Hant": "真棒",
            "pt-PT": "Muito bem"
        ],
        [
            "en": "Wow",
            "ru": "Воу",
            "de": "Wow",
            "es": "Wow",
            "fr": "Wow",
            "ja": "わお",
            "ko": "와우",
            "ar": "واو",
            "it": "Wow",
            "zh-Hans": "哇",
            "zh-Hant": "哇",
            "pt-PT": "Wow"
        ],
        [
            "en": "Yesss",
            "ru": "Вернооооо",
            "de": "Richtiggg",
            "es": "Correctooo",
            "fr": "Exacteee",
            "ja": "正解ーー",
            "ko": "정다아압",
            "ar": "صححح",
            "it": "Giustooo",
            "zh-Hans": "答对啦",
            "zh-Hant": "答對啦",
            "pt-PT": "Certooo"
        ],
        [
            "en": "Spot on",
            "ru": "Точно",
            "de": "Genau",
            "es": "Exacto",
            "fr": "Pile poil",
            "ja": "その通り",
            "ko": "딱 맞아",
            "ar": "تمام",
            "it": "Esatto",
            "zh-Hans": "没错",
            "zh-Hant": "沒錯",
            "pt-PT": "Exato"
        ],
        [
            "en": "You got it",
            "ru": "Красава",
            "de": "Super",
            "es": "Genial",
            "fr": "Nickel",
            "ja": "いいね",
            "ko": "멋져",
            "ar": "ممتاز",
            "it": "Ottimo",
            "zh-Hans": "漂亮",
            "zh-Hant": "漂亮",
            "pt-PT": "Boa"
        ],
        ])
    }

    static func almost() -> String {
        line([
        [
            "en": "Almost",
            "ru": "Почти угадал",
            "de": "Fast geschafft",
            "es": "Casi lo tienes",
            "fr": "Presque",
            "ja": "おしい",
            "ko": "거의 맞았어",
            "ar": "قريب",
            "it": "Quasi",
            "zh-Hans": "差一点",
            "zh-Hant": "差一點",
            "pt-PT": "Quase"
        ],
        [
            "en": "Try again",
            "ru": "Попробуй еще раз",
            "de": "Noch einmal",
            "es": "Inténtalo otra vez",
            "fr": "Réessaie",
            "ja": "もう一回",
            "ko": "다시 해보자",
            "ar": "جرّب مرة تانية",
            "it": "Riprova",
            "zh-Hans": "再试一次",
            "zh-Hant": "再試一次",
            "pt-PT": "Tenta outra vez"
        ],
        [
            "en": "So close",
            "ru": "Близко",
            "de": "Ganz nah",
            "es": "Muy cerca",
            "fr": "Si près",
            "ja": "あと一歩",
            "ko": "아깝다",
            "ar": "قرّبت",
            "it": "Ci sei quasi",
            "zh-Hans": "好近了",
            "zh-Hant": "好近了",
            "pt-PT": "Tão perto"
        ],
        [
            "en": "One more go",
            "ru": "Ещё разок",
            "de": "Noch ein Versuch",
            "es": "Una más",
            "fr": "Encore un essai",
            "ja": "もう一回いける",
            "ko": "한 번 더",
            "ar": "مرة كمان",
            "it": "Ancora una",
            "zh-Hans": "再来一次",
            "zh-Hant": "再來一次",
            "pt-PT": "Mais uma"
        ],
        ])
    }

    static func wrongReveal(_ answer: String) -> String {
        _ = answer
        return line([
        [
            "en": "Not quite",
            "ru": "Не совсем",
            "de": "Nicht ganz",
            "es": "No del todo",
            "fr": "Pas tout à fait",
            "ja": "ちがうね",
            "ko": "아니야",
            "ar": "مو هيك",
            "it": "Non proprio",
            "zh-Hans": "不太对",
            "zh-Hant": "不太對",
            "pt-PT": "Não bem"
        ],
        [
            "en": "Try again",
            "ru": "Попробуй еще раз",
            "de": "Versuch's nochmal",
            "es": "Prueba otra vez",
            "fr": "Essaie encore",
            "ja": "もう一度",
            "ko": "다시 해봐",
            "ar": "حاول مرة تانية",
            "it": "Prova ancora",
            "zh-Hans": "再试一次",
            "zh-Hant": "再試一次",
            "pt-PT": "Tenta de novo"
        ],
        [
            "en": "Almost had it",
            "ru": "Почти угадал",
            "de": "Fast richtig",
            "es": "Casi aciertas",
            "fr": "Tu y étais presque",
            "ja": "おしい",
            "ko": "거의 맞았어",
            "ar": "كنت قريب",
            "it": "C'eri quasi",
            "zh-Hans": "差一点就对了",
            "zh-Hant": "差一點就對了",
            "pt-PT": "Quase tinhas"
        ],
        [
            "en": "Next one",
            "ru": "Дальше будет",
            "de": "Nächste klappt",
            "es": "La siguiente",
            "fr": "La prochaine",
            "ja": "次いける",
            "ko": "다음은 된다",
            "ar": "الي بعدها",
            "it": "La prossima",
            "zh-Hans": "下一题",
            "zh-Hant": "下一題",
            "pt-PT": "A seguir"
        ],
        [
            "en": "No stress",
            "ru": "Без стресса",
            "de": "Kein Stress",
            "es": "Sin estrés",
            "fr": "Tranquille",
            "ja": "大丈夫",
            "ko": "괜찮아",
            "ar": "عادي",
            "it": "Niente stress",
            "zh-Hans": "没事的",
            "zh-Hant": "沒事的",
            "pt-PT": "Sem stress"
        ],
        ])
    }

    static func streak(_ n: Int) -> String {
        let table: [String: String]
        switch n {

        case 3:
            table = [
            "en": "3 in a row — nice start",
            "ru": "3 подряд — хороший старт",
            "de": "3 in Folge — starker Start",
            "es": "3 seguidas — buen comienzo",
            "fr": "3 d’affilée — beau départ",
            "ja": "3連続 — いいスタート",
            "ko": "3연속 — 좋은 시작",
            "ar": "٣ متتالية — بداية حلوة",
            "it": "3 di fila — bel inizio",
            "zh-Hans": "连对 3 个 — 开局不错",
            "zh-Hant": "連對 3 個 — 開局不錯",
            "pt-PT": "3 seguidas — bom começo"
            ]
        case 5:
            table = [
            "en": "5 streak — you're warming up",
            "ru": "5 стрик — разогрев пошёл",
            "de": "5er-Streak — du kommst in Fahrt",
            "es": "Racha de 5 — vas calentando",
            "fr": "Série de 5 — tu chauffes",
            "ja": "5連続 — 調子出てきた",
            "ko": "5연속 — 몸이 풀리는 중",
            "ar": "سلسلة ٥ — عم تسخّن",
            "it": "Streak da 5 — ti stai scaldando",
            "zh-Hans": "连击 5 — 状态上来了",
            "zh-Hant": "連擊 5 — 狀態上來了",
            "pt-PT": "Sequência de 5 — estás a aquecer"
            ]
        case 7:
            table = [
            "en": "7 streak — strong",
            "ru": "7 стрик — мощно",
            "de": "7er-Streak — stark",
            "es": "Racha de 7 — fuerte",
            "fr": "Série de 7 — costaud",
            "ja": "7連続 — 強い",
            "ko": "7연속 — 강하다",
            "ar": "سلسلة ٧ — قوي",
            "it": "Streak da 7 — forte",
            "zh-Hans": "连击 7 — 很强",
            "zh-Hant": "連擊 7 — 很強",
            "pt-PT": "Sequência de 7 — forte"
            ]
        case 10:
            table = [
            "en": "Perfect 10",
            "ru": "Идеальные 10",
            "de": "Perfekte 10",
            "es": "10 perfectos",
            "fr": "10 parfait",
            "ja": "パーフェクト10",
            "ko": "퍼펙트 10",
            "ar": "١٠ كاملة",
            "it": "10 perfetto",
            "zh-Hans": "完美的 10",
            "zh-Hant": "完美的 10",
            "pt-PT": "10 perfeito"
            ]
        default:
            table = [

            "en": "{N} in a row",
            "ru": "{N} подряд",
            "de": "{N} in Folge",
            "es": "{N} seguidas",
            "fr": "{N} d’affilée",
            "ja": "{N}連続",
            "ko": "{N}연속",
            "ar": "{N} متتالية",
            "it": "{N} di fila",
            "zh-Hans": "连对 {N} 个",
            "zh-Hant": "連對 {N} 個",
            "pt-PT": "{N} seguidas"
            ]
        }
        return t(table).replacingOccurrences(of: "{N}", with: "\(n)")
    }

    static func comboOnFire() -> String {
        t([
            "en": "ON FIRE",
            "ru": "В УДАРЕ",
            "de": "LÄUFT!",
            "es": "EN RACHA",
            "fr": "ÇA CHAUFFE",
            "ja": "絶好調",
            "ko": "미쳤다",
            "ar": "نار!",
            "it": "IN FORMA",
            "zh-Hans": "超神",
            "zh-Hant": "超神",
            "pt-PT": "EM FORMA"
        ])
    }

    static func quizDone(percentage: Int) -> (title: String, subtitle: String) {
        let pair: ([String: String], [String: String])
        switch percentage {
        case 100:

            pair = ([
                "en": "Perfect session",
                "ru": "Идеальная сессия",
                "de": "Perfekte Session",
                "es": "Sesión perfecta",
                "fr": "Session parfaite",
                "ja": "完璧なセッション",
                "ko": "완벽한 세션",
                "ar": "جلسة مثالية",
                "it": "Sessione perfetta",
                "zh-Hans": "完美的一局",
                "zh-Hant": "完美的一局",
                "pt-PT": "Sessão perfeita"
            ], [
                "en": "100%. That one felt good.",
                "ru": "100%. Вот это было приятно.",
                "de": "100 %. Das hat sich gut angefühlt.",
                "es": "100%. Eso se sintió bien.",
                "fr": "100 %. Ça faisait du bien.",
                "ja": "100%。気持ちよかった。",
                "ko": "100%. 기분 좋았다.",
                "ar": "١٠٠٪. حسّيت فيها.",
                "it": "100%. Si è sentita bene.",
                "zh-Hans": "100%。这一把很爽。",
                "zh-Hant": "100%。這一把很爽。",
                "pt-PT": "100%. Sentiu-se bem."
            ])
        case 90..<100:
            pair = ([
                "en": "Really strong",
                "ru": "Очень сильно",
                "de": "Wirklich stark",
                "es": "Muy fuerte",
                "fr": "Vraiment fort",
                "ja": "かなり強い",
                "ko": "정말 강하다",
                "ar": "قوي جدًا",
                "it": "Davvero forte",
                "zh-Hans": "非常强",
                "zh-Hant": "非常強",
                "pt-PT": "Muito forte"
            ], [
                "en": "Almost perfect — come back for the last bits.",
                "ru": "Почти идеал — забери остаток в следующий раз.",
                "de": "Fast perfekt — hol den Rest später.",
                "es": "Casi perfecto — vuelve por lo que falta.",
                "fr": "Presque parfait — reviens pour le reste.",
                "ja": "ほぼ完璧 — 残りは次回で。",
                "ko": "거의 완벽 — 나머지는 다음에.",
                "ar": "تقريبًا مثالي — كمّل الباقي بعدين.",
                "it": "Quasi perfetto — torna per il resto.",
                "zh-Hans": "几乎完美 — 剩下的下次再拿。",
                "zh-Hant": "幾乎完美 — 剩下的下次再拿。",
                "pt-PT": "Quase perfeito — volta para o resto."
            ])
        case 70..<90:
            pair = ([
                "en": "Solid work",
                "ru": "Крепко",
                "de": "Solide Arbeit",
                "es": "Buen trabajo",
                "fr": "Du bon boulot",
                "ja": "しっかりできた",
                "ko": "탄탄하다",
                "ar": "شغل متين",
                "it": "Bel lavoro",
                "zh-Hans": "扎实",
                "zh-Hant": "紮實",
                "pt-PT": "Trabalho sólido"
            ], [
                "en": "Good session. Tomorrow builds on this.",
                "ru": "Хорошая сессия. Завтра будет ещё лучше.",
                "de": "Gute Session. Morgen baut darauf auf.",
                "es": "Buena sesión. Mañana construye sobre esto.",
                "fr": "Bonne session. Demain part de là.",
                "ja": "いいセッション。明日につなげよう。",
                "ko": "좋은 세션. 내일이 이어질 거야.",
                "ar": "جلسة حلوة. بكرا بتكمل عليها.",
                "it": "Bella sessione. Domani parti da qui.",
                "zh-Hans": "不错的一局。明天接着练。",
                "zh-Hant": "不錯的一局。明天接著練。",
                "pt-PT": "Boa sessão. Amanhã constrói em cima."
            ])
        case 50..<70:
            pair = ([
                "en": "Getting there",
                "ru": "Идёт",
                "de": "Du kommst hin",
                "es": "Vas llegando",
                "fr": "Ça avance",
                "ja": "近づいてる",
                "ko": "점점 된다",
                "ar": "عم توصل",
                "it": "Ci stai arrivando",
                "zh-Hans": "有进步",
                "zh-Hant": "有進步",
                "pt-PT": "Estás a chegar lá"
            ], [
                "en": "Not bad — another round will lock it in.",
                "ru": "Неплохо — ещё круг закрепит.",
                "de": "Nicht schlecht — noch eine Runde festigt’s.",
                "es": "Nada mal — otra ronda lo fija.",
                "fr": "Pas mal — un autre tour va le figer.",
                "ja": "悪くない — もう一周で定着。",
                "ko": "나쁘지 않아 — 한 판 더면 굳혀져.",
                "ar": "مو سيء — لفة ثانية بتثبّتها.",
                "it": "Non male — un altro giro lo fissa.",
                "zh-Hans": "不错 — 再来一轮就稳了。",
                "zh-Hant": "不錯 — 再來一輪就穩了。",
                "pt-PT": "Nada mau — outra ronda fixe."
            ])
        default:
            pair = ([
                "en": "Showing up counts",
                "ru": "Главное — пришёл",
                "de": "Erscheinen zählt",
                "es": "Aparecer cuenta",
                "fr": "Être là compte",
                "ja": "来たことが大事",
                "ko": "나온 게 중요해",
                "ar": "مجرد إنك جيت مهم",
                "it": "Esserci conta",
                "zh-Hans": "来了就很重要",
                "zh-Hant": "來了就很重要",
                "pt-PT": "Aparecer conta"
            ], [
                "en": "Rough day. Practice again when you're ready.",
                "ru": "День так себе. Зайди ещё, когда будешь готов.",
                "de": "Rauer Tag. Übe weiter, wenn du bereit bist.",
                "es": "Día duro. Vuelve cuando estés listo.",
                "fr": "Journée dure. Reviens quand tu es prêt.",
                "ja": "きつい日。準備できたらまた。",
                "ko": "힘든 날. 준비되면 다시 와.",
                "ar": "يوم صعب. ارجع لما تكون جاهز.",
                "it": "Giornata dura. Torna quando sei pronto.",
                "zh-Hans": "今天有点难。准备好再来。",
                "zh-Hant": "今天有點難。準備好再來。",
                "pt-PT": "Dia difícil. Volta quando estiveres pronto."
            ])
        }
        return (t(pair.0), t(pair.1))
    }

    static func homeEmpty(hasWords: Bool) -> (cta: String, subtitle: String) {
        if hasWords {
            return (

                t([
                "en": "Add a word",
                "ru": "Добавить слово",
                "de": "Wort hinzufügen",
                "es": "Añadir palabra",
                "fr": "Ajouter un mot",
                "ja": "単語を追加",
                "ko": "단어 추가",
                "ar": "أضف كلمة",
                "it": "Aggiungi parola",
                "zh-Hans": "添加单词",
                "zh-Hant": "新增單字",
                "pt-PT": "Adicionar palavra"
                ]),
                t([
                "en": "Your recent words show up here.",
                "ru": "Недавние слова появятся здесь.",
                "de": "Deine letzten Wörter erscheinen hier.",
                "es": "Tus palabras recientes aparecen aquí.",
                "fr": "Tes mots récents s’affichent ici.",
                "ja": "最近の単語がここに出ます。",
                "ko": "최근 단어가 여기에 보여요.",
                "ar": "كلماتك الأخيرة بتظهر هون.",
                "it": "Le tue parole recenti compaiono qui.",
                "zh-Hans": "最近的单词会出现在这里。",
                "zh-Hant": "最近的單字會出現在這裡。",
                "pt-PT": "As tuas palavras recentes aparecem aqui."
                ])
            )
        }
        return (
            t([
                "en": "Add your first word",
                "ru": "Добавь первое слово",
                "de": "Füge dein erstes Wort hinzu",
                "es": "Añade tu primera palabra",
                "fr": "Ajoute ton premier mot",
                "ja": "最初の単語を追加",
                "ko": "첫 단어를 추가해",
                "ar": "أضف أول كلمة",
                "it": "Aggiungi la tua prima parola",
                "zh-Hans": "添加第一个单词",
                "zh-Hant": "新增第一個單字",
                "pt-PT": "Adiciona a tua primeira palavra"
            ]),
            t([
                "en": "One word is enough to start.",
                "ru": "Одного слова хватит, чтобы начать.",
                "de": "Ein Wort reicht zum Start.",
                "es": "Una palabra basta para empezar.",
                "fr": "Un mot suffit pour commencer.",
                "ja": "始めるには1語で十分。",
                "ko": "시작하려면 단어 하나면 충분해.",
                "ar": "كلمة وحدة تكفي عشان تبدأ.",
                "it": "Una parola basta per iniziare.",
                "zh-Hans": "一个词就够开始了。",
                "zh-Hant": "一個詞就夠開始了。",
                "pt-PT": "Uma palavra chega para começar."
            ])
        )
    }

    static func dictionaryGarden() -> (title: String, subtitle: String) {
        (

            t([
            "en": "No words yet",
            "ru": "Слов пока нет",
            "de": "Noch keine Wörter",
            "es": "Aún no hay palabras",
            "fr": "Pas encore de mots",
            "ja": "まだ単語がない",
            "ko": "아직 단어 없음",
            "ar": "ما في كلمات بعد",
            "it": "Ancora nessuna parola",
            "zh-Hans": "还没有单词",
            "zh-Hant": "還沒有單字",
            "pt-PT": "Ainda sem palavras"
            ]),
            t([
            "en": "It's so empty in here… we're crying.",
            "ru": "Тут так пусто… мы плачем.",
            "de": "So leer hier… wir heulen.",
            "es": "Está tan vacío… estamos llorando.",
            "fr": "C’est tellement vide… on pleure.",
            "ja": "空っぽすぎて…泣いてる。",
            "ko": "너무 비어서… 울고 있어.",
            "ar": "فاضي أوي… عم نبكي.",
            "it": "È così vuoto… stiamo piangendo.",
            "zh-Hans": "空得要命…我们在哭。",
            "zh-Hant": "空得要命…我們在哭。",
            "pt-PT": "Está tão vazio… estamos a chorar."
            ])
        )
    }

    static func dictionaryRefresh() -> String {
        line([
            [
                "en": "Checking the garden…",
                "ru": "Проверяем сад…",
                "de": "Garten wird gecheckt…",
                "es": "Revisando el jardín…",
                "fr": "On checke le jardin…",
                "ja": "ガーデン確認中…",
                "ko": "정원 확인 중…",
                "ar": "عم نفحص الحديقة…",
                "it": "Controllo del giardino…",
                "zh-Hans": "看看词园…",
                "zh-Hant": "看看詞園…",
                "pt-PT": "A ver o jardim…"
            ],
            [
                "en": "Shaking the dictionary…",
                "ru": "Трясём словарь…",
                "de": "Wörterbuch schütteln…",
                "es": "Sacudiendo el diccionario…",
                "fr": "On secoue le dico…",
                "ja": "辞書をシェイク中…",
                "ko": "사전 흔드는 중…",
                "ar": "عم نهز القاموس…",
                "it": "Scuoto il dizionario…",
                "zh-Hans": "甩甩词典…",
                "zh-Hant": "甩甩詞典…",
                "pt-PT": "A abanar o dicionário…"
            ],
            [
                "en": "Any new sprouts?",
                "ru": "Есть новые ростки?",
                "de": "Neue Sprösslinge?",
                "es": "¿Brotes nuevos?",
                "fr": "Des nouvelles pousses ?",
                "ja": "新しい芽ある？",
                "ko": "새싹 있나?",
                "ar": "في براعم جديدة؟",
                "it": "Nuovi germogli?",
                "zh-Hans": "有新芽吗？",
                "zh-Hant": "有新芽嗎？",
                "pt-PT": "Há rebentos novos?"
            ],
            [
                "en": "Fresh sync, coming up…",
                "ru": "Свежий синк на подходе…",
                "de": "Frischer Sync kommt…",
                "es": "Sync fresquito…",
                "fr": "Sync fraîche en route…",
                "ja": "フレッシュ同期中…",
                "ko": "새 동기화 중…",
                "ar": "مزامنة فريش…",
                "it": "Sync fresco in arrivo…",
                "zh-Hans": "新鲜同步中…",
                "zh-Hant": "新鮮同步中…",
                "pt-PT": "Sync fresco a caminho…"
            ]
        ])
    }

    static func dictionaryEmpty(tag: String?) -> (title: String, subtitle: String) {
        if let tag, !tag.isEmpty {
            return (
                t([
                "en": "Nothing in «{TAG}» yet",
                "ru": "В «{TAG}» пока пусто",
                "de": "Noch nichts in „{TAG}“",
                "es": "Nada en «{TAG}» aún",
                "fr": "Rien dans « {TAG} » pour l’instant",
                "ja": "「{TAG}」にはまだない",
                "ko": "«{TAG}»에 아직 없음",
                "ar": "ما في شي بـ «{TAG}» بعد",
                "it": "Niente in «{TAG}» ancora",
                "zh-Hans": "「{TAG}」里还没有",
                "zh-Hant": "「{TAG}」裡還沒有",
                "pt-PT": "Nada em «{TAG}» ainda"
            ]).replacingOccurrences(of: "{TAG}", with: BuiltInTag.displayName(tag)),
                t([
                "en": "Tag some words or pick another filter.",
                "ru": "Навесь тег на слова или смени фильтр.",
                "de": "Verschlagworte Wörter oder wähle einen anderen Filter.",
                "es": "Etiqueta palabras o elige otro filtro.",
                "fr": "Tague des mots ou choisis un autre filtre.",
                "ja": "単語にタグを付けるか、別のフィルターを選んで。",
                "ko": "단어에 태그를 달거나 다른 필터를 골라.",
                "ar": "حط تاج على كلمات أو اختار فلتر ثاني.",
                "it": "Metti un tag o scegli un altro filtro.",
                "zh-Hans": "给单词加标签，或换个筛选。",
                "zh-Hant": "幫單字加標籤，或換個篩選。",
                "pt-PT": "Etiqueta palavras ou escolhe outro filtro."
            ])
            )
        }
        return (
            t([
            "en": "No matches",
            "ru": "Ничего не нашлось",
            "de": "Keine Treffer",
            "es": "Sin coincidencias",
            "fr": "Aucun résultat",
            "ja": "一致なし",
            "ko": "검색 결과 없음",
            "ar": "ما في نتائج",
            "it": "Nessun risultato",
            "zh-Hans": "没有匹配",
            "zh-Hant": "沒有符合結果",
            "pt-PT": "Sem resultados"
        ]),
            t([
            "en": "Try another search or clear the filter.",
            "ru": "Другой запрос или сними фильтр.",
            "de": "Andere Suche oder Filter löschen.",
            "es": "Prueba otra búsqueda o quita el filtro.",
            "fr": "Essaie une autre recherche ou enlève le filtre.",
            "ja": "別の検索にするか、フィルターを外して。",
            "ko": "다른 검색을 하거나 필터를 지워.",
            "ar": "جرّب بحث ثاني أو شيل الفلتر.",
            "it": "Prova un’altra ricerca o togli il filtro.",
            "zh-Hans": "换个搜索或清除筛选。",
            "zh-Hant": "換個搜尋或清除篩選。",
            "pt-PT": "Tenta outra pesquisa ou limpa o filtro."
        ])
        )
    }

    static func practiceEmpty() -> (title: String, subtitle: String, tip: String) {
        (
            t([
            "en": "Need a few more words",
            "ru": "Нужно чуть больше слов",
            "de": "Noch ein paar Wörter nötig",
            "es": "Necesitas más palabras",
            "fr": "Il faut encore quelques mots",
            "ja": "もう少し単語が必要",
            "ko": "단어가 조금 더 필요해",
            "ar": "محتاجين كم كلمة زيادة",
            "it": "Servono altre parole",
            "zh-Hans": "还需要多几个词",
            "zh-Hant": "還需要多幾個詞",
            "pt-PT": "É preciso mais algumas palavras"
        ]),
            t([
            "en": "Add at least 4 words with translations to practice.",
            "ru": "Добавь минимум 4 слова с переводами.",
            "de": "Füge mindestens 4 Wörter mit Übersetzung hinzu.",
            "es": "Añade al menos 4 palabras con traducción.",
            "fr": "Ajoute au moins 4 mots avec traduction.",
            "ja": "翻訳付きの単語を4語以上追加して。",
            "ko": "번역이 있는 단어를 최소 4개 추가해.",
            "ar": "أضف ٤ كلمات مع ترجمة على الأقل.",
            "it": "Aggiungi almeno 4 parole con traduzione.",
            "zh-Hans": "至少添加 4 个带翻译的单词。",
            "zh-Hant": "至少新增 4 個有翻譯的單字。",
            "pt-PT": "Adiciona pelo menos 4 palavras com tradução."
        ]),
            t([
            "en": "Tip: grab words from chats, songs, or shows.",
            "ru": "Совет: бери слова из чатов, песен или сериалов.",
            "de": "Tipp: nimm Wörter aus Chats, Songs oder Serien.",
            "es": "Consejo: saca palabras de chats, canciones o series.",
            "fr": "Astuce : prends des mots dans les chats, chansons ou séries.",
            "ja": "ヒント：チャット・曲・ドラマから拾って。",
            "ko": "팁: 채팅, 노래, 드라마에서 단어를 모아.",
            "ar": "نصيحة: خذ كلمات من الشات أو الأغاني أو المسلسلات.",
            "it": "Tip: prendi parole da chat, canzoni o serie.",
            "zh-Hans": "提示：从聊天、歌曲或剧里收集单词。",
            "zh-Hant": "提示：從聊天、歌曲或劇裡收集單字。",
            "pt-PT": "Dica: apanha palavras de chats, músicas ou séries."
        ])
        )
    }

    static func reviewCaughtUp(count: Int) -> (title: String, subtitle: String) {
        (
            t([
            "en": "You're all caught up",
            "ru": "Всё разобрано",
            "de": "Alles erledigt",
            "es": "Estás al día",
            "fr": "Tu es à jour",
            "ja": "全部終わった",
            "ko": "전부 끝",
            "ar": "خلصت كل شي",
            "it": "Sei in pari",
            "zh-Hans": "都复习完了",
            "zh-Hant": "都複習完了",
            "pt-PT": "Estás em dia"
        ]),
            t([
            "en": "You reviewed {COUNT} words. New ones appear when it's time.",
            "ru": "Ты разобрал {COUNT} слов. Новые появятся, когда придёт время.",
            "de": "Du hast {COUNT} Wörter wiederholt. Neue kommen, wenn’s soweit ist.",
            "es": "Repasaste {COUNT} palabras. Las nuevas aparecen a su tiempo.",
            "fr": "Tu as révisé {COUNT} mots. Les nouveaux arrivent au bon moment.",
            "ja": "{COUNT}語レビューしたよ。次はタイミングで来る。",
            "ko": "{COUNT}개 복습했어. 새 건 때가 되면 나와.",
            "ar": "راجعت {COUNT} كلمة. الجداد بيجوا لما يحين الوقت.",
            "it": "Hai ripassato {COUNT} parole. Le nuove arrivano al momento giusto.",
            "zh-Hans": "你复习了 {COUNT} 个词。新的会在合适的时候出现。",
            "zh-Hant": "你複習了 {COUNT} 個詞。新的會在合適的時候出現。",
            "pt-PT": "Reviste {COUNT} palavras. As novas aparecem na altura certa."
        ]).replacingOccurrences(of: "{COUNT}", with: "\(count)")
        )
    }

    static func learnDone(count: Int) -> (title: String, subtitle: String) {
        (
            t([
            "en": "Nice work",
            "ru": "Отлично",
            "de": "Gut gemacht",
            "es": "Buen trabajo",
            "fr": "Beau travail",
            "ja": "よくできた",
            "ko": "잘했어",
            "ar": "شغل حلو",
            "it": "Bel lavoro",
            "zh-Hans": "干得漂亮",
            "zh-Hant": "做得漂亮",
            "pt-PT": "Bom trabalho"
        ]),
            t([
            "en": "{COUNT} new words are in your review rotation.",
            "ru": "{COUNT} новых слов теперь в ротации ревью.",
            "de": "{COUNT} neue Wörter sind in deiner Review-Rotation.",
            "es": "{COUNT} palabras nuevas están en tu rotación de repaso.",
            "fr": "{COUNT} nouveaux mots sont dans ta rotation de révision.",
            "ja": "新しい{COUNT}語が復習ローテに入った。",
            "ko": "새 단어 {COUNT}개가 복습 로테이션에 들어갔어.",
            "ar": "{COUNT} كلمات جديدة بدورة المراجعة.",
            "it": "{COUNT} nuove parole sono nella rotazione di ripasso.",
            "zh-Hans": "{COUNT} 个新词已进入复习轮换。",
            "zh-Hant": "{COUNT} 個新詞已進入複習輪替。",
            "pt-PT": "{COUNT} palavras novas estão na rotação de revisão."
        ]).replacingOccurrences(of: "{COUNT}", with: "\(count)")
        )
    }

    static func quickSessionTitle() -> String {
        let tables: [[String: String]] = [

            [
                "en": "2-min session",
                "ru": "2-мин сессия",
                "de": "2-Min-Session",
                "es": "Sesión de 2 min",
                "fr": "Session 2 min",
                "ja": "2分セッション",
                "ko": "2분 세션",
                "ar": "جلسة دقيقتين",
                "it": "Sessione da 2 min",
                "zh-Hans": "2 分钟练习",
                "zh-Hant": "2 分鐘練習",
                "pt-PT": "Sessão de 2 min"
            ],
            [
                "en": "Quick review",
                "ru": "Быстрое ревью",
                "de": "Schnelles Review",
                "es": "Repaso rápido",
                "fr": "Révision rapide",
                "ja": "さっと復習",
                "ko": "빠른 복습",
                "ar": "مراجعة سريعة",
                "it": "Ripasso veloce",
                "zh-Hans": "快速复习",
                "zh-Hant": "快速複習",
                "pt-PT": "Revisão rápida"
            ],
            [
                "en": "Short session",
                "ru": "Короткая сессия",
                "de": "Kurze Session",
                "es": "Sesión corta",
                "fr": "Session courte",
                "ja": "短いセッション",
                "ko": "짧은 세션",
                "ar": "جلسة قصيرة",
                "it": "Sessione breve",
                "zh-Hans": "短练习",
                "zh-Hant": "短練習",
                "pt-PT": "Sessão curta"
            ],
        ]
        return t(tables[dayIndex % tables.count])
    }

    static func quickSessionCTA() -> String {
        line([

            [
                "en": "Start",
                "ru": "Начать",
                "de": "Start",
                "es": "Empezar",
                "fr": "Commencer",
                "ja": "スタート",
                "ko": "시작",
                "ar": "ابدأ",
                "it": "Inizia",
                "zh-Hans": "开始",
                "zh-Hant": "開始",
                "pt-PT": "Começar"
            ],
            [
                "en": "Let's go",
                "ru": "Погнали",
                "de": "Los geht’s",
                "es": "Vamos",
                "fr": "C’est parti",
                "ja": "いこう",
                "ko": "가자",
                "ar": "يلا",
                "it": "Andiamo",
                "zh-Hans": "走吧",
                "zh-Hant": "走吧",
                "pt-PT": "Vamos"
            ],
            [
                "en": "Open session",
                "ru": "Открыть",
                "de": "Session öffnen",
                "es": "Abrir sesión",
                "fr": "Ouvrir la session",
                "ja": "セッションを開く",
                "ko": "세션 열기",
                "ar": "افتح الجلسة",
                "it": "Apri sessione",
                "zh-Hans": "打开练习",
                "zh-Hant": "打開練習",
                "pt-PT": "Abrir sessão"
            ],
        ])
    }

    static func quickSessionDone(count: Int) -> (title: String, subtitle: String) {
        let subtitle: String
        if count == 1 {
            subtitle = t([
            "en": "1 word reviewed. Nice and light.",
            "ru": "1 слово. Легко и приятно.",
            "de": "1 Wort wiederholt. Leicht und gut.",
            "es": "1 palabra repasada. Ligero y bien.",
            "fr": "1 mot révisé. Léger et bien.",
            "ja": "1語レビュー。軽くていい感じ。",
            "ko": "단어 1개 복습. 가볍고 좋아.",
            "ar": "كلمة وحدة. خفيف ولطيف.",
            "it": "1 parola ripassata. Leggero e bello.",
            "zh-Hans": "复习了 1 个词。轻松舒服。",
            "zh-Hant": "複習了 1 個詞。輕鬆舒服。",
            "pt-PT": "1 palavra revista. Leve e bom."
        ])
        } else {
            subtitle = t([
            "en": "{COUNT} words reviewed. Streak looks good.",
            "ru": "{COUNT} слов. Стрик в порядке.",
            "de": "{COUNT} Wörter wiederholt. Streak sieht gut aus.",
            "es": "{COUNT} palabras repasadas. La racha va bien.",
            "fr": "{COUNT} mots révisés. La série est bonne.",
            "ja": "{COUNT}語レビュー。連続記録も順調。",
            "ko": "{COUNT}개 복습. 스트릭도 괜찮아.",
            "ar": "{COUNT} كلمات. السلسلة تمام.",
            "it": "{COUNT} parole ripassate. Lo streak è a posto.",
            "zh-Hans": "复习了 {COUNT} 个词。连续打卡不错。",
            "zh-Hant": "複習了 {COUNT} 個詞。連續打卡不錯。",
            "pt-PT": "{COUNT} palavras revistas. A sequência está bem."
        ]).replacingOccurrences(of: "{COUNT}", with: "\(count)")
        }
        return (
            t([
            "en": "Session done",
            "ru": "Сессия готова",
            "de": "Session fertig",
            "es": "Sesión lista",
            "fr": "Session terminée",
            "ja": "セッション完了",
            "ko": "세션 완료",
            "ar": "خلصت الجلسة",
            "it": "Sessione fatta",
            "zh-Hans": "练习完成",
            "zh-Hant": "練習完成",
            "pt-PT": "Sessão concluída"
        ]),
            subtitle
        )
    }

    static func nextReviewTitle() -> String {
        t([
        "en": "Next review",
        "ru": "Следующее ревью",
        "de": "Nächstes Review",
        "es": "Próximo repaso",
        "fr": "Prochaine révision",
        "ja": "次の復習",
        "ko": "다음 복습",
        "ar": "المراجعة الجاية",
        "it": "Prossimo ripasso",
        "zh-Hans": "下次复习",
        "zh-Hant": "下次複習",
        "pt-PT": "Próxima revisão"
    ])
    }

    static func dailyChallengesTitle() -> String {
        t([
        "en": "Daily challenges",
        "ru": "Дневные челленджи",
        "de": "Tägliche Challenges",
        "es": "Retos diarios",
        "fr": "Défis du jour",
        "ja": "デイリーチャレンジ",
        "ko": "일일 챌린지",
        "ar": "تحديات يومية",
        "it": "Sfide giornaliere",
        "zh-Hans": "每日挑战",
        "zh-Hant": "每日挑戰",
        "pt-PT": "Desafios diários"
    ])
    }

    static func dailyChallengesSubtitle(done: Int, total: Int) -> String {
        if done >= total && total > 0 {
            return t([
            "en": "All done for today",
            "ru": "На сегодня всё",
            "de": "Für heute erledigt",
            "es": "Todo listo por hoy",
            "fr": "Tout est fait pour aujourd’hui",
            "ja": "今日は完了",
            "ko": "오늘 끝",
            "ar": "خلصت لليوم",
            "it": "Tutto fatto per oggi",
            "zh-Hans": "今天都完成了",
            "zh-Hant": "今天都完成了",
            "pt-PT": "Tudo feito por hoje"
        ])
        }
        return t([
        "en": "{DONE}/{TOTAL} done",
        "ru": "{DONE}/{TOTAL} готово",
        "de": "{DONE}/{TOTAL} erledigt",
        "es": "{DONE}/{TOTAL} listos",
        "fr": "{DONE}/{TOTAL} faits",
        "ja": "{DONE}/{TOTAL} 完了",
        "ko": "{DONE}/{TOTAL} 완료",
        "ar": "{DONE}/{TOTAL} جاهز",
        "it": "{DONE}/{TOTAL} fatti",
        "zh-Hans": "已完成 {DONE}/{TOTAL}",
        "zh-Hant": "已完成 {DONE}/{TOTAL}",
        "pt-PT": "{DONE}/{TOTAL} feitos"
    ])
            .replacingOccurrences(of: "{DONE}", with: "\(done)")
            .replacingOccurrences(of: "{TOTAL}", with: "\(total)")
    }

    static func readingSubtitle() -> String {
        t([
        "en": "A tiny story. A few of your words hide in it.",
        "ru": "Короткая история. Пара твоих слов спрятаны внутри.",
        "de": "Eine kurze Geschichte aus deinen Wörtern",
        "es": "Una historia corta con tus palabras",
        "fr": "Une courte histoire avec tes mots",
        "ja": "あなたの単語から短いストーリー",
        "ko": "네 단어로 만든 짧은 이야기",
        "ar": "قصة قصيرة من كلماتك",
        "it": "Una breve storia con le tue parole",
        "zh-Hans": "用你的单词写的短故事",
        "zh-Hant": "用你的單字寫的短故事",
        "pt-PT": "Uma história curta com as tuas palavras"
    ])
    }

    static func storyTryAgain() -> String {
        t([
        "en": "Try again",
        "ru": "Ещё раз",
        "de": "Nochmal",
        "es": "Intentar de nuevo",
        "fr": "Réessayer",
        "ja": "もう一度",
        "ko": "다시 시도",
        "ar": "حاول مرة ثانية",
        "it": "Riprova",
        "zh-Hans": "再试一次",
        "zh-Hant": "再試一次",
        "pt-PT": "Tentar de novo"
    ])
    }

    static func storyWriting() -> String {
        line([
            [
                "en": "Plot twist incoming…",
                "ru": "Сейчас будет твист…",
                "de": "Plot twist kommt…",
                "es": "Plot twist en camino…",
                "fr": "Plot twist en approche…",
                "ja": "どんでん返し、準備中…",
                "ko": "반전 준비 중…",
                "ar": "التويست جاي…",
                "it": "Plot twist in arrivo…",
                "zh-Hans": "反转马上到…",
                "zh-Hant": "反轉馬上到…",
                "pt-PT": "Plot twist a caminho…"
            ],
            [
                "en": "Convincing the plot to behave…",
                "ru": "Уговариваем сюжет вести себя…",
                "de": "Überrede die Handlung, artig zu sein…",
                "es": "Convenciendo a la trama de portarse bien…",
                "fr": "On négocie avec l’intrigue…",
                "ja": "あらすじを説得中…",
                "ko": "줄거리를 설득하는 중…",
                "ar": "عم نقنع الحبكة تتصرف…",
                "it": "Sto convincendo la trama a comportarsi…",
                "zh-Hans": "正在说服剧情听话…",
                "zh-Hant": "正在說服劇情聽話…",
                "pt-PT": "A convencer o enredo a comportar-se…"
            ],
            [
                "en": "Brewing a tiny saga with your words…",
                "ru": "Варим мини-сагу из твоих слов…",
                "de": "Braue eine Mini-Saga aus deinen Wörtern…",
                "es": "Preparando una mini-saga con tus palabras…",
                "fr": "On concocte une mini-saga avec tes mots…",
                "ja": "単語でミニ叙事詩を仕込んでる…",
                "ko": "네 단어로 미니 서사시 끓이는 중…",
                "ar": "عم نطبخ ساغا صغيرة من كلماتك…",
                "it": "Sto cucinando una mini-saga con le tue parole…",
                "zh-Hans": "用你的词熬一小段 saga…",
                "zh-Hant": "用你的詞熬一小段 saga…",
                "pt-PT": "A cozinhar uma mini-saga com as tuas palavras…"
            ],
            [
                "en": "Finding a main character who actually talks…",
                "ru": "Ищем героя, который вообще говорит…",
                "de": "Suche einen Helden, der wirklich redet…",
                "es": "Buscando un protagonista que hable de verdad…",
                "fr": "On cherche un héros qui parle vraiment…",
                "ja": "ちゃんと喋る主人公を探してる…",
                "ko": "진짜 말하는 주인공 찾는 중…",
                "ar": "عم ندور على بطل يحكي فعلياً…",
                "it": "Cerco un protagonista che parli davvero…",
                "zh-Hans": "在找一个真会说话的主角…",
                "zh-Hant": "在找一個真會說話的主角…",
                "pt-PT": "A procurar um protagonista que fale a sério…"
            ],
            [
                "en": "Don’t peek — the ending is shy…",
                "ru": "Не подглядывай — концовка стесняется…",
                "de": "Nicht spicken — das Ende ist schüchtern…",
                "es": "No mires — el final es tímido…",
                "fr": "Pas de spoil — la fin est timide…",
                "ja": "チラ見禁止 — 結末が照れてる…",
                "ko": "훔쳐보지 마 — 결말이 수줍어해…",
                "ar": "لا تطلّع — النهاية خجولة…",
                "it": "Niente spoiler — il finale è timido…",
                "zh-Hans": "别偷看——结局害羞了…",
                "zh-Hant": "別偷看——結局害羞了…",
                "pt-PT": "Não espreites — o final é tímido…"
            ],
            [
                "en": "Sprinkling your vocab like seasoning…",
                "ru": "Посыпаем твой вокаб как приправу…",
                "de": "Streue dein Vocab wie Gewürz…",
                "es": "Espolvoreando tu vocab como condimento…",
                "fr": "On saupoudre ton vocab comme un assaisonnement…",
                "ja": "単語をスパイスみたいに振ってる…",
                "ko": "단어를 양념처럼 뿌리는 중…",
                "ar": "عم نرش مفرداتك مثل التوابل…",
                "it": "Sto cospargendo il tuo vocab come un condimento…",
                "zh-Hans": "把你的词当调料撒进去…",
                "zh-Hant": "把你的詞當調料撒進去…",
                "pt-PT": "A polvilhar o teu vocab como tempero…"
            ],
        ])
    }

    static func paywallSoft() -> String {
        t([
        "en": "Unlock unlimited reviews",
        "ru": "Безлимитные ревью",
        "de": "Unbegrenzte Reviews freischalten",
        "es": "Desbloquea repasos ilimitados",
        "fr": "Débloque les révisions illimitées",
        "ja": "無制限の復習を解除",
        "ko": "무제한 복습 잠금 해제",
        "ar": "افتح مراجعات بلا حدود",
        "it": "Sblocca ripassi illimitati",
        "zh-Hans": "解锁无限复习",
        "zh-Hant": "解鎖無限複習",
        "pt-PT": "Desbloqueia revisões ilimitadas"
    ])
    }
}
