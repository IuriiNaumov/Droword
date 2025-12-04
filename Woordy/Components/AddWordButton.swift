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
                    RoundedRectangle(cornerRadius: 50)
                        .fill(isDisabled ? Color.gray.opacity(0.4) : Color(.addButton))

                    if isLoading {
                        Loader()
                    } else {
                        Text(title)
                            .font(.custom("Poppins-Medium", size: 20))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.4), radius: 1, x: 0, y: 1)
                    }
                }
                .frame(height: 60)                 // ← фиксированная высота кнопки
                .padding(.vertical, 20)            // ← твой padding 20px
                .padding(.horizontal, 10)
                .scaleEffect(isLoading ? 0.98 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isLoading)
            }
            .disabled(isDisabled || isLoading)
            .buttonStyle(.plain)

            if let message = errorMessage {
                Text(message)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(Color(.mainGrey))
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
    .background(Color(hexRGB: 0xFFF8E7))
}
