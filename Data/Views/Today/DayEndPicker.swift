import SwiftUI

struct DayEndPicker: View {
    @Binding var selectedHour: Int
    var onCancel: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Text(String(localized: "day_end"))   // 标题
                    .font(.title3.bold())
                Spacer()
            }

            // 说明（可选）
            Text(String(localized: "day_end_desc"))  // 例如：“在此时间之前计入前一天的摄入。”
                .font(.footnote)
                .foregroundStyle(.secondary)

            // 选择器（0~23）
            Picker("", selection: $selectedHour) {
                ForEach(0..<24) { h in
                    Text(hourLabel(h)).tag(h)
                }
            }
            .labelsHidden()
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)

            // 底部按钮
            HStack(spacing: 12) {
                Button(role: .cancel, action: onCancel) {
                    Text(LocalizedStringKey("cancel")).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray.opacity(0.35))

                Button(action: onSave) {
                    Text(LocalizedStringKey("save")).bold().frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.9))
                .foregroundStyle(.black)
            }
        }
        .padding(16)
    }

    private func hourLabel(_ h: Int) -> String {
        // 你可以改成 24h 文本或本地化：例如 “每天 03:00 截止”
        String(format: "%02d:00", h)
    }
}
