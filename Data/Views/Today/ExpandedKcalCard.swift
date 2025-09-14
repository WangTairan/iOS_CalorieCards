import SwiftUI

struct ExpandedKcalCard: View {
    @Binding var card: MealCard
    var namespace: Namespace.ID
    var onFinish: (Int, Int, Int, Int) -> Void
    var onAutoUpdate: () -> Void

    @State private var showingPicker = false
    @State private var dragOffset: CGFloat = 0

    // MARK: - 手动输入绑定（kcal + 三大营养素）
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

    // MARK: - 汇总（kcal 允许手动加成；三大营养素也允许手动加成）
    private var totalFromItemsKcal: Double {
        card.items.reduce(0.0) { $0 + $1.kcal }
    }
    private var totalFromItemsProtein: Double {
        card.items.reduce(0.0) { $0 + $1.protein }
    }
    private var totalFromItemsCarb: Double {
        card.items.reduce(0.0) { $0 + $1.carb }
    }
    private var totalFromItemsFat: Double {
        card.items.reduce(0.0) { $0 + $1.fat }
    }

    // 额外手动（非法/空 → 0；不为负）
    private var extraManualKcal: Int { max(0, Int(card.manualKcalText ?? "") ?? 0) }
    private var extraManualProtein: Int { max(0, Int(card.manualProteinText ?? "") ?? 0) }
    private var extraManualCarb: Int    { max(0, Int(card.manualCarbText ?? "") ?? 0) }
    private var extraManualFat: Int     { max(0, Int(card.manualFatText ?? "") ?? 0) }

    private var totalKcal: Int {
        Int(totalFromItemsKcal.rounded()) + extraManualKcal
    }
    private var totalProtein: Int {
        Int(totalFromItemsProtein.rounded()) + extraManualProtein
    }
    private var totalCarb: Int {
        Int(totalFromItemsCarb.rounded()) + extraManualCarb
    }
    private var totalFat: Int {
        Int(totalFromItemsFat.rounded()) + extraManualFat
    }

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

                        ScrollView {
                            VStack(spacing: 12) {
                                if !card.items.isEmpty {
                                    itemsSection
                                }
                                addSection
                                manualKcalSection   // ⬅️ 下方包含“手动三大营养素”
                            }
                            .padding(14)
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
        .sheet(isPresented: $showingPicker) {
            FoodPicker(
                onSelectTemplate: { food in
                    let exists = card.items.contains { $0.localizedName == food.localizedName }
                    if !exists {
                        let q: Double = (food.unit == .perPiece) ? 1 : 100
                        card.items.append(FoodPortion(template: food, defaultQuantity: q))
                        persistNowAndUpdateTotals()
                    }
                },
                onSelectMealSet: { portions in
                    let existingNames = Set(card.items.map { $0.localizedName })
                    let newOnes = portions.filter { !existingNames.contains($0.localizedName) }
                    card.items.append(contentsOf: newOnes)
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

    // MARK: - 三块内容
    private var itemsSection: some View {
        VStack(spacing: 0) {
            ForEach($card.items) { $item in
                itemRow(item: $item)
                if item.id != card.items.last?.id {
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

    // ✅ 额外热量 + 手动三大营养素（连在一起，风格一致）
    private var manualKcalSection: some View {
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

    // MARK: - Bottom Bar
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

    // MARK: - Row（三行：标题+热量 / PCF / 数量控制+删除）
    @ViewBuilder
    private func itemRow(item: Binding<FoodPortion>) -> some View {
        let isPiece = (item.wrappedValue.unit == .perPiece)
        let fieldWidth = ControlsStyle.qtyFieldWidth5Digits
        let unitWidth  = ControlsStyle.unitLabelWidth
        let step: Double = isPiece ? 1 : 20
        let maxValue: Double = isPiece ? 999 : 99_999

        VStack(alignment: .leading, spacing: 6) {
            // 第 1 行：名字 + 热量
            HStack(spacing: 8) {
                Text(item.wrappedValue.localizedName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 8)

                Text("kcal_with_unit \(Int64(item.wrappedValue.kcal.rounded()))")
                    .bold()
                    .monospacedDigit()
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(minWidth: 0, maxWidth: ControlsStyle.kcalColumnMaxWidth, alignment: .trailing)
            }

            // 第 2 行：PCF
            HStack(spacing: 12) {
                macroText(labelKey: "macro_p", value: item.wrappedValue.protein)
                macroText(labelKey: "macro_c", value: item.wrappedValue.carb)
                macroText(labelKey: "macro_f", value: item.wrappedValue.fat)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .monospacedDigit()

            // 第 3 行：数量控制 + 删除
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 0) {
                    let canDecrement = item.quantity.wrappedValue > 1
                    let canIncrement = item.quantity.wrappedValue < maxValue

                    Button {
                        item.quantity.wrappedValue = max(1, item.quantity.wrappedValue - step)
                        enforceDigitLimit(for: &item.wrappedValue, maxValue: Double(maxValue), integerOnly: true)
                        persistNowAndUpdateTotals()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.blue)
                            .font(ControlsStyle.iconFont)
                            .opacity(canDecrement ? 1 : 0.4)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canDecrement)

                    Spacer().frame(width: ControlsStyle.ctrlOuterSpacing)

                    HStack(spacing: ControlsStyle.numberUnitSpacing) {
                        TextField("", value: item.quantity, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .monospacedDigit()
                            .font(ControlsStyle.fieldFont)
                            .textFieldStyle(.plain)
                            .frame(width: fieldWidth)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.thinMaterial))
                            .overlay(
                                Capsule().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1)
                            )
                            .onChange(of: item.quantity.wrappedValue) { _, _ in
                                enforceDigitLimit(for: &item.wrappedValue, maxValue: Double(maxValue), integerOnly: true)
                                persistNowAndUpdateTotals()
                            }

                        Text(item.wrappedValue.unitShortLocalized)
                            .foregroundStyle(.secondary)
                            .frame(width: unitWidth, alignment: .leading)
                    }

                    Spacer().frame(width: ControlsStyle.ctrlOuterSpacing)

                    Button {
                        item.quantity.wrappedValue += step
                        enforceDigitLimit(for: &item.wrappedValue, maxValue: Double(maxValue), integerOnly: true)
                        persistNowAndUpdateTotals()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(ControlsStyle.iconFont)
                            .opacity(canIncrement ? 1 : 0.4)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canIncrement)
                }

                Spacer(minLength: 8)

                Button {
                    withAnimation(.easeInOut) {
                        card.items.removeAll { $0.id == item.wrappedValue.id }
                        persistNowAndUpdateTotals()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .tint(.red)
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers
    private func enforceDigitLimit(for portion: inout FoodPortion,
                                   maxValue: Double,
                                   integerOnly: Bool)
    {
        var q = portion.quantity
        if integerOnly { q = Double(Int(q.rounded())) }
        q = max(1, min(q, maxValue))
        portion.quantity = q
    }

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

    // MARK: - Gestures
    private var dragToClose: some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = max(0, value.translation.height) }
            .onEnded { value in
                if value.translation.height > 120 {
                    finish()
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func dismissKeyboard() {
    #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    #endif
    }

    // MARK: - Persist + Finish
    private func persistNowAndUpdateTotals() {
        // kcal
        card.kcal = totalKcal
        // macros（含手动加成）
        card.protein = totalProtein
        card.carb    = totalCarb
        card.fat     = totalFat
        onAutoUpdate()
    }

    private func finish() {
        persistNowAndUpdateTotals()
        onFinish(totalKcal, totalProtein, totalCarb, totalFat)
    }
}
