<div align="center">
  <h1 align="center">🐕 Agent Island</h1>
  <p align="center">
    A macOS Notch Bar app for AI CLI agents — Dynamic Island-style monitoring for Claude, Codex, Kimi, and more.
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
    <a href="README.zh.md">🇨🇳 中文版</a>
  </p>
</div>

## Features

- **🎨 Idle Icon System** — 6 pixel-art icons (Dog, Cat, Robot, Island, Ghost, Lighthouse) with status animations
- **🔴 Dynamic Notch UI** — Expands from the MacBook notch to show session status and controls
- **🤖 Multi-Provider Support** — Monitor Claude Code, Codex CLI, Kimi CLI, and Cursor simultaneously
- **📊 Status Indicators** — Visual state symbols: ! (processing), ? (waiting approval), ✓ (done)
- **🔔 Smart Notifications** — Sound alerts for session start, tool approvals, and task completion
- **✅ Permission Handling** — 
  - Claude: Approve/deny directly in the notch
  - Codex/Kimi/Cursor: "Go to Terminal" button for quick access
- **💬 Chat History** — View full conversation history with markdown rendering
- **⚙️ Preferences Window** — Settings for idle icon, sounds, and CLI hooks
- **🔧 Auto-Setup** — Hooks install automatically for enabled CLIs

## Supported AI CLIs

| CLI | Status | Notch Approval |
|-----|--------|----------------|
| **Claude Code** | ✅ Supported | ✅ In-notch |
| **Codex** | ✅ Supported | 🔘 Terminal |
| **Kimi** | ✅ Supported | 🔘 Terminal |
| **Cursor** | ✅ Supported (3.0+) | 🔘 Terminal |
| **Qwen** | 🚧 Coming Soon | — |
| **Gemini CLI** | 🚧 Coming Soon | — |
| **GitHub Copilot** | 🚧 Coming Soon | — |

## Requirements

- macOS 15.6+
- At least one supported AI CLI installed

## Install

Download the latest release or build from source:

```bash
xcodebuild -scheme ClaudeIsland -configuration Release build
```

## How It Works

Agent Island installs hooks into each CLI's config directory:
- `~/.claude/hooks/` for Claude Code
- `~/.codex/hooks/` for Codex CLI
- `~/.kimi/hooks/` for Kimi CLI
- `~/.cursor/hooks.json` for Cursor (3.0+)

Hooks communicate session state via a Unix socket (`/tmp/claude-island.sock`). The app listens for events and displays them in the notch overlay.

## Sound Effects

Three 8-bit retro sound effects included:
- **Session Start** — New CLI session detected
- **Need Approval** — Tool execution waiting for permission
- **Task Complete** — AI finished responding

Plus 13 macOS system sounds available. Custom MP3s can be added to `~/Library/Sounds/`.

## Analytics

Agent Island uses Mixpanel to collect anonymous usage data:

- **App Launched** — App version, build number, macOS version
- **Session Started** — When a new CLI session is detected

No personal data or conversation content is collected.

## License

Apache 2.0

---

*Made with ❤️ by developers, for developers.*
