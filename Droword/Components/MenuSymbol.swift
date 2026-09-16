import SwiftUI

struct MenuSymbol: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let systemName: String
    var color: Color? = nil
    var size: CGFloat = 18
    var weight: Font.Weight = .regular
    var frameSize: CGFloat = 28

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: weight))
            .foregroundStyle(color ?? themeStore.mainText)
            .frame(width: frameSize, height: frameSize, alignment: .center)
            .accessibilityHidden(true)
    }
}
