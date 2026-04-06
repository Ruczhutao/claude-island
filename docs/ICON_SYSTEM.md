# Agent Island 图标系统说明

## 概述

Agent Island 采用**双图标架构**：
- **主图标**（32px）：负责情感表达和氛围动画
- **状态指示器**（18px）：负责明确的状态符号

```
┌─────────────────────────────────┐
│  [🐕] [?]  Agent Island        │  ← 主图标 + 状态符号
│   32px 18px                     │
└─────────────────────────────────┘
```

---

## 一、主图标系统

### 1.1 支持的图标

| 图标 | 标识符 | 描述 |
|------|--------|------|
| 🐕 Dog | `dog` | 柯基犬，全身像，向右奔跑 |
| 🐱 Cat | `cat` | 橘猫，头像，耳朵可竖起 |
| 🤖 Robot | `robot` | 复古机器人，带天线 |
| 🏝️ Island | `island` | 热带岛屿，棕榈树 |
| 👻 Ghost | `ghost` | 可爱幽灵，漂浮效果 |
| 🗼 Lighthouse | `lighthouse` | 灯塔，光束旋转 |

### 1.2 文件位置

```
ClaudeIsland/UI/Components/
├── DogIcon.swift        # 参考实现
├── CatIcon.swift
├── RobotIcon.swift
├── IslandIcon.swift
├── GhostIcon.swift
├── LighthouseIcon.swift
└── StatusPixelIcon.swift # 状态指示器

ClaudeIsland/Models/
├── IdleIconStyle.swift   # 图标样式枚举
└── DogStatus.swift       # 状态枚举
```

### 1.3 动画参数

所有主图标统一支持三个动画参数：

```swift
struct DogIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false  // Running - 奔跑/运动动画
    var breathe: Bool = false  // Sleeping - 呼吸/缩放动画
    var pulse: Bool = false    // Waiting - 脉冲/提醒动画
}
```

| 参数 | 状态 | 动画效果 |
|------|------|----------|
| `animate: true` | Running | 逐帧动画（奔跑/摇摆） |
| `breathe: true` | Sleeping | 缩放 0.92x + 透明度 0.85，2秒周期 |
| `pulse: true` | Waiting | 缩放 0.88x 脉冲，0.6秒周期 |
| 全部 `false` | Idle | 静态，100% 不透明 |

---

## 二、状态指示器

### 2.1 设计原则

- **极简**：只有必要状态才显示符号
- **语义明确**：符号全球通用（!?✓）
- **颜色编码**：不同状态有不同颜色

### 2.2 状态映射

| 状态 | 符号 | 颜色 | 显示 | 说明 |
|------|------|------|------|------|
| **Idle** | 无 | - | 隐藏 | 待机状态，只显示主图标 |
| **Running** | **!** | 🔵 蓝色 | 显示 | 处理中/运行中 |
| **Waiting** | **?** | 🟠 琥珀色 | 显示 | 等待用户审批 |
| **Sleeping** | **✓** | 🟢 绿色 | 显示 | 任务完成/等待输入 |

### 2.3 动画效果

| 状态 | 动画类型 | 效果 |
|------|----------|------|
| Idle | 无 | 完全隐藏 |
| Running | 脉冲 | 透明度 0.4→1.0，蓝色发光 |
| Waiting | 快速脉冲 | 透明度 0.3→1.0，琥珀色发光 |
| Sleeping | 缓慢呼吸 | 透明度 0.7→1.0，稳定绿色 |

### 2.4 像素设计

使用 8x8 像素画布绘制极简符号：

```
Exclamation (!)    Question (?)       Checkmark (✓)
  ██                  ███                  █
  ██                     █                  █
  ██                     █                  █
  ██                     █               █
  ██                  ██                  █
  .                    .               █
  ██                     █            █
```

---

## 三、状态优先级

当多个会话同时存在时，按优先级显示：

```swift
waiting > running > sleeping > idle
```

### 3.1 优先级逻辑

```swift
private var currentState: (status: DogStatus, animate: Bool, breathe: Bool, pulse: Bool) {
    // 优先级 1: 等待审批（最紧急）
    if hasPendingPermission {
        return (.waiting, false, false, true)
    }
    // 优先级 2: 处理中
    else if isProcessing {
        return (.running, true, false, false)
    }
    // 优先级 3: 完成/等待输入
    else if hasWaitingForInput {
        return (.sleeping, false, true, false)
    }
    // 优先级 4: 待机
    else {
        return (.idle, false, false, false)
    }
}
```

### 3.2 示例场景

| 场景 | 主图标 | 状态符号 | 说明 |
|------|--------|----------|------|
| 无任何会话 | 🐕 Idle | 无 | 只显示静态主图标 |
| Claude 正在写代码 | 🐕 Running | **!** | 奔跑动画 + 蓝色惊叹号 |
| 需要审批工具调用 | 🐕 Waiting | **?** | 脉冲动画 + 琥珀色问号 |
| 任务完成等你输入 | 🐕 Sleeping | **✓** | 呼吸动画 + 绿色对钩 |
| 多个会话混合 | 按优先级 | 按优先级 | Waiting 优先于 Running |

---

## 四、布局系统

### 4.1 Notch 视图布局

```
┌─────────────────────────────────────────┐
│ ┌─────┐                                 │
│ │ 🐕  │ [!]    Agent Island      ⚙️    │  ← Header Row
│ │ 32px│ 18px                        │   │
│ └─────┘                                 │
│ ─────────────────────────────────────── │
│                                         │
│   [Session List Content]                │  ← Content View
│                                         │
└─────────────────────────────────────────┘
```

### 4.2 尺寸规格

| 元素 | 尺寸 | 说明 |
|------|------|------|
| 主图标 | 32×32pt | 固定大小 |
| 状态图标 | 18×18pt | Idle时隐藏 |
| 图标间距 | 4pt | 只在状态图标显示时有 |
| Header 高度 | 闭合: ~30pt / 展开: ~40pt | 适配刘海高度 |

### 4.3 状态切换动画

```swift
HStack(spacing: dogStatus == .idle ? 0 : 4) {
    // 主图标始终显示
    idleStyle.iconView(size: 32, ...)
    
    // 状态图标条件显示
    if dogStatus != .idle {
        StatusPixelIcon(status: dogStatus, size: 18)
            .transition(.scale.combined(with: .opacity))
    }
}
```

状态切换时有**缩放+淡入淡出**过渡动画。

---

## 五、实现指南

### 5.1 新增主图标

复制 `DogIcon.swift` 结构：

```swift
struct NewIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false
    var breathe: Bool = false  
    var pulse: Bool = false
    
    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    // 1. 定义像素画
    private var idleBody: [(Int, Int, Color)] { [...] }
    private var runningFrames: [[(Int, Int, Color)]] { [...] }
    
    // 2. Canvas 渲染
    var body: some View { ... }
    
    // 3. 状态更新
    private func updateAnimationState() { ... }
}
```

### 5.2 更新 IdleIconStyle

```swift
enum IdleIconStyle: String, CaseIterable, Identifiable {
    case dog, cat, robot, island, ghost, lighthouse
    case newIcon = "newIcon"  // 添加新项
    
    var displayName: String { 
        case .newIcon: return "New Icon"
    }
    
    @ViewBuilder
    func iconView(size: CGFloat, animate: Bool, breathe: Bool, pulse: Bool) -> some View {
        case .newIcon:
            NewIcon(size: size, color: .white, animate: animate, breathe: breathe, pulse: pulse)
    }
}
```

---

## 六、视觉设计原则

### 6.1 信息层级

```
Level 1 (最显眼): 主图标动画 - 表达"氛围"
Level 2 (次显眼): 状态符号 - 表达"功能"  
Level 3 (背景):   颜色变化 - 辅助识别
```

### 6.2 颜色语义

| 颜色 | 含义 | 使用场景 |
|------|------|----------|
| 蓝色 | 活跃/处理中 | Running (!) |
| 琥珀色 | 注意/警告 | Waiting (?) |
| 绿色 | 成功/完成 | Done (✓) |
| 白色 | 中性/待机 | 主图标默认色 |

### 6.3 动效原则

- **Idle**: 静止，给用户平静感
- **Running**: 快速动画，传达"正在工作"
- **Waiting**: 脉冲动画，吸引注意力
- **Sleeping**: 缓慢呼吸，传达"休息中"

---

## 七、文件参考

| 文件 | 用途 |
|------|------|
| `ClaudeIsland/Models/DogStatus.swift` | 状态枚举定义 |
| `ClaudeIsland/Models/IdleIconStyle.swift` | 图标样式枚举 |
| `ClaudeIsland/UI/Components/DogIcon.swift` | 主图标参考实现 |
| `ClaudeIsland/UI/Components/StatusPixelIcon.swift` | 状态指示器 |
| `ClaudeIsland/UI/Views/NotchView.swift` | 布局组装 (搜索 `headerRow`) |

---

## 八、FAQ

**Q: 为什么 Idle 时不显示状态图标？**  
A: 保持界面极简，待机时只显示可爱的主图标，不打扰用户。

**Q: 为什么用 !?✓ 而不是文字？**  
A: 图标大小只有 18px，文字无法辨认。符号全球通用，无需翻译。

**Q: 多个会话状态冲突怎么办？**  
A: 按优先级显示：Waiting > Running > Sleeping > Idle。

**Q: 如何调整动画速度？**  
A: 修改各 Icon 文件中的 `timer` 参数，单位是秒。

**Q: 可以增加新的状态吗？**  
A: 可以，需要修改：
1. `DogStatus.swift` - 添加新状态
2. `StatusPixelIcon.swift` - 添加新符号
3. `NotchView.swift` - 更新优先级逻辑
