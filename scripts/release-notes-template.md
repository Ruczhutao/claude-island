## Agent Island v{VERSION}

macOS Notch 栏 AI 会话监控工具

### 系统要求
- macOS 15.6+
- 支持 Apple Silicon & Intel

### 安装方法

#### 方法1：右键打开（推荐）
1. 下载 `AgentIsland-{VERSION}.dmg`
2. 双击挂载
3. 拖入 Applications 文件夹
4. **右键**点击应用 → **打开** → **仍要打开**

#### 方法2：终端清除隔离属性
```bash
xattr -cr /Applications/Agent\ Island.app
```

### 功能特性
- Dynamic Island 风格 Notch 栏监控
- 支持 Claude / Codex / Kimi / Cursor 四大 AI 工具
- 像素风格图标系统（6款图标可选）
- 实时状态指示（Idle/Running/Waiting/Done）
- 窗口快速聚焦

### 支持的 CLI 工具
| 工具 | 版本要求 | 检测方式 |
|------|----------|----------|
| Claude Code | 最新版 | Hooks |
| Codex CLI | 最新版 | Hooks |
| Kimi CLI | 最新版 | Hooks |
| Cursor | 3.0+ | Hooks |

### 首次使用
1. 在设置中选择你喜欢的图标（Dog/Cat/Robot/Island/Ghost/Lighthouse）
2. 按照设置中的指引安装 CLI hooks
3. 启动任意支持的 AI 工具开始会话

### 已知问题
- 由于是本地签名版本，首次打开需要右键确认
- 部分功能需要授予辅助功能权限

### 更新日志
见 [CHANGELOG.md](../CHANGELOG.md)

---
**注意**：这是社区 Fork 版本，非官方发布。
