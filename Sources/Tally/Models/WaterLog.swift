import Foundation

/// Mirrors `water_log` — one row per (user, day) holding a running total, edited directly
/// rather than itemized (matches the "Edit Water" screen's design: correct/reset a total,
/// not delete individual pours).
struct WaterLog: Codable, Identifiable, Hashable {
    var userId: UUID
    var logDate: String
    var oz: Double

    var id: String { "\(userId)_\(logDate)" }
}
