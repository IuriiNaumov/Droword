import SwiftUI

enum AppToastType {
    case success
    case error
    
    var background: Color {
        switch self {
        case .success:
            return Color.iKnowButton
        case .error:
            return Color.iDontKnowButton
        }
    }
    
    var textColor: Color {
        switch self {
        case .success:
            return darkerShade(of: Color.iKnowButton, by: 0.4)
        case .error:
            return darkerShade(of: Color.iDontKnowButton, by: 0.4)
        }
    }
    
    var text: String {
        switch self {
        case .success:
            return "Saved."
        case .error:
            return "Oops! Something went wrong."
        }
    }
}

struct AppToastView: View {
    
    let type: AppToastType
    let message: String?
    var duration: Double = 2.5
    
    @State private var isVisible = false
    
    var body: some View {
        VStack {
            if isVisible {
                HStack(spacing: 10) {
                    
                    Image(systemName: type == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(type.textColor)
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(message ?? type.text)
                        .font(.custom("Poppins-Medium", size: 15))
                        .foregroundColor(type.textColor)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(type.background)
                )
                .padding(.top, 20)
                .transition(
                    .move(edge: .top)
                    .combined(with: .opacity)
                )
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                isVisible = false
            }
        }
    }
}

#Preview {
    Group {
        
        VStack(spacing: 30) {
            Text("Light Mode")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(Color("MainBlack"))
            
            AppToastView(type: .success, message: nil)
            AppToastView(type: .error, message: nil)
        }
        .padding(.top, 40)
        .background(Color(hexRGB: 0xFFF8E7))
        .preferredColorScheme(.light)
        
        
        VStack(spacing: 30) {
            Text("Dark Mode")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.white)
            
            AppToastView(type: .success, message: nil)
            AppToastView(type: .error, message: nil)
        }
        .padding(.top, 40)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
