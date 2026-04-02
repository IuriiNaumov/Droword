import SwiftUI
import UIKit

struct LanguageCubePicker: View {
    @Binding var selectedLanguage: String
    var title: String
    var languages: [LanguageOption]
    var blockedLanguage: String? = nil

    private let columns = [
        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16),
        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16),
        GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.custom("Poppins-Bold", size: 18))
                .foregroundColor(.primary)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(languages) { lang in
                    let isBlocked = lang.name == blockedLanguage

                    LanguageCube(
                        language: lang,
                        isSelected: selectedLanguage == lang.name,
                        isBlocked: isBlocked
                    ) {
                        if !isBlocked {
                            let generator = UIImpactFeedbackGenerator(style: .soft)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedLanguage = lang.name
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    LanguageCubePicker(
        selectedLanguage: .constant("Español"),
        title: "I speak",
        languages: [
            LanguageOption(name: "English", flag: "🇬🇧", color: Color.accentBlue),
            LanguageOption(name: "Español", flag: "🇲🇽", color: Color.accentBlue),
            LanguageOption(name: "Русский", flag: "🇷🇺", color: Color.accentBlue)
        ]
    )
}
