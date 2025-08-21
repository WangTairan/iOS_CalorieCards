import SwiftUI

struct ExpandedKcalCard: View {
    @Binding var card: MealCard
    var namespace: Namespace.ID
    var onFinish: (Int) -> Void
    var onAutoUpdate: () -> Void

    @State private var showingPicker = false
    @State private var dragOffset: CGFloat = 0

    // 绑定手动 kcal 的 TextField，手动修改后立刻更新变化
    private var manualTextBinding: Binding<String> {
        Binding(
            get: { card.manualKcalText ?? "" },
            set: { card.manualKcalText = $0; persistNowAndUpdateKcal() }
        )
    }

    private var totalKcal: Int {
        let sumFromItems = card.items.reduce(0.0) { $0 + $1.kcal }
        let extraManual = Int(card.manualKcalText ?? "") ?? 0
        return Int(sumFromItems.rounded()) + max(0, extraManual)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { finish() }   // 点击幕布关闭

            VStack {
                Spacer(minLength: 0)

                ZStack {
                    RoundedRectangle(cornerRadius: CardStyle.cornerRadius, style: .continuous)
                        .fill(card.displayColor)
                        .shadow(radius: CardStyle.shadowRadius, y: CardStyle.shadowYOffset)
                        .matchedGeometryEffect(id: card.id, in: namespace, isSource: false)

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
        .sheet(isPresented: $showingPicker) {
            FoodPicker(
                onSelectTemplate: { food in
                    let q: Double = (food.unit == .perPiece) ? 1 : 100
                    card.items.append(FoodPortion(template: food, defaultQuantity: q))
                    persistNowAndUpdateKcal()
                },
                onSelectMealSet: { portions in
                    card.items.append(contentsOf: portions)
                    persistNowAndUpdateKcal()
                }
            )
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

    // MARK: - Content
    private var contentBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)

            ScrollView {
                VStack(spacing: 12) {
                    if !card.items.isEmpty {
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

                    HStack {
                        Text(LocalizedStringKey("extra_add_kcal")).foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: manualTextBinding)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        Text(LocalizedStringKey("kcal_unit")).foregroundStyle(.secondary)
                    }
                    .padding(ContentBlockStyle.padding)
                    .background(
                        RoundedRectangle(cornerRadius: ContentBlockStyle.cornerRadius)
                            .fill(.thinMaterial)
                    )
                }
                .padding(14)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                finish()
            } label: {
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

    // MARK: - Row
    @ViewBuilder
    private func itemRow(item: Binding<FoodPortion>) -> some View {
        let isPiece = (item.wrappedValue.unit == .perPiece)
        let fieldWidth = ControlsStyle.qtyFieldWidth5Digits
        let unitWidth  = ControlsStyle.unitLabelWidth
        let step: Double = isPiece ? 1 : 50
        let maxValue: Double = isPiece ? 999 : 99_999

        VStack(alignment: .leading, spacing: 6) {
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

            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 0) {
                    let canDecrement = item.quantity.wrappedValue > 1
                    let canIncrement = item.quantity.wrappedValue < maxValue

                    Button {
                        item.quantity.wrappedValue = max(1, item.quantity.wrappedValue - step)
                        enforceDigitLimit(for: &item.wrappedValue, maxValue: Double(maxValue), integerOnly: true)
                        persistNowAndUpdateKcal()
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
                                persistNowAndUpdateKcal()
                            }

                        Text(item.wrappedValue.unitShortLocalized)
                            .foregroundStyle(.secondary)
                            .frame(width: unitWidth, alignment: .leading)
                    }

                    Spacer().frame(width: ControlsStyle.ctrlOuterSpacing)

                    Button {
                        item.quantity.wrappedValue += step
                        enforceDigitLimit(for: &item.wrappedValue, maxValue: Double(maxValue), integerOnly: true)
                        persistNowAndUpdateKcal()
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
                        persistNowAndUpdateKcal()
                    }
                } label: {
                    Image(systemName: "trash")
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

    // MARK: - Gestures
    private var dragToClose: some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = max(0, value.translation.height) }
            .onEnded { value in
                if value.translation.height > 120 {
                    finish()  // 下拉超过阈值也 Finish
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Persist + Finish
    private func persistNowAndUpdateKcal() {
        card.kcal = totalKcal
        onAutoUpdate()
    }

    private func finish() {
        persistNowAndUpdateKcal()
        onFinish(totalKcal)   // 通知上层退出
    }
}
