import Foundation

/// Mirrors `user_settings` — a single row today (the hardcoded user in schema.sql).
struct UserSettings: Codable, Identifiable, Hashable {
    var userId: UUID
    var proteinTargetG: Double
    var carbsTargetG: Double
    var fatTargetG: Double
    var calorieTarget: Double
    var waterTargetOz: Double

    var id: UUID { userId }
}
