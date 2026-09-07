import Foundation
import Supabase

struct MacroTotals {
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0
    var calories: Double { proteinG * 4 + carbsG * 4 + fatG * 9 }

    static func += (lhs: inout MacroTotals, rhs: (protein: Double, carbs: Double, fat: Double, calories: Double)) {
        lhs.proteinG += rhs.protein
        lhs.carbsG += rhs.carbs
        lhs.fatG += rhs.fat
    }
}

/// The app's single in-memory data store. Supabase is the source of truth (see schema.sql) —
/// this just caches the current day's data plus the (rarely-changing) catalog so views don't
/// each fetch independently. No offline write-queue: a failed request surfaces `loadError` and
/// leaves local state untouched, matching the "thin cache, not full offline support" call made
/// earlier for v1.
@MainActor
@Observable
final class TallyStore {
    private(set) var foods: [Food] = []
    private(set) var variantsByFood: [String: [FoodVariant]] = [:]
    private(set) var settings = UserSettings(
        userId: SupabaseService.currentUserID,
        proteinTargetG: 180, carbsTargetG: 240, fatTargetG: 70, calorieTarget: 2310, waterTargetOz: 100
    )

    private(set) var currentDateKey = DateKey.today
    private(set) var logEntries: [LogEntry] = []
    private(set) var waterOz: Double = 0

    private(set) var isBootstrapping = false
    var loadError: String?

    private var client: SupabaseClient { SupabaseService.client }
    private var userID: UUID { SupabaseService.currentUserID }

    // MARK: - Loading

    func bootstrap() async {
        guard !isBootstrapping else { return }
        isBootstrapping = true
        defer { isBootstrapping = false }
        do {
            async let foodsTask: [Food] = client.from("foods").select().order("name").execute().value
            async let variantsTask: [FoodVariant] = client.from("food_variants").select().order("sort_order").execute().value
            async let settingsTask: [UserSettings] = client.from("user_settings").select().eq("user_id", value: userID).execute().value

            foods = try await foodsTask
            variantsByFood = Dictionary(grouping: try await variantsTask, by: \.foodId)
            if let s = try await settingsTask.first { settings = s }

            await loadDay(currentDateKey)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    func loadDay(_ dateKey: String) async {
        currentDateKey = dateKey
        do {
            async let entriesTask: [LogEntry] = client.from("log_entries")
                .select()
                .eq("user_id", value: userID)
                .eq("log_date", value: dateKey)
                .order("sort_order")
                .execute().value
            async let waterTask: [WaterLog] = client.from("water_log")
                .select()
                .eq("user_id", value: userID)
                .eq("log_date", value: dateKey)
                .execute().value

            logEntries = try await entriesTask
            waterOz = try await waterTask.first?.oz ?? 0
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Lookups

    func variants(for foodId: String) -> [FoodVariant] { variantsByFood[foodId] ?? [] }

    func defaultVariant(for food: Food) -> FoodVariant? {
        guard let id = food.defaultVariantId else { return nil }
        return variants(for: food.id).first { $0.id == id }
    }

    func entries(for meal: Meal) -> [LogEntry] {
        logEntries.filter { $0.meal == meal }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func totals(for meal: Meal) -> MacroTotals {
        var t = MacroTotals()
        for e in entries(for: meal) { t += (e.proteinG, e.carbsG, e.fatG, e.calories) }
        return t
    }

    func dayTotals() -> MacroTotals {
        var t = MacroTotals()
        for e in logEntries { t += (e.proteinG, e.carbsG, e.fatG, e.calories) }
        return t
    }

    // MARK: - Mutation

    func addLogEntry(food: Food, variant: FoodVariant?, def: ResolvedFoodDef, qty: Double, meal: Meal) async throws {
        let m = def.macros(for: qty)
        let entry = NewLogEntry(
            logDate: currentDateKey, meal: meal, foodId: food.id, variantId: variant?.id,
            qty: qty, unitKey: def.unitKey, unitLabel: "\(qty.formattedTrim) \(def.unitLabel(for: qty))",
            proteinG: m.protein, carbsG: m.carbs, fatG: m.fat,
            sortOrder: entries(for: meal).count
        )
        struct Insert: Encodable { let userId: UUID; let row: NewLogEntry
            enum CodingKeys: String, CodingKey { case userId = "user_id" }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(userId, forKey: .userId)
                try row.encode(to: encoder)
            }
        }
        try await client.from("log_entries").insert(Insert(userId: userID, row: entry)).execute()
        await loadDay(currentDateKey)
    }

    func deleteLogEntry(_ id: UUID) async throws {
        try await client.from("log_entries").delete().eq("id", value: id).execute()
        await loadDay(currentDateKey)
    }

    func addWater(_ oz: Double) async throws {
        let newTotal = waterOz + oz
        try await setWater(newTotal)
    }

    func setWater(_ oz: Double) async throws {
        struct Row: Encodable {
            let userId: UUID
            let logDate: String
            let oz: Double
            enum CodingKeys: String, CodingKey { case userId = "user_id", logDate = "log_date", oz }
        }
        try await client.from("water_log")
            .upsert(Row(userId: userID, logDate: currentDateKey, oz: oz), onConflict: "user_id,log_date")
            .execute()
        waterOz = oz
    }

    func updateTargets(proteinG: Double, carbsG: Double, fatG: Double, calories: Double) async throws {
        struct Patch: Encodable {
            let proteinTargetG: Double, carbsTargetG: Double, fatTargetG: Double, calorieTarget: Double
            enum CodingKeys: String, CodingKey {
                case proteinTargetG = "protein_target_g", carbsTargetG = "carbs_target_g"
                case fatTargetG = "fat_target_g", calorieTarget = "calorie_target"
            }
        }
        try await client.from("user_settings")
            .update(Patch(proteinTargetG: proteinG, carbsTargetG: carbsG, fatTargetG: fatG, calorieTarget: calories))
            .eq("user_id", value: userID)
            .execute()
        settings.proteinTargetG = proteinG
        settings.carbsTargetG = carbsG
        settings.fatTargetG = fatG
        settings.calorieTarget = calories
    }

    func updateWaterGoal(_ oz: Double) async throws {
        struct Patch: Encodable {
            let waterTargetOz: Double
            enum CodingKeys: String, CodingKey { case waterTargetOz = "water_target_oz" }
        }
        try await client.from("user_settings")
            .update(Patch(waterTargetOz: oz))
            .eq("user_id", value: userID)
            .execute()
        settings.waterTargetOz = oz
    }
}

private extension Double {
    /// "4" instead of "4.0", "1.5" instead of "1.5000" — for building the unit_label snapshot.
    var formattedTrim: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(format: "%g", self)
    }
}
