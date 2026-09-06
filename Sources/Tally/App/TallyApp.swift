import SwiftUI

@main
struct TallyApp: App {
    @State private var store = TallyStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
        }
    }
}
