import SwiftUI

/// Create a custom food, tagged for whichever meal you were adding to when you couldn't find
/// it. Always "serving"-based (no oz/g toggle — see FoodMath.unitOptions) since there's no real
/// weight backing a user-defined serving. The emoji field is a plain text field rather than a
/// dedicated picker screen — the system keyboard's own emoji picker covers that already, and a
/// custom icon-picker UI is a separate, not-yet-built feature.
struct CustomFoodView: View {
    let meal: Meal
    @Binding var path: NavigationPath
    @Environment(TallyStore.self) private var store

    @State private var name = ""
    @State private var emoji = "🍽️"
    @State private var protein: Double = 10
    @State private var carbs: Double = 10
    @State private var fat: Double = 5
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var calories: Double { protein * 4 + carbs * 4 + fat * 9 }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 14) {
                    TextField("🍽️", text: $emoji)
                        .font(.system(size: 34))
                        .multilineTextAlignment(.center)
                        .frame(width: 64, height: 64)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
                        .onChange(of: emoji) { _, newValue in
                            // Keep it to roughly "one glyph" — grab the last typed character
                            // so pasting a whole sentence doesn't leave a wall of text here.
                            if newValue.count > 2 { emoji = String(newValue.suffix(2)) }
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

                Text("\(Int(calories)) cal per serving")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("Tagged for \(meal.displayName) — you can log it from other meals too via \"Show all foods.\"")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Custom Food")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Create & Log").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSave)
            .padding()
            .background(.bar)
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
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)
        do {
            let food = try await store.createCustomFood(
                name: trimmedName,
                emoji: trimmedEmoji.isEmpty ? "🍽️" : trimmedEmoji,
                proteinG: protein, carbsG: carbs, fatG: fat,
                mealTags: [meal.rawValue]
            )
            path.append(Route.quantity(food: food, variant: nil, meal: meal))
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
