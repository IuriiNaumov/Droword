import SwiftUI

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: HomeView.Tab
    @Binding var showAddWordView: Bool
    @Binding var activeTabPulse: HomeView.Tab?
    var isCompact: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Основной бар
            ZStack {
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 15, y: 6)
                    .frame(height: 74)
                    .blur(radius: 0.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color.white.opacity(0.05))
                            .blur(radius: 12)
                    )
                    .padding(.horizontal, 16)

                HStack(spacing: isCompact ? 28 : 36){
                    ForEach(HomeView.Tab.allCases) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeTabPulse = tab
                                selectedTab = tab
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                activeTabPulse = nil
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: iconName(for: tab))
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(
                                        selectedTab == tab
                                        ? AnyShapeStyle(LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom))
                                        : AnyShapeStyle(Color.secondary)
                                    )
                                    .scaleEffect(activeTabPulse == tab ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: activeTabPulse)
                            }
                            .frame(width: 48, height: 48)
                            .background(
                                Circle()
                                    .fill(selectedTab == tab ? Color.primary.opacity(0.07) : .clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    showAddWordView = true
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        LinearGradient(
                            colors: [Color("MainBlack"), .black.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            .padding(.leading, 12)
            .offset(y: -6)
        }
        .padding(.bottom, 12)
        .padding(.horizontal, 16)
    }

    private func iconName(for tab: HomeView.Tab) -> String {
        switch tab {
        case .search:
            return tab.systemImage
        default:
            return selectedTab == tab ? tab.systemImage + ".fill" : tab.systemImage
        }
    }
}
