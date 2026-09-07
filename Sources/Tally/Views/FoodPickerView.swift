import SwiftUI

struct FoodPickerView: View {
    let meal: Meal
    @Binding var path: NavigationPath
    @Environment(TallyStore.self) private var store
    @State private var showAllFoods = false
    @State private var searchText = ""
    @State private var sortMode: SortMode = .usual
    @State private var applyingTemplateID: UUID?
    @State private var errorMessage: String?

    enum SortMode: String, CaseIterable, Identifiable {
        case usual = "Usual", alphabetical = "A–Z"
        var id: String { rawValue }
    }

    private var isSearching: Bool { !searchText.isEmpty }

    private var candidates: [Food] {
        // Typing a search term searches the WHOLE catalog regardless of the meal filter or the
        // "Show all foods" toggle — you're looking for a specific food by name at that point,
        // not browsing what's typical for this meal.
        let base = (isSearching || showAllFoods)
            ? store.foods
            : store.foods.filter { $0.mealTags.contains(meal.rawValue) || $0.mealTags.contains("mains") }
        let filtered = isSearching
            ? base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            : base
        switch sortMode {
        case .alphabetical:
            return filtered.sorted { $0.name < $1.name }
        case .usual:
            // Most-recently-logged first (maintained by the DB trigger on log_entries insert —
            // see touch_food_last_used in schema.sql); never-used foods fall back to A-Z among
            // themselves, after everything with real usage.
            return filtered.sorted { a, b in
                switch (a.lastUsedAt, b.lastUsedAt) {
                case let (da?, db?): return da > db
                case (nil, nil): return a.name < b.name
                case (nil, _): return false
                case (_, nil): return true
                }
            }
        }
    }

    var body: some View {
        List {
            if !isSearching && !store.templates.isEmpty {
                Section("Templates") {
                    ForEach(store.templates) { template in
                        Button { apply(template) } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundStyle(Color.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.name).foregroundStyle(.primary)
                                    Text(templatePreview(template)).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if applyingTemplateID == template.id {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(applyingTemplateID != nil)
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                Task { try? await store.deleteTemplate(template.id) }
                            }
                        }
                    }
                }
            }
            Section {
                Toggle("Show all foods", isOn: $showAllFoods)
                    .disabled(isSearching)
                    .foregroundStyle(isSearching ? .secondary : .primary)
                Picker("Sort", selection: $sortMode) {
                    ForEach(SortMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section {
                ForEach(candidates) { food in
                    Button { select(food) } label: {
                        HStack {
                            Text(food.emoji).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name).foregroundStyle(.primary)
                                Text(previewLabel(for: food)).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if food.pickRequired {
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            Section {
                Button {
                    path.append(Route.customFood(meal: meal))
                } label: {
                    Label("Create Custom Food", systemImage: "plus.circle")
                }
            }
            if let errorMessage {
                Section {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search foods")
        .navigationTitle("Add to \(meal.displayName)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func templatePreview(_ template: MealTemplate) -> String {
        let names = template.items.compactMap { item in store.foods.first { $0.id == item.foodId }?.name }
        return names.isEmpty ? "\(template.items.count) items" : names.joined(separator: ", ")
    }

    private func apply(_ template: MealTemplate) {
        applyingTemplateID = template.id
        errorMessage = nil
        Task {
            do {
                try await store.applyTemplate(template, to: meal)
                path = NavigationPath()
            } catch {
                errorMessage = error.localizedDescription
            }
            applyingTemplateID = nil
        }
    }

    private func previewLabel(for food: Food) -> String {
        let variant = store.defaultVariant(for: food)
        let def = FoodMath.resolve(food: food, variant: variant)
        let m = def.macros(for: def.defaultQty)
        return "\(Int(m.calories)) cal per \(def.unitLabel(for: def.defaultQty))"
    }

    private func select(_ food: Food) {
        if store.variants(for: food.id).isEmpty {
            path.append(Route.quantity(food: food, variant: nil, meal: meal))
        } else {
            path.append(Route.variantPicker(food: food, meal: meal))
        }
    }
}
