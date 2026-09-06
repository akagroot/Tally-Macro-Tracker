import Foundation

/// Mirrors the `foods` table (see supabase/schema.sql). Macro fields are "per one native unit"
/// (or per labeled serving for item_mode foods) — never per gram — matching the prototype's
/// quickFoodDef() convention exactly. Calories are always derived, never stored.
struct Food: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var emoji: String
    var isCustom: Bool

    var unit: String?
    var pluralize: Bool
    var step: Double?
    var btnStep: Double?
    var minQty: Double?
    var maxQty: Double?
    var defaultQty: Double?
    var gramsPerUnit: Double?

    var nativeIsOz: Bool
    var pickRequired: Bool

    var itemMode: Bool
    var itemsPerServing: Double?
    var itemName: String?

    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    var macroTag: String
    var mealTags: [String]
    var defaultVariantId: String?

    var lastUsedAt: Date?
    var createdAt: Date?

    /// protein*4 + carbs*4 + fat*9 — keep this identical to schema.sql's comment and the
    /// prototype's kcal() helper. Never store calories directly.
    var calories: Double { proteinG * 4 + carbsG * 4 + fatG * 9 }
}
