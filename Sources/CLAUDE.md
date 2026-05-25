[根目录](../CLAUDE.md) > **Sources**

# Sources 模块 — HermesPet 全部 Swift 源码（76 文件）

> 本目录是 SwiftPM `executableTarget = HermesPet` 的唯一源目录。整个工程**扁平布局**：所有 `.swift` 直接放在 `Sources/`，按职能分组（不再按目录分子模块）。
>
> 根级 [`CLAUDE.md`](../CLAUDE.md) 已经详尽列出每个文件的职责 + 18 条关键技术决策 + 全局快捷键 + 多会话设计 + 用户偏好。本文档**仅作开发期"快速定位 + 模块拓扑"导航**，不重复决策内容；遇到坑请先回根级 `CLAUDE.md`。

---

## 模块职责

把 macOS 顶部刘海"灵动岛"伪装成桌宠 + AI 聊天客户端入口。点击/悬停顶部刘海胶囊呼出聊天窗，对话对象可以是：

- **Hermes Gateway**（绿，sparkle ✦，OpenAI 兼容自部署 HTTP API）
- **OpenClaw**（橙，本地 OpenClaw daemon HTTP API，v1.2.9 起）
- **在线 AI**（indigo，cloud.fill，OpenAI 兼容 + bundled opencode runtime）
- **Claude Code**（橙，spawn `claude -p` 子进程）
- **Codex**（青，spawn `codex exec -i` 子进程）

当前版本：**v1.2.15**。Swift 6 + SwiftUI，macOS 14+（Package.swift），主力测试 macOS 26.3.1。

---

## 入口与启动

```
HermesPetApp.swift            // @main → struct HermesPetApp: App
  └─ AppDelegate              // NSApplicationDelegate，统筹所有 controller
        ├─ DynamicIslandController.shared    （灵动岛 NSPanel）
        ├─ ChatWindowController.shared        （聊天 NSWindow）
        ├─ GlobalHotkey                       （Carbon 注册热键）
        ├─ VoiceInputController               （⌘⇧V 按住说话）
        ├─ PermissionWindowController         （工具权限确认卡）
        ├─ PermissionHookServer/Installer     （Claude/Codex hook）
        ├─ ClawdWalkController                （桌面漫步桌宠）
        ├─ ClawdBubbleOverlayController       （桌宠头顶气泡）
        ├─ IntelligenceOverlay/Voice 字幕     （按住语音 UI）
        ├─ PinCardController                  （桌面 Pin 卡片）
        ├─ QuickAskWindowController           （⌘⇧Space Spotlight 风快问）
        ├─ ResponseSummaryWindowController    （任务完成摘要卡）
        ├─ IntentSuggestionWindowController   （意图反馈卡）
        ├─ OpenCodeServerManager.shared       （bundled opencode daemon）
        ├─ OpenClawGatewayManager.shared      （openclaw daemon 健康监听）
        ├─ HermesGatewayManager.shared        （Hermes gateway 健康监听）
        ├─ ReasoningProxy.shared              （SSE 推理过滤代理）
        ├─ MorningBriefingService             （每日早简）
        ├─ ActivityRecorder.shared            （活动采集 → ActivityStore SQLite）
        ├─ UserIntentRecorder.shared          （意图采集 → ActivityStore）
        └─ SubprocessRegistry.shared          （子进程 SIGTERM 兜底）
```

`@MainActor @Observable final class ChatViewModel`（`ChatViewModel.swift:7`）是全局唯一聊天状态容器：多对话数组 + 流式请求字典 + 持久化 + 4 路 AgentMode 路由 + ~20 个 `@AppStorage`-style UserDefaults 计算属性。被 SwiftUI 树和 controller 共享引用（弱引用模式：`weak var viewModel`）。

---

## 文件全景与公共类型表

> 76 个文件按"高层 → 底层"职能分组。每个文件列出主要公共类型/枚举/单例；详细文件职责见根 `CLAUDE.md` "文件分工"章节。

### 1. 核心架构 (5)

| 文件 | 主要类型 |
|---|---|
| `HermesPetApp.swift` | `struct HermesPetApp: App`、`final class AppDelegate` |
| `ChatViewModel.swift` | `@MainActor @Observable final class ChatViewModel` |
| `ChatView.swift` | `struct ChatView: View`（header / 消息列表 / 输入栏 / 欢迎页） |
| `ChatWindowController.swift` | `final class ChatWindowController: NSWindowDelegate`（含 `static weak var shared`） |
| `Models.swift` | `ChatMessage` / `Conversation` / `AgentMode` / `MessageRole` / `ConversationKind` / `PermissionRequest` / `QuestionRequest` / `AnyCodable` / `APIError`、常量 `kMaxConversations = 8` |

### 2. 聊天 UI 组件 (3)

| 文件 | 主要类型 |
|---|---|
| `ChatComponents.swift` | `MessageBubbleView` / `ChatInputField` / `SendButton` / `SendOnEnterTextEditor`（NSViewRepresentable + `final class PasteAwareTextView: NSTextView`）/ `AssistantImagesGrid` / `ImageThumb` / `DocumentChip` / `AttachedDocumentsRow` / `TypingCursor` / `ThinkingDots` |
| `MarkdownRenderer.swift` | `MarkdownTextView` / `InlineMarkdownView` / `CodeBlockView` / `TableBlockView` / `ChoiceCardList` / `ChoiceCard` / `TaskCardListView` / `struct PlannedTask` |
| `ChatFontScale.swift` | `enum ChatFontScale`（5 档 + EnvironmentKey + AppStorage） |

### 3. 灵动岛 + 桌宠 sprite (12)

| 文件 | 主要类型 |
|---|---|
| `DynamicIslandController.swift` | `final class DynamicIslandController` / `final class EmbeddableIslandPanel: NSPanel` / `DynamicIslandPillView` / `NotchShape` / `IslandHitShape` / `IdleModeDot` / `FloatingSleepZ` / `BackgroundStreamingBadge` / `RightEarIndicator` / `ListeningMic` / `LoadingSpinner` / `AnimatedCheckmark` / `PermissionTransitionModifier` |
| `IntelligenceOverlay.swift` | `final class IntelligenceOverlayController` / `IntelligenceGlowView` |
| `VoiceTranscriptOverlay.swift` | `final class VoiceTranscriptOverlayController` / `TranscriptState` / `VoiceTranscriptView` |
| `ChoiceMenuOverlay.swift` | （v1.2.7 起 dead code，灵动岛下方"原生"选项菜单） |
| `ClawdWalkOverlay.swift` | `final class ClawdWalkController` / `ClawdWalkState` / `enum PetVisualKind` / `final class FileDropView: NSView` / `ClawdWalkView` / `ClawdWalkBubbleView` |
| `ClawdBubbleOverlay.swift` | `final class ClawdBubbleOverlayController` / `BubbleState` / `ClawdBubbleView` |
| `ModeSprite.swift` | `ModeSpriteView` / `ClawdView` / `enum ClawdPose` / `HorseView` / `TerminalView` / `CloudPetView` / `enum ToolKind` / `ToolOverlay` / 各 `IslandSprite` wrapper |
| `FomoSprite.swift` | `FomoView` / `FomoIslandSprite`（九尾狐 sprite，v1.2.9） |
| `LifeSignsModifier.swift` | `struct LifeSignsModifier: ViewModifier`（呼吸 / 眨眼 / 跳跃 token） |
| `MouseTracking.swift` | `final class MouseTrackingController.shared`（鼠标位置 + area 通知） |
| `QuestionCardView.swift` | `struct QuestionCardView: View`（AI 主动提问卡片） |
| `TeleportPortal.swift` | `final class TeleportPortalState` / `TeleportPortalView`（桌宠避让灵动岛传送门像素动画） |
| `PetHeaderStrip.swift` | `struct PetHeaderStrip: View` / `ModeRailView`（聊天窗顶部 28pt 桌宠状态条，含 ModeRail 4 sprite 切换） |

### 4. Mode 引擎 — Streaming Clients (12)

| 文件 | 主要类型 |
|---|---|
| `APIClient.swift` | `final class APIClient: @unchecked Sendable` / `actor APIIdleClock` / `enum ConfigSource { hermes, direct, openclaw }`（OpenAI 兼容 HTTP 流式，3 source 共用） |
| `ClaudeCodeClient.swift` | `final class ClaudeCodeClient: @unchecked Sendable`（spawn `claude -p`，解析 stream-json，发 `HermesPetToolStarted/Ended` 通知） |
| `CodexClient.swift` | `final class CodexClient: @unchecked Sendable`（spawn `codex exec -i`，item.started/completed 事件） |
| `OpenCodeServerManager.swift` | `final class OpenCodeServerManager: @unchecked Sendable.shared` / `enum OpenCodeServerError` / `final class OneShotBox`（bundled opencode headless server 生命周期，含 EOF 防护决策） |
| `OpenCodeHTTPClient.swift` | （在线 AI 走 opencode HTTP API；SSE 流 + permission.asked / question.asked 监听） |
| `OpenCodeClient.swift` | `final class OpenCodeClient` / `EventTypeCounter` / `LineBuffer` / `ByteCounter` / `AtomicFlag`（legacy subprocess 路径，过渡保留） |
| `OpenCodeConfigGenerator.swift` | `enum OpenCodeConfigGenerator`（翻译 HermesPet 配置 → `opencode.json`） |
| `ReasoningProxy.swift` | `final class ReasoningProxy.shared: @unchecked Sendable`（NWListener 本地 SSE 代理过滤 `reasoning_content`） |
| `HermesGatewayManager.swift` | `final class HermesGatewayManager.shared`（本地 spawn `hermes gateway run` 健康监控） |
| `OpenClawGatewayManager.swift` | `final class OpenClawGatewayManager.shared`（v1.2.9，零配置 detect / 读取 `~/.openclaw/openclaw.json` / 自启 daemon） |
| `ProviderPreset.swift` | `struct ProviderPreset` / `enum DirectResponsePreference`（DeepSeek / 智谱 / Kimi / OpenAI / MiniMax / openclawLocal 等预设） |
| `CLIAvailability.swift` | `actor CLIAvailability`（探测 claude/codex 5min 缓存 + 2s 超时） |
| `CLIProcessEnvironment.swift` | `enum CLIProcessEnvironment`（子进程 PATH 环境补全 ~/.local/bin / brew / nvm） |
| `SubprocessRegistry.swift` | `final class SubprocessRegistry.shared: @unchecked Sendable`（统一 SIGTERM 兜底） |

### 5. 工具权限确认 UI (4)

| 文件 | 主要类型 |
|---|---|
| `PermissionWindowController.swift` | `final class PermissionWindowController` / `PermissionViewState` / `PermissionWindowRoot` / `PermissionCardTransition: ViewModifier`（独立 NSWindow，紧贴灵动岛下方） |
| `PermissionCardView.swift` | `struct PermissionCardView: View`（Deny / Allow / Always 三按钮，⌘Y/⌘N chip） |
| `PermissionHookServer.swift` | `final class PermissionHookServer` / `enum HookSource`（NWListener 本地 HTTP，接 Claude/Codex hook） |
| `PermissionHookInstaller.swift` | `enum PermissionHookInstaller`（注入 `~/.claude/settings.json` + `~/.codex/config.toml`） |

### 6. 桌面 Pin / 画布 / 早简 (8)

| 文件 | 主要类型 |
|---|---|
| `PinCardOverlay.swift` | `struct PinCard` / `final class PinStore` / `final class PinCardController` / `final class PinWindowDelegate` / `PinCardView`（每张 Pin 独立 NSWindow） |
| `CanvasView.swift` | `CanvasView` / `CanvasImageCard` / `CanvasTextCard` / `ImageLightboxView` / `CanvasCreatorSheet`（画布模式 + 灯箱） |
| `CanvasService.swift` | `final class CanvasService`（两阶段生成：规划 → 填充图文） |
| `CanvasTemplates.swift` | （电商主图 / 课件 / 故事板 模板库） |
| `MorningBriefingService.swift` | `final class MorningBriefingService` / `struct BriefingData`（每日早简） |
| `ActivityRecorder.swift` | `final class ActivityRecorder: NSObject.shared`（NSWorkspace 监听 + 键鼠 monitor + AX 窗口标题轮询） |
| `ActivityStore.swift` | `final class ActivityStore: @unchecked Sendable` / `ActivityEvent` / `ActivitySession` / `AppDailyStat` / `UserQuestion` / `UserIntent`（SQLite3 + FTS5） |
| `UserIntentRecorder.swift` | `final class UserIntentRecorder.shared`（OCR + 截屏 + 落库 user_intents） |

### 7. 意图反馈系统 (7，v1.3.5)

| 文件 | 主要类型 |
|---|---|
| `IntentPatternDetector.swift` | `final class IntentPatternDetector` / `struct DetectedPattern`（重复屏幕 / 报错关键词归纳） |
| `IntentNotificationManager.swift` | `final class IntentNotificationManager`（detector 路由到 SuggestionWindow） |
| `IntentSuggestionWindowController.swift` | `final class IntentSuggestionWindowController` / `IntentSuggestionViewState` |
| `IntentInstantFeedback.swift` | `enum IntentChannelPreference` / `final class IntentInstantFeedback`（A/B 实时反馈通道路由） |
| `IntentFeedbackBudget.swift` | `final class IntentFeedbackBudget`（每分钟 ≤ N 次抑制规则） |
| `IntentCopyWriter.swift` | `enum IntentSignalKind` / `enum IntentCopyWriter`（按 pattern.kind × agentMode 文案模板池） |
| `EnabledModesStore.swift` | `final class EnabledModesStore.shared: @MainActor @Observable`（5 mode 启用集合 + UserDefaults） |

### 8. 输入交互 (10)

| 文件 | 主要类型 |
|---|---|
| `GlobalHotkey.swift` | `final class GlobalHotkey`（Carbon Event Manager，down/up 双事件） |
| `HotkeySettings.swift` | `struct Hotkey` / `enum HotkeyAction` / `enum HotkeyFormatter`（5 个 action 默认绑定 + UserDefaults） |
| `VoiceInputController.swift` | `final class VoiceInputController: @unchecked Sendable`（按住说话 + SFSpeechRecognizer zh-CN） |
| `ScreenCapture.swift` | `enum ScreenCapture`（ScreenCaptureKit；返回 `.success / .needsPermission / .failed`） |
| `DragDropUtil.swift` | `enum DragDropUtil`（图片读 PNG / 文档只传 URL） |
| `QuickAskWindow.swift` | `final class QuickAskWindowController` / `final class QuickAskPanel: NSPanel` / `QuickAskState` / `QuickAskView`（⌘⇧Space Spotlight 风快问） |
| `AccessibilityReader.swift` | `enum AccessibilityReader` / `enum KeyboardSimulator`（AXUIElement 读焦点 + CGEvent 模拟粘贴） |
| `IdleStateTracker.swift` | `final class IdleStateTracker`（`CGEventSource.secondsSinceLastEventType` 3min 检测） |
| `ResponseSummaryWindowController.swift` | `final class ResponseSummaryWindowController` / `ResponseSummaryViewState` / `ResponseSummaryRoot` / `ResponseSummaryCardView` / `enum SummaryProcessor`（任务完成 200 字摘要） |
| `ChoiceMenuOverlay.swift` | (dead code 保留作 v1.3+ 复活基础设施) |

### 9. 系统支撑 (9)

| 文件 | 主要类型 |
|---|---|
| `CrashReporter.swift` | `final class CrashReporter` / `struct CrashRecord`（崩溃日志扫描 + GitHub Issue 上报） |
| `UpdateChecker.swift` | `final class UpdateChecker`（GitHub Release API + 自动 DMG 替换 install） |
| `SoundManager.swift` | `enum SoundEvent` / `enum SoundManager`（5 类事件 + 自定义音频） |
| `Haptic.swift` | `enum Haptic`（trackpad 触觉反馈） |
| `DesktopIconReader.swift` | `final class DesktopIconReader` / `struct DesktopIcon`（osascript 读桌面图标） |
| `WindowLevels.swift` | `enum HermesWindowLevel`（NSWindow z-order 全局规范） |
| `AnimationTokens.swift` | `enum AnimTok`（snappy / smooth / bouncy / exit / breathe 全局 spring token） |
| `SchemaMigrator.swift` | `enum SchemaMigrator`（UserDefaults 配置版本迁移） |
| `CodeSignVerifier.swift` | `enum CodeSignVerifier`（防伪验证：Team ID `R34KL4X4D9`） |

### 10. 设置 / 数据持久化 (5)

| 文件 | 主要类型 |
|---|---|
| `SettingsView.swift` | `struct SettingsView: View` / `struct ModeEnableRow: View`（Form 风格设置：后端 / 桌宠 / 音效 / 隐私 / 系统 / 关于） |
| `StorageManager.swift` | `final class StorageManager: @unchecked Sendable`（`~/.hermespet/conversations.json` + 图片 PNG 双写） |
| `PetPalette.swift` | `struct PetPalette` / `final class PetPaletteStore` / `enum PetWalkSizeScale`（每 mode 桌宠主色调色盘） |
| `DisplayMode.swift` | `enum DisplayMode` / `enum EffectiveDisplayMode` / `enum HermesIslandGeometry`（刘海 / 非刘海屏尺寸常量） |

---

## 模块结构（Mermaid）

```mermaid
graph TD
    A["(根) HermesPet"] --> S["Sources/"]
    S --> CORE["核心<br/>HermesPetApp · ChatViewModel · Models · ChatView · ChatWindowController"]
    S --> CHAT["聊天 UI<br/>ChatComponents · MarkdownRenderer · ChatFontScale"]
    S --> ISLAND["灵动岛 + 桌宠<br/>DynamicIslandController · ModeSprite · FomoSprite · LifeSigns · MouseTracking · TeleportPortal · ClawdWalkOverlay · ClawdBubbleOverlay · PetHeaderStrip · IntelligenceOverlay · VoiceTranscriptOverlay · ChoiceMenuOverlay · QuestionCardView"]
    S --> ENGINE["Mode 引擎<br/>APIClient · ClaudeCodeClient · CodexClient · OpenCodeServerManager · OpenCodeHTTPClient · OpenCodeClient · OpenCodeConfigGenerator · ReasoningProxy · HermesGatewayManager · OpenClawGatewayManager · ProviderPreset · CLIAvailability · CLIProcessEnvironment · SubprocessRegistry"]
    S --> PERM["权限确认<br/>PermissionWindowController · PermissionCardView · PermissionHookServer · PermissionHookInstaller"]
    S --> EXTRAS["Pin/画布/早简<br/>PinCardOverlay · CanvasView · CanvasService · CanvasTemplates · MorningBriefingService · ActivityRecorder · ActivityStore · UserIntentRecorder"]
    S --> INTENT["意图反馈 (v1.3.5)<br/>IntentPatternDetector · IntentNotificationManager · IntentSuggestionWindowController · IntentInstantFeedback · IntentFeedbackBudget · IntentCopyWriter · EnabledModesStore"]
    S --> INPUT["输入交互<br/>GlobalHotkey · HotkeySettings · VoiceInputController · ScreenCapture · DragDropUtil · QuickAskWindow · AccessibilityReader · IdleStateTracker · ResponseSummaryWindowController"]
    S --> SYS["系统支撑<br/>CrashReporter · UpdateChecker · SoundManager · Haptic · DesktopIconReader · WindowLevels · AnimationTokens · SchemaMigrator · CodeSignVerifier"]
    S --> SET["设置 + 持久化<br/>SettingsView · StorageManager · PetPalette · DisplayMode"]

    CORE -. 全局共享 .-> CHAT
    CORE -. 路由分流 .-> ENGINE
    CORE -. broadcast 通知 .-> ISLAND
    ENGINE -. tool_use 通知 .-> ISLAND
    ENGINE -. permission.asked .-> PERM
    EXTRAS -. SQLite .-> INTENT
```

---

## 对外接口（运行时通讯总线）

> 没有传统意义的"公共接口"——这是一个 macOS App target，对外只有 `HermesPetApp.main()`。但**模块间的通讯总线**用 NotificationCenter，命名约定 `HermesPet*`。下面是核心通知名（按数据流向）：

### Mode 引擎 → 灵动岛 / 桌宠

| 通知名 | 发送方 | 接收方 | 负载 |
|---|---|---|---|
| `HermesPetTaskStarted` | ChatViewModel.sendMessage | PillView / Clawd sprite / PetHeaderStrip | conversationID |
| `HermesPetTaskFinished` | client 流式结束 | 同上 | success, conversationID |
| `HermesPetToolStarted` | ClaudeCodeClient / CodexClient / OpenCodeHTTPClient | PillView ToolOverlay / Clawd sprite | toolName, file_path, arg, toolID |
| `HermesPetToolEnded` | 同上 | 同上 | toolID |
| `HermesPetBackgroundStreamingChanged` | ChatViewModel.broadcast | RightEarIndicator BackgroundStreamingBadge | count |
| `HermesPetModeChanged` | ChatViewModel.agentMode.didSet | 灵动岛 sprite / Clawd 桌面漫步 / PetHeader | mode raw |

### 灵动岛 ↔ 聊天窗

| 通知名 | 发送方 | 接收方 | 用途 |
|---|---|---|---|
| `HermesPetIslandHoverChanged` | DynamicIslandController NSEvent monitor | PillView | hover bool |
| `HermesPetOpenChatRequested` | Pin / QuickAsk / ResponseSummary "查看完整" | AppDelegate.handleOpenChatRequested | 转聊天 |
| `HermesPetChatWindowShown` | ChatWindowController.show | ResponseSummary / IntentSuggestion 自动 hide | — |
| `HermesPetChatWindowWillHide` | ChatWindowController.hide | PetHeaderStrip permission 迁移 | — |
| `HermesPetFocusInputField` | ChoiceCard onTap / 其他抢焦点场景 | NSTextView | 自动 firstResponder |

### 权限确认 + 智能感知

| 通知名 | 发送方 | 接收方 | 负载 |
|---|---|---|---|
| `HermesPetPermissionAsked` | PermissionHookServer / OpenCodeHTTPClient SSE | PermissionWindowController / PetHeaderStrip | PermissionRequest |
| `HermesPetPermissionDecisionMade` | PermissionCardView 三按钮 | PermissionHookServer.dispatchDecision | PermissionDecision |
| `HermesPetPermissionMigrateToIsland` | PetHeaderStrip（聊天窗将关） | PermissionWindowController.showUnconditionally | 移交 pending |
| `HermesPetResponseReady` | ChatViewModel 任务完成 + 聊天窗 hidden | ResponseSummaryWindowController | content, conversationID, modeRaw |
| `HermesPetIntentRecorded` | UserIntentRecorder 落库后 | Clawd glance / PillView shimmer (v1.3.5) | trigger type |
| `HermesPetEnabledModesChanged` | EnabledModesStore | SettingsView ModeRailView mode 切换 UI | — |

### 输入 + 工具

| 通知名 | 发送方 | 接收方 | 用途 |
|---|---|---|---|
| `HermesPetVoiceStarted/Partial/Finished/Cancelled` | VoiceInputController | IntelligenceOverlay / VoiceTranscriptOverlay | push-to-talk 链路 |
| `HermesPetVoiceLevel` | VoiceInputController | DynamicIsland ListeningMic | 0~1 音量 |
| `HermesPetCaptureShutter` | ScreenCapture.success | DynamicIsland 快门动画 | — |
| `HermesPetMouseAreaChanged` | MouseTrackingController | Clawd 眼神跟随 | left/center/right |
| `HermesPetHotkeysChanged` | HotkeySettings 用户改键 | GlobalHotkey 重注册 | — |
| `HermesPetWalkSizeScaleChanged` | PetPaletteStore | 5 个 sprite View | scale |
| `HermesPetChatFontScaleChanged` | ChatFontScale ⌘+/⌘-/⌘0 | 所有 chat font 消费者 | scale 档位 |
| `HermesPetChatWindowPinChanged` | ChatWindowController alwaysOnTop toggle | 聊天 header | — |

---

## 关键依赖与配置

### 系统框架（皆 macOS 原生，无第三方 SwiftPM 依赖）

- **SwiftUI** + **AppKit**（NSWindow / NSPanel / NSHostingView 混用）
- **Carbon**（`Package.swift` 唯一显式 linkerSettings：全局热键 `RegisterEventHotKey`）
- **ScreenCaptureKit**（`SCShareableContent` / `SCScreenshotManager`；决策 #3 用它而不是 `CGDisplayCreateImage`）
- **Speech**（`SFSpeechRecognizer` zh-CN）+ **AVFoundation**（录音 + `installTap`）
- **Vision**（`VNRecognizeTextRequest` 本地 OCR for UserIntentRecorder）
- **Network**（`NWListener` 本地 HTTP server：ReasoningProxy / PermissionHookServer）
- **Accessibility**（`AXUIElementCreateApplication` + `kAXFocusedWindowAttribute` + `IOHIDRequestAccess`）
- **CoreGraphics**（`CGEventSource.secondsSinceLastEventType` for idle / `CGEvent.post` for paste 模拟）
- **SQLite3**（`Sources/ActivityStore.swift`，C API + FTS5 trigger sync）

### 持久化路径

| 数据 | 路径 |
|---|---|
| 对话历史 | `~/.hermespet/conversations.json`（自动从旧 `session.json` 迁移） |
| 图片附件 | `~/.hermespet/images/<groupID>-<idx>.png`（决策 #10） |
| Pin 卡片 | `~/.hermespet/pins.json` |
| Activity SQLite | `~/.hermespet/activity.sqlite`（3 表 + FTS5；ActivityStore.performMaintenance 自动归档） |
| User Intents | 上同 + 压缩 OCR blob（30 天压缩 / 180 天保留） |
| Briefings 日期 | UserDefaults `morningBriefingLastDate` |
| Opencode global | `~/Library/Application Support/HermesPet/opencode-global/` |
| Opencode per-conv | `~/Library/Application Support/HermesPet/conversations/<id>/` |
| Opencode binary | `<app>.app/Contents/Resources/opencode`（DMG 内嵌） |
| Permission hook | `~/.claude/settings.json` + `~/.codex/config.toml`（PermissionHookInstaller 注入） |
| Codex 生成图 | `~/.codex/generated_images/`（diff 后 persist 到 hermespet/images） |
| Reasoning proxy log | `~/.hermespet/reasoning-proxy.log` |
| Opencode debug log | `~/.hermespet/opencode-debug.log` |

### 子进程

| 程序 | spawn 方 | 退出兜底 |
|---|---|---|
| `claude -p ...` | ClaudeCodeClient | SubprocessRegistry SIGTERM |
| `codex exec -i ... --` | CodexClient（必须 `--` 终止 flag，决策 #8） | 同上 |
| `opencode serve` | OpenCodeServerManager（bundled binary，stdout/stderr EOF 防护决策 [TODO.md L331](../TODO.md#L331)） | applicationWillTerminate SIGTERM + 注册 |
| `hermes gateway run` | HermesGatewayManager（同 EOF 防护） | 同上 |
| `openclaw daemon start` | OpenClawGatewayManager（v1.2.9） | launchd 接管 |

### 构建脚本（项目根目录）

| 脚本 | 用途 |
|---|---|
| `../build.sh` | 仅构建 `~/Desktop/HermesPet/HermesPet.app`（自动选 Apple Development 证书） |
| `../install.sh` | 构建 + 覆盖装到 `/Applications/Hermes 桌宠.app` + 启动（**日常用这个**） |
| `../make-dmg.sh` | 生成给别人分发的 DMG（arm64 + Intel 双份） |

---

## 数据模型（核心实体）

### ChatMessage（`Models.swift:4`）

```swift
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    var role: MessageRole          // user / assistant / system
    var content: String
    var timestamp: Date
    var isStreaming: Bool
    var images: [Data]             // 内存中持有（持久化只写 imagePaths）
    var imagePaths: [String]       // 磁盘绝对路径，~/.hermespet/images/...
    var documentPaths: [String]    // 拖入文档（路径，不读全文，决策 #9）
    // ...
}
```

### Conversation（`Models.swift:103`）

```swift
struct Conversation: Identifiable, Codable, Equatable {
    let id: String
    var title: String              // 自动从首条 user 派生 (≤8 字)
    var messages: [ChatMessage]
    var mode: AgentMode            // 首条 user 后锁死（决策 v1.2.x mode 绑定）
    var isStreaming: Bool          // 当前是否在等流式
    var hasUnread: Bool            // 后台完成的红点
    var kind: ConversationKind     // .chat / .canvas / .briefing
    var canvasBoard: CanvasBoard?  // 画布模式专属
    // ...
}
// 常量：kMaxConversations = 8
```

### AgentMode（`Models.swift:313`）

```swift
enum AgentMode: String, Codable, CaseIterable, Identifiable {
    case hermes        // sparkle ✦ · 绿色（Hermes Gateway 自部署 HTTP）
    case openclaw      // sparkle · 橙色（v1.2.9，本地 OpenClaw daemon）
    case directAPI     // cloud.fill · indigo（在线 AI，bundled opencode）
    case claudeCode    // terminal.fill · 橙色（spawn claude -p）
    case codex         // wand.and.stars · 青色（spawn codex exec -i）
}
```

### PermissionRequest（`Models.swift:473`）

opencode `permission.asked` 事件 + Claude/Codex hook 共用。带 `tool` / `patterns` / `metadata` / `always`，决策回执 `PermissionDecision`（`once / always / reject`）。

### Tool kinds（`ModeSprite.swift:369`）

```swift
enum ToolKind: Equatable {
    case read, write, edit, multiEdit, bash, search, web, todo, task
    // 9 类工具映射 SF Symbol + 中文动词 + 渐变色（决策 #13）
}
```

---

## 测试与质量

- **没有 XCTest 测试套件**（`Tests/` 目录不存在）。质量保障靠：
  1. **真机持续使用**（用户在 macOS 26.3.1 主力机长期运行）
  2. **`build.sh` + `install.sh` 一键回归**：编译警告 / 错误立刻可见
  3. **Swift 6 严格并发**：编译期就抓住绝大多数 isolation race（决策 #5）
  4. **CrashReporter** 扫描 `~/Library/Logs/DiagnosticReports/HermesPet-*.ips` 自动上报 GitHub Issue
  5. **CodeSignVerifier**：启动时验证 Team ID = `R34KL4X4D9` 防被改包
- **建议加测试的优先候选**（缺口）：
  - `SummaryProcessor.compress` 文本压缩规则（200 字 + markdown 去标记）
  - `MarkdownRenderer` 表格 / ChoiceCard / TaskCard 解析
  - `IntentCopyWriter.extractNoun` 启发式（D2 待办的硬规则）
  - `SchemaMigrator` 各版本字段迁移
  - `AnyCodable` Codable 兼容性
- **构建**：
  ```bash
  cd /Users/zyq/Desktop/学习/HermesPet
  ./build.sh 2>&1 | grep -E "error:|warning:|Build complete"
  ```
- **部署**：
  ```bash
  xattr -cr ~/Desktop/HermesPet/HermesPet.app && ./install.sh
  ```

---

## 常见问题 (FAQ)

**Q1：灵动岛崩溃 `NSException NSHostingView.updateAnimatedWindowSize`？**
A：你又让灵动岛 NSWindow setFrame 了。看决策 #1。改用独立 NSWindow 紧贴灵动岛底部伪装"长大"。

**Q2：截屏返回 nil 但有权限？**
A：你在用 `CGDisplayCreateImage` —— macOS 15+ 上它默认返回 nil。走 `Sources/ScreenCapture.swift` 的 SCK 路径，并别预检 `CGPreflightScreenCaptureAccess`（ad-hoc 签名假返回 false）。

**Q3：Swift 6 触发 SIGTRAP，isolation 不匹配？**
A：你把 `@MainActor` class 的 closure 传给了 Speech / SCStream / NotificationCenter 的后台回调。`final class XXX: @unchecked Sendable` + NSLock，或者 `MainActor.assumeIsolated { ... }`。决策 #5。

**Q4：加新 AgentMode 编译过了但聊天界面没切换？**
A：检查清单 ——
  1. `Models.swift:AgentMode` 加 case + `id` / `displayName` / `iconName` / `primaryColor`
  2. grep `case .hermes` 把 10+ 文件的 switch 全补齐（决策 #18）
  3. `ProviderPreset.swift` 加 preset / `APIClient.ConfigSource` 加 case
  4. `EnabledModesStore.defaultModes` 决定全新用户是否默认开
  5. 图片传递（决策 #8）+ 文档传递（决策 #9）+ healthCheck 端点（决策 #14）

**Q5：codesign 报 "resource fork / Finder information not allowed"？**
A：`xattr -cr ~/Desktop/HermesPet/HermesPet.app && ./install.sh`（决策 #12）。

**Q6：在线 AI 显示 "(没有响应)"？**
A：opencode + reasoning model 兼容问题，看 TODO.md 的"Phase 2 ReasoningProxy"。已落地（v1.2.3+）：本地 SSE 代理过滤 `reasoning_content` 字段。

**Q7：opencode/Hermes daemon 烧 200% CPU？**
A：`readabilityHandler` EOF 没置 nil。看 TODO.md L331-L333 "EOF 空转排查"，标准模式：`data.isEmpty` → `handle.readabilityHandler = nil` + return。

---

## 相关文件清单（按主题速查）

- **多对话状态**：`Models.swift` (Conversation/ChatMessage) + `ChatViewModel.swift` (activeConversationID / messages computed) + `StorageManager.swift` (落盘)
- **流式分流**：`ChatViewModel.sendMessage` → switch agentMode → `APIClient` (Hermes/.direct/.openclaw) / `ClaudeCodeClient` / `CodexClient` / `OpenCodeHTTPClient`
- **加新工具的灵动岛显示**：`ModeSprite.swift:ToolKind` 加 case → 客户端发 `HermesPetToolStarted` 带 toolName → PillView `ToolOverlay` 自动 dispatch
- **加新通知**：在源文件定义 `static let xxx = Notification.Name("HermesPetXxx")` → 接收方 `.onReceive(NotificationCenter.default.publisher(for: ...))` 监听
- **修改桌宠 sprite**：`ModeSprite.swift`（Hermes 小马 / Codex coco 终端 / Claude Clawd 螃蟹 / 在线 AI 云朵）+ `FomoSprite.swift`（九尾狐）+ `ClawdWalkOverlay.swift:PetVisualKind` 桌面漫步路由
- **修改设置面板**：`SettingsView.swift`（按分类 section：mode / 后端 / 桌宠 / 音效 / 隐私 / 系统 / 关于）
- **修改快捷键**：`HotkeySettings.swift:HotkeyAction` 加 case → `GlobalHotkey.swift` 加 ref/handler 槽位 → AppDelegate.handle 分发 → SettingsView 关于页录制 UI

---

## 变更记录 (Changelog)

| 时间戳 | 变更 |
|---|---|
| 2026-05-25 20:43:59 | 首版生成。基于 v1.2.15、76 个 .swift 全量扫描；根级 CLAUDE.md 保持不动，本文件作为模块导航补充。 |
