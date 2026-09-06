import SwiftUI

struct MealPickerSheet: View {
    let onPick: (Meal) -> Void

    var body: some View {
        NavigationStack {
            List(Meal.allCases) { meal in
                Button { onPick(meal) } label: {
                    Text(meal.displayName)
                }
            }
            .navigationTitle("Log to which meal?")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
