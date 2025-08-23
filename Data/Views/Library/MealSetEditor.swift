// Views/MealSetEditor.swift
import SwiftUI
import SwiftData

private struct EditablePortion: Identifiable, Equatable {
    let id = UUID()
    var template: FoodTemplate
    var portion: FoodPortion
}

struct MealSetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // 传入即为“编辑模式”；默认 nil 为“新建模式”
    let existingSet: MealSet?

    @State private var name: String = ""
    @State private var items: [EditablePortion] = []
    @State private var showingPicker = false
    @State private var didPrefill = false

    init(existingSet: MealSet? = nil) {
        self.existingSet = existingSet
    }

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "set_name")) {
                    TextField(String(localized: "enter_name"), text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }

                if !items.isEmpty {
                    Section(String(localized: "chosen_foods")) {
                        ForEach($items) { $ep in
                            PortionRow(portion: $ep.portion) {
                                items.removeAll { $0.id == ep.id }
                            }
                        }
                        .onDelete { idx in idx.forEach { items.remove(at: $0) } }
                    }
                }

                Button {
                    showingPicker = true
                } label: {
                    Label(String(localized: "add_from_food_library"), systemImage: "plus.circle")
                }
            }
            .navigationTitle(existingSet == nil ? String(localized: "new_meal_set")
                                                : String(localized: "edit_meal_set"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: prefillIfNeeded)
        }
        .sheet(isPresented: $showingPicker) {
            FoodPicker(mode: .templatesOnly) { food in
                let exists = items.contains { $0.template.localizedName == food.localizedName }
                if !exists {
                    let q: Double = (food.unit == .perPiece) ? 1 : 100
                    let portion = FoodPortion(template: food, defaultQuantity: q)
                    items.append(EditablePortion(template: food, portion: portion))
                }
            }
        }
    }

    private func prefillIfNeeded() {
        guard !didPrefill, let set = existingSet else { return }
        didPrefill = true
        name = set.name
        items = set.items.compactMap { item in
            guard let portion = FoodPortion(item: item) else { return nil }
            return EditablePortion(template: item.template, portion: portion)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty
    }

    private func save() {
        let msItems: [MealSetItem] = items.map { ep in
            MealSetItem(template: ep.template, defaultQuantity: ep.portion.quantity)
        }

        if let set = existingSet {
            // 编辑模式：更新原对象
            set.name = name.trimmingCharacters(in: .whitespaces)
            set.items = msItems
        } else {
            // 新建模式
            let set = MealSet(name: name.trimmingCharacters(in: .whitespaces), items: msItems)
            context.insert(set)
        }
        try? context.save()
        dismiss()
    }
}

// 与 ExpandedKcalCard 一致的行控件
private struct PortionRow: View {
    @Binding var portion: FoodPortion
    var onDelete: () -> Void

    private var isPiece: Bool { portion.unit == .perPiece }
    private var step: Double { isPiece ? 1 : 50 }
    private var maxValue: Double { isPiece ? 999 : 99_999 }
    private var unitShort: String {
        portion.unitShortLocalized   // 动态：pc/个、g/克、ml/毫升（随系统语言）
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(portion.localizedName).font(.headline).lineLimit(1)
                Spacer(minLength: 8)
                Text("kcal_with_unit \(Int64(portion.kcal.rounded()))")
                    .bold().monospacedDigit().lineLimit(1)
            }

            HStack(alignment: .center, spacing: 12) {
                let canDec = portion.quantity > 1
                let canInc = portion.quantity < maxValue

                Button {
                    portion.quantity = max(1, portion.quantity - step)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20, weight: .semibold))
                        .opacity(canDec ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .disabled(!canDec)

                Spacer().frame(width: 10)

                HStack(spacing: 8) {
                    TextField("", value: $portion.quantity, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .monospacedDigit()
                        .font(.system(size: 16, weight: .semibold))
                        .textFieldStyle(.plain)
                        .frame(width: 72)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.thinMaterial))
                        .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1))
                        .onChange(of: portion.quantity) { _, _ in clamp() }

                    Text(unitShort).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
                }

                Spacer().frame(width: 10)

                Button {
                    portion.quantity += step
                    clamp()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20, weight: .semibold))
                        .opacity(canInc ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .disabled(!canInc)

                Spacer(minLength: 8)

                Button { onDelete() } label: { Image(systemName: "trash") }
                    .tint(.red)
                    .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }

    private func clamp() {
        var q = portion.quantity
        q = Double(Int(q.rounded()))
        q = max(1, min(q, maxValue))
        portion.quantity = q
    }
}
