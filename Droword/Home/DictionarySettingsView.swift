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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Dictionary")
                    .sheetTitle()

                VStack(spacing: 0) {
                    settingsRow(icon: "square.and.arrow.up", color: themeStore.iconBlue, title: "Export Words") {
                        exportCSV()
                    }
                    settingsRow(icon: "square.and.arrow.down", color: themeStore.iconGreen, title: "Import Words") {
                        showImportPicker = true
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Works with exports from Anki, Quizlet, and any CSV or TXT file. Minimum: a column named \"Word\". Translations will be added automatically if missing.")
                    .font(themeStore.regular(13))
                    .foregroundColor(themeStore.secondaryText)
                    .padding(.horizontal, 4)
                    .padding(.top, -8)

                VStack(spacing: 0) {
                    settingsRow(icon: "trash.fill", color: Color.accentRed, title: "Clear \(store.words.count) words") {
                        store.clear()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            if case .success(let urls) = result, let url = urls.first {
                importCSV(from: url)
            }
        }
        .overlay {
            if let count = importedCount {
                CustomAlertView(
                    icon: "checkmark.circle.fill",
                    iconColor: themeStore.accentGreen,
                    title: "Import Complete",
                    message: "\(count) words imported successfully.",
                    primaryButton: .init(title: "OK", style: .primary) {
                        importedCount = nil
                    }
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }

    private func settingsRow(icon: String, color: Color, title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(themeStore.regular(16))
                    .foregroundColor(color == Color.accentRed ? Color.accentRed : .primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeStore.secondaryText.opacity(0.6))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(themeStore.cardBg)
        }
        .buttonStyle(.plain)
    }

    private func exportCSV() {
        let df = DateFormatting.dayFormatter

        var csv = "Word,Translation,Type,Tag,Comment,Example,Explanation,Breakdown,Transcription,From Language,To Language,Date Added\n"
        for w in store.words {
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
                df.string(from: w.dateAdded)
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
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        let rows = parseCSVRows(content)
        guard rows.count > 1 else { return }

        let header = rows[0].map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        let colWord = header.firstIndex(of: "word")
        let colTranslation = header.firstIndex(of: "translation")
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

        guard let colWord else { return }

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
                needsEnrichment: importedTranslation == nil,
                examples: importedExample != nil ? [importedExample!] : []
            )
            store.add(newWord)
            count += 1
        }

        importedCount = count
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
