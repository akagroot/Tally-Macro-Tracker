import Foundation

/// One saved item inside a template's `items` JSONB column. References, not frozen macros —
/// re-applying a template always pulls current food data, the same deliberate choice the
/// prototype made (see schema.sql).
struct TemplateItem: Codable, Hashable {
    var foodId: String
    var variantId: String?
    var qty: Double
    var unitKey: String
}

/// Mirrors `meal_templates`.
struct MealTemplate: Codable, Identifiable, Hashable {
    let id: UUID
    var userId: UUID
    var name: String
    var items: [TemplateItem]
    var createdAt: Date?
}
