import SwiftUI
import UIKit

struct ExpandedCardSettings: View {
    let draft: MealCard
    let existingNames: [String]
    let originalName: String?          // nil=新建; 非nil=编辑

    var onCancel: () -> Void
    var onSave: (MealCard) -> Void
    var onAutoUpdate: (MealCard) -> Void   // ✅ 新增：编辑时的实时保存

    @State private var pickedSymbol: String = "fork.knife"
    @State private var pickedColor: Color  = Color(.systemBlue)
    @State private var nameText: String = ""

    @State private var dragOffset: CGFloat = 0
    @FocusState private var nameFocused: Bool
    @State private var showDupHint: Bool = false
    @State private var lastValidName: String = ""

    private var isEditingExisting: Bool { originalName != nil }

    private let symbolCandidates = [
        "fork.knife", "sunrise", "moon.stars", "takeoutbag.and.cup.and.straw",
        "leaf", "carrot", "cup.and.saucer"
    ]
    private let colorCandidates: [Color] = [
        Color(.systemBlue), Color(.systemTeal), Color(.systemGreen),
        Color(.systemOrange), Color(.systemRed), Color(.systemPink),
        Color(.systemPurple), Color(.systemIndigo), Color(.systemYellow)
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture {
                    if isEditingExisting {
                        finishIfValid()
                    } else {
                        onCancel()
                    }
                }

            VStack {
                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
                        .fill(pickedColor)
                        .shadow(radius: CardStyle.shadowRadius, y: CardStyle.shadowYOffset)

                    VStack(spacing: 14) {
                        header
                        contentBlock
                        bottomBar
                    }
                }
                .padding(.horizontal, ExpandedLayout.horizontalPadding)
                .padding(.vertical, ExpandedLayout.verticalPadding)
                .offset(y: dragOffset)
                .gesture(dragToClose)

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            // 新建用默认；编辑沿用原卡外观
            pickedSymbol = draft.appearance?.symbol ?? draft.displaySymbol
            pickedColor  = draft.appearance?.color  ?? draft.displayColor
            lastValidName = draft.name.rawValue   // ← 初始合法名
            nameText     = draft.name.rawValue
            nameFocused  = originalName == nil
        }
        // ✅ 编辑时：实时保存（名字合法才触发）
        .onChange(of: nameText) { _, _ in commitIfNeeded() }
        .onChange(of: pickedSymbol) { _, _ in commitIfNeeded() }
        .onChange(of: pickedColor)  { _, _ in commitIfNeeded() }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.25))
                Image(systemName: pickedSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            Text(isEditingExisting ? String(localized: "edit_card")
                                   : String(localized: "new_card"))
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    // MARK: - Content
    private var contentBlock: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            VStack(spacing: 12) {
                // 1) Title
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(String(localized: "title")).font(.headline)
                            .foregroundStyle(.primary)
                        if showDupHint {
                            Text(String(localized: "title_already_exists"))
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }
                    }
                    TextField("", text: $nameText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .autocorrectionDisabled()
                        .focused($nameFocused)
                        .onSubmit { _ = validateName() }
                        .submitLabel(.done)
                }
                .padding(ContentBlockStyle.padding)
                .background(
                    RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius).fill(.thinMaterial)
                )

                // 2) 图标
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "icon")).font(.headline)
                        .foregroundStyle(.primary)
                    Wrap(symbolCandidates, spacing: 10) { s in
                        Button { pickedSymbol = s } label: {
                            ZStack {
                                Circle()
                                    .fill(s == pickedSymbol ? Color.white.opacity(0.25) : Color.white.opacity(0.15))
                                    .overlay(
                                        Circle().strokeBorder(s == pickedSymbol ? .white : .clear, lineWidth: 2)
                                    )
                                Image(systemName: s)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .opacity(s == pickedSymbol ? 1 : 0.85)
                            }
                            .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(ContentBlockStyle.padding)
                .background(
                    RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius).fill(.thinMaterial)
                )

                // 3) 颜色
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "color")).font(.headline)
                        .foregroundStyle(.primary)
                    Wrap(colorCandidates, spacing: 10) { c in
                        Button { pickedColor = c } label: {
                            Circle()
                                .fill(c)
                                .overlay(
                                    Circle().strokeBorder(
                                        pickedColor.hexRGB == c.hexRGB ? Color.primary.opacity(0.9) : .clear,
                                        lineWidth: 2
                                    )
                                )
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(ContentBlockStyle.padding)
                .background(
                    RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius).fill(.thinMaterial)
                )
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Bottom
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if isEditingExisting {
                // 编辑：只有 Finish
                Button {
                    finishIfValid()
                } label: {
                    Text(LocalizedStringKey("finish"))
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.9))
                .foregroundStyle(.black)
                .disabled(!canCommit)
            } else {
                // 新建：Cancel + Save
                Button(role: .cancel) { onCancel() } label: {
                    Text(LocalizedStringKey("cancel")).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray.opacity(0.35))

                Button {
                    if validateName() {
                        onSave(buildResult())
                    }
                } label: {
                    Text(LocalizedStringKey("save")).bold().frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.9))
                .foregroundStyle(.black)
                .disabled(trimmedName().isEmpty)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: - Helpers
    private var canCommit: Bool {
        // 名称合法（非空、且在“允许同名保留原名”的前提下不重复）
        let n = trimmedName().lowercased()
        if n.isEmpty { return false }
        var pool = Set(existingNames.map { $0.lowercased() })
        if let original = originalName?.lowercased() { pool.remove(original) }
        return !pool.contains(n)
    }

    private func buildResult() -> MealCard {
        var result = draft
        result.name = CardName(rawValue: trimmedName())
        result.appearance = CardAppearance(symbol: pickedSymbol, colorHex: pickedColor.hexRGB)
        return result
    }

    private func trimmedName() -> String {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validateName() -> Bool {
        let ok = canCommit
        showDupHint = !ok
        if !ok { nameFocused = true }
        return ok
    }

    // 编辑时：只要可提交就触发实时保存
    private func commitIfNeeded() {
        guard isEditingExisting, canCommit else { return }
        let result = buildResult()
        lastValidName = trimmedName()         // ← 提交成功后，刷新最近合法名
        onAutoUpdate(result)
    }

    private func finishIfValid() {
        if canCommit {
            onSave(buildResult())
        } else {
            // 名字不合法（重复或为空）
            showDupHint = true
            nameFocused = true
            // 回退：编辑回退到最近合法名；新建回退为空
            if isEditingExisting {
                nameText = lastValidName
            } else {
                nameText = ""
            }
        }
    }


    // MARK: - Gestures
    private var dragToClose: some Gesture {
        DragGesture()
            .onChanged { v in dragOffset = max(0, v.translation.height) }
            .onEnded { v in
                if v.translation.height > 120 {
                    if isEditingExisting {
                        finishIfValid()  // 编辑：Finish
                    } else {
                        onCancel()       // 新建：Cancel
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { dragOffset = 0 }
                }
            }
    }
}

// Wrap & FlowLayout 同你现有版本


// 简易换行容器（图标/颜色通用）— 使用 Layout，稳定左对齐换行
struct Wrap<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(_ data: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
    }
}

// 基于 Layout 的流式布局：从左到右，放不下则换行到下一行，从左边重新开始
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {      // 换行
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {      // 换行
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            sub.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                      proposal: ProposedViewSize(size))
            lineHeight = max(lineHeight, size.height)
            x += size.width + spacing
        }
    }
}
