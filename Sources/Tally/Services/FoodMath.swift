import Foundation

/// A fully-resolved "how to log this food right now" definition — the Swift equivalent of the
/// prototype's quickFoodDef() return value. Everything here is already scaled to `unit`;
/// multiply by a chosen quantity to get final macros.
struct ResolvedFoodDef {
    var foodId: String
    var genericName: String
    var name: String
    var emoji: String

    var unitKey: String          // "native" | "oz" | "g"
    var unitOptions: [String]
    var unit: String
    var pluralize: Bool

    var step: Double
    var btnStep: Double
    var minQty: Double
    var maxQty: Double
    var defaultQty: Double

    /// Macros per ONE of `unit` at this unitKey (e.g. per oz, per egg, per bagel).
    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    var hasVariant: Bool
    var activeVariantId: String?
    var itemMode: Bool

    func unitLabel(for qty: Double) -> String {
        pluralize ? (qty == 1 ? unit : unit + "s") : unit
    }

    func macros(for qty: Double) -> (protein: Double, carbs: Double, fat: Double, calories: Double) {
        let p = proteinG * qty, c = carbsG * qty, f = fatG * qty
        return (p, c, f, p * 4 + c * 4 + f * 9)
    }
}

/// Faithful port of the HTML prototype's unitOptionsFor / unitDefFor / quickFoodDef. Keep this
/// in lockstep with that logic if the prototype ever changes — the whole point of porting is
/// that these numbers must never silently drift from what was already tested in the browser.
enum FoodMath {
    static let ozGrams = 28.3495

    /// A variant whose own unit override happens to equal "oz" collapses the same way
    /// nativeIsOz foods do — no point showing both a "native" pill and an "oz" pill when
    /// they're identical.
    static func unitOptions(food: Food, variant: FoodVariant?) -> [String] {
        let nativeUnit = variant?.unit ?? food.unit
        return (food.nativeIsOz || nativeUnit == "oz") ? ["oz", "g"] : ["native", "oz", "g"]
    }

    private struct UnitDef {
        var unit: String
        var pluralize: Bool
        var step: Double
        var btnStep: Double
        var minQty: Double
        var maxQty: Double
        var gramsPerUnit: Double
    }

    private static func unitDef(food: Food, key: String, variant: FoodVariant?) -> UnitDef {
        switch key {
        case "oz":
            let maxQty = max(8, ((food.gramsPerUnit ?? 0) * 4 / ozGrams).rounded(.up))
            return UnitDef(unit: "oz", pluralize: false, step: 0.5, btnStep: 0.5, minQty: 0.5, maxQty: maxQty, gramsPerUnit: ozGrams)
        case "g":
            let stepped = (((food.gramsPerUnit ?? 0) * 4 / 5).rounded()) * 5
            let maxQty = max(150, stepped)
            return UnitDef(unit: "g", pluralize: false, step: 5, btnStep: 5, minQty: 5, maxQty: maxQty, gramsPerUnit: 1)
        default: // "native" — any field a variant doesn't set falls back to the parent food's.
            return UnitDef(
                unit: variant?.unit ?? food.unit ?? "",
                pluralize: variant?.pluralize ?? food.pluralize,
                step: variant?.step ?? food.step ?? 1,
                btnStep: variant?.btnStep ?? food.btnStep ?? (variant?.step ?? food.step ?? 1),
                minQty: variant?.minQty ?? food.minQty ?? (variant?.step ?? food.step ?? 1),
                maxQty: variant?.maxQty ?? food.maxQty ?? 10,
                gramsPerUnit: variant?.gramsPerUnit ?? food.gramsPerUnit ?? 1
            )
        }
    }

    /// unitKey: pass nil to use the food's natural default (native, unless it collapses to oz).
    static func resolve(food: Food, variant: FoodVariant?, unitKey: String? = nil) -> ResolvedFoodDef {
        let baseP = variant?.proteinG ?? food.proteinG
        let baseC = variant?.carbsG ?? food.carbsG
        let baseF = variant?.fatG ?? food.fatG

        // Item-count foods (Oreos, Chips Ahoy): macros are entered per labeled serving, but you
        // log by individual piece. No oz/g swap — counting pieces IS the measurement.
        if food.itemMode {
            let itemsPerServing = food.itemsPerServing ?? 1
            return ResolvedFoodDef(
                foodId: food.id, genericName: food.name, name: variant?.name ?? food.name, emoji: food.emoji,
                unitKey: "native", unitOptions: ["native"],
                unit: food.itemName ?? "item", pluralize: true,
                step: 1, btnStep: 1, minQty: 1, maxQty: max(8, itemsPerServing * 4), defaultQty: 1,
                proteinG: baseP / itemsPerServing, carbsG: baseC / itemsPerServing, fatG: baseF / itemsPerServing,
                hasVariant: variant != nil, activeVariantId: variant?.id, itemMode: true
            )
        }

        let nativeUnitLabel = variant?.unit ?? food.unit
        let collapsedToOz = food.nativeIsOz || nativeUnitLabel == "oz"
        let key = unitKey ?? (collapsedToOz ? "oz" : "native")
        let ud = unitDef(food: food, key: key, variant: variant)

        // active p/c/f are always "per one native unit" for whichever cut is active — convert
        // through the NATIVE unit's own gramsPerUnit (which a variant may override), never oz/g's.
        let nativeGramsPerUnit = unitDef(food: food, key: "native", variant: variant).gramsPerUnit
        let perGramP = baseP / nativeGramsPerUnit
        let perGramC = baseC / nativeGramsPerUnit
        let perGramF = baseF / nativeGramsPerUnit

        let nativeDefaultQty = variant?.defaultQty ?? food.defaultQty ?? 1
        let defaultQty: Double = key == "native"
            ? nativeDefaultQty
            : (((nativeDefaultQty * nativeGramsPerUnit) / ud.gramsPerUnit) * 10).rounded() / 10

        return ResolvedFoodDef(
            foodId: food.id, genericName: food.name, name: variant?.name ?? food.name, emoji: food.emoji,
            unitKey: key, unitOptions: unitOptions(food: food, variant: variant),
            unit: ud.unit, pluralize: ud.pluralize,
            step: ud.step, btnStep: ud.btnStep, minQty: ud.minQty, maxQty: ud.maxQty, defaultQty: defaultQty,
            proteinG: perGramP * ud.gramsPerUnit, carbsG: perGramC * ud.gramsPerUnit, fatG: perGramF * ud.gramsPerUnit,
            hasVariant: variant != nil, activeVariantId: variant?.id, itemMode: false
        )
    }

    /// Re-resolves a def under a new unit key, converting the current quantity to the equivalent
    /// amount so the actual physical serving stays constant across the switch (mirrors switchUnit()).
    static func switchUnit(food: Food, variant: FoodVariant?, currentDef: ResolvedFoodDef, currentQty: Double, newKey: String) -> (def: ResolvedFoodDef, qty: Double) {
        let oldGramsPerUnit = unitDef(food: food, key: currentDef.unitKey, variant: variant).gramsPerUnit
        let grams = currentQty * oldGramsPerUnit
        let newDef = resolve(food: food, variant: variant, unitKey: newKey)
        let newGramsPerUnit = unitDef(food: food, key: newKey, variant: variant).gramsPerUnit
        let rawQty = grams / newGramsPerUnit
        let stepped = (rawQty / newDef.step).rounded() * newDef.step
        let qty = (min(max(stepped, newDef.minQty), newDef.maxQty) * 10).rounded() / 10
        return (newDef, qty)
    }
}
