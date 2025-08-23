import SwiftUI
import Combine

// 供 ContentView 发出“点击任何非卡片区域关闭”用
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

    @State private var showingCutoffPicker = false
    @State private var pendingCutoffHour = DayCycleManager.shared.currentCutoff

    @Namespace private var cardNS

    private let springResponse: Double = 0.38
    private let springDamping: Double  = 0.86

    @State private var overlayActive: Bool = false
    @State private var cycleKey = DayCycleManager.shared.currentCycleKey()
    @State private var cancellables = Set<AnyCancellable>()

    private var totalKcal: Int { cards.reduce(0) { $0 + $1.kcal } }
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var showingOverlayContent: Bool { expandedIndex != nil || settingsIndex != nil || isCreating }
    private var hasAnyOverlayLocal: Bool { overlayActive || showingOverlayContent }

    var body: some View {
        NavigationStack {
            ZStack {
                // ===== 背景内容 =====
                ScrollView {
                    VStack(spacing: 16) {
                        headerBar
                        gridSection
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                    .gesture(tapToExitEditing, including: .gesture)
                }
                .allowsHitTesting(!hasAnyOverlayLocal)

                // ===== 幕布 =====
                if showingOverlayContent {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { closeOverlayAnimated() }
                        .transition(.opacity)
                        .zIndex(1)
                }

                // ===== 展开卡片 =====
                if let idx = expandedIndex {
                    ExpandedKcalCard(
                        card: $cards[idx],
                        namespace: cardNS,
                        onFinish: { newKcal in
                            cards[idx].kcal = newKcal
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

                // ===== 设置面板 =====
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

                // ===== 新建面板 =====
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
        .sheet(isPresented: $showingCutoffPicker) {
            DayEndPicker(
                selectedHour: $pendingCutoffHour,
                onCancel: { showingCutoffPicker = false },
                onSave: {
                    DayCycleManager.shared.setCutoff(to: pendingCutoffHour)
                    MealCardStateStore.shared.saveAll(cards: cards)
                    showingCutoffPicker = false
                }
            )
            .presentationDetents([.height(320), .medium])
        }
        .onAppear {
            DayCycleManager.shared.tick()
            cards = MealCardStateStore.shared.loadOrInitCards()
            cycleKey = DayCycleManager.shared.currentCycleKey()
            hasOverlay = hasAnyOverlayLocal
        }
        .onDisappear { hasOverlay = false }
        .onChange(of: showingOverlayContent) { v in hasOverlay = v || overlayActive }
        .onChange(of: overlayActive) { v in hasOverlay = v || showingOverlayContent }
        .onReceive(NotificationCenter.default.publisher(for: .closeTodayOverlay)) { _ in
            if hasAnyOverlayLocal { closeOverlayAnimated() }
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            Text(String(localized: "total_today")).font(.headline)
            Spacer()
            Text("kcal_with_unit \(Int64(totalKcal))")
                .font(.title2).bold().monospacedDigit()
        }
        .padding(.horizontal, 2)
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
                    onMoveRight: { moveRight(at: idx) }   // ✅ 新增
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

    /// ✅ 新增：向右移动卡片
    private func moveRight(at index: Int) {
        withAnimation(.easeInOut) {
            guard !cards.isEmpty else { return }
            if index == cards.count - 1 {
                // 最后一个 → 移动到开头
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
                isEditing && expandedIndex == nil && settingsIndex == nil && !isCreating && !showingCutoffPicker
            if shouldCatchTap { withAnimation(.easeInOut) { isEditing = false } }
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                pendingCutoffHour = DayCycleManager.shared.currentCutoff
                showingCutoffPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark")
                    Text(String(localized: "day_end"))
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
