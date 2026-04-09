# Changelog

所有对 Agent Island 项目的显著变更都将记录在此文件。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## [2.3.2] - 2026-04-09

### 新增

#### Qwen CLI 像素图标
- **全新 Qwen Provider 图标** — 基于 Qwen 官方 logo 设计的 16×16 像素六角星形
  - 6 个彩色花瓣，渐变色接近原 logo（紫罗兰→粉紫→玫红→橙红→橙粉→紫色）
  - 中心白色亮点，模拟光效
  - Running 状态：花瓣高亮顺时针旋转动画
  - Waiting 状态：整体脉冲缩放（0.88x）
  - Sleeping 状态：呼吸缩放（0.92x）+ 透明度 0.85
  - Idle 状态：静态显示
- **新增文件**：
  - `ClaudeIsland/UI/Components/QwenIcon.swift` — 完整 4 状态像素图标实现

#### Qwen Notch 内审批支持
- **修复 Qwen PermissionRequest 无法在 Notch 中审批的 bug**
  - `HookSocketServer.swift` 的 `expectsResponse` 方法现在包含 `.qwen` provider
  - Qwen 现在支持完整的 allow/deny 决策返回，与 Claude 一致
- **注意**：Codex、Kimi、Cursor、Gemini 因 CLI 本身限制，不支持 `allow` 返回，仍需前往终端/IDE 审批

### 变更
- Qwen 图标仅作为 CLI Provider 图标使用，不作为待机图标选择器选项
- Codex 会话标题现在优先显示首条用户消息，多个 conversation 在列表里更容易区分
- README 支持矩阵与 hook 配置说明同步到当前真实能力

### 修复
- **Qwen Running 动画完整轮转** — 运行态高亮从 4 帧改为 6 帧，6 个花瓣都会依次成为高亮焦点
- **Codex 会话残留恢复** — app 重启后不再恢复停留在 `waitingForInput` / 空闲态的旧 Codex conversation，减少列表中“像重复会话”的残留项

## [2.3.1] - 2026-04-08

### 新增

#### 状态栏文字动效系统
- 为 Notch 关闭态的状态短语新增 4 种文字效果：
  - **滚动** — 同一状态下多条短语拼接成长串，持续无缝滚动
  - **快闪** — 短语快速淡入淡出切换，保持动态
  - **打字机** — 逐字打出随机短语，`_` 光标闪烁，打完停留后切换下一句
  - **静态** — 单条短语居中显示
- 新增「动画速度」Slider，范围 0.2x – 2.0x，统一控制所有动效速度

### 改进
- 状态栏短语不再每 8 秒随机跳变，切换更自然流畅
- 文本宽度测量改用真实字体大小，滚动判断更准确

### 修复
- **严重崩溃** — 修复 `deinit` 中异步访问 `self` 导致的 `SIGSEGV` / `EXC_BAD_ACCESS` 启动崩溃
- **设置卡死** — 修复拖动「动画速度」Slider 时因 `UserDefaults.didChangeNotification` 风暴导致的主线程卡死

### 变更
- 移除「马克思」预设主题（用户可将其内容用于自定义主题）

## [2.3.0] - 2026-04-08

### 新增

#### Gemini CLI 完整支持 ✅
- **第五 Provider 完整集成** - Gemini CLI (v0.36.0+) 现已完全支持
  - 支持事件：SessionStart, BeforeAgent, BeforeTool, AfterTool, AfterAgent, SessionEnd
  - 事件映射：BeforeAgent → UserPromptSubmit, BeforeTool → PreToolUse, AfterTool → PostToolUse, AfterAgent → Stop
  - 使用 Gemini CLI 原生嵌套 hook 格式 `{"hooks": [{"command":..., "type": "command"}]}`
  - Hook 脚本输出 `{"continue":true}` 符合 Gemini CLI 协议
  - 显示 Gemini 菱形星星像素图标（蓝紫色，带闪烁动画）
- **新增文件**：
  - `ClaudeIsland/Resources/gemini-island-state.py` - Gemini bridge 脚本
  - `ClaudeIsland/UI/Components/GeminiIcon.swift` - 菱形星星像素图标
- **配置文件**：`~/.gemini/settings.json` (hooks 部分)
- **Hook 脚本安装路径**：`~/.gemini/hooks/gemini-island-state.py`

#### 浏览器全屏自动隐藏修复
- 浏览器（Safari/Chrome/Firefox/Edge/Arc/Brave）进入全屏模式时刘海栏不再遮挡
- 检测间隔从 2 秒缩短到 0.5 秒，检测所有屏幕

#### 自定义铃声修复
- `AvailableSound` 从 enum 改为 struct，支持动态扫描自定义 MP3 铃声
- 每 2 秒自动扫描 Sounds 目录，新增铃声无需重启即可出现
- 修复预览播放中断问题

### 改进
- HookInstaller 支持 Gemini CLI 的嵌套 hook 格式安装
- SessionStore 支持 Gemini 的工具审批流程
- 全屏检测覆盖所有主流浏览器

### 修复
- **设置窗口状态重置** - 每次打开设置窗口都是全新实例，不再复用旧窗口
- **检查更新弹窗** - 添加取消按钮，关闭弹窗更方便

#### 状态栏短语系统
- **刘海栏滚动文字** - 关闭态刘海内显示状态提示文字
  - 根据会话状态自动切换：工作中 / 等待审批 / 任务完成 / 空闲
  - 每种状态从短语库中随机选取，8 秒自动更换
  - 多个 Agent 同时工作时显示数量（如 "2 个 Agent 正在工作"）
- **主题包系统** - 内置两套主题风格 + 自定义模式
  - 「默认」— 简洁专业风格
  - 「汪星人」— 趣味汪汪风格
  - 「自定义」— 用户可编辑每种状态的短语（每状态最多 10 条，每行一条）
- **设置界面** - 显示设置中新增「状态栏短语」区段，含主题选择器和自定义编辑器
- **新增文件**：
  - `ClaudeIsland/UI/Components/MarqueeText.swift` - 滚动文字组件
  - `ClaudeIsland/UI/Components/MarqueeStatusProvider.swift` - 短语状态管理（含主题定义）
- **Mixpanel 初始化** - 将初始化移到 `override init()` 中，避免 socket 事件提前触发导致的 crash

## [2.2.0] - 2026-04-06

### 新增

#### Cursor 3.0 Hooks 完整支持 ✅
- **第四 Provider 完整集成** - Cursor 3.0+ 现在支持完整的 hooks 机制
  - 支持事件：beforeSubmitPrompt, afterAgentResponse, beforeShellExecution, afterShellExecution, stop
  - 自动获取真实项目名（从 workspace_roots）
  - 检测 Agent 处理状态和工具调用
  - 显示 Cursor 六边形像素图标（白色，带闪烁动画）
- **新增文件**：
  - `ClaudeIsland/Resources/cursor-island-state.py` - Cursor bridge 脚本
- **配置文件**：`~/.cursor/hooks.json`

#### yabai 一键安装
- **窗口增强组件安装器** - 在设置中提供 yabai 一键安装
  - 自动检测 Homebrew 并安装 yabai
  - 引导用户授予辅助功能权限
  - 自动启动 yabai 服务
  - 实时显示安装进度和日志
- **安装界面** - 美观的安装面板，说明 yabai 的作用
  - 列出增强功能：精确聚焦、多窗口支持、跨空间聚焦
  - 清晰的权限说明
  - 安装状态实时反馈
- **新增文件**：
  - `ClaudeIsland/Services/Window/YabaiInstaller.swift`
  - `scripts/install-yabai.sh`

### 改进

#### 全新待机图标系统 🎨
- **双图标架构** - 主图标(32px) + 状态指示器(18px)
  - 主图标负责情感表达（动画氛围）
  - 状态指示器负责明确状态（!?✓符号）
- **六大主图标** - Dog/Cat/Robot/Island/Ghost/Lighthouse
  - 每个图标都有4种状态动画：Idle/Sleeping/Running/Waiting
  - 统一的动画参数：呼吸0.92x、脉冲0.88x、奔跑12fps
- **极简状态指示器**
  - Idle: 完全隐藏（极简设计）
  - Running: 蓝色「!」惊叹号
  - Waiting: 琥珀色「?」问号
  - Sleeping: 绿色「✓」对钩
- **状态优先级**: Waiting > Running > Sleeping > Idle
- **新增文档**:
  - `docs/ICON_SYSTEM.md` - 系统架构说明
  - `docs/ICON_CATALOG.md` - 图标分类与状态说明

#### Cursor 窗口聚焦增强
- **智能窗口匹配** - 根据项目名匹配正确的 Cursor 窗口
  - 解析窗口标题提取项目名称
  - 支持 "文件名 - 项目名 — Cursor" 格式
  - 支持 "项目名 — Cursor" 格式
- **yabai 集成** - 使用 yabai 精确聚焦特定窗口
  - 通过窗口 ID 精确聚焦
  - 优先聚焦可见窗口
- **增强文件**：`ClaudeIsland/Services/Window/UniversalWindowFocuser.swift`
  - 添加 `focusCursorEnhanced()` 方法
  - 添加 `findCursorWindow()` 窗口查找
  - 添加详细的日志记录

### 修复

- **CursorIcon 数组越界** - 修复 sparklePixels 和 sparklePhases 数量不匹配导致的崩溃
- **声音文件打包** - 修复 MP3 文件未包含在构建产物中的问题
- **主线程阻塞** - 修复 `fetchAndRegisterClaudeVersion()` 在主线程执行文件遍历导致卡顿的问题
- **声音播放** - 修复 `SoundManager.playMP3()` 可能阻塞主线程的问题

### 技术债务
- `DEVELOPMENT_TEAM` 签名需要恢复为原始值后再提 PR
- 如需启用自动更新，需配置新的 Sparkle 更新源

---

## [2.1.2] - 2026-04-05

### 修复

#### Cursor 会话消失
- **修复 stop 事件处理** - 将 `status: "ended"` 改为 `status: "waiting_for_input"`，会话不再在回复完成后消失
- **文件**：`ClaudeIsland/Resources/cursor-island-state.py`

#### 删除按钮
- **所有会话可删除** - 移除仅 `idle` 或 `waitingForInput` 状态才能删除的限制
- **文件**：`ClaudeIsland/UI/Views/ClaudeInstancesView.swift`

#### Cursor 按钮文本
- **动态文本** - 根据 Provider 显示不同文本：
  - Cursor："前往 Cursor"
  - Kimi/Codex："前往终端审批"
- **文件**：`ClaudeIsland/UI/Views/ClaudeInstancesView.swift`

#### 窗口聚焦
- **无 yabai 时也能聚焦** - 移除 `cursorApp.isActive` 限制
- **文件**：`ClaudeIsland/Services/Session/CursorWindowMonitor.swift`

#### 支持属性
- **添加 Cursor 支持** - `supportsChatHistory` 和 `supportsInNotchApproval` 包含 Cursor
- **文件**：`ClaudeIsland/Models/SessionState.swift`

### 新增

#### 全屏自动隐藏
- **可选功能** - 应用进入全屏时自动隐藏 Notch 栏（默认关闭）
- **实现方式** - 检测窗口面积覆盖率（>95%）判断全屏状态
- **设置位置** - 设置 → 显示 → "全屏时隐藏"
- **注意** - 该功能可靠性有限，如需使用请手动开启
- **文件**：`ClaudeIsland/Core/FullscreenDetector.swift`

#### 下次会话提示词
- **新增文件** - `NEXT_SESSION_PROMPT_2026-04-05_v2.1.2.md` 方便下次继续开发

### 改进

#### Cursor Hooks 格式
- **使用简单格式** - 与 Codex/Claude 的嵌套格式不同，Cursor 使用 `{"hooks": {"event": [{"command": "..."}]}}`
- **新增函数** - `updateCursorHooksFile()` 和 `cursorHooksFile()`
- **文件**：`ClaudeIsland/Services/Hooks/HookInstaller.swift`

---

## [2.1.0] - 2026-04-04

### 新增

#### Cursor IDE 支持
- **第四 Provider** - 新增对 Cursor 编辑器的支持
  - 启用 Cursor 开关（设置 → 通用 → CLI Hooks）
  - **像素图标**：白色六边形钻石 + 3D 立方体效果 + 闪烁动画
  - **颜色**：白色/银色
  - **窗口聚焦**：支持点击会话跳转到 Cursor 应用
  - **文件**：`ClaudeIsland/UI/Components/CursorIcon.swift`

#### 会话状态持久化
- **启动恢复** - 应用重启后自动恢复之前的活跃会话
  - 保存会话元数据（项目名、最后消息、时间戳等）
  - 自动从历史文件恢复完整对话记录
  - 24小时后自动清理过期会话
  - 状态变化时自动保存
  - 实现类似 Raycast 等应用的会话延续体验
- **新增文件**：`ClaudeIsland/Services/State/SessionPersistence.swift`

#### 本地构建脚本
- **build-local.sh** - 简化版构建脚本，无需 Apple Developer 账号
  - 自动重新签名 Sparkle 框架（修复签名不匹配导致的崩溃）
  - 清理扩展属性避免"iCopy"等残留创建者信息
  - 设置自定义创建者信息（RUC涛子）
  - 生成标准 DMG 安装界面（应用图标 + 箭头 + Applications 文件夹）

### 修改

#### 应用名称
- **Bundle Display Name** 从 "Claude Island" 改为 "Agent Island"
- **DMG 卷标** 改为 "Agent Island"

#### 趣味弹窗更新
- "现在就去微信催他" 按钮改为 "去 B 站支持他"
- 链接改为：https://www.bilibili.com/video/BV1Pe41157zg/

#### 版本号
- **版本**：2.1.0
- **Build**：4

---

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
