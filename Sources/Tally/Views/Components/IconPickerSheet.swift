import SwiftUI

/// A grid of common food/drink emoji to reassign a food's icon — same role as the prototype's
/// ICON_PALETTE + icon-picker screen. Presented as a sheet; tapping an icon selects it and
/// dismisses immediately (no separate confirm step needed for a single-tap choice like this).
struct IconPickerSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    // Grouped roughly fruit / veg / protein-dairy-grain / prepared dishes / snacks-sweets /
    // drinks-misc, in that display order — deliberately NOT alphabetized, so related icons
    // stay near each other in the grid.
    private let palette: [String] = [
        "🍎", "🍌", "🍊", "🍋", "🍇", "🍓", "🫐", "🍑", "🍒", "🍍", "🥭", "🍉",
        "🥑", "🥕", "🥦", "🌽", "🥒", "🫑", "🍆", "🥬", "🥔", "🧄", "🧅", "🍄",
        "🍗", "🍖", "🥩", "🥓", "🍳", "🧀", "🥛", "🍞", "🥐", "🥯", "🧈", "🥞",
        "🍚", "🍜", "🍝", "🍲", "🥗", "🌮", "🌯", "🥪", "🍕", "🍟", "🍔", "🌭",
        "🍿", "🥜", "🍪", "🍩", "🍫", "🍦", "🍰", "🧇", "🥧", "🍯", "🍬", "🍱",
        "☕", "🍵", "🥤", "🧃", "🍶", "🥣", "🫙", "🍤", "🐟", "🍽️"
    ]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(palette, id: \.self) { emoji in
                        Button {
                            selected = emoji
                            dismiss()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 28))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle().fill(emoji == selected ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
