import SwiftUI

struct ActionButton: View {
    let title: String
    let color: Color
    let action: () async throws -> Void
    var onSuccess: (() -> Void)? = nil
    var onError: ((Error) -> Void)? = nil

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 6) {
            Button {
                if !isLoading {
                    Task { await performAction() }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(color)
                        .frame(height: 58)
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 3)

                    if isLoading {
                        Loader()
                    } else {
                        Text(title)
                            .font(.custom("Poppins-Medium", size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.7 : 1)
            .animation(.easeInOut(duration: 0.25), value: isLoading)

            if let message = errorMessage {
                Text(message)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: errorMessage)
    }

    private func performAction() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            try await action()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onSuccess?()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation {
                errorMessage = "Something went wrong. Try again."
            }
            onError?(error)
        }

        isLoading = false
    }
}
