import Foundation

/// Mirrors `food_variants`. Any field left nil here means "inherit from the parent Food" —
/// matches unitDefFor()'s pick() fallback in the prototype exactly. Only merge these onto the
/// parent Food when resolving a display/quantity definition; never assume a variant is complete
/// on its own.
struct FoodVariant: Codable, Identifiable, Hashable {
    let id: String
    var foodId: String
    var name: String

    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    var unit: String?
    var pluralize: Bool?
    var step: Double?
    var btnStep: Double?
    var minQty: Double?
    var maxQty: Double?
    var defaultQty: Double?
    var gramsPerUnit: Double?

    var sortOrder: Int
}
