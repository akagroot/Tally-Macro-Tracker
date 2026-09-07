import SwiftUI

/// Every food in the catalog (built-in and custom), alphabetical, tap one to rename it, change
/// its icon, or adjust its macros — same "Customize" concept as the prototype, applied uniformly
/// to any food rather than special-casing custom vs. built-in.
struct ManageFoodsView: View {
    @Environment(TallyStore.self) private var store
    @Binding var path: NavigationPath
    @State private var searchText = ""

    private var foods: [Food] {
        let sorted = store.foods.sorted { $0.name < $1.name }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List(foods) { food in
            Button {
                path.append(Route.customizeFood(food: food))
            } label: {
                HStack {
                    Text(food.emoji).font(.title3)
                    Text(food.name).foregroundStyle(.primary)
                    Spacer()
                    if food.isCustom {
                        Text("Custom").font(.caption2).foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search foods")
        .navigationTitle("Manage Foods")
        .navigationBarTitleDisplayMode(.inline)
    }
}
