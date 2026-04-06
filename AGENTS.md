# Agent Island - AI 开发助手指引

> **Agent Island** 是一个 macOS Notch 栏应用，为 Claude、Codex、Kimi 等 AI CLI 工具提供 Dynamic Island 风格的会话监控。

---

## 🚀 快速开始

### 环境要求
- macOS 15.6+
- Xcode 15+
- 至少一个支持的 AI CLI 工具（Claude Code / Codex CLI / Kimi CLI / Cursor 3.0）

### 本地构建

```bash
# 克隆仓库
git clone https://github.com/Ruczhutao/claude-island.git
cd claude-island

# 本地构建（无需 Apple Developer）
./scripts/build-local.sh

# 输出位置
# releases/AgentIsland-2.1.0-local.dmg
```

### 开发环境

```bash
# 打开 Xcode 项目
open ClaudeIsland.xcodeproj

# 或使用命令行构建
xcodebuild -project ClaudeIsland.xcodeproj \
  -scheme ClaudeIsland \
  -configuration Debug \
  build
```

---

## 📁 项目结构

```
ClaudeIsland/
├── App/                    # 应用生命周期
│   ├── AppDelegate.swift
│   └── ClaudeIslandApp.swift
├── Core/                   # 核心组件
│   ├── NotchViewModel.swift    # Notch 状态管理
│   ├── Settings.swift          # 设置管理
│   └── ...
├── Models/                 # 数据模型
│   ├── SessionState.swift      # 会话状态
│   ├── SessionProvider.swift   # Provider 枚举
│   └── ...
├── Services/               # 业务服务
│   ├── Hooks/              # CLI hooks 安装与管理
│   │   ├── HookInstaller.swift
│   │   └── HookSocketServer.swift
│   ├── Session/            # 会话监控
│   │   ├── CursorWindowMonitor.swift
│   │   └── ...
│   ├── State/              # 状态持久化
│   │   ├── SessionStore.swift
│   │   └── SessionPersistence.swift
│   ├── Window/             # 窗口聚焦
│   │   ├── UniversalWindowFocuser.swift
│   │   └── YabaiInstaller.swift
│   └── ...
├── UI/                     # 用户界面
│   ├── Components/         # 图标组件（像素风格）
│   ├── Views/              # 视图
│   └── Window/             # 窗口管理
└── Resources/              # 资源文件
    └── Sounds/             # 音效文件
```

---

## 🎯 核心概念

### Provider 系统

| Provider | 图标 | 颜色 | 检测方式 | 审批方式 |
|----------|------|------|----------|----------|
| Claude | 🦀 | 橙色 | Hooks | Notch 内审批 |
| Codex | ☁️ | 蓝色 | Hooks | 前往终端 |
| Kimi | 🔷 | 亮蓝 | Hooks | 前往终端 |
| Cursor | ⬡ | 白色 | Hooks (v3.0+) | 前往应用 |

**注意**：Cursor 3.0+ 使用完整的 hooks 机制，类似 Claude/Codex/Kimi。

### 像素图标系统

- 使用 16×16 像素网格绘制
- Notch 栏显示 26px，会话列表显示 16px
- 支持动画（Canvas + Timer）

### Hook 系统

- 通过 Unix Socket 通信 (`/tmp/claude-island.sock`)
- 自动安装到 CLI 配置目录
- Python 脚本监听 CLI 事件

---

## 📝 开发规范

### 代码风格

- 使用 Swift 5.9+
- 优先使用 `async/await` 处理异步
- Actor 隔离用于线程安全
- 使用 `os.log` 进行日志记录

### 新增 Provider

1. 在 `SessionProvider.swift` 添加枚举
2. 在 `HookInstaller.swift` 添加安装逻辑
3. 创建像素图标（参考 `CursorIcon.swift`）
4. 在 `ClaudeInstancesView.swift` 添加颜色和图标
5. 更新 `SessionStore.swift` 处理事件

### 新增音效

1. 添加 MP3 到 `Resources/Sounds/`
2. 在 `SoundManager.swift` 的 `AvailableSound` 枚举添加
3. 运行 `xattr -cr` 清除扩展属性

---

## 🔥 本期重点：Cursor 3.0 Hooks 支持

### 背景
经过测试发现，Cursor 3.0 支持完整的 hooks 机制，可以实现与 Claude/Codex 相同的监控体验。

### 目标
用 Cursor hooks 替代窗口检测，实现：
- 获取真实项目名（从 workspace_roots）
- 检测会话开始/结束
- 检测 Agent 处理状态
- 检测工具调用

### 参考文件
- `scripts/cursor-bridge.py` - 测试脚本，展示 hooks 数据格式
- `~/.cursor/hooks.json` - Cursor hooks 配置
- `/tmp/cursor-bridge.log` - 测试日志

### 实现步骤
详见 [HANDOVER.md](./docs/HANDOVER.md) 的「Cursor 3.0 Hooks 开发设计」章节。

---

## 📚 文档导航

| 文档 | 用途 |
|------|------|
| [README.md](README.md) | 用户入门指南 |
| [CHANGELOG.md](CHANGELOG.md) | 版本更新日志 |
| [HANDOVER.md](docs/HANDOVER.md) | 开发交接文档（含待办清单）⭐ |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | 系统架构详解 |
| [docs/README.md](docs/README.md) | 文档索引 |

---

## 🗂️ 后期任务清单

### 高优先级
- [x] ~~测试/修复 Cursor 窗口聚焦~~ (v2.1.1)
- [x] ~~yabai 一键安装~~ (v2.1.1)
- [x] ~~发现 Cursor 3.0 hooks~~ (v2.1.1)
- [x] **Cursor 3.0 Hooks 完整支持** ✅ 已完成
- [ ] 测试 Codex Desktop 窗口聚焦
- [ ] 配置 Sparkle 更新源（可选）
- [ ] 恢复 `DEVELOPMENT_TEAM` 签名（如要分发）

### 中优先级
- [ ] 音效热加载（不需要重启）
- [ ] 全局快捷键（设置界面已有预留）
- [ ] API 用量显示（需接入 Anthropic API）

### 低优先级/想法
- [ ] 更多 Provider 支持（Qwen、Gemini CLI、Copilot）
- [ ] 自定义图标上传
- [ ] 会话搜索/过滤
- [ ] 导出会话历史

---

## 🔗 相关链接

- **Fork 仓库**: https://github.com/Ruczhutao/claude-island
- **原仓库**: https://github.com/farouqaldori/claude-island
- **问题反馈**: GitHub Issues

---

## 💡 提示

> 本文档面向 AI 开发助手。如果你是人类开发者，请阅读 [README.md](README.md) 开始。

- 修改代码前查看 [HANDOVER.md](docs/HANDOVER.md) 了解当前状态
- 本期重点是 **Cursor 3.0 Hooks 完整支持**
- 架构问题查看 [ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 确保修改后更新相关文档
