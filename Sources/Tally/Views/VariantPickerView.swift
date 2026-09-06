import SwiftUI

struct VariantPickerView: View {
    let food: Food
    let meal: Meal
    @Binding var path: NavigationPath
    @Environment(TallyStore.self) private var store

    var body: some View {
        List(store.variants(for: food.id).sorted { $0.sortOrder < $1.sortOrder }) { variant in
            Button {
                path.append(Route.quantity(food: food, variant: variant, meal: meal))
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(variant.name).foregroundStyle(.primary)
                        let def = FoodMath.resolve(food: food, variant: variant)
                        let m = def.macros(for: def.defaultQty)
                        Text("\(Int(m.calories)) cal per \(def.unitLabel(for: def.defaultQty))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
        .navigationTitle("Which \(food.name.lowercased())?")
        .navigationBarTitleDisplayMode(.inline)
    }
}
