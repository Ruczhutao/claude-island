# yabai 集成方案

本文档说明 Agent Island 如何集成 yabai 窗口管理器。

## 为什么不直接捆绑 yabai？

| 问题 | 说明 |
|------|------|
| **权限要求** | yabai 需要辅助功能权限，必须由用户手动授权 |
| **系统服务** | yabai 作为系统服务运行，不能单纯作为库嵌入 |
| **SIP 设置** | 高级功能需要用户部分禁用 SIP |
| **维护成本** | 捆绑二进制会增加应用体积和更新复杂度 |

## 采用的方案：可选增强组件

```
Agent Island
    ├── 核心功能 (无需 yabai)  ← 所有人可用
    │   ├── 基本的 App 级聚焦
    │   └── Bundle ID 启动
    │
    └── 增强功能 (可选 yabai)  ← 进阶用户
        ├── 窗口标题匹配
        └── 精确窗口 ID 聚焦
```

## 用户体验

### 1. 透明回退
- 安装 yabai = 精确聚焦到项目窗口
- 未安装 yabai = 基本的 App 聚焦（切换到 Cursor）

### 2. 设置界面集成
在「通用 → 窗口增强」提供一键安装

### 3. 安装流程
```
用户点击"安装 yabai"
    ↓
检查 Homebrew → 运行安装脚本
    ↓
授予辅助功能权限
    ↓
启动 yabai 服务
    ↓
完成！
```

## 技术实现

### 核心文件
- `YabaiInstaller.swift` - 安装管理
- `install-yabai.sh` - 安装脚本
- `UniversalWindowFocuser.swift` - 聚焦逻辑

### 回退策略
```swift
func focusCursor(cwd: String) async -> Bool {
    // 1. 尝试 yabai 精确聚焦
    if useYabai {
        return await focusViaYabai(cwd: cwd)
    }
    
    // 2. 回退：Bundle ID 激活
    return await activateViaBundleId()
}
```

## 权限要求

**必需**：辅助功能权限（控制窗口）  
**可选**：屏幕录制权限（窗口动画）

## 安全性
- yabai MIT 许可证，可自由集成
- 所有权限请求透明
- 核心功能无需 yabai 也可用
- 无网络请求或数据收集
