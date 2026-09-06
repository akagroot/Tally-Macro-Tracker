import SwiftUI

/// Temporary scaffolding screen — proves the Xcode → Supabase → UI pipeline works end to end
/// before the real UI gets ported over from the HTML prototype. Replace this once that starts.
struct ContentView: View {
    @State private var foods: [Food] = []
    @State private var loadState: LoadState = .idle

    enum LoadState: Equatable {
        case idle, loading, loaded, failed(String)

        static func == (lhs: LoadState, rhs: LoadState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.loaded, .loaded): return true
            case let (.failed(a), .failed(b)): return a == b
            default: return false
            }
        }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("🥗 Tally")
                .task { await loadFoods() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .idle, .loading:
            ProgressView("Connecting to Supabase…")
        case .failed(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text("Couldn't load the food catalog")
                    .font(.headline)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Retry") { Task { await loadFoods() } }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        case .loaded:
            List(foods) { food in
                HStack {
                    Text(food.emoji)
                    VStack(alignment: .leading) {
                        Text(food.name).font(.body)
                        Text("\(Int(food.calories)) cal · P\(Int(food.proteinG)) C\(Int(food.carbsG)) F\(Int(food.fatG)) per \(food.unit ?? food.itemName ?? "serving")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .overlay(alignment: .top) {
                Text("Connected — \(foods.count) foods loaded from Supabase")
                    .font(.caption2)
                    .padding(6)
                    .background(.green.opacity(0.15))
            }
        }
    }

    private func loadFoods() async {
        loadState = .loading
        do {
            let foods: [Food] = try await SupabaseService.client
                .from("foods")
                .select()
                .order("name")
                .execute()
                .value
            self.foods = foods
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
}
