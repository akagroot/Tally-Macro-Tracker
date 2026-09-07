import SwiftUI

struct WaterGoalView: View {
    @Binding var path: NavigationPath
    @Environment(TallyStore.self) private var store

    @State private var oz: Double
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let waterTint = Color(red: 0.36, green: 0.61, blue: 0.84)

    init(initialOz: Double, path: Binding<NavigationPath>) {
        self._path = path
        self._oz = State(initialValue: initialOz)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("\(Int(oz)) oz")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .padding(.top, 40)

            HStack(spacing: 16) {
                Button { oz = max(32, oz - 4) } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 32))
                }
                QuantitySlider(value: $oz, range: 32...200, step: 4, tint: waterTint)
                Button { oz = min(200, oz + 4) } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 32))
                }
            }
            .foregroundStyle(waterTint)
            .padding(.horizontal)

            Text("Your daily target — applies to every day, not just today.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
                    Text("Save goal").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(waterTint)
            .controlSize(.large)
            .disabled(isSaving)
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .navigationTitle("Water Goal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await store.updateWaterGoal(oz)
            path.removeLast()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
