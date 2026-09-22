import SwiftUI

enum ModalIconKind: String, CaseIterable, Identifiable {
    case trash
    case warning
    case success
    case offline
    case duplicate
    case idea
    case celebrate

    var id: String { rawValue }

    var systemName: String {
        switch self {
        case .trash: return "trash.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .offline: return "wifi.slash"
        case .duplicate: return "doc.on.doc.fill"
        case .idea: return "lightbulb.fill"
        case .celebrate: return "star.fill"
        }
    }

    static func from(systemName: String) -> ModalIconKind {
        switch systemName {
        case "trash", "trash.fill": return .trash
        case "exclamationmark.triangle.fill", "exclamationmark.triangle": return .warning
        case "checkmark.circle.fill", "checkmark.circle", "checkmark": return .success
        case "wifi.slash": return .offline
        case "doc.on.doc", "doc.on.doc.fill": return .duplicate
        case "lightbulb", "lightbulb.fill": return .idea
        default:
            if systemName.contains("trash") { return .trash }
            if systemName.contains("wifi") { return .offline }
            if systemName.contains("check") { return .success }
            if systemName.contains("exclamation") { return .warning }
            return .warning
        }
    }
}

struct ModalIconView: View {
    let kind: ModalIconKind
    var color: Color
    var size: CGFloat = 88

    var body: some View {
        Image(systemName: kind.systemName)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size * 0.55, height: size * 0.55)
            .accessibilityHidden(true)
    }
}

#Preview("Modal icons") {
    HStack(spacing: 20) {
        ForEach(ModalIconKind.allCases) { kind in
            VStack {
                ModalIconView(kind: kind, color: .orange, size: 72)
                Text(kind.rawValue).font(.caption2)
            }
        }
    }
    .padding()
}
