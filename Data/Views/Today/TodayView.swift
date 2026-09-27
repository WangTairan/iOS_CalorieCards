import SwiftUI
import Combine

extension Notification.Name {
    static let closeTodayOverlay = Notification.Name("closeTodayOverlay")
}

struct TodayView: View {
    @Binding var hasOverlay: Bool

    @State private var cards: [MealCard] = [
        MealCard(name: .breakfast),
        MealCard(name: .lunch),
        MealCard(name: .snack),
        MealCard(name: .dinner)
    ]

    @State private var expandedIndex: Int? = nil
    @State private var isEditing = false
    @State private var isCreating = false
    @State private var settingsIndex: Int? = nil

    @Namespace private var cardNS
    private let springResponse: Double = 0.38
    private let springDamping: Double  = 0.86

    @State private var overlayActive: Bool = false
    @State private var cycleKey = DayCycleManager.shared.currentCycleKey()
    @State private var cancellables = Set<AnyCancellable>()

    // 目标值
    @AppStorage(AppKeys.dailyKcalGoal)    private var dailyKcalGoal: Int = 2000
    @AppStorage(AppKeys.dailyProteinGoal) private var dailyProteinGoal: Int = 125   // 2000kcal * 25% / 4 = 125g
    @AppStorage(AppKeys.dailyCarbGoal)    private var dailyCarbGoal: Int = 250      // 2000kcal * 50% / 4 = 250g
    @AppStorage(AppKeys.dailyFatGoal)     private var dailyFatGoal: Int = 56        // 2000kcal * 25% / 9 ≈ 55.5

    // 当日摄入（从卡片汇总）
    private var totalKcal: Int    { cards.reduce(0) { $0 + $1.kcal } }
    private var totalProtein: Int { cards.reduce(0) { $0 + $1.protein } }  // 需要 MealCard 有 protein
    private var totalCarb: Int    { cards.reduce(0) { $0 + $1.carb } }     // 需要 MealCard 有 carb
    private var totalFat: Int     { cards.reduce(0) { $0 + $1.fat } }      // 需要 MealCard 有 fat

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var showingOverlayContent: Bool { expandedIndex != nil || settingsIndex != nil || isCreating }
    private var hasAnyOverlayLocal: Bool { overlayActive || showingOverlayContent }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        goalBar
                        gridSection
                    }
                    .padding(16)
                }
                .allowsHitTesting(!hasAnyOverlayLocal)
                
                if isEditing && !hasAnyOverlayLocal {
                        Color.clear
                            .contentShape(Rectangle())
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    isEditing = false
                                }
                            }
                            .zIndex(0.5)
                    }

                if showingOverlayContent {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { closeOverlayAnimated() }
                        .transition(.opacity)
                        .zIndex(1)
                }

                if let idx = expandedIndex {
                    ExpandedKcalCard(
                        card: $cards[idx],
                        namespace: cardNS,
                        onFinish: { kcal, protein, carb, fat in
                            cards[idx].kcal    = kcal
                            cards[idx].protein = protein
                            cards[idx].carb    = carb
                            cards[idx].fat     = fat
                            MealCardStateStore.shared.saveAll(cards: cards)
                            closeOverlayAnimated()
                        },
                        onAutoUpdate: {
                            MealCardStateStore.shared.saveAll(cards: cards)
                        }
                    )
                    .transition(.opacity)
                    .zIndex(2)
                }

                if let sidx = settingsIndex {
                    ExpandedCardSettings(
                        draft: cards[sidx],
                        existingNames: cards.map { $0.name.id },
                        originalName: cards[sidx].name.rawValue,
                        onCancel: { closeSettingsAnimated() },
                        onSave: { updated in
                            cards[sidx] = updated
                            MealCardStateStore.shared.saveAll(cards: cards)
                            closeSettingsAnimated()
                        },
                        onAutoUpdate: { updated in
                            cards[sidx] = updated
                            MealCardStateStore.shared.saveAll(cards: cards)
                        }
                    )
                    .transition(.opacity)
                    .zIndex(2)
                }

                if isCreating {
                    ExpandedCardSettings(
                        draft: MealCard(
                            name: CardName(rawValue: ""),
                            appearance: CardAppearance(symbol: "fork.knife", colorHex: Color(.systemBlue).hexRGB)
                        ),
                        existingNames: cards.map { $0.name.id },
                        originalName: nil,
                        onCancel: { closeCreateAnimated() },
                        onSave: { newCard in
                            cards.append(newCard)
                            MealCardStateStore.shared.saveAll(cards: cards)
                            closeCreateAnimated()
                        },
                        onAutoUpdate: { _ in }
                    )
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
            .navigationTitle(String(localized: "app_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DayCycleManager.shared.tick()
            cards = MealCardStateStore.shared.loadOrInitCards()
            cycleKey = DayCycleManager.shared.currentCycleKey()
            hasOverlay = hasAnyOverlayLocal
        }
        .onDisappear { hasOverlay = false }
        .onChange(of: showingOverlayContent) {
            hasOverlay = overlayActive || showingOverlayContent
        }
        .onChange(of: overlayActive) {
            hasOverlay = overlayActive || showingOverlayContent
        }
        .onReceive(NotificationCenter.default.publisher(for: .closeTodayOverlay)) { _ in
            if hasAnyOverlayLocal { closeOverlayAnimated() }
        }
    }

    // MARK: - Goal Bar（上：kcal 进度；下：三大营养素微型进度条）
    private var goalBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部标题 + 总热量目标
            HStack {
                Label(String(localized: "daily_goal"), systemImage: "target")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("kcal_with_unit \(Int64(dailyKcalGoal))")
                    .font(.subheadline)
                    .monospacedDigit()
            }

            // 总热量进度条
            progressBar(
                current: Double(totalKcal),
                goal: Double(max(dailyKcalGoal, 1)),
                height: 10
            )

            // 三大营养素：并排 3 段（每段垂直布局：数字 + 微进度条）
            HStack(spacing: 12) {
                microColumn(title: String(localized: "protein"),
                            value: totalProtein,
                            unitLabel: "g",
                            goal: dailyProteinGoal,
                            tint: .pink)

                microColumn(title: String(localized: "carb"),
                            value: totalCarb,
                            unitLabel: "g",
                            goal: dailyCarbGoal,
                            tint: .blue)

                microColumn(title: String(localized: "fat"),
                            value: totalFat,
                            unitLabel: "g",
                            goal: dailyFatGoal,
                            tint: .orange)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.08))
        )
    }

    // 微型列：标题 + 数字 + 进度条（竖排布局，三段排成一行）
    private func microColumn(title: String,
                             value: Int,
                             unitLabel: String,
                             goal: Int,
                             tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.footnote.weight(.semibold))
                Spacer()
                Text("\(value)/\(goal)\(unitLabel)")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            progressBar(
                current: Double(value),
                goal: Double(max(goal, 1)),
                height: 6
            )
            .tint(tint)
        }
        .frame(maxWidth: .infinity) // 让三段平均分布
    }


    // 通用大进度条
    private func progressBar(current: Double, goal: Double, height: CGFloat) -> some View {
        let p = min(current / max(goal, 1), 1.0)
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: height)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.9))
                    .frame(width: geo.size.width * p, height: height)
            }
        }
        .frame(height: height)
    }

    // 微型行：左标题，中间进度，右数字
    private func microRow(title: String, value: Int, unitLabel: String, goal: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.footnote.weight(.semibold))
                Spacer()
                Text("\(value)/\(goal)\(unitLabel)")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            progressBar(current: Double(value),
                        goal: Double(max(goal, 1)),
                        height: 6)
        }
    }

    // MARK: - Grid
    private var gridSection: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(cards.indices, id: \.self) { idx in
                CardView(
                    card: cards[idx],
                    isEditing: isEditing,
                    onDelete: { deleteCard(at: idx) },
                    onSettings: {
                        overlayActive = true
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                                settingsIndex = idx
                            }
                        }
                    },
                    onMoveRight: { moveRight(at: idx) }
                )
                .aspectRatio(1, contentMode: .fit)
                .matchedGeometryEffect(id: cards[idx].id, in: cardNS, isSource: expandedIndex != idx)
                .opacity(expandedIndex == idx ? 0 : 1)
                .onTapGesture {
                    guard !isEditing else { return }
                    overlayActive = true
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                            expandedIndex = idx
                        }
                    }
                }
                .onLongPressGesture(minimumDuration: 0.35) {
                    withAnimation(.easeInOut) { isEditing = true }
                }
            }

            if isEditing {
                Button {
                    overlayActive = true
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                            isCreating = true
                        }
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "plus")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        )
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    // MARK: - Actions
    private func deleteCard(at index: Int) {
        withAnimation(.easeInOut) {
            if expandedIndex == index { expandedIndex = nil }
            if let ex = expandedIndex, ex > index { expandedIndex = ex - 1 }
            cards.remove(at: index)
        }
        MealCardStateStore.shared.saveAll(cards: cards)
    }

    private func moveRight(at index: Int) {
        withAnimation(.easeInOut) {
            guard !cards.isEmpty else { return }
            if index == cards.count - 1 {
                let last = cards.removeLast()
                cards.insert(last, at: 0)
            } else {
                cards.swapAt(index, index + 1)
            }
        }
        MealCardStateStore.shared.saveAll(cards: cards)
    }

    // MARK: - Close helpers
    private func closeOverlayAnimated() {
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            expandedIndex = nil
            settingsIndex = nil
            isCreating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + springResponse) {
            overlayActive = false
        }
    }

    private func closeSettingsAnimated() {
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            settingsIndex = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + springResponse) {
            overlayActive = false
        }
    }

    private func closeCreateAnimated() {
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            isCreating = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + springResponse) {
            overlayActive = false
        }
    }

    // MARK: - Tap Gesture
    private var tapToExitEditing: some Gesture {
        TapGesture().onEnded {
            let shouldCatchTap =
                isEditing && expandedIndex == nil && settingsIndex == nil && !isCreating
            if shouldCatchTap { withAnimation(.easeInOut) { isEditing = false } }
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            NavigationLink {
                SettingsHomeView()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape")
                    Text(String(localized: "settings"))
                }
            }
            .disabled(hasAnyOverlayLocal)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation(.easeInOut) { isEditing.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                    Text(String(localized: "edit"))
                }
                .padding(.horizontal, 2)
            }
            .controlSize(.regular)
            .disabled(hasAnyOverlayLocal)
        }
    }
}
