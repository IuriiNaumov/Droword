import SwiftUI

struct ContentView: View {
    @StateObject private var store = WordsStore()

    var body: some View {
        HomeView()
            .environmentObject(store)
    }
}

#Preview {
    ContentView()
}
