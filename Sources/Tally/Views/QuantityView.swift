import SwiftUI

struct QuantityView: View {
    let food: Food
    let variant: FoodVariant?
    let meal: Meal
    @Binding var path: NavigationPath
    @Environment(TallyStore.self) private var store

    @State private var def: ResolvedFoodDef
    @State private var qty: Double
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(food: Food, variant: FoodVariant?, meal: Meal, path: Binding<NavigationPath>) {
        self.food = food
        self.variant = variant
        self.meal = meal
        self._path = path
        let resolved = FoodMath.resolve(food: food, variant: variant)
        self._def = State(initialValue: resolved)
        self._qty = State(initialValue: resolved.defaultQty)
    }

    private var macros: (protein: Double, carbs: Double, fat: Double, calories: Double) {
        def.macros(for: qty)
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text(food.emoji).font(.system(size: 48))
                Text(variant?.name ?? food.name).font(.title2.bold())
            }
            .padding(.top, 12)

            Text("\(qty.trimmedString) \(def.unitLabel(for: qty))")
                .font(.system(size: 40, weight: .bold, design: .rounded))

            HStack(spacing: 16) {
                Button { step(-1) } label: { stepButtonLabel("minus") }
                QuantitySlider(value: $qty, range: def.minQty...def.maxQty, step: def.step)
                Button { step(1) } label: { stepButtonLabel("plus") }
            }
            .padding(.horizontal)

            if def.unitOptions.count > 1 {
                Picker("Unit", selection: unitKeyBinding) {
                    ForEach(def.unitOptions, id: \.self) { key in
                        Text(unitPillLabel(key)).tag(key)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }

            HStack(spacing: 20) {
                macroChip("P", macros.protein, .orange)
                macroChip("C", macros.carbs, .yellow)
                macroChip("F", macros.fat, .purple)
            }

            Text("\(Int(macros.calories)) cal").font(.headline).foregroundStyle(.secondary)

            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(.red)
            }

            Spacer()

            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Add to \(meal.displayName)").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving)
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepButtonLabel(_ systemSuffix: String) -> some View {
        Image(systemName: "\(systemSuffix).circle.fill")
            .font(.system(size: 32))
            .foregroundStyle(Color.accentColor)
    }

    private func macroChip(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack {
            Text(label).font(.caption).foregroundStyle(color)
            Text("\(Int(value))g").font(.subheadline.bold())
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)))
    }

    private func unitPillLabel(_ key: String) -> String {
        switch key {
        case "oz": return "oz"
        case "g": return "g"
        // The native pill must always show the food's OWN native unit (e.g. "tbsp"), not
        // def.unit — which reflects whatever unit is currently active and would otherwise
        // relabel itself "oz"/"g" after switching away from native.
        default: return variant?.unit ?? food.unit ?? "native"
        }
    }

    private var unitKeyBinding: Binding<String> {
        Binding(
            get: { def.unitKey },
            set: { newKey in
                guard newKey != def.unitKey else { return }
                let result = FoodMath.switchUnit(food: food, variant: variant, currentDef: def, currentQty: qty, newKey: newKey)
                def = result.def
                qty = result.qty
            }
        )
    }

    private func step(_ direction: Double) {
        let stepped = qty + direction * def.btnStep
        qty = (max(def.minQty, min(def.maxQty, stepped)) * 100).rounded() / 100
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await store.addLogEntry(food: food, variant: variant, def: def, qty: qty, meal: meal)
            path = NavigationPath() // back to Home
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private extension Double {
    var trimmedString: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(format: "%g", self)
    }
}
