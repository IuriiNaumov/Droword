import SwiftUI

struct AddWordButton: View {
    let title: String
    let isDisabled: Bool
    let action: () async throws -> Void
    var onSuccess: (() -> Void)? = nil
    var onError: ((Error) -> Void)? = nil

    @EnvironmentObject private var themeStore: ThemeStore
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 8) {
            Button {
                if !isLoading && !isDisabled {
                    Task { await performAction() }
                }
            } label: {
                ZStack {
                    Text(title)
                        .font(.custom("Poppins-Bold", size: 17))
                        .foregroundColor(.clear)

                    if isLoading {
                        LoadingStagesView()
                    } else {
                        Text(title)
                            .font(.custom("Poppins-Bold", size: 17))
                            .foregroundColor(.white)
                    }
                }

                .duo3DStyle(themeStore.mainAccentColor, isDisabled: isDisabled)
            }
            .disabled(isDisabled || isLoading)
            .buttonStyle(Duo3DButtonStyle())

            if let message = errorMessage {
                Text(message)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(themeStore.secondaryText)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: errorMessage)
    }

    private struct TimeoutError: Error {}

    private func runWithTimeout(seconds: Double, _ operation: @escaping () async throws -> Void) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            let _ = try await group.next()
            group.cancelAll()
        }
    }

    @MainActor
    private func performAction() async {
        guard !isLoading else { return }
        withAnimation(.easeInOut(duration: 0.2)) { isLoading = true }
        errorMessage = nil

        defer {
            withAnimation(.easeInOut(duration: 0.2)) { isLoading = false }
        }

        do {
            try await runWithTimeout(seconds: 20) {
                try await action()
            }
            Haptics.success()
            onSuccess?()
        } catch {
            Haptics.error()
            withAnimation {
                if (error as? TimeoutError) != nil {
                    errorMessage = String(localized: "The request took too long. Please try again.")
                } else {
                    errorMessage = String(localized: "Something went wrong. Try again.")
                }
            }
            onError?(error)
        }
    }
}

#Preview {
    VStack(spacing: 50) {
        AddWordButton(
            title: "Add Word",
            isDisabled: false
        ) { }

        AddWordButton(
            title: "Disabled",
            isDisabled: true
        ) { }
    }
    .padding()
    .background(Color("AppBackground"))
}
