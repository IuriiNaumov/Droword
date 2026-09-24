import SwiftUI
import UniformTypeIdentifiers

struct DictionarySettingsView: View {
    @EnvironmentObject private var store: WordsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    @State private var csvFileURL: URL?
    @State private var showImportPicker = false
    @State private var importedCount: Int?
    @State private var importError: String?
    @State private var showClearConfirm = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Dictionary")
                    .sheetTitle()

                sectionHeader("Home Screen")

                HomeExtrasToggleList()

                Text("Hide extras you don’t want on Home. Dictionary and lessons stay.")
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .padding(.horizontal, 4)
                    .padding(.top, -8)

                sectionHeader("Data")

                VStack(spacing: 0) {
                    settingsRow(icon: "square.and.arrow.up", color: themeStore.iconBlue, title: "Export Words") {
                        exportCSV()
                    }
                    settingsRow(icon: "square.and.arrow.down", color: themeStore.iconGreen, title: "Import Words") {
                        showImportPicker = true
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))

                Text("Works with exports from Anki, Quizlet, and any CSV or TXT file. Minimum: a column named \"Word\". Translations will be added automatically if missing.")
                    .font(themeStore.regular(13))
                    .foregroundStyle(themeStore.secondaryText)
                    .padding(.horizontal, 4)
                    .padding(.top, -8)

                VStack(spacing: 0) {
                    settingsRow(icon: "trash.fill", color: Color.accentRed, title: "Clear dictionary") {
                        guard !store.words.isEmpty else { return }
                        showClearConfirm = true
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.card, style: .continuous))
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
        }
        .background(themeStore.appBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                SettingsBackButton()
            }
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .onChange(of: csvFileURL) { _, newURL in
            guard let url = newURL else { return }
            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                var topVC = root
                while let presented = topVC.presentedViewController { topVC = presented }
                if let popover = av.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                topVC.present(av, animated: true)
            }
            csvFileURL = nil
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importCSV(from: url)
                } else {
                    importError = String(localized: "No file selected.")
                }
            case .failure:
                importError = String(localized: "Couldn't open that file.")
            }
        }
        .overlay {
            if showClearConfirm {
                CustomAlertView(
                    icon: "trash.fill",
                    iconColor: Color.accentRed,
                    title: "Clear dictionary?",
                    message: "This action cannot be undone.",
                    primaryButton: .init(title: "Clear all", style: .destructive) {
                        store.clear()
                        showClearConfirm = false
                        Haptics.warning()
                    },
                    secondaryButton: .init(title: "Cancel", style: .cancel) {
                        showClearConfirm = false
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            } else if let count = importedCount {
                CustomAlertView(
                    icon: "checkmark.circle.fill",
                    iconColor: themeStore.mainAccentColor,
                    title: "Import Complete",
                    message: LocalizedStringKey(
                        count == 0
                            ? String(localized: "No new words to import.")
                            : String(localized: "\(count) words imported successfully.")
                    ),
                    primaryButton: .init(title: "OK", style: .primary) {
                        importedCount = nil
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            } else if let importError {
                CustomAlertView(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: themeStore.accentGold,
                    title: "Import failed",
                    message: LocalizedStringKey(importError),
                    primaryButton: .init(title: "OK", style: .primary) {
                        self.importError = nil
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(themeStore.bold(18))
            .foregroundStyle(.primary)
    }

    private func settingsRow(icon: String, color: Color = .clear, title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.menuTap()
            action()
        } label: {
            HStack(spacing: 14) {
                MenuSymbol(
                    systemName: icon,
                    color: color == Color.accentRed ? Color.accentRed : nil
                )

                Text(title)
                    .font(themeStore.regular(16))
                    .foregroundStyle(color == Color.accentRed ? Color.accentRed : themeStore.mainText)

                Spacer()

                DisclosureChevron()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .background(themeStore.cardBg)
        }
        .buttonStyle(.plain)
    }

    private func exportCSV() {
        let df = DateFormatting.dayFormatter

        var csv = "Word,Translation,Type,Tag,Comment,Example,Explanation,Breakdown,Transcription,From Language,To Language,Date Added,Ease Factor,Interval Days,Repetitions,Lapses,Due Date,Introduced\n"
        for w in store.words {
            let due = w.dueDate.map { df.string(from: $0) } ?? ""
            let fields: [String] = [
                csvEscape(w.word),
                csvEscape(w.translation ?? ""),
                csvEscape(w.type),
                csvEscape(w.tag ?? ""),
                csvEscape(w.comment ?? ""),
                csvEscape(w.example ?? ""),
                csvEscape(w.explanation ?? ""),
                csvEscape(w.breakdown ?? ""),
                csvEscape(w.transcription ?? ""),
                csvEscape(w.fromLanguage),
                csvEscape(w.toLanguage),
                df.string(from: w.dateAdded),
                csvEscape(String(w.easeFactor)),
                csvEscape(String(w.intervalDays)),
                csvEscape(String(w.repetitions)),
                csvEscape(String(w.lapses)),
                csvEscape(due),
                csvEscape(w.introduced ? "true" : "false")
            ]
            csv += fields.joined(separator: ",") + "\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Droword_Dictionary.csv")
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            csvFileURL = fileURL
        } catch {
            #if DEBUG
            print("Failed to write CSV:", error.localizedDescription)
            #endif
        }
    }

    private func csvEscape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"") || field.contains("\n")
        if needsQuoting {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    private func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importError = String(localized: "Couldn't access that file.")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let content: String
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            content = utf8
        } else if let latin1 = try? String(contentsOf: url, encoding: .isoLatin1) {
            content = latin1
        } else {
            importError = String(localized: "Couldn't read the file. Use UTF-8 CSV or TXT.")
            return
        }

        let rows = parseCSVRows(content)
        guard rows.count > 1 else {
            importError = String(localized: "File is empty or has no data rows.")
            return
        }

        let header = rows[0].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        let colWord = header.firstIndex(of: "word")
            ?? header.firstIndex(of: "front")
            ?? header.firstIndex(of: "term")
        let colTranslation = header.firstIndex(of: "translation")
            ?? header.firstIndex(of: "back")
            ?? header.firstIndex(of: "definition")
        let colType = header.firstIndex(of: "type")
        let colTag = header.firstIndex(of: "tag")
        let colComment = header.firstIndex(of: "comment")
        let colExample = header.firstIndex(of: "example")
        let colExplanation = header.firstIndex(of: "explanation")
        let colBreakdown = header.firstIndex(of: "breakdown")
        let colTranscription = header.firstIndex(of: "transcription")
        let colFromLang = header.firstIndex(of: "from language")
        let colToLang = header.firstIndex(of: "to language")
        let colDate = header.firstIndex(of: "date added")
        let colEase = header.firstIndex(of: "ease factor")
        let colInterval = header.firstIndex(of: "interval days")
        let colReps = header.firstIndex(of: "repetitions")
        let colLapses = header.firstIndex(of: "lapses")
        let colDue = header.firstIndex(of: "due date")
        let colIntroduced = header.firstIndex(of: "introduced")

        guard let colWord else {
            importError = String(localized: "Need a column named \"Word\" (or Front / Term).")
            return
        }

        let df = DateFormatting.dayFormatter

        let existingWords = Set(store.words.map { $0.word.lowercased() })
        var count = 0

        func field(at col: Int?, in row: [String]) -> String? {
            guard let col, col < row.count else { return nil }
            let value = row[col].trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }

        for row in rows.dropFirst() {
            guard row.count > colWord else { continue }
            let wordText = row[colWord].trimmingCharacters(in: .whitespaces)
            guard !wordText.isEmpty else { continue }
            guard !existingWords.contains(wordText.lowercased()) else { continue }

            let date: Date = {
                if let ci = colDate, ci < row.count {
                    return df.date(from: row[ci].trimmingCharacters(in: .whitespaces)) ?? Date()
                }
                return Date()
            }()

            let importedTranslation = field(at: colTranslation, in: row)
            let importedExample = field(at: colExample, in: row)
            let ease = Double(field(at: colEase, in: row) ?? "") ?? 2.5
            let interval = Int(field(at: colInterval, in: row) ?? "") ?? 0
            let reps = Int(field(at: colReps, in: row) ?? "") ?? 0
            let lapses = Int(field(at: colLapses, in: row) ?? "") ?? 0
            let dueDate = field(at: colDue, in: row).flatMap { df.date(from: $0) }
            let introducedFlag = (field(at: colIntroduced, in: row)?.lowercased() == "true")
                || reps > 0 || interval > 0 || dueDate != nil

            let newWord = StoredWord(
                word: wordText,
                type: field(at: colType, in: row) ?? "word",
                translation: importedTranslation,
                example: importedExample,
                explanation: field(at: colExplanation, in: row),
                breakdown: field(at: colBreakdown, in: row),
                transcription: field(at: colTranscription, in: row),
                comment: field(at: colComment, in: row),
                tag: field(at: colTag, in: row),
                dateAdded: date,
                fromLanguage: field(at: colFromLang, in: row) ?? languageStore.nativeLanguage,
                toLanguage: field(at: colToLang, in: row) ?? languageStore.learningLanguage,
                easeFactor: ease,
                intervalDays: interval,
                repetitions: reps,
                lapses: lapses,
                dueDate: dueDate,
                needsEnrichment: importedTranslation == nil,
                examples: importedExample != nil ? [importedExample!] : [],
                introduced: introducedFlag
            )
            store.add(newWord)
            count += 1
        }

        importedCount = count
        if count > 0 {
            NotificationCenter.default.post(name: .triggerEnrichment, object: nil)
        }
    }

    private func parseCSVRows(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var inQuotes = false
        var i = text.startIndex

        while i < text.endIndex {
            let ch = text[i]

            if inQuotes {
                if ch == "\"" {
                    let next = text.index(after: i)
                    if next < text.endIndex && text[next] == "\"" {
                        currentField.append("\"")
                        i = text.index(after: next)
                    } else {
                        inQuotes = false
                        i = text.index(after: i)
                    }
                } else {
                    currentField.append(ch)
                    i = text.index(after: i)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                    i = text.index(after: i)
                } else if ch == "," {
                    currentRow.append(currentField)
                    currentField = ""
                    i = text.index(after: i)
                } else if ch == "\r" || ch == "\n" {
                    if ch == "\r" {
                        let next = text.index(after: i)
                        if next < text.endIndex && text[next] == "\n" {
                            i = text.index(after: next)
                        } else {
                            i = text.index(after: i)
                        }
                    } else {
                        i = text.index(after: i)
                    }
                    currentRow.append(currentField)
                    currentField = ""
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                } else {
                    currentField.append(ch)
                    i = text.index(after: i)
                }
            }
        }

        currentRow.append(currentField)
        if !currentRow.allSatisfy({ $0.isEmpty }) {
            rows.append(currentRow)
        }

        return rows
    }
}

#Preview {
    NavigationStack {
        DictionarySettingsView()
    }
    .environmentObject(WordsStore())
    .environmentObject(LanguageStore())
    .environmentObject(ThemeStore())
}
