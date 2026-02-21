import SwiftUI

struct DictionaryView: View {
    @EnvironmentObject private var store: WordsStore
    @State private var selectedTag: String? = nil
    @State private var isLoading = true

    @State private var cachedTag: String? = nil
    @State private var cachedWords: [StoredWord] = []
    @State private var cachedFiltered: [StoredWord] = []
    @State private var showAddTag = false

    private var filteredWords: [StoredWord] { cachedFiltered }
    private var horizontalPadding: CGFloat { 20 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Dictionary")
                    .font(.custom("Poppins-Bold", size: 38))
                    .foregroundColor(.mainBlack)
                    .padding(.top, 8)
                    .padding(.horizontal, horizontalPadding)

                TagsView(selectedTag: $selectedTag, onAddTag: { showAddTag = true })
                    .padding(.horizontal, horizontalPadding)

                LazyVStack(spacing: 8) {
                    if isLoading {
                        Skeleton()
                    } else if filteredWords.isEmpty {
                        VStack {
                            Spacer(minLength: 40)

                            VStack(spacing: 18) {
                                Text("Your word garden is waiting ❤️")
                                    .font(.title3.weight(.medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)

                                Text("Add a couple of words and I’ll keep them safe here. Little by little — you’ll see your vocabulary grow every day.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)

                                Text("Tip: pick words from movies, chats, or walks — that’s how learning feels alive.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 42)
                            }
                            .frame(maxWidth: .infinity)

                            Spacer(minLength: 100)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 360)
                    } else {
                        ForEach(filteredWords) { word in
                            WordCardView(
                                word: word.word,
                                translation: word.translation,
                                type: word.type,
                                example: word.example,
                                transcription: word.transcription,
                                comment: word.comment, explanation: word.explanation,
                                breakdown: word.breakdown,
                                tag: word.tag
                            ) {
                                store.remove(word)
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.appBackground))
        .sheet(isPresented: $showAddTag) {
            AddTagView()
                .presentationDetents([.fraction(0.5)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            recalculateFiltered()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isLoading = false
                }
            }
        }
        .onChange(of: selectedTag) { _ in recalculateFiltered() }
        .onChange(of: store.words) { _ in recalculateFiltered() }
        .animation(.spring(), value: store.words.count)
    }

    private func recalculateFiltered() {
        let tag = selectedTag?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if tag == cachedTag, store.words == cachedWords { return }

        if tag.isEmpty {
            cachedFiltered = Array(store.words.reversed())
        } else {
            cachedFiltered = Array(store.words.filter {
                ($0.tag ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == tag.lowercased()
            }.reversed())
        }
        cachedTag = tag
        cachedWords = store.words
    }
}

#Preview {
    DictionaryView()
        .environmentObject(WordsStore())
}
