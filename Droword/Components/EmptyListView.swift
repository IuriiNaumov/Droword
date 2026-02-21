import SwiftUI

struct EmptyListView: View {
    var title: String = "Add a couple of words — and we’ll begin the journey 🚀"

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel(Text(title))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color.clear)
    }
}

#Preview {
    EmptyListView(
        title: "Your word garden is waiting ❤️"
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    EmptyListView(
        title: "No words yet — let’s start small and build daily ✨"
    )
    .preferredColorScheme(.dark)
}
