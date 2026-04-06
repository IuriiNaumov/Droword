import Foundation

struct StarterWord {
    let word: String
    let translation: String
    let type: String
    let transcription: String?
}

struct StarterWordBank {
    /// Returns 3 beginner words for the given language pair, or nil if the pair is unsupported.
    static func words(learning: String, native: String) -> [StarterWord]? {
        let key = "\(learning)→\(native)"
        return bank[key]
    }

    private static let bank: [String: [StarterWord]] = [
        // English learning pairs
        "English→Русский": [
            StarterWord(word: "Hello", translation: "Привет", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "Спасибо", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "Друг", type: "noun", transcription: "frɛnd"),
        ],
        "English→Español": [
            StarterWord(word: "Hello", translation: "Hola", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "Gracias", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "Amigo", type: "noun", transcription: "frɛnd"),
        ],
        "English→Français": [
            StarterWord(word: "Hello", translation: "Bonjour", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "Merci", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "Ami", type: "noun", transcription: "frɛnd"),
        ],
        "English→Deutsch": [
            StarterWord(word: "Hello", translation: "Hallo", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "Danke", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "Freund", type: "noun", transcription: "frɛnd"),
        ],
        "English→Italiano": [
            StarterWord(word: "Hello", translation: "Ciao", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "Grazie", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "Amico", type: "noun", transcription: "frɛnd"),
        ],
        "English→Português": [
            StarterWord(word: "Hello", translation: "Olá", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "Obrigado", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "Amigo", type: "noun", transcription: "frɛnd"),
        ],
        "English→中文": [
            StarterWord(word: "Hello", translation: "你好", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "谢谢", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "朋友", type: "noun", transcription: "frɛnd"),
        ],
        "English→日本語": [
            StarterWord(word: "Hello", translation: "こんにちは", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "ありがとう", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "友達", type: "noun", transcription: "frɛnd"),
        ],
        "English→한국어": [
            StarterWord(word: "Hello", translation: "안녕하세요", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "감사합니다", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "친구", type: "noun", transcription: "frɛnd"),
        ],
        "English→العربية": [
            StarterWord(word: "Hello", translation: "مرحبا", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "شكرا", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "صديق", type: "noun", transcription: "frɛnd"),
        ],
        "English→हिन्दी": [
            StarterWord(word: "Hello", translation: "नमस्ते", type: "interjection", transcription: "həˈloʊ"),
            StarterWord(word: "Thank you", translation: "धन्यवाद", type: "phrase", transcription: "θæŋk juː"),
            StarterWord(word: "Friend", translation: "दोस्त", type: "noun", transcription: "frɛnd"),
        ],

        // Español learning pairs
        "Español→Русский": [
            StarterWord(word: "Hola", translation: "Привет", type: "interjection", transcription: "ˈola"),
            StarterWord(word: "Gracias", translation: "Спасибо", type: "noun", transcription: "ˈɡɾasjas"),
            StarterWord(word: "Amigo", translation: "Друг", type: "noun", transcription: "aˈmiɣo"),
        ],
        "Español→English": [
            StarterWord(word: "Hola", translation: "Hello", type: "interjection", transcription: "ˈola"),
            StarterWord(word: "Gracias", translation: "Thank you", type: "noun", transcription: "ˈɡɾasjas"),
            StarterWord(word: "Amigo", translation: "Friend", type: "noun", transcription: "aˈmiɣo"),
        ],

        // Русский learning pairs
        "Русский→English": [
            StarterWord(word: "Привет", translation: "Hello", type: "interjection", transcription: "prʲɪˈvʲet"),
            StarterWord(word: "Спасибо", translation: "Thank you", type: "noun", transcription: "spɐˈsʲibə"),
            StarterWord(word: "Друг", translation: "Friend", type: "noun", transcription: "druɡ"),
        ],
        "Русский→Español": [
            StarterWord(word: "Привет", translation: "Hola", type: "interjection", transcription: "prʲɪˈvʲet"),
            StarterWord(word: "Спасибо", translation: "Gracias", type: "noun", transcription: "spɐˈsʲibə"),
            StarterWord(word: "Друг", translation: "Amigo", type: "noun", transcription: "druɡ"),
        ],

        // Français learning pairs
        "Français→Русский": [
            StarterWord(word: "Bonjour", translation: "Привет", type: "interjection", transcription: "bɔ̃ʒuʁ"),
            StarterWord(word: "Merci", translation: "Спасибо", type: "interjection", transcription: "mɛʁsi"),
            StarterWord(word: "Ami", translation: "Друг", type: "noun", transcription: "ami"),
        ],
        "Français→English": [
            StarterWord(word: "Bonjour", translation: "Hello", type: "interjection", transcription: "bɔ̃ʒuʁ"),
            StarterWord(word: "Merci", translation: "Thank you", type: "interjection", transcription: "mɛʁsi"),
            StarterWord(word: "Ami", translation: "Friend", type: "noun", transcription: "ami"),
        ],

        // Deutsch learning pairs
        "Deutsch→Русский": [
            StarterWord(word: "Hallo", translation: "Привет", type: "interjection", transcription: "ˈhalo"),
            StarterWord(word: "Danke", translation: "Спасибо", type: "interjection", transcription: "ˈdaŋkə"),
            StarterWord(word: "Freund", translation: "Друг", type: "noun", transcription: "fʁɔʏnt"),
        ],
        "Deutsch→English": [
            StarterWord(word: "Hallo", translation: "Hello", type: "interjection", transcription: "ˈhalo"),
            StarterWord(word: "Danke", translation: "Thank you", type: "interjection", transcription: "ˈdaŋkə"),
            StarterWord(word: "Freund", translation: "Friend", type: "noun", transcription: "fʁɔʏnt"),
        ],

        // Italiano learning pairs
        "Italiano→Русский": [
            StarterWord(word: "Ciao", translation: "Привет", type: "interjection", transcription: "tʃao"),
            StarterWord(word: "Grazie", translation: "Спасибо", type: "interjection", transcription: "ˈɡrattsje"),
            StarterWord(word: "Amico", translation: "Друг", type: "noun", transcription: "aˈmiko"),
        ],
        "Italiano→English": [
            StarterWord(word: "Ciao", translation: "Hello", type: "interjection", transcription: "tʃao"),
            StarterWord(word: "Grazie", translation: "Thank you", type: "interjection", transcription: "ˈɡrattsje"),
            StarterWord(word: "Amico", translation: "Friend", type: "noun", transcription: "aˈmiko"),
        ],

        // Português learning pairs
        "Português→Русский": [
            StarterWord(word: "Olá", translation: "Привет", type: "interjection", transcription: "oˈla"),
            StarterWord(word: "Obrigado", translation: "Спасибо", type: "interjection", transcription: "obɾiˈɡadu"),
            StarterWord(word: "Amigo", translation: "Друг", type: "noun", transcription: "ɐˈmiɡu"),
        ],
        "Português→English": [
            StarterWord(word: "Olá", translation: "Hello", type: "interjection", transcription: "oˈla"),
            StarterWord(word: "Obrigado", translation: "Thank you", type: "interjection", transcription: "obɾiˈɡadu"),
            StarterWord(word: "Amigo", translation: "Friend", type: "noun", transcription: "ɐˈmiɡu"),
        ],

        // 中文 learning pairs
        "中文→English": [
            StarterWord(word: "你好", translation: "Hello", type: "interjection", transcription: "nǐ hǎo"),
            StarterWord(word: "谢谢", translation: "Thank you", type: "interjection", transcription: "xiè xiè"),
            StarterWord(word: "朋友", translation: "Friend", type: "noun", transcription: "péng yǒu"),
        ],

        // 日本語 learning pairs
        "日本語→English": [
            StarterWord(word: "こんにちは", translation: "Hello", type: "interjection", transcription: "konnichiwa"),
            StarterWord(word: "ありがとう", translation: "Thank you", type: "interjection", transcription: "arigatō"),
            StarterWord(word: "友達", translation: "Friend", type: "noun", transcription: "tomodachi"),
        ],

        // 한국어 learning pairs
        "한국어→English": [
            StarterWord(word: "안녕하세요", translation: "Hello", type: "interjection", transcription: "annyeonghaseyo"),
            StarterWord(word: "감사합니다", translation: "Thank you", type: "interjection", transcription: "gamsahamnida"),
            StarterWord(word: "친구", translation: "Friend", type: "noun", transcription: "chingu"),
        ],
    ]
}
