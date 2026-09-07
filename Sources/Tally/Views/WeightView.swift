import SwiftUI

/// Logs/edits today's weight — a simple single-value-per-day entry, same pattern as
/// WaterGoalView/WaterEditView. Reachable from Settings; not shown on Home (matches the
/// prototype, which kept weight in Settings rather than on the daily screen).
struct WeightView: View {
    @Binding var path: NavigationPath
    @Environment(TallyStore.self) private var store

    @State private var lbs: Double
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(initialLbs: Double, path: Binding<NavigationPath>) {
        self._path = path
        self._lbs = State(initialValue: initialLbs)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("\(lbs.trimmedString) lbs")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .padding(.top, 40)

            HStack(spacing: 16) {
                Button { lbs = max(60, lbs - 0.5) } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 32))
                }
                QuantitySlider(value: $lbs, range: 60...400, step: 0.5)
                Button { lbs = min(400, lbs + 0.5) } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 32))
                }
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal)

            Text("Logged for \(DateKey.friendly(store.currentDateKey).lowercased()).")
                .font(.footnote)
                .foregroundStyle(.secondary)

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
                    Text("Save").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isSaving)
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await store.setWeight(lbs)
            path.removeLast()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private extension Double {
    var trimmedString: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(Int(self)) : String(format: "%.1f", self)
    }
}
