import SwiftUI

/// Состояние квиза, когда слов недостаточно для начала практики.
struct QuizNotEnoughView: View {
    var body: some View {
        VStack(spacing: 18) {
            Text("Not enough words yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Add at least 4 words with translations to start practicing. Every word counts!")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
