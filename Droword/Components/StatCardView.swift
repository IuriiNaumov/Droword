import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String

    @Environment(\.colorScheme) private var colorScheme

    private var baseColor: Color {
        colorScheme == .dark ? Color(hex: "#6F68A8") : Color(hex: "#CBCDEA")
    }

    private var textColor: Color {
        darkerShade(of: baseColor, by: colorScheme == .dark ? 0.3 : 0.4)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(textColor)

            Text(title)
                .font(.custom("Poppins-Medium", size: 13))
                .foregroundColor(textColor.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(baseColor.opacity(colorScheme == .dark ? 0.9 : 1.0))
        )
        .shadow(
            color: baseColor.opacity(colorScheme == .dark ? 0.25 : 0.4),
            radius: colorScheme == .dark ? 6 : 8,
            y: colorScheme == .dark ? 3 : 4
        )
        .scaleEffect(1.02)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 16) {
            StatCardView(title: "Total", value: "123")
            StatCardView(title: "Today", value: "5")
        }

        StatCardView(title: "Last 7 days", value: "28")
    }
    .padding()
    .preferredColorScheme(.light)

    VStack(spacing: 16) {
        HStack(spacing: 16) {
            StatCardView(title: "Total", value: "123")
            StatCardView(title: "Today", value: "5")
        }

        StatCardView(title: "Last 7 days", value: "28")
    }
    .padding()
    .preferredColorScheme(.dark)
}
