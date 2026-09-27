import SwiftUI

struct ExpandedKcalCard: View {
    @Binding var card: MealCard
    var namespace: Namespace.ID
    var onFinish: (Int, Int, Int, Int) -> Void
    var onAutoUpdate: () -> Void

    @State private var showingPicker = false
    @State private var dragOffset: CGFloat = 0
    @State private var editingSetIndex: Int? = nil   // 当前进入编辑的套餐索引

    // ===== 手动文本绑定（总卡片层，含三大营养素）=====
    private var manualKcalBinding: Binding<String> {
        Binding(
            get: { card.manualKcalText ?? "" },
            set: { card.manualKcalText = $0; persistNowAndUpdateTotals() }
        )
    }
    private var manualProteinBinding: Binding<String> {
        Binding(
            get: { card.manualProteinText ?? "" },
            set: { card.manualProteinText = $0; persistNowAndUpdateTotals() }
        )
    }
    private var manualCarbBinding: Binding<String> {
        Binding(
            get: { card.manualCarbText ?? "" },
            set: { card.manualCarbText = $0; persistNowAndUpdateTotals() }
        )
    }
    private var manualFatBinding: Binding<String> {
        Binding(
            get: { card.manualFatText ?? "" },
            set: { card.manualFatText = $0; persistNowAndUpdateTotals() }
        )
    }

    // ===== 汇总（items 合计 + 卡片手动）=====
    private var itemsKcal: Double    { card.items.reduce(0) { $0 + $1.totalKcal    } }
    private var itemsProtein: Double { card.items.reduce(0) { $0 + $1.totalProtein } }
    private var itemsCarb: Double    { card.items.reduce(0) { $0 + $1.totalCarb    } }
    private var itemsFat: Double     { card.items.reduce(0) { $0 + $1.totalFat     } }

    private var extraKcal: Int    { max(0, Int(card.manualKcalText ?? "") ?? 0) }
    private var extraProtein: Int { max(0, Int(card.manualProteinText ?? "") ?? 0) }
    private var extraCarb: Int    { max(0, Int(card.manualCarbText ?? "") ?? 0) }
    private var extraFat: Int     { max(0, Int(card.manualFatText ?? "") ?? 0) }

    private var totalKcal: Int    { Int(itemsKcal.rounded())    + extraKcal }
    private var totalProtein: Int { Int(itemsProtein.rounded()) + extraProtein }
    private var totalCarb: Int    { Int(itemsCarb.rounded())    + extraCarb }
    private var totalFat: Int     { Int(itemsFat.rounded())     + extraFat }

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { finish() }

            VStack {
                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
                        .fill(card.displayColor)
                        .shadow(radius: CardStyle.shadowRadius, y: CardStyle.shadowYOffset)
                        .matchedGeometryEffect(id: card.id, in: namespace, isSource: false)

                    VStack(spacing: 14) {
                        header

                        // ⬇️ 在卡片内部“切页”：左侧是主列表；右侧是套餐面板
                        if let idx = editingSetIndex,
                           let binding = bindingMealSet(at: idx) {
                            MealSetPanel(
                                entry: binding,
                                onChange: { persistNowAndUpdateTotals() },
                                onBack:   { withAnimation(.easeInOut) { editingSetIndex = nil } }
                            )
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    if !card.items.isEmpty {
                                        itemsSection
                                    }
                                    addSection
                                    manualSection // 卡片层额外 kcal + 三大营养素
                                }
                                .padding(14)
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        }

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
        // 仅保留“选食物/套餐”的选择器
        .sheet(isPresented: $showingPicker) {
            FoodPicker(
                onSelectTemplate: { food in
                    let q: Double = (food.unit == .perPiece) ? 1 : 100
                    let portion = FoodPortion(template: food, defaultQuantity: q)
                    card.items.append(.food(portion))
                    persistNowAndUpdateTotals()
                },
                onSelectMealSet: { set in
                    let portions = FoodPortion.fromMealSet(set)
                    let entry = MealSetEntry(name: set.name, items: portions, manualKcalText: nil)
                    card.items.append(.mealSet(entry))
                    persistNowAndUpdateTotals()
                }
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("done") { dismissKeyboard() }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.white.opacity(0.2))
                Image(systemName: card.displaySymbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            Text(card.name.title)
                .font(.title3.bold())
                .foregroundStyle(.white)

            Spacer()

            Text("kcal_with_unit \(Int64(totalKcal))")
                .font(.headline).bold().monospacedDigit()
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    // MARK: - 列表（两种行）
    private var itemsSection: some View {
        VStack(spacing: 0) {
            ForEach(card.items.indices, id: \.self) { idx in
                switch card.items[idx] {
                case .food:
                    foodRow(index: idx)
                case .mealSet:
                    mealSetRow(index: idx)
                }
                if idx != card.items.indices.last {
                    Divider().padding(.leading, 12)
                }
            }
        }
        .padding(ContentBlockStyle.padding)
        .background(
            RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius)
                .fill(.thinMaterial)
        )
    }

    // —— 单食物行（复用你已有的 FoodPortionRow：三行）——
    @ViewBuilder
    private func foodRow(index idx: Int) -> some View {
        if case .food(let f) = card.items[idx] {
            let binding = Binding<FoodPortion>(
                get: { f },
                set: { card.items[idx] = .food($0) }
            )
            FoodPortionRow(
                item: binding,
                onDelete: {
                    withAnimation(.easeInOut) {
                        card.items.remove(at: idx)
                        persistNowAndUpdateTotals()
                    }
                },
                onChanged: { persistNowAndUpdateTotals() }
            )
        }
    }

    // —— 套餐行（两行 + chevron；点击进入内嵌面板）——
    @ViewBuilder
    private func mealSetRow(index idx: Int) -> some View {
        if case .mealSet(let s) = card.items[idx] {
            Button {
                withAnimation(.easeInOut) { editingSetIndex = idx }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    // 第 1 行：名字 + kcal + chevron
                    HStack(spacing: 8) {
                        Text(s.name)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 8)

                        HStack(spacing: 6) {
                            Text("kcal_with_unit \(Int64(s.kcal.rounded()))")
                                .bold().monospacedDigit()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 第 2 行：pcf（小字）
                    HStack(spacing: 12) {
                        macroText(labelKey: "macro_p", value: s.protein)
                        macroText(labelKey: "macro_c", value: s.carb)
                        macroText(labelKey: "macro_f", value: s.fat)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(role: .destructive) {
                    withAnimation(.easeInOut) {
                        card.items.remove(at: idx)
                        persistNowAndUpdateTotals()
                    }
                } label: {
                    Label(String(localized: "delete"), systemImage: "trash")
                }
            }
        }
    }

    // MARK: - 添加 / 手动
    private var addSection: some View {
        Button {
            showingPicker = true
        } label: {
            Label(LocalizedStringKey("add_from_food_library"), systemImage: "plus.circle")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(ContentBlockStyle.padding)
        .background(
            RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius)
                .fill(.thinMaterial)
        )
    }

    private var manualSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text(LocalizedStringKey("extra_add_kcal")).foregroundStyle(.secondary)
                Spacer()
                TextField("0", text: manualKcalBinding)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                Text(LocalizedStringKey("kcal_unit")).foregroundStyle(.secondary)
            }
            HStack {
                Text(LocalizedStringKey("extra_add_protein")).foregroundStyle(.secondary)
                Spacer()
                TextField("0", text: manualProteinBinding)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                Text(LocalizedStringKey("g_unit")).foregroundStyle(.secondary)
            }
            HStack {
                Text(LocalizedStringKey("extra_add_carb")).foregroundStyle(.secondary)
                Spacer()
                TextField("0", text: manualCarbBinding)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                Text(LocalizedStringKey("g_unit")).foregroundStyle(.secondary)
            }
            HStack {
                Text(LocalizedStringKey("extra_add_fat")).foregroundStyle(.secondary)
                Spacer()
                TextField("0", text: manualFatBinding)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                Text(LocalizedStringKey("g_unit")).foregroundStyle(.secondary)
            }
        }
        .padding(ContentBlockStyle.padding)
        .background(
            RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius)
                .fill(.thinMaterial)
        )
    }

    // MARK: - Bottom
    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button { finish() } label: {
                Text(String(localized: "finish"))
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.9))
            .foregroundStyle(.black)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: - Helpers
    private func macroText(labelKey: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Text(LocalizedStringKey(labelKey))
            Text(fmt(value)).monospacedDigit()
            Text(String(localized: "g_unit"))
        }
    }

    private func fmt(_ x: Double) -> String {
        let v = (x * 10).rounded() / 10
        if abs(v.rounded() - v) < 0.0001 { return String(Int(v)) }
        return String(format: "%.1f", v)
    }

    private var dragToClose: some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = max(0, value.translation.height) }
            .onEnded { value in
                if value.translation.height > 120 { finish() }
                else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func dismissKeyboard() {
    #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    #endif
    }

    // 汇总写回
    private func persistNowAndUpdateTotals() {
        card.kcal    = totalKcal
        card.protein = totalProtein
        card.carb    = totalCarb
        card.fat     = totalFat
        onAutoUpdate()
    }

    private func finish() {
        persistNowAndUpdateTotals()
        onFinish(totalKcal, totalProtein, totalCarb, totalFat)
    }

    // 取 items[idx] 的套餐可写绑定
    private func bindingMealSet(at index: Int) -> Binding<MealSetEntry>? {
        guard index >= 0 && index < card.items.count else { return nil }
        switch card.items[index] {
        case .mealSet(let val):
            return Binding<MealSetEntry>(
                get: { val },
                set: { card.items[index] = .mealSet($0) }
            )
        default:
            return nil
        }
    }
}

// 单食物行复用（与你现有的 FoodPortionRow 一致）
struct FoodPortionRow: View {
    @Binding var item: FoodPortion
    var onDelete: () -> Void
    var onChanged: () -> Void

    let fieldWidth = ControlsStyle.qtyFieldWidth5Digits
    let unitWidth  = ControlsStyle.unitLabelWidth

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(item.localizedName).font(.headline).lineLimit(1)
                Spacer(minLength: 8)
                Text("kcal_with_unit \(Int64(item.kcal.rounded()))")
                    .bold().monospacedDigit()
            }

            HStack(spacing: 12) {
                macro("macro_p", item.protein)
                macro("macro_c", item.carb)
                macro("macro_f", item.fat)
            }
            .font(.caption2).foregroundStyle(.secondary).monospacedDigit()

            HStack(alignment: .center, spacing: 12) {
                let isPiece = (item.unit == .perPiece)
                let step: Double = isPiece ? 1 : 20
                let maxValue: Double = isPiece ? 999 : 99_999

                Button {
                    item.quantity = max(1, item.quantity - step)
                    onChanged()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.blue)
                        .font(ControlsStyle.iconFont)
                }
                .buttonStyle(.plain)

                HStack(spacing: ControlsStyle.numberUnitSpacing) {
                    TextField("", value: $item.quantity, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .font(ControlsStyle.fieldFont)
                        .textFieldStyle(.plain)
                        .frame(width: fieldWidth)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.thinMaterial))
                        .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1))
                        .onChange(of: item.quantity) { _, _ in onChanged() }

                    Text(item.unitShortLocalized)
                        .foregroundStyle(.secondary)
                        .frame(width: unitWidth, alignment: .leading)
                }

                Button {
                    item.quantity += step
                    onChanged()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(ControlsStyle.iconFont)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                Button { withAnimation(.easeInOut) { onDelete() } } label: {
                    Image(systemName: "trash").foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }

    private func macro(_ k: String, _ v: Double) -> some View {
        HStack(spacing: 4) {
            Text(LocalizedStringKey(k))
            Text(String(format: v == floor(v) ? "%.0f" : "%.1f", v)).monospacedDigit()
            Text(String(localized: "g_unit"))
        }
    }
}

private extension CardEntry {
    var mealSet: MealSetEntry? {
        if case .mealSet(let s) = self { return s } else { return nil }
    }
}
