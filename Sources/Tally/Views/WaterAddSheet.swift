import SwiftUI

struct WaterAddSheet: View {
    @Environment(TallyStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var customOz: Double = 8
    @State private var showCustom = false
    @State private var isSaving = false

    private let presets: [(oz: Double, height: CGFloat)] = [(16, 60), (24, 78), (40, 100)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack(spacing: 14) {
                    ForEach(presets, id: \.oz) { preset in
                        Button { Task { await add(preset.oz) } } label: {
                            VStack(spacing: 10) {
                                Image(systemName: "waterbottle.fill")
                                    .font(.system(size: preset.height * 0.5))
                                    .foregroundStyle(Color(red: 0.36, green: 0.61, blue: 0.84))
                                Text("\(Int(preset.oz)) oz").font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 140)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button { showCustom.toggle() } label: {
                    Label("Custom amount", systemImage: "plus")
                }

                if showCustom {
                    VStack(spacing: 14) {
                        Text("\(Int(customOz)) oz").font(.system(size: 32, weight: .bold, design: .rounded))
                        HStack {
                            Button { customOz = max(1, customOz - 1) } label: { Image(systemName: "minus.circle.fill").font(.title2) }
                            QuantitySlider(value: $customOz, range: 1...100, step: 1, tint: Color(red: 0.36, green: 0.61, blue: 0.84))
                            Button { customOz = min(100, customOz + 1) } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                        }
                        Button("Add") { Task { await add(customOz) } }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(red: 0.36, green: 0.61, blue: 0.84))
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemGroupedBackground)))
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Add Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .disabled(isSaving)
        }
        .presentationDetents([.medium, .large])
    }

    private func add(_ oz: Double) async {
        isSaving = true
        try? await store.addWater(oz)
        isSaving = false
        dismiss()
    }
}
