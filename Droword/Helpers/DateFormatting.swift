import Foundation

enum DateFormatting {
    static let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    static var todayString: String {
        dayFormatter.string(from: Date())
    }
}
