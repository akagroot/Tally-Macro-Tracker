import Foundation

/// "YYYY-MM-DD" day keys in the user's local calendar — same convention the prototype used
/// (dateKey/keyToDate/shiftKey), deliberately kept as plain strings rather than Date to avoid
/// any timezone ambiguity around what "today" means.
enum DateKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        return f
    }()

    static var today: String { formatter.string(from: Date()) }

    static func shift(_ key: String, byDays delta: Int) -> String {
        guard let date = formatter.date(from: key),
              let shifted = Calendar.current.date(byAdding: .day, value: delta, to: date) else {
            return key
        }
        return formatter.string(from: shifted)
    }

    static func friendly(_ key: String) -> String {
        if key == today { return "Today" }
        if key == shift(today, byDays: -1) { return "Yesterday" }
        if key == shift(today, byDays: 1) { return "Tomorrow" }
        guard let date = formatter.date(from: key) else { return key }
        let f = DateFormatter()
        f.dateStyle = .long
        f.setLocalizedDateFormatFromTemplate("EEEE MMMM d")
        return f.string(from: date)
    }
}
