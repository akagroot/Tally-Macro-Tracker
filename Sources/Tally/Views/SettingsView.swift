import SwiftUI

struct SettingsView: View {
    @Environment(TallyStore.self) private var store
    @Binding var path: NavigationPath

    var body: some View {
        List {
            Button {
                path.append(Route.targets(initial: store.settings))
            } label: {
                row(icon: "target", title: "Daily Targets", value: "\(Int(store.settings.calorieTarget)) cal")
            }
            Button {
                path.append(Route.waterGoal(initialOz: store.settings.waterTargetOz))
            } label: {
                row(icon: "drop.fill", title: "Water Goal", value: "\(Int(store.settings.waterTargetOz)) oz")
            }
            Button {
                path.append(Route.weight(initialLbs: store.weightLbs ?? 150))
            } label: {
                row(icon: "figure.stand", title: "Weight", value: store.weightLbs.map { "\(Int($0)) lbs" } ?? "Not set")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(Color.accentColor).frame(width: 24)
            Text(title).foregroundStyle(.primary)
            Spacer()
            Text(value).foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
    }
}
