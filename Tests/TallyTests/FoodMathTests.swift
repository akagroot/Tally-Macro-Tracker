import XCTest
@testable import Tally

/// Pins FoodMath's output to values already verified live against the running app and the
/// original HTML prototype (see the food-picker screenshots earlier in the project). If one of
/// these ever fails after an edit to FoodMath, the fix is almost always to make FoodMath match
/// the prototype again, not to update the expectation.
final class FoodMathTests: XCTestCase {

    private func makeFood(
        id: String, name: String = "", emoji: String = "🍽️", isCustom: Bool = false, unit: String? = nil,
        pluralize: Bool = false, step: Double? = nil, minQty: Double? = nil, maxQty: Double? = nil,
        defaultQty: Double? = nil, gramsPerUnit: Double? = nil, nativeIsOz: Bool = false,
        pickRequired: Bool = false, itemMode: Bool = false, itemsPerServing: Double? = nil,
        itemName: String? = nil, p: Double, c: Double, f: Double
    ) -> Food {
        Food(
            id: id, name: name, emoji: emoji, isCustom: isCustom, unit: unit, pluralize: pluralize,
            step: step, btnStep: step, minQty: minQty, maxQty: maxQty, defaultQty: defaultQty,
            gramsPerUnit: gramsPerUnit, nativeIsOz: nativeIsOz, pickRequired: pickRequired,
            itemMode: itemMode, itemsPerServing: itemsPerServing, itemName: itemName,
            proteinG: p, carbsG: c, fatG: f, macroTag: "other", mealTags: [],
            defaultVariantId: nil, lastUsedAt: nil, createdAt: nil
        )
    }

    // MARK: - Simple whole-item food (Egg): 2 eggs = 143 cal, matches the seeded Home screenshot.

    func testEggTwoServings() {
        let egg = makeFood(id: "egg", unit: "egg", pluralize: true, step: 1, minQty: 1, maxQty: 6, defaultQty: 1, gramsPerUnit: 50, p: 6, c: 0.6, f: 5)
        let def = FoodMath.resolve(food: egg, variant: nil)
        XCTAssertEqual(def.unitKey, "native")
        let m = def.macros(for: 2)
        XCTAssertEqual(m.protein, 12, accuracy: 0.001)
        XCTAssertEqual(m.calories, 143, accuracy: 0.5) // 12*4 + 1.2*4 + 10*9 = 142.8 → rounds to 143
        XCTAssertEqual(def.unitLabel(for: 2), "eggs")
        XCTAssertEqual(def.unitLabel(for: 1), "egg")
    }

    // MARK: - Fractional-unit food (Avocado): 1 half = 120 cal, matches the seeded screenshot.

    func testAvocadoOneHalf() {
        let avocado = makeFood(id: "avocado", unit: "half", step: 1, minQty: 1, maxQty: 4, defaultQty: 1, gramsPerUnit: 65, p: 1.5, c: 6, f: 10)
        let def = FoodMath.resolve(food: avocado, variant: nil)
        let m = def.macros(for: 1)
        XCTAssertEqual(m.calories, 120, accuracy: 0.001) // 1.5*4 + 6*4 + 10*9 = 120 exactly
    }

    // MARK: - nativeIsOz + variant (Chicken Breast): confirms oz-collapse and variant override.

    func testChickenBreastCollapsesToOzAndScales() {
        let chicken = makeFood(id: "chicken", unit: "oz", step: 1, minQty: 1, maxQty: 12, defaultQty: 4, gramsPerUnit: 28.35, nativeIsOz: true, pickRequired: true, p: 9, c: 0, f: 1)
        let breast = FoodVariant(id: "chicken-breast", foodId: "chicken", name: "Chicken Breast", proteinG: 9, carbsG: 0, fatG: 1, unit: nil, pluralize: nil, step: nil, btnStep: nil, minQty: nil, maxQty: nil, defaultQty: nil, gramsPerUnit: nil, sortOrder: 1)
        let def = FoodMath.resolve(food: chicken, variant: breast)
        XCTAssertEqual(def.unitKey, "oz", "nativeIsOz foods must collapse straight to the oz unit key")
        XCTAssertEqual(def.unitOptions, ["oz", "g"], "oz-native foods never offer a separate native pill")
        let m = def.macros(for: 4)
        XCTAssertEqual(m.protein, 36, accuracy: 0.001) // matches the seeded lunch entry: 4oz breast = 36g protein
        XCTAssertEqual(m.fat, 4, accuracy: 0.001)
    }

    // MARK: - Variant with its own unit override (Pretzels): the exact bug fixed earlier in the
    // prototype — switching from an oz-measured cut to a whole-item cut must reset the unit,
    // not keep showing "oz" for a food now measured in pretzels.

    func testPretzelVariantUnitOverride() {
        let pretzels = makeFood(id: "pretzels", unit: "oz", step: 0.5, minQty: 0.5, maxQty: 4, defaultQty: 1, gramsPerUnit: 28.35, pickRequired: true, p: 3.5, c: 22, f: 1)
        let hard = FoodVariant(id: "pretzel-hard", foodId: "pretzels", name: "Hard Pretzels", proteinG: 3.5, carbsG: 22, fatG: 1, unit: nil, pluralize: nil, step: nil, btnStep: nil, minQty: nil, maxQty: nil, defaultQty: nil, gramsPerUnit: nil, sortOrder: 0)
        let soft = FoodVariant(id: "pretzel-soft", foodId: "pretzels", name: "Soft Pretzel", proteinG: 9, carbsG: 72, fatG: 2, unit: "pretzel", pluralize: true, step: 1, btnStep: 1, minQty: 1, maxQty: 3, defaultQty: 1, gramsPerUnit: 120, sortOrder: 1)

        let hardDef = FoodMath.resolve(food: pretzels, variant: hard)
        XCTAssertEqual(hardDef.unit, "oz", "hard pretzels inherit the parent food's oz unit")

        let softDef = FoodMath.resolve(food: pretzels, variant: soft)
        XCTAssertEqual(softDef.unit, "pretzel", "soft pretzel overrides to its own whole-item unit")
        XCTAssertEqual(softDef.unitOptions, ["native", "oz", "g"], "a non-oz variant unit must NOT collapse to the oz-only pill set")
        let m = softDef.macros(for: 1)
        let expectedCalories: Double = 342 // 9*4 + 72*4 + 2*9 = 36 + 288 + 18
        XCTAssertEqual(m.calories, expectedCalories, accuracy: 0.001)
    }

    // MARK: - Item-mode food (Oreos): macros are per labeled serving, logged per individual piece.

    func testOreosPerCookie() {
        let oreos = makeFood(id: "oreos", itemMode: true, itemsPerServing: 3, itemName: "cookie", p: 1, c: 25, f: 7)
        let def = FoodMath.resolve(food: oreos, variant: nil)
        XCTAssertEqual(def.unit, "cookie")
        XCTAssertEqual(def.proteinG, 1.0 / 3.0, accuracy: 0.0001)
        let m = def.macros(for: 3)
        let expectedCalories: Double = 167 // 1*4 + 25*4 + 7*9
        XCTAssertEqual(m.calories, expectedCalories, accuracy: 0.01, "3 cookies should equal exactly one labeled serving")
    }

    // MARK: - Custom foods never offer an oz/g toggle (no real gramsPerUnit backs a
    // user-defined "serving", so a gram conversion would be meaningless).

    func testCustomFoodHasNoOzGramToggle() {
        let custom = makeFood(id: "custom-1", isCustom: true, unit: "serving", pluralize: true, step: 0.5, minQty: 0.5, maxQty: 4, defaultQty: 1, p: 20, c: 10, f: 5)
        let def = FoodMath.resolve(food: custom, variant: nil)
        XCTAssertEqual(def.unitOptions, ["native"], "custom foods must never show an oz/g pill")
        XCTAssertEqual(def.unitKey, "native")
        let m = def.macros(for: 1)
        let expectedCalories: Double = 165 // 20*4 + 10*4 + 5*9
        XCTAssertEqual(m.calories, expectedCalories, accuracy: 0.001)
    }

    // MARK: - switchUnit keeps the physical serving constant across a unit change.

    func testSwitchUnitPreservesPhysicalAmount() {
        let almonds = makeFood(id: "almonds", unit: "oz", step: 0.5, minQty: 0.5, maxQty: 4, defaultQty: 1, gramsPerUnit: 28.35, nativeIsOz: true, p: 6, c: 6, f: 13)
        let ozDef = FoodMath.resolve(food: almonds, variant: nil)
        let (gDef, gQty) = FoodMath.switchUnit(food: almonds, variant: nil, currentDef: ozDef, currentQty: 1, newKey: "g")
        XCTAssertEqual(gDef.unit, "g")
        XCTAssertEqual(gQty, 30, accuracy: 0.001, "1 oz (~28.35g) should round to the nearest 5g step (30g)")
    }
}
