# Agent Island 系统架构

> 本文档详细说明 Agent Island 的技术架构和核心组件。

---

## 🏗️ 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                        用户界面层                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   NotchView  │  │ ClaudeInstances│  │ Preferences  │       │
│  │   (刘海栏)    │  │   (会话列表)   │  │   (设置)      │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
└─────────┼─────────────────┼─────────────────┼───────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      状态管理层                              │
│              ┌──────────────────────────┐                   │
│              │      SessionStore        │                   │
│              │      (Actor 隔离)         │                   │
│              └────────────┬─────────────┘                   │
│                           │                                 │
│     ┌─────────────────────┼─────────────────────┐          │
│     ▼                     ▼                     ▼          │
│ ┌──────────┐      ┌──────────────┐      ┌──────────────┐  │
│ │SessionState│     │SessionPersistence│    │  NotchViewModel │  │
│ └──────────┘      └──────────────┘      └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                       服务层                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Hooks   │  │  Window  │  │  Session │  │   Chat   │    │
│  │  System  │  │  Focus   │  │  Monitor │  │  History │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      外部接口层                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  AI CLI  │  │   yabai  │  │  Mixpanel│  │  Sparkle │    │
│  │  Hooks   │  │  (可选)  │  │Analytics │  │  Update  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧩 核心组件

### 1. SessionStore（状态中心）

```swift
actor SessionStore {
    static let shared = SessionStore()
    
    // 所有会话状态
    private var sessions: [String: SessionState] = [:]
    
    // 事件处理入口
    func process(_ event: SessionEvent) async
}
```

**职责：**
- 单点状态管理（Single Source of Truth）
- 线程安全（Actor 隔离）
- 事件驱动状态变更

**事件类型：**
- `hookReceived` - CLI hook 事件
- `fileUpdated` - JSONL 文件更新
- `permissionApproved/Denied` - 用户审批操作
- `sessionEnded` - 会话结束

### 2. Hook 系统

```
AI CLI 工具
    │
    ▼ 触发事件
┌─────────────┐
│ Python Hook │  ~/.claude/hooks/claude-island-state.py
│   脚本      │  ~/.codex/hooks/codex-island-state.py
└──────┬──────┘
       │
       ▼ Unix Socket
┌─────────────┐
│HookSocket   │  /tmp/claude-island.sock
│Server       │
└──────┬──────┘
       │
       ▼ SessionEvent
┌─────────────┐
│ SessionStore│
└─────────────┘
```

**支持的 Hook 事件：**
- `SessionStart/End` - 会话开始/结束
- `UserPromptSubmit` - 用户提交提示
- `PreToolUse/PostToolUse` - 工具调用
- `PermissionRequest` - 权限请求（仅 Claude）

### 3. 窗口聚焦系统

```swift
actor UniversalWindowFocuser {
    func focusSession(_ session: SessionState) async -> Bool {
        // 策略 1: yabai 精确聚焦
        // 策略 2: Bundle ID 激活
        // 策略 3: 应用名激活
    }
}
```

**聚焦策略优先级：**
1. yabai（如果安装）- 窗口 ID 精确聚焦
2. Bundle ID - 通过 `NSWorkspace` 激活
3. 应用名 - 通用回退方案

### 4. 会话持久化

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ SessionStore │────▶│  Persisted   │────▶│ UserDefaults │
│   (内存)      │     │   Session    │     │  (磁盘)       │
└──────────────┘     └──────────────┘     └──────────────┘
                            │
                            │ 24h 过期清理
                            ▼
                     ┌──────────────┐
                     │  JSON 编码   │
                     └──────────────┘
```

**持久化数据：**
- 会话 ID、项目名、Provider
- 最后消息、时间戳
- 不包含聊天记录（从历史文件恢复）

---

## 🔄 数据流

### 会话生命周期

```
用户运行 claude
      │
      ▼
Hook: SessionStart
      │
      ▼
SessionStore 创建 SessionState
      │
      ▼
UI 显示会话卡片
      │
      ├─▶ 用户提问 ──▶ Hook: UserPromptSubmit
      │
      ├─▶ 工具调用 ──▶ Hook: PreToolUse
      │                      │
      │                      ▼
      │              需要审批？
      │              /        \
      │           是          否
      │           │            │
      │           ▼            ▼
      │   显示审批UI      直接执行
      │   用户允许/拒绝
      │
      ▼
Hook: SessionEnd ──▶ 清理会话
```

### 文件更新流

```
AI CLI 写入 JSONL
      │
      ▼
AgentFileWatcher 检测变化
      │
      ▼
ConversationParser 解析
      │
      ▼
SessionEvent.fileUpdated
      │
      ▼
SessionStore 更新 UI
```

---

## 🎨 UI 架构

### Notch 视图层次

```
NotchWindow (NSWindow)
    └── NotchViewController
            └── NotchView
                    ├── NotchShape (刘海形状)
                    ├── NotchHeaderView (头部)
                    ├── ClaudeInstancesView (会话列表)
                    │       └── InstanceRow (单行会话)
                    └── NotchMenuView (菜单)
```

### 状态管理

```swift
// 双轨状态管理
NotchViewModel        // 视图状态（动画、展开/收起）
     │
     │ observes
     ▼
SessionStore          // 业务状态（会话数据）
     │
     │ publishes
     ▼
ClaudeSessionMonitor  // UI 绑定
```

---

## 🔌 Provider 架构

### 统一接口

```swift
enum SessionProvider: String {
    case claude
    case codex
    case kimi
    case cursor
}

// Provider 特性
extension SessionProvider {
    var supportsInNotchApproval: Bool {
        self == .claude  // 仅 Claude 支持 Notch 内审批
    }
    
    var supportsChatHistory: Bool {
        self == .claude || self == .kimi
    }
}
```

### Hook vs 窗口检测

| Provider | 检测方式 | 说明 |
|----------|----------|------|
| Claude | Hook | JSON 配置 |
| Codex | Hook | JSON 配置 |
| Kimi | Hook | TOML 配置 |
| Cursor | Hook (v3.0+) | JSON 配置，类似 Claude/Codex |

---

## 🔒 线程安全

### Actor 隔离

```swift
// SessionStore 是 Actor，自动线程安全
actor SessionStore {
    func process(_ event: SessionEvent)  // 串行执行
}

// 调用方式
await SessionStore.shared.process(event)
```

### 状态发布

```swift
// 使用 Combine 发布状态变化
nonisolated let sessionsPublisher: AnyPublisher<[SessionState], Never>

// UI 订阅
sessionStore.sessionsPublisher
    .sink { sessions in
        // 更新 UI
    }
```

---

## 📦 外部依赖

| 依赖 | 用途 | 必需 |
|------|------|------|
| Sparkle | 自动更新 | ❌ 已禁用 |
| Mixpanel | 匿名分析 | ✅ |
| SwiftMarkdown | Markdown 渲染 | ✅ |
| yabai | 窗口管理 | ❌ 可选 |

---

## 🚀 性能考虑

### 优化策略

1. **Debouncing** - 文件更新防抖（100ms）
2. **Lazy Loading** - 聊天记录懒加载
3. **Caching** - 窗口信息缓存
4. **Actor 隔离** - 避免锁竞争

### 内存管理

- 会话自动清理（24h 过期）
- 聊天记录按需加载
- 图片资源延迟加载

---

## 📚 相关文档

- [AGENTS.md](../AGENTS.md) - 开发指南
- [HANDOVER.md](./HANDOVER.md) - 当前状态
- [YABAI_INTEGRATION.md](./YABAI_INTEGRATION.md) - 窗口管理

---

*本文档描述 v2.1.0 架构，如有变更请同步更新。*
