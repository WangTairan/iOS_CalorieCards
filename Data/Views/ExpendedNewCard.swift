import SwiftUI

struct ExpandedNewCard: View {
    // 现有卡片列表（用于重名校验）
    let existingNames: [String]

    // 交互回调
    var onCancel: () -> Void
    var onSave: (MealCard) -> Void

    // 本地状态：选择项
    @State private var pickedSymbol: String = "fork.knife"
    @State private var pickedColor: Color  = Color(.systemBlue)
    @State private var nameText: String = ""

    @State private var dragOffset: CGFloat = 0
    @FocusState private var nameFocused: Bool
    @State private var showDupHint: Bool = false

    // 你可按需补充更多图标/颜色
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
        .onAppear { nameFocused = true }
    }

    // 顶部
    private var header: some View {
        HStack(spacing: 10) {
            // 预览左上角样式（与 CardView 一致）
            ZStack {
                Circle().fill(pickedColor.opacity(0.25))
                Image(systemName: pickedSymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(pickedColor)
            }
            .frame(width: 32, height: 32)

            Text("New Card")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    // 内容
    private var contentBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            VStack(spacing: 12) {

                // 选择图标
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(symbolCandidates, id: \.self) { s in
                                Button {
                                    pickedSymbol = s
                                } label: {
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

                // 名称输入
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Name").font(.headline)
                        if showDupHint {
                            Text("Name already exists").foregroundStyle(.red).font(.footnote)
                        }
                    }
                    TextField("e.g. Midnight Snack", text: $nameText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($nameFocused)
                        .onSubmit { validateName() }
                        .submitLabel(.done)
                }
                .padding(ContentBlockStyle.padding)
                .background(RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius).fill(.thinMaterial))

                // 颜色选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color").font(.headline)
                    Wrap(colors: colorCandidates, spacing: 10) { c in
                        Button {
                            pickedColor = c
                        } label: {
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

    // 底部按钮（位置与样式沿用）
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
                    let new = MealCard(name: CardName(rawValue: trimmedName()),
                                       kcal: 0,
                                       items: [],
                                       manualKcalText: nil,
                                       appearance: appearance)
                    onSave(new)
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

    // 名称校验
    @discardableResult
    private func validateName() -> Bool {
        let n = trimmedName().lowercased()
        let dup = existingNames.map { $0.lowercased() }.contains(n)
        showDupHint = dup
        if dup {
            nameText = ""              // 清空
            nameFocused = true
        }
        return !dup && !n.isEmpty
    }

    private func trimmedName() -> String {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 下拉关闭手势
    private var dragToClose: some Gesture {
        DragGesture()
            .onChanged { v in dragOffset = max(0, v.translation.height) }
            .onEnded { v in
                if v.translation.height > 120 { onCancel() }
                else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { dragOffset = 0 }
                }
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
