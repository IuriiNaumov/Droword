import SwiftUI

struct SheetTitleStyle: ViewModifier {
    @EnvironmentObject private var themeStore: ThemeStore
    func body(content: Content) -> some View {
        content
            .font(themeStore.bold(24))
            .foregroundColor(.primary)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    func sheetTitle() -> some View {
        modifier(SheetTitleStyle())
    }
}
