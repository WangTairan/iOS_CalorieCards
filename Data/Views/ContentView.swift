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
                    // 顶部合计
                    HStack {
                        Text(String(localized: "total_today"))
                            .font(.headline)
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
                                onDelete: {
                                    deleteCard(at: idx)
                                },
                                onSettings: {
                                    // 预留：设置行为
                                }
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .matchedGeometryEffect(id: cards[idx].id, in: cardNS, isSource: expandedIndex != idx)
                            .opacity(expandedIndex == idx ? 0 : 1)
                            .onTapGesture {
                                guard !isEditing else { return } // 编辑模式下不展开
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                    expandedIndex = idx
                                }
                            }
                        }
                        
                        // 编辑模式下：灰色“+”占位卡片（点击无动作）
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut) { isEditing.toggle() }
                    } label: {
                        Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle")
                    }
                }
            }
            .overlay {
                ZStack {
                    // 1) 已有卡片的“展开编辑”层
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
                    
                    // 2) 新建卡片的“白色扩展”层
                    if isCreating {
                        ExpandedNewCard(
                            existingNames: cards.map { $0.name.id },
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
                            }
                        )
                        .transition(.opacity)
                        .zIndex(11) // 在上面
                    }
                }
            }
        }
        .onAppear {
            if let savedCards = MealCardStateStore.shared.loadAll() {
                self.cards = savedCards
            } else {
                self.cards = [
                    MealCard(name: .breakfast),
                    MealCard(name: .lunch),
                    MealCard(name: .snack),
                    MealCard(name: .dinner)
                ]
                MealCardStateStore.shared.saveAll(cards: self.cards)
            }
        }
    }

    // MARK: - 操作
    private func deleteCard(at index: Int) {
        withAnimation(.easeInOut) {
            if expandedIndex == index { expandedIndex = nil }
            if let ex = expandedIndex, ex > index { expandedIndex = ex - 1 }
            cards.remove(at: index)
        }
        MealCardStateStore.shared.saveAll(cards: cards)
    }
}
