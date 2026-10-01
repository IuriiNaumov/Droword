import UIKit

enum MenuBarIcons {
    private static var cache: [String: UIImage] = [:]
    private static let lock = NSLock()

    static func image(for tab: HomeView.Tab, selected: Bool) -> UIImage {
        let key = "\(tab.rawValue)-\(selected)"
        lock.lock()
        defer { lock.unlock() }
        if let image = cache[key] { return image }

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let image = UIGraphicsImageRenderer(
            size: CGSize(width: 28, height: 28),
            format: format
        ).image { _ in
            let path: UIBezierPath
            switch tab {
            case .home: path = homePath()
            case .list: path = dictionaryPath()
            case .practice: path = practicePath()
            case .add: path = addPath()
            }
            path.lineWidth = selected ? 2.6 : 2.2
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            UIColor.black.setStroke()
            path.stroke()
        }
        .withRenderingMode(.alwaysTemplate)

        cache[key] = image
        return image
    }

    private static func homePath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 4.8, y: 13))
        path.addCurve(
            to: CGPoint(x: 6.4, y: 9.8),
            controlPoint1: CGPoint(x: 4.8, y: 11.8),
            controlPoint2: CGPoint(x: 5.4, y: 10.6)
        )
        path.addLine(to: CGPoint(x: 11.6, y: 5.4))
        path.addCurve(
            to: CGPoint(x: 16.4, y: 5.4),
            controlPoint1: CGPoint(x: 12.9, y: 4.1),
            controlPoint2: CGPoint(x: 15.1, y: 4.1)
        )
        path.addLine(to: CGPoint(x: 21.6, y: 9.8))
        path.addCurve(
            to: CGPoint(x: 23.2, y: 13),
            controlPoint1: CGPoint(x: 22.6, y: 10.6),
            controlPoint2: CGPoint(x: 23.2, y: 11.8)
        )
        path.addLine(to: CGPoint(x: 23.2, y: 20.4))
        path.addCurve(
            to: CGPoint(x: 20.4, y: 23.2),
            controlPoint1: CGPoint(x: 23.2, y: 22.1),
            controlPoint2: CGPoint(x: 22.1, y: 23.2)
        )
        path.addLine(to: CGPoint(x: 7.6, y: 23.2))
        path.addCurve(
            to: CGPoint(x: 4.8, y: 20.4),
            controlPoint1: CGPoint(x: 5.9, y: 23.2),
            controlPoint2: CGPoint(x: 4.8, y: 22.1)
        )
        path.close()
        path.move(to: CGPoint(x: 10.8, y: 23.2))
        path.addLine(to: CGPoint(x: 10.8, y: 17.6))
        path.addCurve(
            to: CGPoint(x: 17.2, y: 17.6),
            controlPoint1: CGPoint(x: 12, y: 15.2),
            controlPoint2: CGPoint(x: 16, y: 15.2)
        )
        path.addLine(to: CGPoint(x: 17.2, y: 23.2))
        return path
    }

    private static func dictionaryPath() -> UIBezierPath {
        let path = UIBezierPath(
            roundedRect: CGRect(x: 5.4, y: 3.6, width: 17.2, height: 20.8),
            cornerRadius: 5
        )
        path.move(to: CGPoint(x: 9.2, y: 10.4))
        path.addLine(to: CGPoint(x: 18.8, y: 10.4))
        path.move(to: CGPoint(x: 9.2, y: 14.4))
        path.addLine(to: CGPoint(x: 18.8, y: 14.4))
        path.move(to: CGPoint(x: 9.2, y: 18.4))
        path.addLine(to: CGPoint(x: 15.8, y: 18.4))
        return path
    }

    private static func practicePath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 10.5, y: 19.2))
        path.addCurve(
            to: CGPoint(x: 8.4, y: 16),
            controlPoint1: CGPoint(x: 10.5, y: 17.9),
            controlPoint2: CGPoint(x: 9.4, y: 17)
        )
        path.addCurve(
            to: CGPoint(x: 6.8, y: 11.2),
            controlPoint1: CGPoint(x: 7.3, y: 14.7),
            controlPoint2: CGPoint(x: 6.8, y: 13.1)
        )
        path.addCurve(
            to: CGPoint(x: 14, y: 4),
            controlPoint1: CGPoint(x: 6.8, y: 7.2),
            controlPoint2: CGPoint(x: 10, y: 4)
        )
        path.addCurve(
            to: CGPoint(x: 21.2, y: 11.2),
            controlPoint1: CGPoint(x: 18, y: 4),
            controlPoint2: CGPoint(x: 21.2, y: 7.2)
        )
        path.addCurve(
            to: CGPoint(x: 19.6, y: 16),
            controlPoint1: CGPoint(x: 21.2, y: 13.1),
            controlPoint2: CGPoint(x: 20.7, y: 14.7)
        )
        path.addCurve(
            to: CGPoint(x: 17.5, y: 19.2),
            controlPoint1: CGPoint(x: 18.6, y: 17),
            controlPoint2: CGPoint(x: 17.5, y: 17.9)
        )
        path.move(to: CGPoint(x: 10.5, y: 21.2))
        path.addLine(to: CGPoint(x: 17.5, y: 21.2))
        path.move(to: CGPoint(x: 11.7, y: 24))
        path.addLine(to: CGPoint(x: 16.3, y: 24))
        return path
    }

    private static func addPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 6, y: 14))
        path.addLine(to: CGPoint(x: 22, y: 14))
        path.move(to: CGPoint(x: 14, y: 6))
        path.addLine(to: CGPoint(x: 14, y: 22))
        return path
    }
}
