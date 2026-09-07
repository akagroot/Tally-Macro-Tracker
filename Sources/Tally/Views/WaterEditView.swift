import SwiftUI

/// Correct or remove today's water total — the running total is edited directly rather than
/// itemized (water isn't logged as separate entries the way meals are, so there's nothing to
/// delete individually; matches the prototype's "Edit Water" screen exactly).
struct WaterEditView: View {
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

    private var maxOz: Double {
        max(200, store.settings.waterTargetOz * 2, oz)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("\(Int(oz)) oz")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .padding(.top, 40)

            HStack(spacing: 16) {
                Button { oz = max(0, oz - 4) } label: {
                    Image(systemName: "minus.circle.fill").font(.system(size: 32))
                }
                QuantitySlider(value: $oz, range: 0...maxOz, step: 1, tint: waterTint)
                Button { oz = min(maxOz, oz + 4) } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 32))
                }
            }
            .foregroundStyle(waterTint)
            .padding(.horizontal)

            Text("Correct or remove today's water total.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Reset to 0") { oz = 0 }
                .font(.footnote.bold())
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
            .tint(waterTint)
            .controlSize(.large)
            .disabled(isSaving)
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .navigationTitle("Edit Water")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await store.setWater(oz)
            path.removeLast()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
