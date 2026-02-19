import SwiftUI

struct EmptyListView: View {
    var title: String = "No words"
    var iconName: String = "EmptyList"
    var iconSize: CGFloat = 128
    var tint: Color = .accentColor

    var body: some View {
        VStack(spacing: 16) {
            icon
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(tint.opacity(0.9))
                .accessibilityHidden(true)

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel(Text(title))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .background(Color.clear)
    }

    @ViewBuilder
    private var icon: some View {

        Image(iconName)
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)

    }
}

#Preview {
    EmptyListView(
        title: "No saved words yet",
        iconName: "EmptyList",
        iconSize: 140,
        tint: .blue
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    EmptyListView(
        title: "Aún no tienes palabras 😴",
        iconName: "EmptyList",
        iconSize: 140,
        tint: .orange
    )
    .preferredColorScheme(.dark)
}
