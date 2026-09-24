import SwiftUI

struct DailyLessonCard: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let plan: DailyLessonPlan
    var onStart: () -> Void
    var onDismissDone: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(plan.title)
                            .font(themeStore.bold(22))
                            .foregroundStyle(themeStore.mainText)

                        if plan.isDone {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(themeStore.accentPink)
                                .accessibilityHidden(true)
                        }
                    }

                    Text(plan.subtitle)
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    if !plan.isDone {
                        Text("~\(plan.minutes) min")
                            .font(themeStore.bold(13))
                            .foregroundStyle(themeStore.mainAccentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(themeStore.mainAccentColor.opacity(0.14))
                            )
                    }

                    if plan.isDone {
                        Button {
                            Haptics.softTap()
                            withAnimation(.easeOut(duration: 0.25)) {
                                onDismissDone?()
                            }
                        } label: {
                            MenuSymbol(
                                systemName: "xmark",
                                color: themeStore.secondaryText.opacity(0.45),
                                size: 14,
                                weight: .semibold,
                                frameSize: 28
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Close"))
                    }
                }
            }

            if plan.isDone, !plan.tomorrowWords.isEmpty {
                Text(plan.tomorrowWords.prefix(4).map(\.displayCapitalized).joined(separator: "  ·  "))
                    .font(themeStore.medium(13))
                    .foregroundStyle(themeStore.mainText)
            } else if !plan.topicLabels.isEmpty, !plan.isDone {
                HStack(spacing: 6) {
                    ForEach(plan.topicLabels, id: \.self) { label in
                        Text(label)
                            .font(themeStore.medium(12))
                            .foregroundStyle(themeStore.mainText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(themeStore.dividerColor.opacity(0.55))
                            )
                    }
                }
            }

            if !plan.isDone {
                Button {
                    Haptics.buttonPress()
                    onStart()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(plan.canStart ? "Start today's lesson" : "Add 4 words to unlock")
                            .font(themeStore.bold(16))
                    }
                    .duo3DStyle(themeStore.mainAccentColor, isDisabled: !plan.canStart)
                }
                .buttonStyle(Duo3DButtonStyle())
                .disabled(!plan.canStart)
            }
        }
        .padding(DesignSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(plan.title). \(plan.subtitle)"))
    }
}

#Preview {
    DailyLessonCard(plan: DailyLessonPlan(
        title: "Today's lesson",
        subtitle: "A short set for today",
        words: [],
        minutes: 4,
        styleLabel: "Mixed",
        topicLabels: ["Travel"],
        canStart: true,
        isDone: false,
        correct: 0,
        total: 0,
        tomorrowWords: []
    ), onStart: {})
        .padding()
        .environmentObject(ThemeStore())
}
