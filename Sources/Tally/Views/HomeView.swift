import SwiftUI

enum Route: Hashable {
    case foodPicker(meal: Meal)
    case variantPicker(food: Food, meal: Meal)
    case quantity(food: Food, variant: FoodVariant?, meal: Meal)
    case settings
    case targets(initial: UserSettings)
    case waterGoal(initialOz: Double)
    case waterEdit(initialOz: Double)
    case weight(initialLbs: Double)
    case customFood(meal: Meal)
    case manageFoods
    case customizeFood(food: Food)
}

struct HomeView: View {
    @Environment(TallyStore.self) private var store
    @State private var path = NavigationPath()
    @State private var showMealPicker = false
    @State private var showWaterAdd = false

    // Day-transition animation state — mirrors the prototype's animateDayChange: exit
    // animates off, the jump to the opposite starting offset happens instantly (no
    // withAnimation wrapper), then the enter animates back to center/full opacity.
    @State private var dayContentOffset: CGFloat = 0
    @State private var dayContentOpacity: Double = 1
    @State private var isChangingDay = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    calorieCard
                    waterCard
                    mealsSection
                }
                .padding(.top, 8)
                .padding(.bottom, 90)
                .offset(x: dayContentOffset)
                .opacity(dayContentOpacity)
            }
            .background(Color(.systemGroupedBackground))
            // Pan-y equivalent: a plain vertical scroll is untouched, only a
            // horizontally-dominant drag past the threshold changes the day.
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        guard abs(horizontal) > 60, abs(horizontal) > abs(vertical) else { return }
                        Task { await changeDay(by: horizontal < 0 ? 1 : -1) }
                    }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button { Task { await jumpToToday() } } label: {
                        Text("🥗 Tally · \(DateKey.friendly(store.currentDateKey))")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .disabled(store.currentDateKey == DateKey.today)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { path.append(Route.settings) } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) { fab }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .foodPicker(let meal):
                    FoodPickerView(meal: meal, path: $path)
                case .variantPicker(let food, let meal):
                    VariantPickerView(food: food, meal: meal, path: $path)
                case .quantity(let food, let variant, let meal):
                    QuantityView(food: food, variant: variant, meal: meal, path: $path)
                case .settings:
                    SettingsView(path: $path)
                case .targets(let initial):
                    TargetsView(initialSettings: initial, path: $path)
                case .waterGoal(let initialOz):
                    WaterGoalView(initialOz: initialOz, path: $path)
                case .waterEdit(let initialOz):
                    WaterEditView(initialOz: initialOz, path: $path)
                case .weight(let initialLbs):
                    WeightView(initialLbs: initialLbs, path: $path)
                case .customFood(let meal):
                    CustomFoodView(meal: meal, path: $path)
                case .manageFoods:
                    ManageFoodsView(path: $path)
                case .customizeFood(let food):
                    CustomizeFoodView(food: food, path: $path)
                }
            }
            .sheet(isPresented: $showMealPicker) {
                MealPickerSheet { meal in
                    showMealPicker = false
                    path.append(Route.foodPicker(meal: meal))
                }
            }
            .sheet(isPresented: $showWaterAdd) {
                WaterAddSheet()
            }
            .task { await store.bootstrap() }
            .refreshable { await store.loadDay(store.currentDateKey) }
        }
    }

    // MARK: - Day navigation

    /// direction: 1 = moving forward a day (content exits left, enters from right),
    /// -1 = backward (reversed) — same convention as the prototype's animateDayChange.
    private func changeDay(by direction: Int) async {
        guard !isChangingDay else { return }
        let newKey = DateKey.shift(store.currentDateKey, byDays: direction)
        await animateDayChange(direction: direction, to: newKey)
    }

    private func jumpToToday() async {
        guard store.currentDateKey != DateKey.today, !isChangingDay else { return }
        let direction = store.currentDateKey < DateKey.today ? 1 : -1
        await animateDayChange(direction: direction, to: DateKey.today)
    }

    private func animateDayChange(direction: Int, to newKey: String) async {
        isChangingDay = true
        withAnimation(.easeInOut(duration: 0.18)) {
            dayContentOffset = direction > 0 ? -26 : 26
            dayContentOpacity = 0
        }
        try? await Task.sleep(nanoseconds: 180_000_000)

        await store.loadDay(newKey)

        // Instant jump to the opposite starting edge — no animation wrapper here,
        // matching the prototype's "set transition:none, force reflow, re-enable" trick.
        dayContentOffset = direction > 0 ? 26 : -26
        dayContentOpacity = 0

        withAnimation(.easeInOut(duration: 0.18)) {
            dayContentOffset = 0
            dayContentOpacity = 1
        }
        isChangingDay = false
    }

    // MARK: - Calorie / macro card

    private var calorieCard: some View {
        let totals = store.dayTotals()
        let target = store.settings.calorieTarget
        let left = max(0, target - totals.calories)
        return VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(1, totals.calories / max(target, 1)))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(Int(left))").font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("CAL LEFT").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)

            Text("\(Int(totals.calories)) eaten · \(Int(target)) target")
                .font(.footnote).foregroundStyle(.secondary)

            VStack(spacing: 8) {
                macroRow("Protein", totals.proteinG, store.settings.proteinTargetG, .orange)
                macroRow("Carbs", totals.carbsG, store.settings.carbsTargetG, .yellow)
                macroRow("Fat", totals.fatG, store.settings.fatTargetG, .purple)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.horizontal)
    }

    private func macroRow(_ label: String, _ eaten: Double, _ target: Double, _ color: Color) -> some View {
        let over = eaten > target
        return HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).frame(width: 56, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule().fill(over ? Color.red : color)
                        .frame(width: geo.size.width * min(1, eaten / max(target, 1)))
                }
            }
            .frame(height: 6)
            Text(over ? "+\(Int(eaten - target))g over" : "\(Int(max(0, target - eaten)))g left")
                .font(.caption2).foregroundStyle(.secondary).frame(width: 80, alignment: .trailing)
        }
    }

    // MARK: - Water card

    private var waterCard: some View {
        HStack(spacing: 12) {
            Button {
                path.append(Route.waterEdit(initialOz: store.waterOz))
            } label: {
                waterTapContent
            }
            .buttonStyle(.plain)
            Button("+ Add") { showWaterAdd = true }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.36, green: 0.61, blue: 0.84))
                .controlSize(.small)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.horizontal)
    }

    // Tapping this (not the Add button) opens Edit Water — correct or reset today's total,
    // same "tap the amount to edit it" pattern as the prototype.
    private var waterTapContent: some View {
        HStack(spacing: 12) {
            Text("💧").font(.title2)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(Int(store.waterOz)) / \(Int(store.settings.waterTargetOz)) oz")
                    .font(.system(.footnote, design: .monospaced)).fontWeight(.bold)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.15))
                        Capsule().fill(Color(red: 0.36, green: 0.61, blue: 0.84))
                            .frame(width: geo.size.width * min(1, store.waterOz / max(store.settings.waterTargetOz, 1)))
                    }
                }
                .frame(height: 6)
            }
        }
        .contentShape(Rectangle())
        .foregroundStyle(.primary)
    }

    // MARK: - Meals

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EATEN TODAY").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 20)
            ForEach(Meal.allCases) { meal in
                mealCard(meal)
            }
        }
    }

    private func mealCard(_ meal: Meal) -> some View {
        let entries = store.entries(for: meal)
        let totals = store.totals(for: meal)
        return VStack(spacing: 0) {
            HStack {
                Text(meal.displayName).font(.headline)
                Spacer()
                Text("\(Int(totals.calories)) cal").font(.subheadline).foregroundStyle(.secondary)
                Button { path.append(Route.foodPicker(meal: meal)) } label: {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
            }
            .padding(14)

            ForEach(entries) { entry in
                if let food = store.foods.first(where: { $0.id == entry.foodId }) {
                    HStack {
                        Text(food.emoji)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.variantId.flatMap { vid in store.variants(for: food.id).first { $0.id == vid }?.name } ?? food.name)
                            Text(entry.unitLabel).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(entry.calories))").foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    Divider().padding(.leading, 14)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
        .padding(.horizontal)
    }

    private var fab: some View {
        Button { showMealPicker = true } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 4, y: 2)
        }
        .padding(24)
    }
}
