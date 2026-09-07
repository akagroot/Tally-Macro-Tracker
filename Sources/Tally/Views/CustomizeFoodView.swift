import SwiftUI

/// Rename a food, change its icon, or adjust its base macros — applies uniformly to built-in
/// and custom foods alike (the DB doesn't distinguish beyond the is_custom flag). Editing a
/// food this way is a catalog-level change: it updates the name/icon everywhere that food is
/// referenced, including past log entries' display (which only store a food_id, not a frozen
/// name) — deliberately different from log_entries' own macro snapshot, see updateFood's doc.
struct CustomizeFoodView: View {
    let food: Food
    @Binding var path: NavigationPath
    @Environment(TallyStore.self) private var store

    @State private var name: String
    @State private var emoji: String
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double
    @State private var showIconPicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(food: Food, path: Binding<NavigationPath>) {
        self.food = food
        self._path = path
        self._name = State(initialValue: food.name)
        self._emoji = State(initialValue: food.emoji)
        self._protein = State(initialValue: food.proteinG)
        self._carbs = State(initialValue: food.carbsG)
        self._fat = State(initialValue: food.fatG)
    }

    private var calories: Double { protein * 4 + carbs * 4 + fat * 9 }
    private var unitLabel: String { food.itemMode ? (food.itemName ?? "serving") : (food.unit ?? "unit") }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 14) {
                    Button { showIconPicker = true } label: {
                        Text(emoji)
                            .font(.system(size: 34))
                            .frame(width: 64, height: 64)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                    }
                    TextField("Food name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                }

                VStack(spacing: 20) {
                    macroRow(title: "Protein", value: $protein, range: 0...100, tint: .orange)
                    macroRow(title: "Carbs", value: $carbs, range: 0...150, tint: .yellow)
                    macroRow(title: "Fat", value: $fat, range: 0...100, tint: .purple)
                }

                Text("\(Int(calories)) cal per \(unitLabel)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if food.pickRequired || !store.variants(for: food.id).isEmpty {
                    Text("This food has cuts/variants with their own macros — these values are only the fallback shown before a cut is picked.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Customize")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Save").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSave)
            .padding()
            .background(.bar)
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerSheet(selected: $emoji)
        }
    }

    private func macroRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.subheadline.bold())
                Spacer()
                Text("\(Int(value.wrappedValue))g").font(.system(.body, design: .rounded)).bold()
            }
            HStack(spacing: 12) {
                Button { value.wrappedValue = max(range.lowerBound, value.wrappedValue - 1) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                QuantitySlider(value: value, range: range, step: 1, tint: tint)
                Button { value.wrappedValue = min(range.upperBound, value.wrappedValue + 1) } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .font(.system(size: 24))
            .foregroundStyle(tint)
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await store.updateFood(
                food, name: name.trimmingCharacters(in: .whitespaces), emoji: emoji,
                proteinG: protein, carbsG: carbs, fatG: fat
            )
            path.removeLast()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
