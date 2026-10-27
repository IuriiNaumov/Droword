import SwiftUI

struct AddPlusIcon: View {
    var size: CGFloat = 14

    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: size, weight: .bold))
    }
}

#Preview {
    AddPlusIcon()
        .padding()
}
