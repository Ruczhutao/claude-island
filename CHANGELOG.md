# Changelog

所有对 Agent Island 项目的显著变更都将记录在此文件。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## [2.0.0] - 2026-04-04

### 🎉 重大更新：项目更名为 Agent Island

原项目 "ClaudeIsland" 正式更名为 **"Agent Island"** —— 一个支持多 AI CLI 的 macOS Notch 栏应用。

### 新增

#### 多 Provider 支持
- **Kimi CLI 支持** - 新增对 Kimi Code CLI 的完整支持
  - 新增 `kimi` Provider，与 `claude` 和 `codex` 并列
  - 新增 `kimi-island-state.py` hook 脚本监听 Kimi 事件
  - Kimi = 🔵 蓝色标识，字母 "K"
  - 支持 hooks: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, SubagentStop, PreCompact, SessionEnd
  - 支持审批通知（用户需前往终端操作）
  - 自动安装/卸载 Kimi hooks 到 `~/.kimi/config.toml`
  - **专属 Kimi 像素图标** - 基于 Kimi logo 设计的像素风格方块脸图标

- **Codex CLI 支持** - 新增对 OpenAI Codex CLI 的完整支持
  - 新增 `codex` Provider
  - 新增 `codex-island-state.py` hook 脚本
  - Codex = ☁️ 蓝色云朵标识，字母 "X"
  - 支持审批通知（用户需前往终端操作）

#### 像素图标系统
- **常驻图标**：白色像素狗（柯基风格，耳朵摆动动画 + 呼吸效果）
- **Claude 会话**：橙色像素螃蟹（钳子摆动动画）
- **Codex 会话**：蓝色像素云朵（终端光标闪烁动画）
- **Kimi 会话**：亮蓝色像素方块（眨眼动画）
- 所有图标均为 16×16 像素网格绘制
- Notch 栏图标尺寸 26px，会话列表 16px

#### 设置窗口
- **弹出式设置窗口** - 类似 Vibe Island 的设置界面
  - 侧边栏导航：通用、显示、声音、关于
  - 全功能设置界面，替代原菜单
- **CLI Hooks 管理** - 设置中可独立开关各 CLI 的 hooks
  - 显示每个 CLI 的激活状态（已激活/未激活/即将支持）
  - 即将支持的 CLI：Qwen、Gemini CLI、Cursor Agent、GitHub Copilot
- **音效设置** - 新增"打开音效文件夹"功能，支持用户自定义 MP3

#### 音效系统
- 3 个内置 8-bit 音效（8bit1, 8bit2, 8bit3）
- 13 个 macOS 系统音效（Pop, Ping, Tink, Glass 等）
- 支持为不同事件配置不同音效
  - 会话开始
  - 任务完成
  - 需要审批
- 全局音量控制（0-100%）
- 每个音效独立开关
- 音效预览功能
- **智能音效延迟** - Kimi/Codex 审批音效延迟 0.5s，避免 yolo 模式误触发

#### 其他新增
- **通用窗口聚焦** - 支持多种终端和 IDE
  - iTerm2、Ghostty、Warp、Terminal
  - VS Code、Cursor
  - Codex Desktop
- **无活动呼吸动画** - 像素狗在无 CLI 活动时显示呼吸效果（淡入淡出）

### 修改
- **界面全面汉化** - 所有 UI 文字翻译为中文
- **Notch 栏交互优化**
  - 三条杠菜单按钮改为齿轮图标
  - 点击齿轮直接打开设置窗口
- **自动更新改为趣味弹窗** - 点击检查更新显示：
  - 标题："朱涛忙着呢，等会儿的"
  - 按钮1："默默支持，给他点赞" → 打开 B 站视频
  - 按钮2："现在就去微信催他" → 打开微信

### 修复
- **权限审批音效问题** - 修复审批和完成音效同时播放的问题
- **状态指示器换行** - 修复 processing 状态省略号闪烁换行的问题
- **Kimi 审批无响应** - 修复点击允许无反应的问题（改为"前往终端"模式）

### 技术债务
- `DEVELOPMENT_TEAM` 签名需要恢复为原始值后再提 PR
- 如需启用自动更新，需配置新的 Sparkle 更新源

---

## [1.x] - 原始版本 (ClaudeIsland)

### 功能
- Dynamic Island 风格 Notch UI
- Claude Code CLI 会话监控
- 权限审批（允许/拒绝工具执行）
- 聊天历史查看
- Hook 自动安装
