import SwiftUI

struct MainView: View {
    @State private var selection = 0
    @State private var showAddWordView = false
    @AppStorage("lastActiveAt") private var lastActiveAt: Double = Date().timeIntervalSince1970

    @EnvironmentObject var golden: GoldenWordsStore
    @ObservedObject var store = WordsStore()

    var body: some View {
        TabView(selection: $selection) {
            DictionaryView()
                .tabItem {
                    Label("Words", systemImage: "list.bullet")
                }
                .tag(0)

            PracticeView()
                .tabItem {
                    Label("Quiz", systemImage: "pencil")
                }
                .tag(1)

            Text("Profile")
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .environmentObject(golden)
        .onAppear {
            // Update last active and schedule gentle inactivity reminders
            let last = Date(timeIntervalSince1970: lastActiveAt)
            NotificationManager.shared.scheduleInactivityReminders(lastActive: last)
            lastActiveAt = Date().timeIntervalSince1970
        }
        .sheet(isPresented: $showAddWordView) {
            AddWordView(store: store)
                .transaction { $0.disablesAnimations = true }
                .onDisappear { lastActiveAt = Date().timeIntervalSince1970 }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddWordView = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

