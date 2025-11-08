import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    var color: Color = Color(hexRGB: 0xE4D2FF)

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.statsNumber)

            Text(title)
                .font(.custom("Poppins-Medium", size: 13))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(color.opacity(0.25))
        )

        .scaleEffect(1.02)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
    }
}

#Preview {
    HStack(spacing: 20) {
        StatCardView(title: "Total", value: "123", color: Color(hexRGB: 0xFFDFA4))
        StatCardView(title: "Today", value: "5", color: Color(hexRGB: 0xC6F6D5))
        StatCardView(title: "Last 7 days", value: "28", color: Color(hexRGB: 0xB9E3FF))
    }
    .padding()
    .background(Color(.appBackground))
}
