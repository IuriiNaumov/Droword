import SwiftUI

struct AddWordButton: View {
    let title: String
    let isDisabled: Bool
    let action: () async throws -> Void
    var onSuccess: (() -> Void)? = nil
    var onError: ((Error) -> Void)? = nil

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
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .transition(.opacity)
                    } else {
                        Text(title)
                            .font(.custom("Poppins-Bold", size: 17))
                            .foregroundColor(.white)
                            .transition(.opacity)
                    }
                }
                .duo3DStyle(Color.accentGreen, isDisabled: isDisabled)
            }
            .disabled(isDisabled || isLoading)
            .buttonStyle(.plain)

            if let message = errorMessage {
                Text(message)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(Color.mainGrey)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: errorMessage)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
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
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
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
                    errorMessage = "The request took too long. Please try again."
                } else {
                    errorMessage = "Something went wrong. Try again."
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
    .background(Color.appBackground)
}
