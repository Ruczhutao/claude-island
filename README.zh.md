<div align="center">
  <h1 align="center">🐕 Agent Island</h1>
  <p align="center">
    专为 AI CLI 设计的 macOS 刘海栏应用 —— 支持 Claude、Codex、Kimi 等，Dynamic Island 风格监控体验。
    <br />
    <br />
    <a href="https://github.com/Ruczhutao/claude-island/releases/latest" target="_blank" rel="noopener noreferrer">
      <img src="https://img.shields.io/github/v/release/Ruczhutao/claude-island?style=rounded&color=white&labelColor=000000&label=release" alt="Release Version" />
    </a>
    <a href="https://github.com/Ruczhutao/claude-island/stargazers" target="_blank" rel="noopener noreferrer">
      <img src="https://img.shields.io/github/stars/Ruczhutao/claude-island?style=rounded&color=white&labelColor=000000&label=stars" alt="GitHub Stars" />
    </a>
  </p>
  <p>
    <a href="README.md">🇺🇸 English</a>
  </p>
</div>

## 功能特性

- **🎨 待机图标系统** —— 6款像素风格图标（狗、猫、机器人、岛屿、幽灵、灯塔），带状态动画
- **🔴 动态刘海 UI** —— 从 MacBook 刘海处展开，显示会话状态和控制选项
- **🤖 多 AI 支持** —— 同时监控 Claude Code、Codex CLI、Kimi CLI、Cursor、Gemini CLI 和 Qwen
- **📊 状态指示器** —— 视觉状态符号：!（处理中）、?（等待审批）、✓（完成）
- **🔔 智能通知** —— 会话开始、需要审批、任务完成时的音效提醒
- **✅ 权限处理** —— 
  - Claude / Qwen：直接在刘海栏中批准/拒绝
  - Codex / Kimi / Gemini：显示“前往终端审批”按钮快速跳转
  - Cursor：返回 IDE 中审批
- **💬 聊天历史** —— 查看完整的对话记录，支持 Markdown 渲染
- **🏷️ 状态栏短语** —— 关闭态刘海栏内显示滚动状态文字，支持主题包（默认/汪星人/自定义）
- **✨ 状态栏文字动效** —— 5 种动画效果：滚动、快闪、打字机、逐星、静态，支持调节动画速度
- **🖥️ 浏览器全屏自动隐藏** —— Safari、Chrome、Firefox、Edge、Arc、Brave 进入全屏时刘海栏自动隐藏
- **⚙️ 设置窗口** —— 弹出式偏好设置，支持选择待机图标、声音、状态栏短语、CLI hooks 管理
- **🔧 自动配置** —— 启用后会自动安装对应 CLI 的 hooks

## 支持的 AI CLI

| CLI | 状态 | 刘海栏审批 |
|-----|------|-----------|
| **Claude Code** | ✅ 已支持 | ✅ 刘海栏内 |
| **Codex** | ✅ 已支持 | 🔘 终端操作 |
| **Kimi** | ✅ 已支持 | 🔘 终端操作 |
| **Cursor** | ✅ 已支持 (3.0+) | 🔘 IDE 操作 |
| **Qwen** | ✅ 已支持 | ✅ 刘海栏内 |
| **Gemini CLI** | ✅ 已支持 | 🔘 终端操作 |
| **GitHub Copilot** | 🚧 即将支持 | — |

## 系统要求

- macOS 15.6+
- 至少安装一个支持的 AI CLI

## 安装

### 方式 1：下载 Release（推荐）

从 [Releases](https://github.com/Ruczhutao/claude-island/releases) 下载最新 DMG，然后拖到 Applications。

### 方式 2：本地构建（无需 Apple Developer 账号）

适合本地开发或无签名测试：

```bash
# 克隆仓库
git clone https://github.com/Ruczhutao/claude-island.git
cd claude-island

# 使用本地签名构建
./scripts/build-local.sh

# DMG 输出位置：
# releases/AgentIsland-x.x.x-local.dmg
```

**首次启动**：右键应用 → 打开 → 打开，以绕过未签名本地构建的 Gatekeeper 提示。

### 方式 3：Xcode 构建（开发）

```bash
# 在 Xcode 中打开
open ClaudeIsland.xcodeproj

# 或命令行构建
xcodebuild -scheme ClaudeIsland -configuration Release build
```

## 工作原理

Agent Island 会在各 CLI 的配置目录安装 hooks：
- `~/.claude/hooks/` —— Claude Code
- `~/.codex/hooks/` —— Codex CLI
- `~/.kimi/hooks/` —— Kimi CLI
- `~/.cursor/hooks.json` —— Cursor (3.0+)
- `~/.gemini/settings.json` —— Gemini CLI
- `~/.qwen/settings.json` —— Qwen

Hooks 通过 Unix socket (`/tmp/claude-island.sock`) 与会话状态通信，应用监听事件并在刘海栏中展示。

## 音效系统

内置 3 个复古 8-bit 音效：
- **会话开始** —— 检测到新 CLI 会话
- **需要审批** —— 工具执行等待批准
- **任务完成** —— AI 完成回复

还支持 13 个 macOS 系统音效。应用会自动热加载 Sounds 目录中的自定义 MP3 文件，无需重启。

## 隐私说明

Agent Island 使用 Mixpanel 收集匿名使用数据：

- **应用启动** —— 应用版本、构建号、macOS 版本
- **会话开始** —— 检测到新 CLI 会话时

**不收集任何个人数据或对话内容。**

## 开源协议

Apache 2.0

---

*Made with ❤️ by developers, for developers.*
