import AppKit

/// 用户在设置里的"显示模式"选项。
/// - `auto`：按当前激活屏判，有刘海 → notch、无刘海 → menuBar
/// - `notch`：强制刘海模式（NSWindow 顶部贴菜单栏顶 + NotchShape 顶部直角左右下凹）
/// - `floating`：强制悬浮胶囊（NSWindow 顶部贴菜单栏下方 8pt + 完整 Capsule + mode 主色外发光）
/// - `menuBar`：不显示顶部灵动岛 / 悬浮胶囊，只保留菜单栏图标入口
///
/// 切换后会弹 alert 提示重启生效（决策 #1：NSWindow 永远不能运行期 setFrame）
enum DisplayMode: String, Codable {
    case auto
    case notch
    case floating
    case menuBar

    static let storageKey = "HermesPetDisplayMode"

    /// 用户设置的原始选项（含 `.auto`）
    static var current: DisplayMode {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? "auto"
        return DisplayMode(rawValue: raw) ?? .auto
    }

    static func save(_ value: DisplayMode) {
        UserDefaults.standard.set(value.rawValue, forKey: storageKey)
    }
}

/// 解析后的实际显示形态（去 `auto`）。
/// `notch` 模式下灵动岛紧贴菜单栏顶 + NotchShape；`floating` 模式下悬浮在菜单栏下方 + 完整 Capsule + glow。
/// `menuBar` 模式下不创建顶部胶囊，所有入口回落到菜单栏图标。
enum EffectiveDisplayMode: Equatable {
    case notch
    case floating
    case menuBar
}

/// 几何 helper 单一权威源 —— DynamicIslandController / Permission / ResponseSummary / ClawdWalk
/// 都从这里读 "顶部入口在哪 / 卡片紧贴在哪 / 桌宠避让带"，避免散落多处计算导致漂移。
enum HermesIslandGeometry {

    /// 灵动岛"卡片紧贴底部 y" 余量 —— 方案 A 后 floating / notch 都贴屏幕顶，留 0 跟刘海一致
    static let floatingGap: CGFloat = 0

    /// 解析 `DisplayMode.current`：auto 时按屏幕是否有刘海决定，否则用用户选的
    static func effective(on screen: NSScreen) -> EffectiveDisplayMode {
        switch DisplayMode.current {
        case .notch:    return .notch
        case .floating: return .floating
        case .menuBar:  return .menuBar
        case .auto:     return screen.safeAreaInsets.top > 0 ? .notch : .menuBar
        }
    }

    /// 当前显示模式是否需要创建顶部灵动岛 / 悬浮胶囊窗口。
    /// 无刘海屏的 auto 默认返回 false，让 App 只保留菜单栏入口。
    static func shouldShowTopIsland(on screen: NSScreen) -> Bool {
        effective(on: screen) != .menuBar
    }

    /// 灵动岛跟着鼠标当前所在屏走 —— 用户接外接屏 / 在屏间切换时灵动岛跟随
    /// （NSScreen.main 的语义：当前接收用户交互的屏，等价于"鼠标所在屏"）
    /// fallback：没有 main → 屏幕数组第一个
    static func targetScreen() -> NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
    }

    /// 顶部入口水平中心 x（用 auxiliary 反推；无顶部胶囊时取屏幕中线作为兜底几何）
    static func islandCenterX(on screen: NSScreen) -> CGFloat {
        if let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
            return (l.maxX + r.minX) / 2
        }
        return screen.frame.midX
    }

    /// 灵动岛核心宽度（物理刘海宽度；无刘海屏退到固定 200pt）
    static func islandCoreWidth(on screen: NSScreen) -> CGFloat {
        if let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
            return r.minX - l.maxX
        }
        return 200
    }

    /// 灵动岛核心高度（刘海模式 = safeArea.top；floating 模式固定 28pt）
    static func islandCoreHeight(on screen: NSScreen) -> CGFloat {
        switch effective(on: screen) {
        case .notch:    return max(screen.safeAreaInsets.top, 28)
        case .floating: return 28
        case .menuBar:  return 0
        }
    }

    /// 顶部入口"底部 y" —— 卡片紧贴这条线展开（PermissionWindow / ResponseSummary 用）。
    /// menuBar 模式没有顶部胶囊，卡片从菜单栏底部向下展开。
    static func islandBottomY(on screen: NSScreen) -> CGFloat {
        if effective(on: screen) == .menuBar {
            return screen.visibleFrame.maxY
        }
        return screen.frame.maxY - islandCoreHeight(on: screen)
    }

    /// 卡片紧贴顶部入口底部时多留多少 gap（floating / menuBar 模式视觉上更喘息）
    static func cardTopGapBelowIsland(on screen: NSScreen) -> CGFloat {
        switch effective(on: screen) {
        case .notch:    return 0   // 跟凹槽无缝衔接
        case .floating: return 10  // 跟悬浮胶囊错开一点呼吸感
        case .menuBar:  return 8   // 标准菜单栏下拉卡片间距
        }
    }

    /// 顶部辅助卡片宽度。menuBar 模式下不再受"刘海宽度"限制，使用更自然的通知卡片宽度。
    static func cardWidth(on screen: NSScreen) -> CGFloat {
        switch effective(on: screen) {
        case .notch, .floating:
            return islandCoreWidth(on: screen) + 80
        case .menuBar:
            return min(420, max(300, screen.visibleFrame.width - 24))
        }
    }

    /// 顶部辅助卡片横向位置。menuBar 模式右对齐到菜单栏图标区域附近；其他模式居中对齐顶部胶囊。
    static func cardOriginX(on screen: NSScreen, width: CGFloat) -> CGFloat {
        let visible = screen.visibleFrame
        switch effective(on: screen) {
        case .notch, .floating:
            let x = islandCenterX(on: screen) - width / 2
            return max(visible.minX + 12, min(visible.maxX - width - 12, x))
        case .menuBar:
            return max(visible.minX + 12, visible.maxX - width - 12)
        }
    }

    /// 桌宠"避让带" —— 普通漫步软墙 + chasing/patrol 跨越触发传送门。
    /// - notch 模式：物理刘海两侧各 +30pt
    /// - floating 模式：悬浮胶囊矩形两侧各 +30pt（胶囊本体宽 = islandCoreWidth + 80pt buffer）
    static func avoidZoneX(on screen: NSScreen) -> ClosedRange<CGFloat>? {
        let core = islandCoreWidth(on: screen)
        switch effective(on: screen) {
        case .notch:
            guard let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea else {
                return nil   // 非刘海屏没物理刘海可读
            }
            return (l.maxX - 30)...(r.minX + 30)
        case .floating:
            // 悬浮胶囊本体宽度 = core + 80pt (idleExtraWidth)，对称分布在 centerX 两侧
            let cx = islandCenterX(on: screen)
            let halfWidth = (core + 80) / 2
            return (cx - halfWidth - 30)...(cx + halfWidth + 30)
        case .menuBar:
            return nil
        }
    }

    /// 桌宠 walkY —— 沿菜单栏下方哪条线走。
    /// floating 模式下需要走在悬浮胶囊"下方"留 8pt gap，避免穿胶囊
    static func clawdWalkBaseY(on screen: NSScreen, clawdHeight: CGFloat) -> CGFloat {
        switch effective(on: screen) {
        case .notch, .menuBar:
            // visibleFrame.maxY 已扣掉菜单栏，紧贴菜单栏下方 4pt
            return screen.visibleFrame.maxY - 4 - clawdHeight
        case .floating:
            // 走在悬浮胶囊下方 8pt（避开胶囊 + glow）
            return islandBottomY(on: screen) - 8 - clawdHeight
        }
    }
}
