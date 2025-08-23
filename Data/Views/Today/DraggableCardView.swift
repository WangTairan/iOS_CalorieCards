import SwiftUI

struct DraggableCardView: View {
    @Binding var card: MealCard
    let index: Int
    @Binding var cards: [MealCard]
    let isEditing: Bool
    @Binding var expandedIndex: Int?
    @Binding var settingsIndex: Int?
    @Binding var overlayActive: Bool
    var cardNS: Namespace.ID
    let onDelete: () -> Void
    let onSettings: () -> Void

    @GestureState private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    private let rowSize = 2   // 每行两列

    var body: some View {
        CardView(
            card: card,
            isEditing: isEditing,
            onDelete: onDelete,
            onSettings: onSettings
        )
        .aspectRatio(1, contentMode: .fit)
        .matchedGeometryEffect(id: card.id, in: cardNS, isSource: expandedIndex != index)
        .opacity(expandedIndex == index ? 0 : 1)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .zIndex(isDragging ? 1 : 0) // 拖拽中在最上层
        .offset(dragOffset)
        .gesture(
            isEditing ? dragGesture : nil
        )
        .onTapGesture {
            guard !isEditing else { return }
            overlayActive = true
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                    expandedIndex = index
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.35) {
            // ✅ 保留长按进入编辑模式
            withAnimation(.easeInOut) {
                if !isEditing {
                    isDragging = false
                }
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onChanged { value in
                if !isDragging {
                    withAnimation { isDragging = true }
                }
                reorderIfNeeded(translation: value.translation)
            }
            .onEnded { _ in
                withAnimation {
                    isDragging = false
                }
            }
    }

    /// 根据拖动方向和偏移量，实时调整数组顺序
    private func reorderIfNeeded(translation: CGSize) {
        guard let fromIndex = cards.firstIndex(of: card) else { return }

        // 根据拖动距离计算目标 index
        let cardWidth: CGFloat = 150 // 粗略估计卡片大小（或者用 GeometryReader 动态测量）
        let cardHeight: CGFloat = 150

        let rowOffset = Int((translation.height / cardHeight).rounded())
        let colOffset = Int((translation.width / cardWidth).rounded())

        let targetRow = fromIndex / rowSize + rowOffset
        let targetCol = fromIndex % rowSize + colOffset
        let toIndex = targetRow * rowSize + targetCol

        guard toIndex != fromIndex,
              toIndex >= 0, toIndex < cards.count else { return }

        withAnimation(.easeInOut) {
            let item = cards.remove(at: fromIndex)
            cards.insert(item, at: toIndex)
            MealCardStateStore.shared.saveAll(cards: cards)
        }
    }
}
