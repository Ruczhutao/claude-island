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
- **🤖 多 AI 支持** —— 同时监控 Claude Code、Codex CLI、Kimi CLI 和 Cursor
- **📊 状态指示器** —— 视觉状态符号：!（处理中）、?（等待审批）、✓（完成）
- **🔔 智能通知** —— 会话开始、需要审批、任务完成时的音效提醒
- **✅ 权限处理** —— 
  - Claude：直接在刘海栏中批准/拒绝
  - Codex/Kimi/Cursor：显示"前往终端"按钮快速跳转
- **💬 聊天历史** —— 查看完整的对话记录，支持 Markdown 渲染
- **⚙️ 设置窗口** —— 弹出式偏好设置，支持选择待机图标、声音、CLI hooks 管理
- **🔧 自动配置** —— 启用后会自动安装对应 CLI 的 hooks

## 支持的 AI CLI

| CLI | 状态 | 刘海栏审批 |
|-----|------|-----------|
| **Claude Code** | ✅ 已支持 | ✅ 刘海栏内 |
| **Codex** | ✅ 已支持 | 🔘 终端操作 |
| **Kimi** | ✅ 已支持 | 🔘 终端操作 |
| **Cursor** | ✅ 已支持 (3.0+) | 🔘 终端操作 |
| **Qwen** | 🚧 即将支持 | — |
| **Gemini CLI** | 🚧 即将支持 | — |
| **GitHub Copilot** | 🚧 即将支持 | — |

## 系统要求

- macOS 15.6+
- 至少安装一个支持的 AI CLI

## 安装

下载最新 Release 或从源码构建：

```bash
xcodebuild -scheme ClaudeIsland -configuration Release build
```

## 工作原理

Agent Island 会在各 CLI 的配置目录安装 hooks：
- `~/.claude/hooks/` —— Claude Code
- `~/.codex/hooks/` —— Codex CLI
- `~/.kimi/hooks/` —— Kimi CLI

Hooks 通过 Unix socket (`/tmp/claude-island.sock`) 与会话状态通信，应用监听事件并在刘海栏中展示。

## 音效系统

内置 3 个复古 8-bit 音效：
- **会话开始** —— 检测到新 CLI 会话
- **需要审批** —— 工具执行等待批准
- **任务完成** —— AI 完成回复

还支持 13 个 macOS 系统音效。可自定义 MP3 文件，放入 `~/Library/Sounds/` 即可。

## 隐私说明

Agent Island 使用 Mixpanel 收集匿名使用数据：

- **应用启动** —— 应用版本、构建号、macOS 版本
- **会话开始** —— 检测到新 CLI 会话时

**不收集任何个人数据或对话内容。**

## 开源协议

Apache 2.0

---

*Made with ❤️ by developers, for developers.*
