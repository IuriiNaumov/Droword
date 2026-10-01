import SwiftUI

struct LanguageFlagView: View {
    let language: String
    var width: CGFloat = 38
    var height: CGFloat = 26
    var cornerRadius: CGFloat? = nil

    private var radius: CGFloat {
        cornerRadius ?? max(4, height * 0.18)
    }

    private var normalized: String {
        language.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            flagGraphics
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay {
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .allowsHitTesting(false)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.8)
                }
        }
        .frame(width: width, height: height)
        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
    }

    @ViewBuilder
    private var flagGraphics: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            switch normalized {
            case "english", "uk", "en", "gb", "🇬🇧":
                ukFlag(w: w, h: h)
            case "español", "espanol", "spanish", "es", "🇪🇸":
                spainFlag(w: w, h: h)
            case "русский", "russian", "ru", "🇷🇺":
                russiaFlag(w: w, h: h)
            case "français", "francais", "french", "fr", "🇫🇷":
                franceFlag(w: w, h: h)
            case "deutsch", "german", "de", "🇩🇪":
                germanyFlag(w: w, h: h)
            case "italiano", "italian", "it", "🇮🇹":
                italyFlag(w: w, h: h)
            case "português", "portugues", "portuguese", "pt", "🇵🇹":
                portugalFlag(w: w, h: h)
            case "한국어", "korean", "ko", "🇰🇷":
                koreaFlag(w: w, h: h)
            case "中文", "chinese", "zh", "cn", "🇨🇳":
                chinaFlag(w: w, h: h)
            case "日本語", "japanese", "ja", "jp", "🇯🇵":
                japanFlag(w: w, h: h)
            case "العربية", "arabic", "ar", "sa", "🇸🇦":
                saudiFlag(w: w, h: h)
            case "हिन्दी", "hindi", "hi", "in", "🇮🇳":
                indiaFlag(w: w, h: h)
            case "українська", "ukrainian", "ua", "🇺🇦":
                ukraineFlag(w: w, h: h)
            case "türkçe", "turkce", "turkish", "tr", "🇹🇷":
                turkeyFlag(w: w, h: h)
            case "ελληνικά", "greek", "el", "gr", "🇬🇷":
                greeceFlag(w: w, h: h)
            case "nederlands", "dutch", "nl", "🇳🇱":
                netherlandsFlag(w: w, h: h)
            case "polski", "polish", "pl", "🇵🇱":
                polandFlag(w: w, h: h)
            case "svenska", "swedish", "se", "sv", "🇸🇪":
                swedenFlag(w: w, h: h)
            case "norsk", "norwegian", "no", "🇳🇴":
                norwayFlag(w: w, h: h)
            case "dansk", "danish", "da", "dk", "🇩🇰":
                denmarkFlag(w: w, h: h)
            case "suomi", "finnish", "fi", "🇫🇮":
                finlandFlag(w: w, h: h)
            case "tiếng việt", "tieng viet", "vietnamese", "vi", "vn", "🇻🇳":
                vietnamFlag(w: w, h: h)
            case "bahasa indonesia", "indonesian", "id", "🇮🇩":
                indonesiaFlag(w: w, h: h)
            case "ไทย", "thai", "th", "🇹🇭":
                thailandFlag(w: w, h: h)
            case "עברית", "hebrew", "he", "il", "🇮🇱":
                israelFlag(w: w, h: h)
            case "čeština", "cestina", "czech", "cz", "cs", "🇨🇿":
                czechFlag(w: w, h: h)
            case "română", "romana", "romanian", "ro", "🇷🇴":
                romaniaFlag(w: w, h: h)
            case "magyar", "hungarian", "hu", "🇭🇺":
                hungaryFlag(w: w, h: h)
            default:
                fallbackFlag(w: w, h: h)
            }
        }
    }

    private func ukFlag(w: CGFloat, h: CGFloat) -> some View {
        let navy = Color(hex: "#012169")
        let red = Color(hex: "#C8102E")
        return ZStack {
            navy
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: w, y: h))
                p.move(to: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: 0, y: h))
            }
            .stroke(Color.white, lineWidth: h * 0.24)

            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: w, y: h))
                p.move(to: CGPoint(x: w, y: 0))
                p.addLine(to: CGPoint(x: 0, y: h))
            }
            .stroke(red, lineWidth: h * 0.08)

            Rectangle().fill(.white).frame(width: w, height: h * 0.32).position(x: w / 2, y: h / 2)
            Rectangle().fill(.white).frame(width: h * 0.32, height: h).position(x: w / 2, y: h / 2)

            Rectangle().fill(red).frame(width: w, height: h * 0.18).position(x: w / 2, y: h / 2)
            Rectangle().fill(red).frame(width: h * 0.18, height: h).position(x: w / 2, y: h / 2)
        }
    }

    private func spainFlag(w: CGFloat, h: CGFloat) -> some View {
        let red = Color(hex: "#AA151B")
        let yellow = Color(hex: "#F1BF00")
        let gold = Color(hex: "#BFA15F")
        return ZStack {
            VStack(spacing: 0) {
                red.frame(height: h * 0.25)
                yellow.frame(height: h * 0.50)
                red.frame(height: h * 0.25)
            }

            HStack(spacing: 2) {
                Rectangle().fill(gold).frame(width: 1.5, height: h * 0.22)
                VStack(spacing: 1) {
                    Circle().fill(gold).frame(width: 3, height: 3)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(red)
                        .frame(width: h * 0.18, height: h * 0.20)
                        .overlay {
                            RoundedRectangle(cornerRadius: 1)
                                .fill(yellow.opacity(0.8))
                                .frame(width: h * 0.11, height: h * 0.13)
                        }
                }
                Rectangle().fill(gold).frame(width: 1.5, height: h * 0.22)
            }
            .position(x: w * 0.32, y: h * 0.5)
        }
    }

    private func russiaFlag(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color.white
            Color(hex: "#0039A6")
            Color(hex: "#D52B1E")
        }
    }

    private func franceFlag(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color(hex: "#002654")
            Color.white
            Color(hex: "#ED2939")
        }
    }

    private func germanyFlag(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color(hex: "#1C1C1E")
            Color(hex: "#DD0000")
            Color(hex: "#FFCE00")
        }
    }

    private func italyFlag(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color(hex: "#009246")
            Color.white
            Color(hex: "#CE2B37")
        }
    }

    private func portugalFlag(w: CGFloat, h: CGFloat) -> some View {
        let green = Color(hex: "#006600")
        let red = Color(hex: "#FF0000")
        let yellow = Color(hex: "#FFCC00")
        return ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                green.frame(width: w * 0.40)
                red.frame(width: w * 0.60)
            }

            ZStack {
                Circle()
                    .stroke(yellow, lineWidth: 1.2)
                    .frame(width: h * 0.42, height: h * 0.42)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: h * 0.22, height: h * 0.26)
                    .overlay {
                        RoundedRectangle(cornerRadius: 1.5)
                            .stroke(red, lineWidth: 1.2)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "#002654"))
                            .frame(width: h * 0.12, height: h * 0.14)
                    }
            }
            .position(x: w * 0.40, y: h * 0.5)
        }
    }

    private func koreaFlag(w: CGFloat, h: CGFloat) -> some View {
        let red = Color(hex: "#CD2E3A")
        let blue = Color(hex: "#0047A0")
        let r = h * 0.24

        return ZStack {
            Color.white

            ZStack {
                Circle()
                    .fill(blue)
                    .frame(width: r * 2, height: r * 2)

                Path { path in
                    path.addArc(
                        center: CGPoint(x: r, y: r),
                        radius: r,
                        startAngle: .degrees(0),
                        endAngle: .degrees(180),
                        clockwise: true
                    )
                    path.addArc(
                        center: CGPoint(x: r * 0.5, y: r),
                        radius: r * 0.5,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0),
                        clockwise: true
                    )
                    path.addArc(
                        center: CGPoint(x: r * 1.5, y: r),
                        radius: r * 0.5,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .fill(red)
                .frame(width: r * 2, height: r * 2)
            }
            .position(x: w / 2, y: h / 2)

            trigram(count: 3).position(x: w * 0.18, y: h * 0.22)
            trigram(count: 3).position(x: w * 0.82, y: h * 0.22)
            trigram(count: 3).position(x: w * 0.18, y: h * 0.78)
            trigram(count: 3).position(x: w * 0.82, y: h * 0.78)
        }
    }

    private func trigram(count: Int) -> some View {
        VStack(spacing: 1.2) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color(hex: "#1C1C1E"))
                    .frame(width: 7, height: 1.2)
            }
        }
    }

    private func chinaFlag(w: CGFloat, h: CGFloat) -> some View {
        let gold = Color(hex: "#FFDE00")
        return ZStack {
            Color(hex: "#DE2910")

            FlagStarShape()
                .fill(gold)
                .frame(width: h * 0.32, height: h * 0.32)
                .position(x: w * 0.24, y: h * 0.32)

            FlagStarShape()
                .fill(gold)
                .frame(width: h * 0.10, height: h * 0.10)
                .position(x: w * 0.40, y: h * 0.16)

            FlagStarShape()
                .fill(gold)
                .frame(width: h * 0.10, height: h * 0.10)
                .position(x: w * 0.47, y: h * 0.26)

            FlagStarShape()
                .fill(gold)
                .frame(width: h * 0.10, height: h * 0.10)
                .position(x: w * 0.47, y: h * 0.40)

            FlagStarShape()
                .fill(gold)
                .frame(width: h * 0.10, height: h * 0.10)
                .position(x: w * 0.40, y: h * 0.50)
        }
    }

    private func japanFlag(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Color.white
            Circle()
                .fill(Color(hex: "#BC002D"))
                .frame(width: h * 0.58, height: h * 0.58)
                .position(x: w / 2, y: h / 2)
        }
    }

    private func saudiFlag(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Color(hex: "#006C35")

            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 0.5).fill(.white).frame(width: 4, height: 2)
                    RoundedRectangle(cornerRadius: 0.5).fill(.white).frame(width: 6, height: 2.5)
                    RoundedRectangle(cornerRadius: 0.5).fill(.white).frame(width: 5, height: 2)
                    RoundedRectangle(cornerRadius: 0.5).fill(.white).frame(width: 4, height: 2.5)
                }

                HStack(spacing: 1) {
                    Capsule().fill(.white).frame(width: w * 0.45, height: 1.5)
                    Rectangle().fill(.white).frame(width: 1.5, height: 4)
                    Circle().fill(.white).frame(width: 2, height: 2)
                }
            }
            .position(x: w / 2, y: h / 2)
        }
    }

    private func indiaFlag(w: CGFloat, h: CGFloat) -> some View {
        let navy = Color(hex: "#000080")
        return ZStack {
            VStack(spacing: 0) {
                Color(hex: "#FF9933")
                Color.white
                Color(hex: "#138808")
            }

            ZStack {
                Circle()
                    .stroke(navy, lineWidth: 1)
                    .frame(width: h * 0.28, height: h * 0.28)
                Circle()
                    .fill(navy)
                    .frame(width: 2, height: 2)
                ForEach(0..<6) { i in
                    Rectangle()
                        .fill(navy)
                        .frame(width: h * 0.28, height: 0.7)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
            }
            .position(x: w / 2, y: h / 2)
        }
    }

    private func ukraineFlag(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color(hex: "#0057B7")
            Color(hex: "#FFD700")
        }
    }

    private func turkeyFlag(w: CGFloat, h: CGFloat) -> some View {
        let red = Color(hex: "#E30A17")
        return ZStack {
            red
            Circle()
                .fill(.white)
                .frame(width: h * 0.52, height: h * 0.52)
                .position(x: w * 0.38, y: h * 0.5)
            Circle()
                .fill(red)
                .frame(width: h * 0.42, height: h * 0.42)
                .position(x: w * 0.45, y: h * 0.5)
            FlagStarShape()
                .fill(.white)
                .frame(width: h * 0.24, height: h * 0.24)
                .rotationEffect(.degrees(-15))
                .position(x: w * 0.62, y: h * 0.5)
        }
    }

    private func greeceFlag(w: CGFloat, h: CGFloat) -> some View {
        let blue = Color(hex: "#0D5EAF")
        let stripeH = h / 9
        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<9, id: \.self) { i in
                    (i.isMultiple(of: 2) ? blue : Color.white)
                        .frame(height: stripeH)
                }
            }

            ZStack {
                blue
                Rectangle().fill(.white).frame(width: w * 0.40, height: stripeH)
                Rectangle().fill(.white).frame(width: stripeH, height: stripeH * 5)
            }
            .frame(width: w * 0.40, height: stripeH * 5)
        }
    }

    private func netherlandsFlag(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color(hex: "#AE1C28")
            Color.white
            Color(hex: "#21468B")
        }
    }

    private func polandFlag(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color.white
            Color(hex: "#DC143C")
        }
    }

    private func swedenFlag(w: CGFloat, h: CGFloat) -> some View {
        nordicCross(field: Color(hex: "#006AA7"), cross: Color(hex: "#FECC00"), w: w, h: h)
    }

    private func norwayFlag(w: CGFloat, h: CGFloat) -> some View {
        let x = w * 0.36
        return ZStack {
            Color(hex: "#BA0C2F")
            Rectangle().fill(.white).frame(width: h * 0.28, height: h).position(x: x, y: h / 2)
            Rectangle().fill(.white).frame(width: w, height: h * 0.28).position(x: w / 2, y: h / 2)
            Rectangle().fill(Color(hex: "#00205B")).frame(width: h * 0.16, height: h).position(x: x, y: h / 2)
            Rectangle().fill(Color(hex: "#00205B")).frame(width: w, height: h * 0.16).position(x: w / 2, y: h / 2)
        }
    }

    private func denmarkFlag(w: CGFloat, h: CGFloat) -> some View {
        nordicCross(field: Color(hex: "#C60C30"), cross: .white, w: w, h: h)
    }

    private func finlandFlag(w: CGFloat, h: CGFloat) -> some View {
        nordicCross(field: .white, cross: Color(hex: "#003580"), w: w, h: h)
    }

    private func nordicCross(field: Color, cross: Color, w: CGFloat, h: CGFloat) -> some View {
        let x = w * 0.36
        let thick = h * 0.20
        return ZStack {
            field
            Rectangle().fill(cross).frame(width: thick, height: h).position(x: x, y: h / 2)
            Rectangle().fill(cross).frame(width: w, height: thick).position(x: w / 2, y: h / 2)
        }
    }

    private func vietnamFlag(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Color(hex: "#DA251D")
            FlagStarShape()
                .fill(Color(hex: "#FFFF00"))
                .frame(width: h * 0.56, height: h * 0.56)
                .position(x: w / 2, y: h / 2)
        }
    }

    private func indonesiaFlag(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color(hex: "#CE1126")
            Color.white
        }
    }

    private func thailandFlag(w: CGFloat, h: CGFloat) -> some View {
        let red = Color(hex: "#A51931")
        let blue = Color(hex: "#2D2A4A")
        return VStack(spacing: 0) {
            red.frame(height: h / 6)
            Color.white.frame(height: h / 6)
            blue.frame(height: h * 2 / 6)
            Color.white.frame(height: h / 6)
            red.frame(height: h / 6)
        }
    }

    private func israelFlag(w: CGFloat, h: CGFloat) -> some View {
        let blue = Color(hex: "#0038B8")
        return ZStack {
            Color.white
            Rectangle().fill(blue).frame(width: w, height: h * 0.11).position(x: w / 2, y: h * 0.18)
            Rectangle().fill(blue).frame(width: w, height: h * 0.11).position(x: w / 2, y: h * 0.82)
            FlagStarOfDavid()
                .stroke(blue, lineWidth: max(1.2, h * 0.045))
                .frame(width: h * 0.44, height: h * 0.44)
                .position(x: w / 2, y: h / 2)
        }
    }

    private func czechFlag(w: CGFloat, h: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                Color.white
                Color(hex: "#D7141A")
            }
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: w * 0.5, y: h / 2))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.closeSubpath()
            }
            .fill(Color(hex: "#11457E"))
        }
    }

    private func romaniaFlag(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color(hex: "#002B7F")
            Color(hex: "#FCD116")
            Color(hex: "#CE1126")
        }
    }

    private func hungaryFlag(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color(hex: "#CE2939")
            Color.white
            Color(hex: "#477050")
        }
    }

    private func fallbackFlag(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Color(hex: "#5B9BD5")
            Text(language.prefix(2).uppercased())
                .font(.system(size: h * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

private struct FlagStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.382
        var path = Path()

        for i in 0..<10 {
            let radius = i.isMultiple(of: 2) ? outer : inner
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let pt = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }
}

private struct FlagStarOfDavid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.75))
        path.closeSubpath()

        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25))
        path.closeSubpath()
        return path
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
        ForEach(LanguageCatalog.availableLanguages) { lang in
            VStack(spacing: 4) {
                LanguageFlagView(language: lang.name, width: 44, height: 30)
                Text(lang.name)
                    .font(.system(size: 11))
            }
        }
    }
    .padding()
}
