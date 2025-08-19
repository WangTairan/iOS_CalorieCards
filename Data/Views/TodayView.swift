import SwiftUI

struct TodayView: View {
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
    @State private var pendingCutoffHour = DayRollover.cutoffHour

    @Namespace private var cardNS

    private var totalKcal: Int { cards.reduce(0) { $0 + $1.kcal } }

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerBar
                    gridSection
                }
                .padding(16)
                .contentShape(Rectangle())
                .gesture(tapToExitEditing, including: .gesture)
            }
            .navigationTitle(String(localized: "app_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay { expandedOverlay }
        }
        .sheet(isPresented: $showingCutoffPicker) {
            DayEndPicker(
                selectedHour: $pendingCutoffHour,
                onCancel: { showingCutoffPicker = false },
                onSave: {
                    DayRollover.cutoffHour = pendingCutoffHour
                    MealCardStateStore.shared.saveAll(cards: cards)
                    showingCutoffPicker = false
                }
            )
            .presentationDetents([.height(320), .medium])
        }
        .onAppear {
            if let savedCards = MealCardStateStore.shared.loadAll() {
                self.cards = savedCards
            } else {
                MealCardStateStore.shared.saveAll(cards: self.cards)
            }
        }
    }

    // MARK: - Pieces

    private var headerBar: some View {
        HStack {
            Text(String(localized: "total_today")).font(.headline)
            Spacer()
            Text("kcal_with_unit \(Int64(totalKcal))")
                .font(.title2).bold().monospacedDigit()
        }
        .padding(.horizontal, 2)
    }

    private var gridSection: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(cards.indices, id: \.self) { idx in
                CardView(
                    card: cards[idx],
                    isEditing: isEditing,
                    onDelete: { deleteCard(at: idx) },
                    onSettings: {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            settingsIndex = idx
                        }
                    }
                )
                .aspectRatio(1, contentMode: .fit)
                .matchedGeometryEffect(id: cards[idx].id, in: cardNS, isSource: expandedIndex != idx)
                .opacity(expandedIndex == idx ? 0 : 1)
                .onTapGesture {
                    guard !isEditing else { return }
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        expandedIndex = idx
                    }
                }
                .onLongPressGesture(minimumDuration: 0.35) {
                    withAnimation(.easeInOut) { isEditing = true }
                }
            }

            if isEditing {
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        isCreating = true
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

    // 单独的退出编辑手势，避免把大闭包塞进 body
    private var tapToExitEditing: some Gesture {
        TapGesture().onEnded {
            let shouldCatchTap =
                isEditing &&
                expandedIndex == nil &&
                settingsIndex == nil &&
                !isCreating &&
                !showingCutoffPicker

            if shouldCatchTap {
                withAnimation(.easeInOut) { isEditing = false }
            }
        }
    }

    // 工具栏
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                pendingCutoffHour = DayRollover.cutoffHour
                showingCutoffPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.badge.checkmark")
                    Text(String(localized: "day_end"))
                }
            }
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
        }
    }

    // overlay 拆出去，减少主 body 的推断复杂度
    @ViewBuilder
    private var expandedOverlay: some View {
        ZStack {
            if let idx = expandedIndex {
                // ⚠️ 确认 ExpandedKcalCard 的参数名是否是 onFinish；如果你组件里叫 onSave，就把 onFinish 改成 onSave
                ExpandedKcalCard(
                    card: $cards[idx],
                    namespace: cardNS,
                    onFinish: { newKcal in
                        cards[idx].kcal = newKcal
                        MealCardStateStore.shared.saveAll(cards: cards)
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            expandedIndex = nil
                        }
                    },
                    onAutoUpdate: {
                        MealCardStateStore.shared.saveAll(cards: cards)
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }

            if let sidx = settingsIndex {
                ExpandedCardSettings(
                    draft: cards[sidx],
                    existingNames: cards.map { $0.name.id },
                    originalName: cards[sidx].name.rawValue,
                    onCancel: {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            settingsIndex = nil
                        }
                    },
                    onSave: { updated in
                        cards[sidx] = updated
                        MealCardStateStore.shared.saveAll(cards: cards)
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            settingsIndex = nil
                        }
                    },
                    onAutoUpdate: { updated in
                        cards[sidx] = updated
                        MealCardStateStore.shared.saveAll(cards: cards)
                    }
                )
                .transition(.opacity)
                .zIndex(11)
            }

            if isCreating {
                ExpandedCardSettings(
                    draft: MealCard(
                        name: CardName(rawValue: ""),
                        appearance: CardAppearance(symbol: "fork.knife", colorHex: Color(.systemBlue).hexRGB)
                    ),
                    existingNames: cards.map { $0.name.id },
                    originalName: nil,
                    onCancel: {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            isCreating = false
                        }
                    },
                    onSave: { newCard in
                        cards.append(newCard)
                        MealCardStateStore.shared.saveAll(cards: cards)
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                            isCreating = false
                        }
                    },
                    onAutoUpdate: { _ in } // 新建不需要实时保存
                )
                .transition(.opacity)
                .zIndex(11)
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
}
