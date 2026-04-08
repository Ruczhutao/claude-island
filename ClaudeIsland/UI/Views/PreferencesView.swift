//
//  PreferencesView.swift
//  ClaudeIsland
//
//  Main preferences view with sidebar navigation
//

import Combine
import SwiftUI
import ServiceManagement

// MARK: - Main Preferences View

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel.shared
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            PreferencesSidebar(selectedCategory: $viewModel.selectedCategory)
                .frame(minWidth: 180, idealWidth: 200)
        } detail: {
            // Content
            PreferencesContent(category: viewModel.selectedCategory)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Sidebar

struct PreferencesSidebar: View {
    @Binding var selectedCategory: PreferenceCategory
    
    var body: some View {
        List(PreferenceCategory.allCases, selection: $selectedCategory) { category in
            SidebarItem(
                category: category,
                isSelected: selectedCategory == category
            )
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }
}

struct SidebarItem: View {
    let category: PreferenceCategory
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : category.color)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? category.color : category.color.opacity(0.15))
                )
            
            // Label
            Text(category.rawValue)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .primary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? category.color.opacity(0.9) : Color.clear)
        )
        .contentShape(Rectangle())
        .tag(category)
    }
}

// MARK: - Content

struct PreferencesContent: View {
    let category: PreferenceCategory
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text(category.rawValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                
                // Content based on category
                switch category {
                case .general:
                    GeneralSettingsView()
                case .display:
                    DisplaySettingsView()
                case .sound:
                    SoundSettingsView()
                case .about:
                    AboutSettingsView()
                }
            }
            .padding(24)
            .frame(maxWidth: 600, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideWhenNoActiveSession") private var hideWhenNoActiveSession = false
    @AppStorage("smartSuppress") private var smartSuppress = false
    @AppStorage("autoCollapseOnMouseLeave") private var autoCollapseOnMouseLeave = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // System Section
            SettingsSection(title: "系统") {
                ToggleRow(
                    title: "登录时打开",
                    subtitle: nil,
                    isOn: $launchAtLogin
                )
                .onChange(of: launchAtLogin) { _, newValue in
                    toggleLaunchAtLogin(enabled: newValue)
                }
            }
            
            // CLI Hooks Section
            SettingsSection(title: "CLI Hooks") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(CLIProvider.allCases) { provider in
                        CLIHookRow(provider: provider)
                    }
                }
                
                Text("启动时自动配置 Hooks。可通过开关控制各 CLI 的事件监听。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            // Behavior Section
            SettingsSection(title: "行为") {
                ToggleRow(
                    title: "无活跃会话时自动隐藏",
                    subtitle: "当没有运行中的 Claude/Codex 会话时隐藏刘海栏",
                    isOn: $hideWhenNoActiveSession
                )
                
                ToggleRow(
                    title: "智能抑制",
                    subtitle: "Agent 所在终端标签页在前台时不自动展开面板",
                    isOn: $smartSuppress
                )
                
                ToggleRow(
                    title: "鼠标离开时自动收起",
                    subtitle: "鼠标移出刘海区域后自动关闭面板",
                    isOn: $autoCollapseOnMouseLeave
                )
            }
        }
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
            launchAtLogin = !enabled // Revert on failure
        }
    }
}

// MARK: - CLI Hook Row

struct CLIHookRow: View {
    let provider: CLIProvider
    @State private var isInstalled: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        HStack {
            // Provider icon and name
            HStack(spacing: 8) {
                Text(provider.icon)
                    .font(.system(size: 16))
                    .opacity(provider.isSupported ? 1.0 : 0.5)
                Text(provider.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(provider.isSupported ? .primary : .secondary)
            }
            
            Spacer()
            
            // Status and toggle
            HStack(spacing: 8) {
                // Status indicator
                if provider.isSupported {
                    // 已支持：显示激活状态
                    HStack(spacing: 4) {
                        Image(systemName: isInstalled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundColor(isInstalled ? TerminalColors.green : .secondary)
                        Text(isInstalled ? "已激活" : "未激活")
                            .font(.system(size: 11))
                            .foregroundColor(isInstalled ? TerminalColors.green : .secondary)
                    }
                    
                    // Toggle switch
                    Toggle("", isOn: Binding(
                        get: { isInstalled },
                        set: { newValue in
                            toggleHook(enabled: newValue)
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.35, green: 0.55, blue: 0.95)))
                    .disabled(isLoading)
                } else {
                    // 即将支持
                    Text("即将支持")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            checkStatus()
        }
    }
    
    private func checkStatus() {
        guard provider.isSupported else { return }
        isInstalled = HookInstaller.isInstalled(provider)
    }
    
    private func toggleHook(enabled: Bool) {
        guard provider.isSupported else { return }
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if enabled {
                HookInstaller.install(provider)
            } else {
                HookInstaller.uninstall(provider)
            }
            DispatchQueue.main.async {
                checkStatus()
                isLoading = false
            }
        }
    }
}

// MARK: - Display Settings

struct DisplaySettingsView: View {
    @ObservedObject private var screenSelector = ScreenSelector.shared
    @AppStorage("hideInFullscreen") private var hideInFullscreen = false
    @AppStorage("idleIconStyle") private var idleIconStyle: String = IdleIconStyle.dog.rawValue
    @AppStorage("marqueeEnabled") private var marqueeEnabled: Bool = true
    @AppStorage("marqueeTheme") private var marqueeThemeRaw: String = MarqueeTheme.default.rawValue
    @AppStorage("customPhrasesWorking") private var customWorking: String = ""
    @AppStorage("customPhrasesApproval") private var customApproval: String = ""
    @AppStorage("customPhrasesDone") private var customDone: String = ""
    @AppStorage("customPhrasesIdle") private var customIdle: String = ""
    @AppStorage("marqueeFontSize") private var fontSize: Double = 11
    @AppStorage("marqueeFontDesign") private var fontDesignRaw: String = "default"
    @AppStorage("marqueeColorActive") private var colorActiveRaw: String = "auto"
    @AppStorage("marqueeColorIdle") private var colorIdleRaw: String = "dimWhite"
    @AppStorage("marqueeEffectMode") private var effectModeRaw: String = MarqueeEffectMode.scroll.rawValue
    @AppStorage("marqueeAnimationSpeed") private var animationSpeed: Double = 1.0

    private var selectedTheme: MarqueeTheme {
        MarqueeTheme(rawValue: marqueeThemeRaw) ?? .default
    }

    private var selectedEffect: MarqueeEffectMode {
        MarqueeEffectMode(rawValue: effectModeRaw) ?? .scroll
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Idle Icon Selection
            SettingsSection(title: "待机图标") {
                IdleIconPicker(selectedStyle: $idleIconStyle)
            }

            // Display Selection
            SettingsSection(title: "显示器") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("选择显示器")
                                .font(.system(size: 13, weight: .medium))
                            Text("刘海栏将显示在所选显示器的顶部")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Screen picker button
                        Menu {
                            Button("自动") {
                                screenSelector.selectAutomatic()
                            }
                            Divider()
                            ForEach(screenSelector.availableScreens, id: \.self) { screen in
                                Button(screen.localizedName) {
                                    screenSelector.selectScreen(screen)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(screenSelector.selectedScreen?.localizedName ?? "自动")
                                    .font(.system(size: 13))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.secondary.opacity(0.15))
                            )
                        }
                        .menuStyle(.button)
                        .buttonStyle(.plain)
                    }
                }
            }

            // Appearance Section
            SettingsSection(title: "外观") {
                ToggleRow(
                    title: "全屏时隐藏",
                    subtitle: "应用进入全屏模式时自动隐藏刘海栏",
                    isOn: $hideInFullscreen
                )
            }

            // Marquee Section
            SettingsSection(title: "状态栏短语") {
                ToggleRow(
                    title: "启用状态栏短语",
                    subtitle: "在闭合刘海栏中显示状态提示文字",
                    isOn: $marqueeEnabled
                )

                if marqueeEnabled {
                    // Theme Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("主题风格")
                            .font(.system(size: 12, weight: .medium))

                        HStack(spacing: 8) {
                            ForEach(MarqueeTheme.allCases) { theme in
                                let isSelected = selectedTheme == theme
                                Button {
                                    marqueeThemeRaw = theme.rawValue
                                } label: {
                                    Text(theme.displayName)
                                        .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(isSelected
                                                      ? Color(red: 0.35, green: 0.55, blue: 0.95)
                                                      : Color.secondary.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Custom Editor (only when custom theme selected)
                    if selectedTheme == .custom {
                        customPhraseEditor(
                            title: "工作中",
                            hint: "Agent 正在处理任务时显示",
                            text: $customWorking
                        )
                        customPhraseEditor(
                            title: "等待审批",
                            hint: "Agent 需要用户确认时显示",
                            text: $customApproval
                        )
                        customPhraseEditor(
                            title: "任务完成",
                            hint: "任务完成等待下一步时显示",
                            text: $customDone
                        )
                        customPhraseEditor(
                            title: "空闲",
                            hint: "没有活跃会话时显示",
                            text: $customIdle
                        )
                    }

                    // Effect Mode Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("文字效果")
                            .font(.system(size: 12, weight: .medium))

                        Picker("", selection: $effectModeRaw) {
                            ForEach(MarqueeEffectMode.allCases) { mode in
                                Text(mode.displayName).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Animation Speed
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("动画速度")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text(String(format: "%.1fx", animationSpeed))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                        Slider(value: $animationSpeed, in: 0.2...2.0, step: 0.1)
                    }

                    // Font & Color Settings
                    VStack(alignment: .leading, spacing: 12) {
                        // Font size
                        HStack {
                            Text("字体大小")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(Int(fontSize))pt")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 36, alignment: .trailing)
                        }
                        Slider(value: $fontSize, in: 9...16, step: 1)

                        // Font design
                        HStack {
                            Text("字体风格")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            HStack(spacing: 6) {
                                ForEach(FontDesign.allCases) { design in
                                    let isSelected = fontDesignRaw == design.rawValue
                                    Button {
                                        fontDesignRaw = design.rawValue
                                    } label: {
                                        Text(design.displayName)
                                            .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                                            .foregroundColor(isSelected ? .white : .primary)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(isSelected
                                                          ? Color(red: 0.35, green: 0.55, blue: 0.95)
                                                          : Color.secondary.opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Active color
                        colorPickerRow(
                            title: "活跃时颜色",
                            selection: $colorActiveRaw,
                            options: [.auto, .orange, .blue, .purple, .green, .yellow, .white]
                        )

                        // Idle color
                        colorPickerRow(
                            title: "空闲时颜色",
                            selection: $colorIdleRaw,
                            options: [.dimWhite, .dimGray, .dimBlue, .dimGreen, .white, .blue, .green]
                        )
                    }
                }
            }
        }
    }

    // MARK: - Color Picker Row

    private func colorPickerRow(title: String, selection: Binding<String>, options: [MarqueePresetColor]) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            HStack(spacing: 6) {
                ForEach(options) { option in
                    Button {
                        selection.wrappedValue = option.rawValue
                    } label: {
                        ZStack {
                            Circle()
                                .fill(option.color)
                                .frame(width: 20, height: 20)
                            if selection.wrappedValue == option.rawValue {
                                Circle()
                                    .stroke(Color(red: 0.35, green: 0.55, blue: 0.95), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Custom Phrase Editor

    private func customPhraseEditor(title: String, hint: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(lineCount(text.wrappedValue))/10 条")
                    .font(.system(size: 10))
                    .foregroundColor(lineCount(text.wrappedValue) > 10 ? .red : .secondary)
            }

            TextEditor(text: text)
                .font(.system(size: 12))
                .frame(height: 72)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )

            Text(hint + "，每行一条")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    private func lineCount(_ text: String) -> Int {
        text.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .count
    }
}

// SoundSettingsView is now in its own file SoundSettingsView.swift

// MARK: - About Settings

struct AboutSettingsView: View {
    @ObservedObject private var updateManager = UpdateManager.shared
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // App Info
            SettingsSection(title: "应用") {
                VStack(alignment: .center, spacing: 12) {
                    // App Icon placeholder
                    Image(systemName: "cube.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.85, green: 0.47, blue: 0.34))
                    
                    Text("Agent Island")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(appVersion)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            // Update Section
            SettingsSection(title: "更新") {
                UpdateSettingsRow(updateManager: updateManager)
            }
            
            // Links
            SettingsSection(title: "链接") {
                VStack(alignment: .leading, spacing: 8) {
                    LinkRow(
                        icon: "star.fill",
                        title: "在 GitHub 上标星",
                        subtitle: "支持开源项目",
                        url: "https://github.com/Ruczhutao/claude-island"
                    )
                    
                    LinkRow(
                        icon: "doc.text",
                        title: "使用文档",
                        subtitle: "查看 README",
                        url: "https://github.com/Ruczhutao/claude-island#readme"
                    )
                }
            }
            
            // Quit
            SettingsSection(title: "操作") {
                Button {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                        Text("退出 Agent Island")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct UpdateSettingsRow: View {
    @ObservedObject var updateManager: UpdateManager
    @State private var isHovered = false
    @State private var isSpinning = false
    @State private var showUpdateAlert = false
    
    var body: some View {
        Button {
            handleTap()
        } label: {
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    if case .installing = updateManager.state {
                        Image(systemName: "gear")
                            .font(.system(size: 14))
                            .foregroundColor(TerminalColors.blue)
                            .rotationEffect(.degrees(isSpinning ? 360 : 0))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
                            .onAppear { isSpinning = true }
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(iconColor)
                    }
                }
                .frame(width: 20)
                
                // Label
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(labelColor)
                
                Spacer()
                
                // Right side: progress or status
                rightContent
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered && isInteractive ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
        .onHover { isHovered = $0 }
        .updateCheckAlert(isPresented: $showUpdateAlert)
    }
    
    @ViewBuilder
    private var rightContent: some View {
        switch updateManager.state {
        case .idle:
            Text("点击检查")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                
        case .upToDate:
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(TerminalColors.green)
                Text("已是最新")
                    .font(.system(size: 11))
                    .foregroundColor(TerminalColors.green)
            }
            
        case .checking, .installing:
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 12, height: 12)
                
        case .found(let version, _):
            HStack(spacing: 6) {
                Circle()
                    .fill(TerminalColors.green)
                    .frame(width: 6, height: 6)
                Text("v\(version) 可用")
                    .font(.system(size: 11))
                    .foregroundColor(TerminalColors.green)
            }
            
        case .downloading(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 60)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11))
            }
            
        case .extracting(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress)
                    .frame(width: 60)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11))
            }
            
        case .readyToInstall(let version):
            HStack(spacing: 6) {
                Circle()
                    .fill(TerminalColors.green)
                    .frame(width: 6, height: 6)
                Text("v\(version) 就绪")
                    .font(.system(size: 11))
                    .foregroundColor(TerminalColors.green)
            }
            
        case .error:
            Text("检查失败，点击重试")
                .font(.system(size: 11))
                .foregroundColor(.red)
        }
    }
    
    private var icon: String {
        switch updateManager.state {
        case .idle, .checking:
            return "arrow.down.circle"
        case .upToDate:
            return "checkmark.circle.fill"
        case .found, .readyToInstall:
            return "arrow.down.circle.fill"
        case .downloading, .extracting:
            return "arrow.down.circle"
        case .installing:
            return "gear"
        case .error:
            return "exclamationmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch updateManager.state {
        case .idle:
            return .secondary
        case .checking, .downloading, .extracting, .installing:
            return .secondary
        case .upToDate:
            return TerminalColors.green
        case .found, .readyToInstall:
            return TerminalColors.green
        case .error:
            return .red
        }
    }
    
    private var label: String {
        switch updateManager.state {
        case .idle:
            return "检查更新"
        case .checking:
            return "检查中..."
        case .upToDate:
            return "已是最新版本"
        case .found:
            return "发现新版本"
        case .downloading:
            return "下载中..."
        case .extracting:
            return "解压中..."
        case .readyToInstall:
            return "点击安装并重启"
        case .installing:
            return "安装中..."
        case .error:
            return "检查更新失败"
        }
    }
    
    private var labelColor: Color {
        switch updateManager.state {
        case .idle:
            return .primary
        case .checking, .downloading, .extracting, .installing:
            return .primary
        case .upToDate:
            return TerminalColors.green
        case .found, .readyToInstall:
            return TerminalColors.green
        case .error:
            return .red
        }
    }
    
    private var isInteractive: Bool {
        switch updateManager.state {
        case .idle, .upToDate, .found, .readyToInstall, .error:
            return true
        case .checking, .downloading, .extracting, .installing:
            return false
        }
    }
    
    private func handleTap() {
        switch updateManager.state {
        case .idle, .upToDate, .error:
            showUpdateAlert = true
        case .found:
            updateManager.downloadAndInstall()
        case .readyToInstall:
            updateManager.installAndRelaunch()
        default:
            break
        }
    }
}

// Extension to add alert modifier
extension View {
    func updateCheckAlert(isPresented: Binding<Bool>) -> some View {
        self.alert("朱涛忙着呢，等会儿的", isPresented: isPresented) {
            Button("取消", role: .cancel) {
                // 关闭弹窗
            }
            Button("默默支持，给他点赞") {
                // 跳转到点赞视频
                if let url = URL(string: "https://www.bilibili.com/video/BV124411A7sS/?spm_id_from=333.337.search-card.all.click&vd_source=f7f066dc4b95e192aad482bfc4f861e5") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("去 B 站支持他") {
                // 跳转到 B 站视频
                if let url = URL(string: "https://www.bilibili.com/video/BV1Pe41157zg/?spm_id_from=333.337.search-card.all.click&vd_source=f7f066dc4b95e192aad482bfc4f861e5") {
                    NSWorkspace.shared.open(url)
                }
            }
        } message: {
            Text("开发者正在努力 coding 中...")
        }
    }
}

struct LinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let url: String
    @State private var isHovered = false
    
    var body: some View {
        Button {
            if let url = URL(string: url) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Idle Icon Picker

struct IdleIconPicker: View {
    @Binding var selectedStyle: String
    @State private var previewAnimate = false

    private let columns = [
        GridItem(.adaptive(minimum: 90, maximum: 110), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(IdleIconStyle.allCases) { style in
                    IdleIconCard(
                        style: style,
                        isSelected: selectedStyle == style.rawValue,
                        animate: previewAnimate
                    ) {
                        selectedStyle = style.rawValue
                    }
                }
            }

            Text("选择刘海栏待机图标样式，处理任务时会播放对应动画")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Button {
                previewAnimate.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: previewAnimate ? "pause.fill" : "play.fill")
                        .font(.system(size: 10))
                    Text(previewAnimate ? "停止预览" : "预览动画")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct IdleIconCard: View {
    let style: IdleIconStyle
    let isSelected: Bool
    let animate: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // Icon preview
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)
                        .frame(width: 56, height: 36)

                    style.iconView(size: 28, animate: animate, breathe: false)
                }

                // Label
                Text(style.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected
                          ? Color(red: 0.35, green: 0.55, blue: 0.95)
                          : isHovered ? Color.white.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected
                            ? Color(red: 0.35, green: 0.55, blue: 0.95)
                            : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Reusable Components

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.textBackgroundColor))
            )
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: subtitle != nil ? .top : .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.35, green: 0.55, blue: 0.95)))
                .labelsHidden()
        }
    }
}

