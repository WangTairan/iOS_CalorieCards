import SwiftUI

struct GoalSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppKeys.dailyKcalGoal)    private var dailyKcalGoal: Int = 2000
    @AppStorage(AppKeys.dailyProteinGoal) private var dailyProteinGoal: Int = 125
    @AppStorage(AppKeys.dailyCarbGoal)    private var dailyCarbGoal: Int = 250
    @AppStorage(AppKeys.dailyFatGoal)     private var dailyFatGoal: Int = 56

    @FocusState private var focus: Bool

    @State private var kcalText: String = ""
    @State private var proteinText: String = ""
    @State private var carbText: String = ""
    @State private var fatText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Daily kcal goal
                Section(header: Text(String(localized: "daily_goal"))) {
                    HStack {
                        Text(String(localized: "kcal_goal"))
                        Spacer()
                        TextField("2000", text: $kcalText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($focus)
                            .onChange(of: kcalText) { onlyDigits(&kcalText) }
                        Text(String(localized: "kcal_unit"))
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - Macros goals
                Section(header: Text(String(localized: "macros_goal"))) {
                    HStack {
                        Text(String(localized: "protein_goal"))
                        Spacer()
                        TextField("125", text: $proteinText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: proteinText) { onlyDigits(&proteinText) }
                        Text(String(localized: "g_unit")).foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(String(localized: "carb_goal"))
                        Spacer()
                        TextField("250", text: $carbText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: carbText) { onlyDigits(&carbText) }
                        Text(String(localized: "g_unit")).foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(String(localized: "fat_goal"))
                        Spacer()
                        TextField("56", text: $fatText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .onChange(of: fatText) { onlyDigits(&fatText) }
                        Text(String(localized: "g_unit")).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "goal_settings"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "save")) {
                        apply()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            kcalText = "\(max(dailyKcalGoal, 0))"
            proteinText = "\(max(dailyProteinGoal, 0))"
            carbText = "\(max(dailyCarbGoal, 0))"
            fatText = "\(max(dailyFatGoal, 0))"
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "done")) {
                    apply()
                    focus = false
                }
            }
        }
    }

    private func onlyDigits(_ s: inout String) {
        let filtered = s.filter { $0.isNumber }
        if filtered != s { s = filtered }
    }

    private func apply() {
        dailyKcalGoal = max(Int(kcalText) ?? dailyKcalGoal, 0)
        dailyProteinGoal = max(Int(proteinText) ?? dailyProteinGoal, 0)
        dailyCarbGoal = max(Int(carbText) ?? dailyCarbGoal, 0)
        dailyFatGoal = max(Int(fatText) ?? dailyFatGoal, 0)
    }
}
