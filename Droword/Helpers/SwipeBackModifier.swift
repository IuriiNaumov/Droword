import SwiftUI

struct SwipeBackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(SwipeBackHelper())
    }
}

extension View {
    func enableSwipeBack() -> some View {
        modifier(SwipeBackModifier())
    }
}

private struct SwipeBackHelper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SwipeBackViewController {
        SwipeBackViewController()
    }

    func updateUIViewController(_ uiViewController: SwipeBackViewController, context: Context) {}
}

private final class SwipeBackViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
}
