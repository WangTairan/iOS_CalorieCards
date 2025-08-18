import SwiftUI
import UIKit

struct ExpandedCardSettings: View {
    // 传入一个草稿（新建=空白草稿，编辑=现卡拷贝）
    let draft: MealCard

    // 用于重名校验；编辑时传入 originalName 以排除自身
    let existingNames: [String]
    let originalName: String?

    var onCancel: () -> Void
    var onSave: (MealCard) -> Void

    // 本地编辑状态（从 draft 初始化）
    @State private var pickedSymbol: String = "fork.knife"
    @State private var pickedColor: Color  = Color(.systemBlue)
    @State private var nameText: String = ""

    @State private var dragOffset: CGFloat = 0
    @FocusState private var nameFocused: Bool
    @State private var showDupHint: Bool = false

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
                .onTapGesture { onCancel() }

            VStack {
                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
                        .fill(.white)
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
            // 从 draft 初始化 UI
            pickedSymbol = draft.appearance?.symbol ?? draft.displaySymbol
            pickedColor  = draft.appearance?.color  ?? draft.displayColor
            nameText     = draft.name.rawValue
            nameFocused  = draft.name.rawValue.isEmpty // 新建时聚焦
        }
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(pickedColor.opacity(0.25))
                Image(systemName: pickedSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(pickedColor)
            }
            .frame(width: 32, height: 32)

            Text(nameText.isEmpty ? String(localized: "new_card") : String(localized: "edit_card"))
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    // MARK: Content
    private var contentBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            VStack(spacing: 12) {
                // 图标
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "icon")).font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(validSymbols, id: \.self) { s in
                                Button { pickedSymbol = s } label: {
                                    ZStack {
                                        Circle()
                                            .fill(s == pickedSymbol ? pickedColor.opacity(0.25) : Color.secondary.opacity(0.15))
                                            .overlay(
                                                Circle().strokeBorder(s == pickedSymbol ? pickedColor : .clear, lineWidth: 2)
                                            )
                                        Image(systemName: s)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(s == pickedSymbol ? pickedColor : .secondary)
                                    }
                                    .frame(width: 36, height: 36)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(ContentBlockStyle.padding)
                .background(RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius).fill(.thinMaterial))

                // 名称
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(String(localized: "title")).font(.headline)
                        if showDupHint {
                            Text(String(localized: "title_already_exists")).foregroundStyle(.red).font(.footnote)
                        }
                    }
                    TextField(String(localized: "title_example"), text: $nameText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($nameFocused)
                        .onSubmit { _ = validateName() }
                        .submitLabel(.done)
                }
                .padding(ContentBlockStyle.padding)
                .background(RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius).fill(.thinMaterial))

                // 颜色
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "color")).font(.headline)
                    Wrap(colors: colorCandidates, spacing: 10) { c in
                        Button { pickedColor = c } label: {
                            Circle()
                                .fill(c)
                                .overlay(
                                    Circle().strokeBorder(pickedColor.hexRGB == c.hexRGB ? Color.primary.opacity(0.9) : .clear, lineWidth: 2)
                                )
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(ContentBlockStyle.padding)
                .background(RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius).fill(.thinMaterial))
            }
            .padding(14)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: Bottom
    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button(role: .cancel) { onCancel() } label: {
                Text(LocalizedStringKey("cancel")).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.gray.opacity(0.35))

            Button {
                if validateName() {
                    let appearance = CardAppearance(symbol: pickedSymbol, colorHex: pickedColor.hexRGB)
                    var result = draft
                    result.name = CardName(rawValue: trimmedName())
                    result.appearance = appearance
                    onSave(result)                          // ← 统一回传
                }
            } label: {
                Text(LocalizedStringKey("save")).bold().frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.9))
            .foregroundStyle(.black)
            .disabled(trimmedName().isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: Helpers
    private var validSymbols: [String] {
        symbolCandidates.filter { UIImage(systemName: $0) != nil }
    }

    private func trimmedName() -> String {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validateName() -> Bool {
        let n = trimmedName().lowercased()
        var pool = Set(existingNames.map { $0.lowercased() })
        if let original = originalName?.lowercased() {
            pool.remove(original)                  // 编辑时排除自己的原名
        }
        let dup = pool.contains(n)
        showDupHint = dup
        if dup {
            nameText = ""
            nameFocused = true
        }
        return !dup && !n.isEmpty
    }

    private var dragToClose: some Gesture {
        DragGesture()
            .onChanged { v in dragOffset = max(0, v.translation.height) }
            .onEnded { v in
                if v.translation.height > 120 { onCancel() }
                else { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { dragOffset = 0 } }
            }
    }
}

struct Wrap<Data: RandomAccessCollection, Content: View>: View where Data.Element: Equatable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(colors: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = colors
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        var width: CGFloat = 0
        var height: CGFloat = 0
        return GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, element in
                    content(element)
                        .padding(.trailing, spacing)
                        .padding(.bottom, spacing)
                        .alignmentGuide(.leading) { d in
                            if (abs(width - d.width) > geo.size.width) {
                                width = 0
                                height -= d.height + spacing
                            }
                            let result = width
                            if element == data.last { width = 0 }
                            else { width -= d.width + spacing }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if element == data.last { height = 0 }
                            return result
                        }
                }
            }
        }
        .frame(height: 100) // 可按需调整
    }
}
