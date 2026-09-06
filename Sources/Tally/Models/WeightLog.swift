import Foundation

/// Mirrors `weight_log` — one row per (user, day).
struct WeightLog: Codable, Identifiable, Hashable {
    var userId: UUID
    var logDate: String
    var lbs: Double

    var id: String { "\(userId)_\(logDate)" }
}
