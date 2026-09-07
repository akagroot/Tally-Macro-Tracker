import SwiftUI

struct TargetsView: View {
    @Binding var path: NavigationPath
    @Environment(TallyStore.self) private var store

    @State private var calories: Double
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(initialSettings: UserSettings, path: Binding<NavigationPath>) {
        self._path = path
        self._calories = State(initialValue: initialSettings.calorieTarget)
        self._protein = State(initialValue: initialSettings.proteinTargetG)
        self._carbs = State(initialValue: initialSettings.carbsTargetG)
        self._fat = State(initialValue: initialSettings.fatTargetG)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                targetRow(title: "Calories", value: $calories, range: 1200...5000, step: 10, unit: "cal", tint: .accentColor)
                targetRow(title: "Protein", value: $protein, range: 20...400, step: 5, unit: "g", tint: .orange)
                targetRow(title: "Carbs", value: $carbs, range: 20...600, step: 5, unit: "g", tint: .yellow)
                targetRow(title: "Fat", value: $fat, range: 10...200, step: 5, unit: "g", tint: .purple)

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Daily Targets")
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
            .disabled(isSaving)
            .padding()
            .background(.bar)
        }
    }

    private func targetRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, unit: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.subheadline.bold())
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(.body, design: .rounded)).bold()
            }
            HStack(spacing: 12) {
                Button { adjust(value, by: -step, range: range) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                QuantitySlider(value: value, range: range, step: step, tint: tint)
                Button { adjust(value, by: step, range: range) } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .font(.system(size: 26))
            .foregroundStyle(tint)
        }
    }

    private func adjust(_ value: Binding<Double>, by delta: Double, range: ClosedRange<Double>) {
        value.wrappedValue = max(range.lowerBound, min(range.upperBound, value.wrappedValue + delta))
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await store.updateTargets(proteinG: protein, carbsG: carbs, fatG: fat, calories: calories)
            path.removeLast()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
