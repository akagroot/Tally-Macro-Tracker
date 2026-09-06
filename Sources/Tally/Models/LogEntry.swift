import Foundation

enum Meal: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var displayName: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
}

/// Mirrors `log_entries`. Macros are snapshotted at log time (see schema.sql note #3) so
/// editing a food's catalog values later never rewrites history — logDate is a plain
/// "YYYY-MM-DD" string, same convention the prototype used for its day keys, to sidestep any
/// timezone ambiguity a real Date would introduce for a calendar-day concept.
struct LogEntry: Codable, Identifiable, Hashable {
    let id: UUID
    var userId: UUID
    var logDate: String
    var meal: Meal
    var foodId: String
    var variantId: String?
    var qty: Double
    var unitKey: String
    var unitLabel: String

    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    var sortOrder: Int
    var createdAt: Date?

    var calories: Double { proteinG * 4 + carbsG * 4 + fatG * 9 }
}

/// Insert payload — omits fields the database fills in (id, user_id default, created_at).
struct NewLogEntry: Codable {
    var logDate: String
    var meal: Meal
    var foodId: String
    var variantId: String?
    var qty: Double
    var unitKey: String
    var unitLabel: String
    var proteinG: Double
    var carbsG: Double
    var fatG: Double
    var sortOrder: Int
}
