import SwiftUI

struct DailyLessonCard: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let plan: DailyLessonPlan
    var onStart: () -> Void
    var onEditVibe: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.title)
                        .font(themeStore.bold(22))
                        .foregroundStyle(themeStore.mainText)

                    Text(plan.subtitle)
                        .font(themeStore.regular(14))
                        .foregroundStyle(themeStore.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if plan.isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(themeStore.accentGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule(style: .continuous)
                                .fill(themeStore.accentGreen.opacity(0.14))
                        )
                } else {
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
            }

            if plan.isDone, !plan.tomorrowWords.isEmpty {
                Text(plan.tomorrowWords.prefix(4).joined(separator: "  ·  "))
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

            if plan.isDone {
                Button {
                    Haptics.softTap()
                    onStart()
                } label: {
                    Text("Once more")
                        .font(themeStore.medium(14))
                        .foregroundStyle(themeStore.mainAccentColor)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            } else {
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

            if let onEditVibe {
                Button {
                    Haptics.softTap()
                    onEditVibe()
                } label: {
                    Text("Tune learning vibe")
                        .font(themeStore.medium(13))
                        .foregroundStyle(themeStore.mainAccentColor)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignRadius.large, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: DesignRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(plan.title). \(plan.subtitle)"))
    }
}
