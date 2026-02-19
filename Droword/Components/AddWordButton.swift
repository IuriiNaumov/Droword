import SwiftUI

struct AddWordButton: View {
    let title: String
    let isDisabled: Bool
    let action: () async throws -> Void
    var onSuccess: (() -> Void)? = nil
    var onError: ((Error) -> Void)? = nil

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isPressed = false
    @Namespace private var buttonNamespace

    var body: some View {
        VStack(spacing: 8) {

            Button {
                if !isLoading && !isDisabled {
                    Task { await performAction() }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(
                            isDisabled
                            ? LinearGradient(
                                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                gradient: Gradient(colors: [Color(.addButton), Color(.addButton).opacity(0.85)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(isPressed ? Color.white.opacity(0.35) : Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color(.addButton).opacity(isPressed ? 0.25 : 0.15), radius: isPressed ? 16 : 10, x: 0, y: isPressed ? 8 : 6)

                    if isLoading {
                        Loader()
                            .matchedGeometryEffect(id: "loader", in: buttonNamespace)
                            .transition(.opacity)
                    } else {
                        Text(title)
                            .font(.custom("Poppins-Medium", size: 20))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.35), radius: 1, x: 0, y: 1)
                            .matchedGeometryEffect(id: "title", in: buttonNamespace)
                            .transition(.opacity)
                    }
                }
                .frame(height: 60)
                .padding(.vertical, 20)
                .padding(.horizontal, 10)
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.1), value: isPressed)
            }
            .disabled(isDisabled || isLoading)
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed && !isLoading && !isDisabled {
                            isPressed = true
                            DispatchQueue.main.async {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                    .onEnded { _ in
                        if isPressed {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isPressed = false
                            }
                        }
                    }
            )

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
            DispatchQueue.main.async {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            onSuccess?()
        } catch {
            DispatchQueue.main.async {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
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
