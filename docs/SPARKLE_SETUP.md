# Sparkle 自动更新配置指南

## 背景

当前 Sparkle 更新被禁用，因为这是一个 fork 项目，需要配置自己的更新源。

## 方案 1：GitHub Releases（推荐，免费）

### 步骤

1. **启用 GitHub Pages**
   ```
   仓库设置 → Pages → Source: Deploy from a branch
   选择 branch: gh-pages / (root)
   ```

2. **生成 Appcast XML**
   ```bash
   # 安装 Sparkle 工具
   brew install sparkle
   
   # 生成签名（用于更新包验证）
   ./bin/generate_keys
   
   # 生成 appcast.xml
   ./bin/generate_appcast -s https://ruczhutao.github.io/claude-island/appcast.xml \
     ./releases/*.dmg
   ```

3. **更新 Info.plist**
   ```xml
   <key>SUFeedURL</key>
   <string>https://ruczhutao.github.io/claude-island/appcast.xml</string>
   <key>SUEnableAutomaticChecks</key>
   <true/>
   ```

4. **发布流程**
   ```bash
   # 1. 构建 Release
   ./scripts/build-local.sh
   
   # 2. 上传到 GitHub Releases
   # 3. 更新 appcast.xml
   # 4. 提交到 gh-pages 分支
   ```

## 方案 2：自建服务器

如果有自己的服务器：

```xml
<key>SUFeedURL</key>
<string>https://updates.yourdomain.com/agent-island/appcast.xml</string>
```

## 方案 3：禁用自动更新（现状）

保持现状，用户手动下载新版本：

```xml
<key>SUEnableAutomaticChecks</key>
<false/>
```

设置界面显示"检查更新"按钮，点击跳转到 GitHub Releases 页面。

## 建议

对于个人开源项目：

| 方案 | 成本 | 维护难度 | 推荐度 |
|------|------|----------|--------|
| GitHub Pages | 免费 | 中 | ⭐⭐⭐⭐⭐ |
| 自建服务器 | 有 | 高 | ⭐⭐ |
| 手动更新 | 免费 | 低 | ⭐⭐⭐ |

## 当前实现

`PreferencesView.swift` 里已实现趣味弹窗：

```swift
Button("检查更新") {
    showUpdateAlert = true
}
```

点击后显示：
- "朱涛忙着呢，等会儿的"
- 链接到 B 站视频

如果要启用真正的自动更新，需要：
1. 选择上方方案之一
2. 更新 `Info.plist` 中的 `SUFeedURL`
3. 设置 `SUEnableAutomaticChecks` 为 `true`
4. 每次发布时更新 `appcast.xml`
