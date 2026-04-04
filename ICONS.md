# ClaudeIsland 图标系统

## 概述

ClaudeIsland 使用像素风格动画图标：

### 主界面常驻图标

| 场景 | 图标文件 | 视觉形象 | 颜色 | 动画效果 |
|------|----------|----------|------|----------|
| **无会话时** | `DogIcon.swift` | 🐕 像素狗 (柯基) | 橙色 `#D97857` | 耳朵上下摆动 |

### 各 Provider 会话图标

| Provider | 图标文件 | 视觉形象 | 颜色 | 动画效果 |
|----------|----------|----------|------|----------|
| **Claude** | `ClaudeIcon.swift` | 🦀 像素螃蟹 | 橙色 `#D97857` | 身体脉冲 + 双钳摆动 |
| **Codex** | `CodexIcon.swift` | ☁️ 云朵终端 | 蓝色 `#3399FF` | 上下跳动 + 光标闪烁 |
| **Kimi** | `KimiIcon.swift` | 🔷 方块脸 | 亮蓝 `#008CFF` | 上下弹跳 + 眨眼 |

## 文件结构

```
ClaudeIsland/UI/Components/
├── DogIcon.swift         # 🐕 像素狗（主界面常驻图标）
├── ClaudeIcon.swift      # 🦀 Claude 像素螃蟹
├── CodexIcon.swift       # ☁️ Codex 像素云朵终端
├── KimiIcon.swift        # 🔷 Kimi 像素方块脸
└── RenDaIcon.swift       # 人大三人行（备用）
```

## 使用位置

### 1. Notch 栏头部 (`NotchView.swift`)

#### A. 无会话时（常驻图标）
```swift
if !showClosedActivity {
    // 默认图标 - 人大三人行
    RenDaIcon(size: 18, color: Color(red: 0.75, green: 0.15, blue: 0.15), animate: false)
}
```
- **显示位置**：Notch 栏左侧
- **颜色**：人大红
- **动画**：无会话时静态，有会话时消失

#### B. 有会话时（Provider 图标）
```swift
// 根据当前活动的 Provider 显示对应图标
@ViewBuilder
private func providerIcon(size: CGFloat, animate: Bool) -> some View {
    switch dominantProvider {
    case .claude: ClaudeIcon(...)
    case .codex:  CodexIcon(...)
    case .kimi:   KimiIcon(...)
    }
}
```
- **触发**：有活跃会话时替换三人行图标
- **动画**：`isProcessing` 为 true 时播放

### 2. 会话列表 (`ClaudeInstancesView.swift`)

```swift
// 每个会话行显示对应 Provider 的图标
@ViewBuilder
private var providerIcon: some View {
    let isProcessing = session.phase == .processing || session.phase == .compacting
    
    switch session.provider {
    case .claude:
        ClaudeIcon(size: 16, color: providerColor, animate: isProcessing)
    case .codex:
        CodexIcon(size: 16, color: providerColor, animate: isProcessing)
    case .kimi:
        KimiIcon(size: 16, color: providerColor, animate: isProcessing)
    }
}
```

**触发时机**：
- 每个会话行左侧显示
- 该会话处于 processing/compacting 状态时播放动画

## 颜色定义

### 无会话时（常驻图标）
```swift
// RenDa 三人行 - 人大红
RenDaIcon(size: 18, color: Color(red: 0.75, green: 0.15, blue: 0.15), animate: false)
```

### 有会话时（Provider 图标）

#### NotchView.swift
```swift
private var activityColor: Color {
    switch dominantProvider {
    case .claude:
        return Color(red: 0.85, green: 0.47, blue: 0.34) // 橙色
    case .codex:
        return Color(red: 0.2, green: 0.6, blue: 1.0)   // 蓝色
    case .kimi:
        return Color(red: 0.0, green: 0.55, blue: 1.0)  // 亮蓝色
    }
}
```

### ClaudeInstancesView.swift
```swift
private var providerColor: Color {
    switch session.provider {
    case .claude:
        return claudeOrange  // Color(red: 0.85, green: 0.47, blue: 0.34)
    case .codex:
        return Color(red: 0.2, green: 0.6, blue: 1.0)
    case .kimi:
        return Color(red: 0.0, green: 0.55, blue: 1.0)
    }
}
```

## 图标规格

所有图标遵循统一规格：

| 属性 | 值 | 说明 |
|------|-----|------|
| 基础网格 | 16×16 | 像素艺术标准尺寸 |
| 渲染方式 | `Canvas` + `Path` | SwiftUI 原生绘制 |
| 动画帧率 | 0.2-0.3 秒/帧 | 不同图标略有差异 |
| 动画类型 | `Timer.publish` | 基于 Combine |

## 动画详情

### RenDaIcon (三人行)
- **左右分开**：左人左移、右人右移（扩散）
- **向中合并**：三个人字聚拢
- **周期**：8 帧循环（0.15秒/帧）
- **效果**：像呼吸一样张开聚合

### ClaudeIcon (螃蟹)
- **身体脉冲**：缩放比例 0.95 → 1.0 → 1.05 → 1.0
- **钳子摆动**：左右钳子反向上下摆动
- **周期**：16 帧循环

### CodexIcon (云朵终端)
- **上下跳动**：Y 轴偏移 -1 → 0 → 1 → 0
- **光标闪烁**：下划线 `_` 每 4 帧隐藏一次
- **周期**：16 帧循环

### KimiIcon (方块脸)
- **上下弹跳**：Y 轴偏移 -1 → 0 → 1 → 0
- **眨眼**：眼睛每 6 帧闭合一次
- **周期**：12 帧循环

## 添加新 Provider

如需添加新 Provider 图标：

1. **创建图标文件**：`NewProviderIcon.swift`
   ```swift
   struct NewProviderIcon: View {
       let size: CGFloat
       let color: Color
       var animate: Bool = false
       // ... 实现
   }
   ```

2. **更新 `SessionProvider.swift`**：添加新 case

3. **更新颜色定义**：在 `NotchView.swift` 和 `ClaudeInstancesView.swift` 中添加颜色

4. **更新图标选择逻辑**：在 `providerIcon` 中添加 switch case

## 设计原则

1. **像素风格**：所有图标使用 16×16 像素网格
2. **统一动画**：所有图标支持 `animate` 参数，处理中时播放动画
3. **颜色区分**：每个 Provider 有独特的品牌色
4. **语义明确**：图标形状反映品牌特征（螃蟹/云朵/方块）
