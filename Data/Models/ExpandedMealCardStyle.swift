import SwiftUI

/// 卡片外观（圆角、阴影）
struct CardStyle {
    static let cornerRadius: CGFloat = 18
    static let shadowRadius: CGFloat = 10
    static let shadowYOffset: CGFloat = 6
}

/// 展开层的整体留白
struct ExpandedLayout {
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 20
    static let maxHeightPadding: CGFloat = 40
}

/// 内容块（浅色背景容器）
struct ContentBlockStyle {
    static let cornerRadius: CGFloat = 12
    static let padding: CGFloat = 12
}

/// 行与图标尺寸（列表内的一些通用间距）
struct RowStyle {
    static let rowSpacing: CGFloat = 8
    static let rowIconSize: CGFloat = 22
}

/// 控制条（减号/数量胶囊/单位/加号）与顶部 kcal 列宽
struct ControlsStyle {
    // 间距与列宽
    static let ctrlOuterSpacing: CGFloat = 8      // “按钮 ↔ 数字(胶囊)”间距
    static let numberUnitSpacing: CGFloat = 4     // “数字 ↔ 单位”间距
    static let qtyFieldWidth5Digits: CGFloat = 68 // 数字最大宽（最多5位）
    static let unitLabelWidth: CGFloat = 40       // 单位固定宽
    static let kcalColumnMaxWidth: CGFloat = 110  // 顶部 kcal 栏最大宽

    // 视觉尺寸
    static let iconFont: Font = .title3
    static let fieldFont: Font = .system(size: 16, weight: .semibold, design: .rounded)
}
