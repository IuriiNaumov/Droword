import SwiftUI

struct DailyLessonCard: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let plan: DailyLessonPlan
    var onStart: () -> Void
    var onAddWords: (() -> Void)? = nil
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

                    if !plan.subtitle.isEmpty {
                        Text(plan.subtitle)
                            .font(themeStore.regular(14))
                            .foregroundStyle(themeStore.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    if !plan.isDone, plan.canStart {
                        Text("~\(plan.minutes) min")
                            .font(themeStore.bold(13))
                            .foregroundStyle(themeStore.isDuolingo && !themeStore.isGlass ? Color.white : themeStore.mainAccentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background {
                                if themeStore.isDuolingo && !themeStore.isGlass {
                                    let face = themeStore.mainAccentColor
                                    let radius = themeStore.chipRadius
                                    ZStack {
                                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                                            .fill(darkerShade(of: face, by: 0.16))
                                            .offset(y: 2)
                                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                                            .fill(face)
                                    }
                                } else {
                                    Capsule(style: .continuous)
                                        .fill(themeStore.mainAccentColor.opacity(0.14))
                                }
                            }
                            .padding(.bottom, themeStore.isDuolingo && !themeStore.isGlass ? 2 : 0)
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

            if plan.isDone {
                doneExtras
            } else if !plan.topicLabels.isEmpty, plan.canStart {
                HStack(spacing: 6) {
                    ForEach(plan.topicLabels, id: \.self) { label in
                        Text(label)
                            .font(themeStore.medium(12))
                            .foregroundStyle(themeStore.isDuolingo ? Color.white : themeStore.mainText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background {
                                if themeStore.isDuolingo && !themeStore.isGlass {
                                    let face = themeStore.mainAccentColor
                                    let radius = themeStore.chipRadius
                                    ZStack {
                                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                                            .fill(darkerShade(of: face, by: 0.16))
                                            .offset(y: 2)
                                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                                            .fill(face)
                                    }
                                } else {
                                    Capsule(style: .continuous)
                                        .fill(themeStore.dividerColor.opacity(0.55))
                                }
                            }
                            .padding(.bottom, themeStore.isDuolingo ? 2 : 0)
                    }
                }
            }

            if !plan.isDone {
                Button {
                    Haptics.buttonPress()
                    if plan.canStart {
                        onStart()
                    } else {
                        onAddWords?()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: plan.canStart ? "bolt.fill" : "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text(ctaTitle)
                            .font(themeStore.bold(16))
                    }
                    .duo3DStyle(themeStore.mainAccentColor)
                }
                .buttonStyle(Duo3DButtonStyle())
            }
        }
        .padding(DesignSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: themeStore.cardRadius, style: .continuous)
                .fill(themeStore.isGlass ? Color.clear : themeStore.cardBg)
        )
        .modifier(GlassCardModifier(isGlass: themeStore.isGlass, cornerRadius: themeStore.cardRadius))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(plan.subtitle.isEmpty ? plan.title : "\(plan.title). \(plan.subtitle)"))
    }

    private var ctaTitle: LocalizedStringKey {
        if plan.canStart { return "Start today's lesson" }
        return "Add words to start"
    }

    @ViewBuilder
    private var doneExtras: some View {
        if plan.nextReviewCount > 0, let date = plan.nextReviewDate {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(themeStore.mainAccentColor)
                Text(wordsReadyLine(count: plan.nextReviewCount, date: date))
                    .font(themeStore.medium(13))
                    .foregroundStyle(themeStore.mainText)
            }
        } else if !plan.tomorrowWords.isEmpty {
            Text(plan.tomorrowWords.prefix(4).map(\.displayCapitalized).joined(separator: "  ·  "))
                .font(themeStore.medium(13))
                .foregroundStyle(themeStore.mainText)
        }
    }

    private func wordsReadyLine(count: Int, date: Date) -> String {
        let time = timeUntil(date)
        if RussianPlural.prefersRussian {
            let noun = RussianPlural.words(count)
            let verb = RussianPlural.form(count: count, one: "будет готово", few: "будут готовы", many: "будут готовы")
            return "\(count) \(noun) \(verb) через \(time)"
        }
        return String(localized: "\(count) words ready in \(time)")
    }

    private func timeUntil(_ date: Date) -> String {
        let seconds = max(0, date.timeIntervalSince(Date()))
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            let m = max(1, minutes)
            if RussianPlural.prefersRussian {
                let unit = RussianPlural.form(count: m, one: "минуту", few: "минуты", many: "минут")
                return "\(m) \(unit)"
            }
            return String(localized: "\(m) min")
        }
        let hours = minutes / 60
        if hours < 24 {
            if RussianPlural.prefersRussian {
                let unit = RussianPlural.form(count: hours, one: "час", few: "часа", many: "часов")
                return "\(hours) \(unit)"
            }
            return String(localized: "\(hours) h")
        }
        let days = hours / 24
        if RussianPlural.prefersRussian {
            let unit = RussianPlural.form(count: days, one: "день", few: "дня", many: "дней")
            return "\(days) \(unit)"
        }
        return String(localized: "\(days) d")
    }
}

#Preview {
    DailyLessonCard(plan: DailyLessonPlan(
        title: "Today's lesson",
        subtitle: "8 words · 3 due · Mixed",
        words: [],
        minutes: 4,
        styleLabel: "Mixed",
        topicLabels: ["Travel"],
        canStart: true,
        isDone: false,
        correct: 0,
        total: 0,
        tomorrowWords: [],
        nextReviewCount: 0,
        nextReviewDate: nil
    ), onStart: {})
        .padding()
        .environmentObject(ThemeStore())
}
