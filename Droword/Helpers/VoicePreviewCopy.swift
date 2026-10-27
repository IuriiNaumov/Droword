enum VoicePreviewCopy {
    static func phrase(for nativeLanguage: String) -> String {
        switch nativeLanguage {
        case "Español": return "Hola, ¿qué tal estás hoy?"
        case "Русский": return "Привет, как у тебя дела сегодня?"
        case "Français": return "Salut, comment tu vas aujourd'hui ?"
        case "Deutsch": return "Hey, wie geht's dir heute?"
        case "Italiano": return "Ciao, come stai oggi?"
        case "Português": return "Olá, como estás hoje?"
        case "한국어": return "안녕, 오늘 기분 어때?"
        case "中文": return "嗨，你今天怎么样？"
        case "日本語": return "こんにちは、今日はどう？"
        case "العربية": return "مرحبا، كيف حالك اليوم؟"
        case "हिन्दी": return "नमस्ते, आज तुम कैसे हो?"
        case "Українська": return "Привіт, як у тебе справи сьогодні?"
        case "Türkçe": return "Merhaba, bugün nasılsın?"
        case "Ελληνικά": return "Γεια σου, πώς είσαι σήμερα;"
        case "Nederlands": return "Hoi, hoe gaat het vandaag?"
        case "Polski": return "Cześć, jak się dzisiaj masz?"
        case "Svenska": return "Hej, hur mår du idag?"
        case "Norsk": return "Hei, hvordan har du det i dag?"
        case "Dansk": return "Hej, hvordan har du det i dag?"
        case "Suomi": return "Hei, mitä kuuluu tänään?"
        case "Tiếng Việt": return "Chào bạn, hôm nay bạn thế nào?"
        case "Bahasa Indonesia": return "Hai, apa kabar hari ini?"
        case "ไทย": return "สวัสดี วันนี้เป็นอย่างไรบ้าง"
        case "עברית": return "היי, מה שלומך היום?"
        case "Čeština": return "Ahoj, jak se máš dnes?"
        case "Română": return "Salut, ce mai faci astăzi?"
        case "Magyar": return "Szia, hogy vagy ma?"
        default: return "Hey, how are you doing today?"
        }
    }
}
