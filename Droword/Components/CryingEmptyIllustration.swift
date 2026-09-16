import SwiftUI

struct CryingEmptyIllustration: View {
    var body: some View {
        EmptyDictionaryArt()
    }
}

#Preview {
    CryingEmptyIllustration()
        .environmentObject(ThemeStore())
        .frame(width: 260)
        .padding()
}
