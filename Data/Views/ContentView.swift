import SwiftUI

struct ContentView: View {
    @State private var cards: [MealCard] = [
        MealCard(name: .breakfast),
        MealCard(name: .lunch),
        MealCard(name: .snack),
        MealCard(name: .dinner)
    ]

    @State private var expandedIndex: Int? = nil
    @State private var isEditing = false
    @State private var isCreating = false
    @State private var settingsIndex: Int? = nil      // ← 用于“编辑设置”
    
    @State private var showingCutoffPicker = false          // ✅ 新增：是否显示日切时间选择
    @State private var pendingCutoffHour = DayRollover.cutoffHour
    
    
    @Namespace private var cardNS

    private var totalKcal: Int { cards.reduce(0) { $0 + $1.kcal } }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text(String(localized: "total_today")).font(.headline)
                        Spacer()
                        Text("kcal_with_unit \(Int64(totalKcal))")
                            .font(.title2).bold().monospacedDigit()
                    }
                    .padding(.horizontal, 2)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(cards.indices, id: \.self) { idx in
                            CardView(
                                card: cards[idx],
                                isEditing: isEditing,
                                onDelete: { deleteCard(at: idx) },
                                onSettings: {                         // ✅ 打开“统一设置面板”
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
                        }

                        // 编辑模式：灰色 “+”
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
                .padding(16)
            }
            .navigationTitle(String(localized: "app_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // ✅ 左上角：设置“每天结束时间”
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        pendingCutoffHour = DayRollover.cutoffHour
                        showingCutoffPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.checkmark")
                            Text(String(localized: "day_end")) // 你翻译里对应“每天结束时间”的 key
                        }
                    }
                }
                // 右上角：Edit
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
            .overlay {
                ZStack {
                    // ① 展开卡：热量编辑
                    if let idx = expandedIndex {
                        ExpandedKcalCard(
                            card: $cards[idx],
                            namespace: cardNS,
                            onSave: { newKcal in
                                cards[idx].kcal = newKcal
                                MealCardStateStore.shared.saveAll(cards: cards)
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                    expandedIndex = nil
                                }
                            },
                            onCancel: {
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

                    // ② 统一设置面板：编辑（传入现有卡片的拷贝）
                    if let sidx = settingsIndex {
                        ExpandedCardSettings(
                            draft: cards[sidx],                                   // ← 以现卡为草稿
                            existingNames: cards.map { $0.name.id },
                            originalName: cards[sidx].name.rawValue,              // ← 排除自己
                            onCancel: {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                    settingsIndex = nil
                                }
                            },
                            onSave: { updated in                                   // ← 替换
                                cards[sidx] = updated
                                MealCardStateStore.shared.saveAll(cards: cards)
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                    settingsIndex = nil
                                }
                            }
                        )
                        .transition(.opacity)
                        .zIndex(11)
                    }

                    // ③ 统一设置面板：新建（传入空白草稿）
                    if isCreating {
                        ExpandedCardSettings(
                            draft: MealCard(                                     // ← 空白草稿
                                name: CardName(rawValue: ""),
                                appearance: CardAppearance(symbol: "fork.knife", colorHex: Color(.systemBlue).hexRGB)
                            ),
                            existingNames: cards.map { $0.name.id },
                            originalName: nil,                                    // ← 新建：无原名
                            onCancel: {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                    isCreating = false
                                }
                            },
                            onSave: { newCard in                                   // ← 追加
                                cards.append(newCard)
                                MealCardStateStore.shared.saveAll(cards: cards)
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                    isCreating = false
                                }
                            }
                        )
                        .transition(.opacity)
                        .zIndex(11)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCutoffPicker) {          // ✅ 弹出选择面板
            DayEndPicker(
                selectedHour: $pendingCutoffHour,
                onCancel: { showingCutoffPicker = false },
                onSave: {
                    DayRollover.cutoffHour = pendingCutoffHour   // 持久化
                    // 立刻用新周期键落库 —— 使之“当天立即生效”
                    MealCardStateStore.shared.saveAll(cards: cards)
                    showingCutoffPicker = false
                }
            )
            .presentationDetents([.height(320), .medium])    // 可调
        }
        .onAppear {
            if let savedCards = MealCardStateStore.shared.loadAll() {
                self.cards = savedCards
            } else {
                MealCardStateStore.shared.saveAll(cards: self.cards)
            }
        }
    }

    private func deleteCard(at index: Int) {
        withAnimation(.easeInOut) {
            if expandedIndex == index { expandedIndex = nil }
            if let ex = expandedIndex, ex > index { expandedIndex = ex - 1 }
            cards.remove(at: index)
        }
        MealCardStateStore.shared.saveAll(cards: cards)
    }
}
