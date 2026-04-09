//
//  HookInstaller.swift
//  ClaudeIsland
//
//  Auto-installs supported CLI hooks on app launch.
//

import AppKit
import Foundation

enum CLIProvider: String, CaseIterable, Identifiable {
    // 已支持
    case claude = "Claude Code"
    case codex = "Codex"
    case kimi = "Kimi"
    case cursor = "Cursor"
    case gemini = "Gemini CLI"
    
    // 即将支持
    case qwen = "Qwen"
    case copilot = "GitHub Copilot"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .claude: return "🦀"
        case .codex: return "☁️"
        case .kimi: return "🔷"
        case .qwen: return "🌟"
        case .gemini: return "♊️"
        case .cursor: return "⚡️"
        case .copilot: return "👨‍✈️"
        }
    }
    
    var isSupported: Bool {
        switch self {
        case .claude, .codex, .kimi, .cursor, .gemini, .qwen:
            return true
        case .copilot:
            return false
        }
    }
    
    var statusText: String {
        isSupported ? "" : "即将支持"
    }
}

struct HookInstaller {
    private static let fileManager = FileManager.default

    static func installIfNeeded() {
        installClaudeHooks()
        installCodexHooks()
        installKimiHooks()
        installCursorHooks()
        installGeminiHooks()
        installQwenHooks()
    }

    static func isInstalled() -> Bool {
        isClaudeInstalled() || isCodexInstalled() || isKimiInstalled() || isCursorInstalled() || isGeminiInstalled() || isQwenInstalled()
    }

    static func uninstall() {
        uninstallClaudeHooks()
        uninstallCodexHooks()
        uninstallKimiHooks()
        uninstallCursorHooks()
        uninstallGeminiHooks()
        uninstallQwenHooks()
    }

    // MARK: - Per-Provider API
    
    static func isInstalled(_ provider: CLIProvider) -> Bool {
        guard provider.isSupported else { return false }
        switch provider {
        case .claude: return isClaudeInstalled()
        case .codex: return isCodexInstalled()
        case .kimi: return isKimiInstalled()
        case .cursor: return isCursorInstalled()
        case .gemini: return isGeminiInstalled()
        case .qwen: return isQwenInstalled()
        default: return false
        }
    }
    
    static func install(_ provider: CLIProvider) {
        guard provider.isSupported else { return }
        switch provider {
        case .claude: installClaudeHooks()
        case .codex: installCodexHooks()
        case .kimi: installKimiHooks()
        case .cursor: installCursorHooks()
        case .gemini: installGeminiHooks()
        case .qwen: installQwenHooks()
        default: break
        }
    }
    
    static func uninstall(_ provider: CLIProvider) {
        guard provider.isSupported else { return }
        switch provider {
        case .claude: uninstallClaudeHooks()
        case .codex: uninstallCodexHooks()
        case .kimi: uninstallKimiHooks()
        case .cursor: uninstallCursorHooks()
        case .gemini: uninstallGeminiHooks()
        case .qwen: uninstallQwenHooks()
        default: break
        }
    }

    // MARK: - Claude

    private static func installClaudeHooks() {
        let claudeDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
        let hooksDir = claudeDir.appendingPathComponent("hooks")
        let scriptURL = hooksDir.appendingPathComponent("claude-island-state.py")
        let settingsURL = claudeDir.appendingPathComponent("settings.json")

        installBundledScript(
            resourceName: "claude-island-state",
            destination: scriptURL
        )

        let python = detectPython()
        let command = "\(python) ~/.claude/hooks/claude-island-state.py"
        let hookEntry: [[String: Any]] = [["type": "command", "command": command]]
        let hookEntryWithTimeout: [[String: Any]] = [["type": "command", "command": command, "timeout": 86400]]
        let withMatcher: [[String: Any]] = [["matcher": "*", "hooks": hookEntry]]
        let withMatcherAndTimeout: [[String: Any]] = [["matcher": "*", "hooks": hookEntryWithTimeout]]
        let withoutMatcher: [[String: Any]] = [["hooks": hookEntry]]
        let preCompactConfig: [[String: Any]] = [
            ["matcher": "auto", "hooks": hookEntry],
            ["matcher": "manual", "hooks": hookEntry]
        ]

        let hookEvents: [(String, [[String: Any]])] = [
            ("UserPromptSubmit", withoutMatcher),
            ("PreToolUse", withMatcher),
            ("PostToolUse", withMatcher),
            ("PermissionRequest", withMatcherAndTimeout),
            ("Notification", withMatcher),
            ("Stop", withoutMatcher),
            ("SubagentStop", withoutMatcher),
            ("SessionStart", withoutMatcher),
            ("SessionEnd", withoutMatcher),
            ("PreCompact", preCompactConfig),
        ]

        updateHooksFile(
            at: settingsURL,
            commandIdentifier: "claude-island-state.py",
            hookEvents: hookEvents
        )
    }

    private static func isClaudeInstalled() -> Bool {
        let settingsURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/settings.json")
        return hooksFile(at: settingsURL).contains { command in
            command.contains("claude-island-state.py")
        }
    }

    private static func uninstallClaudeHooks() {
        let claudeDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
        let scriptURL = claudeDir.appendingPathComponent("hooks/claude-island-state.py")
        let settingsURL = claudeDir.appendingPathComponent("settings.json")

        try? fileManager.removeItem(at: scriptURL)
        removeHookCommand(
            at: settingsURL,
            commandIdentifier: "claude-island-state.py"
        )
    }

    // MARK: - Codex

    private static func installCodexHooks() {
        let codexDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
        let hooksDir = codexDir.appendingPathComponent("hooks")
        let scriptURL = hooksDir.appendingPathComponent("codex-island-state.py")
        let hooksURL = codexDir.appendingPathComponent("hooks.json")

        installBundledScript(
            resourceName: "codex-island-state",
            destination: scriptURL
        )

        let python = detectPython()
        let command = "\(python) ~/.codex/hooks/codex-island-state.py"
        let shortHookEntry: [[String: Any]] = [["type": "command", "command": command, "timeout": 5]]
        let longHookEntry: [[String: Any]] = [["type": "command", "command": command, "timeout": 86400]]
        let shortConfig: [[String: Any]] = [["hooks": shortHookEntry]]
        let longConfig: [[String: Any]] = [["hooks": longHookEntry]]
        let hookEvents: [(String, [[String: Any]])] = [
            ("SessionStart", shortConfig),
            ("UserPromptSubmit", shortConfig),
            ("PreToolUse", longConfig),
            ("PostToolUse", shortConfig),
            ("Stop", shortConfig),
        ]

        updateHooksFile(
            at: hooksURL,
            commandIdentifier: "codex-island-state.py",
            hookEvents: hookEvents
        )
    }

    private static func isCodexInstalled() -> Bool {
        let hooksURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/hooks.json")
        return hooksFile(at: hooksURL).contains { command in
            command.contains("codex-island-state.py")
        }
    }

    private static func uninstallCodexHooks() {
        let codexDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".codex")
        let scriptURL = codexDir.appendingPathComponent("hooks/codex-island-state.py")
        let hooksURL = codexDir.appendingPathComponent("hooks.json")

        try? fileManager.removeItem(at: scriptURL)
        removeHookCommand(
            at: hooksURL,
            commandIdentifier: "codex-island-state.py"
        )
    }

    // MARK: - Kimi

    private static func installKimiHooks() {
        let kimiDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".kimi")
        let hooksDir = kimiDir.appendingPathComponent("hooks")
        let scriptURL = hooksDir.appendingPathComponent("kimi-island-state.py")
        let configURL = kimiDir.appendingPathComponent("config.toml")

        installBundledScript(
            resourceName: "kimi-island-state",
            destination: scriptURL
        )

        let python = detectPython()
        let command = "\(python) ~/.kimi/hooks/kimi-island-state.py"

        // Kimi uses TOML format with [[hooks]] array
        let hookConfigs = [
            "[[hooks]]",
            "event = \"SessionStart\"",
            "command = \"\(command)\"",
            "timeout = 5",
            "",
            "[[hooks]]",
            "event = \"UserPromptSubmit\"",
            "command = \"\(command)\"",
            "timeout = 5",
            "",
            "[[hooks]]",
            "event = \"PreToolUse\"",
            "command = \"\(command)\"",
            "timeout = 300",
            "",
            "[[hooks]]",
            "event = \"PostToolUse\"",
            "command = \"\(command)\"",
            "timeout = 5",
            "",
            "[[hooks]]",
            "event = \"Stop\"",
            "command = \"\(command)\"",
            "timeout = 5",
            "",
            "[[hooks]]",
            "event = \"SubagentStop\"",
            "command = \"\(command)\"",
            "timeout = 5",
            "",
            "[[hooks]]",
            "event = \"PreCompact\"",
            "command = \"\(command)\"",
            "timeout = 5",
            "",
            "[[hooks]]",
            "event = \"SessionEnd\"",
            "command = \"\(command)\"",
            "timeout = 5",
        ]

        updateTOMLHooks(
            at: configURL,
            commandIdentifier: "kimi-island-state.py",
            hookConfigs: hookConfigs
        )
    }

    private static func isKimiInstalled() -> Bool {
        let configURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".kimi/config.toml")
        guard let content = try? String(contentsOf: configURL) else {
            return false
        }
        return content.contains("kimi-island-state.py")
    }

    private static func uninstallKimiHooks() {
        let kimiDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".kimi")
        let scriptURL = kimiDir.appendingPathComponent("hooks/kimi-island-state.py")
        let configURL = kimiDir.appendingPathComponent("config.toml")

        try? fileManager.removeItem(at: scriptURL)
        removeTOMLHooks(
            at: configURL,
            commandIdentifier: "kimi-island-state.py"
        )
    }

    // MARK: - Cursor
    
    // Cursor 3.0+ supports full hooks mechanism similar to Claude/Codex
    // Hooks are configured in ~/.cursor/hooks.json
    
    private static let cursorEnabledKey = "com.claudeisland.cursor-enabled"
    
    private static func installCursorHooks() {
        let cursorDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".cursor")
        let hooksDir = cursorDir.appendingPathComponent("hooks")
        let scriptURL = hooksDir.appendingPathComponent("cursor-island-state.py")
        let hooksURL = cursorDir.appendingPathComponent("hooks.json")

        installBundledScript(
            resourceName: "cursor-island-state",
            destination: scriptURL
        )

        let python = detectPython()
        let command = "\(python) ~/.cursor/hooks/cursor-island-state.py"
        
        // Cursor uses a simpler hooks format than Claude/Codex
        // Format: {"hooks": {"eventName": [{"command": "..."}]}}
        // Note: No nested "hooks" array, no "type" field, no "timeout" field
        let hookEvents: [(String, [[String: Any]])] = [
            ("beforeSubmitPrompt", [["command": command]]),
            ("afterAgentResponse", [["command": command]]),
            ("beforeShellExecution", [["command": command]]),
            ("afterShellExecution", [["command": command]]),
            ("stop", [["command": command]]),
        ]

        updateCursorHooksFile(
            at: hooksURL,
            commandIdentifier: "cursor-island-state.py",
            hookEvents: hookEvents
        )
        
        // Mark as enabled in UserDefaults for app-level tracking
        UserDefaults.standard.set(true, forKey: cursorEnabledKey)
    }
    
    private static func isCursorInstalled() -> Bool {
        // Check if Cursor app is installed
        let cursorBundleId = "com.todesktop.230313mzl4w4u92"
        let cursorInstalled = NSWorkspace.shared.urlForApplication(withBundleIdentifier: cursorBundleId) != nil
        
        // Check if our hook script is installed (using Cursor's simple format)
        let hooksURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".cursor/hooks.json")
        let hooksInstalled = cursorHooksFile(at: hooksURL).contains { command in
            command.contains("cursor-island-state.py")
        }
        
        return cursorInstalled && hooksInstalled
    }
    
    private static func uninstallCursorHooks() {
        UserDefaults.standard.set(false, forKey: cursorEnabledKey)
        
        let cursorDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".cursor")
        let scriptURL = cursorDir.appendingPathComponent("hooks/cursor-island-state.py")
        let hooksURL = cursorDir.appendingPathComponent("hooks.json")

        try? fileManager.removeItem(at: scriptURL)
        removeHookCommand(
            at: hooksURL,
            commandIdentifier: "cursor-island-state.py"
        )
    }

    // MARK: - Gemini

    // Gemini CLI stores hooks in settings.json (not a separate hooks.json)
    // Event names use Gemini native names: BeforeTool, AfterTool, BeforeAgent, AfterAgent, SessionStart, SessionEnd

    private static func installGeminiHooks() {
        let geminiDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".gemini")
        let hooksDir = geminiDir.appendingPathComponent("hooks")
        let scriptURL = hooksDir.appendingPathComponent("gemini-island-state.py")
        let settingsURL = geminiDir.appendingPathComponent("settings.json")

        installBundledScript(
            resourceName: "gemini-island-state",
            destination: scriptURL
        )

        let python = detectPython()
        let command = "\(python) ~/.gemini/hooks/gemini-island-state.py"
        // Gemini format: direct array of command objects (no nested "hooks" key)
        // Use 1000ms (1s) instead of 5ms because python startup takes >50ms
        let shortHookEntry: [String: Any] = ["name": "island-state-update", "type": "command", "command": command, "timeout": 1000]
        let longHookEntry: [String: Any] = ["name": "island-tool-approval", "type": "command", "command": command, "timeout": 86400]
        let hookEvents: [(String, [[String: Any]])] = [
            ("SessionStart", [shortHookEntry]),
            ("BeforeAgent", [shortHookEntry]),
            ("BeforeTool", [longHookEntry]),
            ("AfterTool", [shortHookEntry]),
            ("AfterAgent", [shortHookEntry]),
            ("SessionEnd", [shortHookEntry]),
        ]

        updateGeminiSettingsFile(
            at: settingsURL,
            commandIdentifier: "gemini-island-state.py",
            hookEvents: hookEvents
        )
        
        // Enable hooks in Gemini CLI
        enableGeminiHooks(at: settingsURL)
        
        // Add to trusted hooks
        addGeminiTrustedHook(geminiDir: geminiDir, fullCommand: command)

        // Clean up old hooks.json if it exists from previous installation
        let oldHooksURL = geminiDir.appendingPathComponent("hooks.json")
        if fileManager.fileExists(atPath: oldHooksURL.path) {
            try? fileManager.removeItem(at: oldHooksURL)
        }
    }

    private static func isGeminiInstalled() -> Bool {
        let settingsURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".gemini/settings.json")
        // Gemini uses same format as Cursor: direct command objects
        return geminiHooksFile(at: settingsURL).contains { command in
            command.contains("gemini-island-state.py")
        }
    }

    private static func uninstallGeminiHooks() {
        let geminiDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".gemini")
        let scriptURL = geminiDir.appendingPathComponent("hooks/gemini-island-state.py")
        let settingsURL = geminiDir.appendingPathComponent("settings.json")

        try? fileManager.removeItem(at: scriptURL)
        
        // Use Gemini-specific removal for direct command format
        removeGeminiHookCommand(
            at: settingsURL,
            commandIdentifier: "gemini-island-state.py"
        )
        
        // Disable hooks in settings
        disableGeminiHooks(at: settingsURL)
        
        let python = detectPython()
        let command = "\(python) ~/.gemini/hooks/gemini-island-state.py"
        // Remove from trusted hooks
        removeGeminiTrustedHook(geminiDir: geminiDir, fullCommand: command)
    }

    // MARK: - Qwen

    // Qwen Code uses identical hook format to Claude Code
    // Config: ~/.qwen/settings.json

    private static func installQwenHooks() {
        let qwenDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".qwen")
        let hooksDir = qwenDir.appendingPathComponent("hooks")
        let scriptURL = hooksDir.appendingPathComponent("qwen-island-state.py")
        let settingsURL = qwenDir.appendingPathComponent("settings.json")

        installBundledScript(
            resourceName: "qwen-island-state",
            destination: scriptURL
        )

        let python = detectPython()
        let command = "\(python) ~/.qwen/hooks/qwen-island-state.py"
        let hookEntry: [[String: Any]] = [["type": "command", "command": command]]
        let hookEntryWithTimeout: [[String: Any]] = [["type": "command", "command": command, "timeout": 86400]]
        let withMatcher: [[String: Any]] = [["matcher": "*", "hooks": hookEntry]]
        let withMatcherAndTimeout: [[String: Any]] = [["matcher": "*", "hooks": hookEntryWithTimeout]]
        let withoutMatcher: [[String: Any]] = [["hooks": hookEntry]]
        let preCompactConfig: [[String: Any]] = [
            ["matcher": "auto", "hooks": hookEntry],
            ["matcher": "manual", "hooks": hookEntry]
        ]

        let hookEvents: [(String, [[String: Any]])] = [
            ("UserPromptSubmit", withoutMatcher),
            ("PreToolUse", withMatcher),
            ("PostToolUse", withMatcher),
            ("PermissionRequest", withMatcherAndTimeout),
            ("Notification", withMatcher),
            ("Stop", withoutMatcher),
            ("SubagentStop", withoutMatcher),
            ("SessionStart", withoutMatcher),
            ("SessionEnd", withoutMatcher),
            ("PreCompact", preCompactConfig),
        ]

        updateHooksFile(
            at: settingsURL,
            commandIdentifier: "qwen-island-state.py",
            hookEvents: hookEvents
        )
    }

    private static func isQwenInstalled() -> Bool {
        let settingsURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".qwen/settings.json")
        return hooksFile(at: settingsURL).contains { command in
            command.contains("qwen-island-state.py")
        }
    }

    private static func uninstallQwenHooks() {
        let qwenDir = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".qwen")
        let scriptURL = qwenDir.appendingPathComponent("hooks/qwen-island-state.py")
        let settingsURL = qwenDir.appendingPathComponent("settings.json")

        try? fileManager.removeItem(at: scriptURL)
        removeHookCommand(
            at: settingsURL,
            commandIdentifier: "qwen-island-state.py"
        )
    }

    // MARK: - Shared Helpers

    private static func installBundledScript(resourceName: String, destination: URL) {
        try? fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        guard let bundled = Bundle.main.url(forResource: resourceName, withExtension: "py") else {
            return
        }

        try? fileManager.removeItem(at: destination)
        try? fileManager.copyItem(at: bundled, to: destination)
        try? fileManager.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: destination.path
        )
    }

    private static func updateHooksFile(at fileURL: URL, commandIdentifier: String, hookEvents: [(String, [[String: Any]])]) {
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        var hooks = json["hooks"] as? [String: Any] ?? [:]

        for (event, config) in hookEvents {
            if var existingEvent = hooks[event] as? [[String: Any]] {
                let hasOurHook = existingEvent.contains { entry in
                    entryContainsCommand(entry, commandIdentifier: commandIdentifier)
                }
                if !hasOurHook {
                    existingEvent.append(contentsOf: config)
                    hooks[event] = existingEvent
                }
            } else {
                hooks[event] = config
            }
        }

        json["hooks"] = hooks
        writeJSON(json, to: fileURL)
    }

    private static func removeHookCommand(at fileURL: URL, commandIdentifier: String) {
        guard let data = try? Data(contentsOf: fileURL),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooks = json["hooks"] as? [String: Any] else {
            return
        }

        for (event, value) in hooks {
            guard var entries = value as? [[String: Any]] else { continue }

            entries.removeAll { entry in
                entryContainsCommand(entry, commandIdentifier: commandIdentifier)
            }

            if entries.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = entries
            }
        }

        if hooks.isEmpty {
            json.removeValue(forKey: "hooks")
        } else {
            json["hooks"] = hooks
        }

        writeJSON(json, to: fileURL)
    }

    // MARK: - Cursor Helpers
    
    /// Cursor uses a simpler hooks format than Claude/Codex
    /// Format: {"hooks": {"eventName": [{"command": "..."}]}, "version": 1}
    /// Note: No nested "hooks" array, no "type" field, no "timeout" field
    private static func updateCursorHooksFile(at fileURL: URL, commandIdentifier: String, hookEvents: [(String, [[String: Any]])]) {
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        var hooks = json["hooks"] as? [String: Any] ?? [:]

        for (event, config) in hookEvents {
            // Cursor format: direct array of command objects
            if var existingEvent = hooks[event] as? [[String: Any]] {
                let hasOurHook = existingEvent.contains { entry in
                    if let cmd = entry["command"] as? String {
                        return cmd.contains(commandIdentifier)
                    }
                    return false
                }
                if !hasOurHook {
                    existingEvent.append(contentsOf: config)
                    hooks[event] = existingEvent
                }
            } else {
                hooks[event] = config
            }
        }

        json["hooks"] = hooks
        json["version"] = 1  // Cursor expects version field
        writeJSON(json, to: fileURL)
    }

    // MARK: - Gemini Helpers

    /// Gemini uses settings.json format: {"hooks": {"event": [{"type": "command", "command": "...", "timeout": 5}]}}
    /// Note: No nested "hooks" array, direct command object in the array
    private static func updateGeminiSettingsFile(at fileURL: URL, commandIdentifier: String, hookEvents: [(String, [[String: Any]])]) {
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        var hooks = json["hooks"] as? [String: Any] ?? [:]

        for (event, config) in hookEvents {
            // Gemini format: direct array of command objects
            if var existingEvent = hooks[event] as? [[String: Any]] {
                let hasOurHook = existingEvent.contains { entry in
                    if let cmd = entry["command"] as? String {
                        return cmd.contains(commandIdentifier)
                    }
                    return false
                }
                if !hasOurHook {
                    // Append all command entries from config
                    existingEvent.append(contentsOf: config)
                    hooks[event] = existingEvent
                }
            } else {
                // Use config directly as the event's hook array
                hooks[event] = config
            }
        }

        json["hooks"] = hooks
        writeJSON(json, to: fileURL)
    }

    private static func hooksFile(at fileURL: URL) -> [String] {
        guard let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return []
        }

        var commands: [String] = []
        for (_, value) in hooks {
            guard let entries = value as? [[String: Any]] else { continue }
            for entry in entries {
                if let entryHooks = entry["hooks"] as? [[String: Any]] {
                    for hook in entryHooks {
                        if let command = hook["command"] as? String {
                            commands.append(command)
                        }
                    }
                }
            }
        }
        return commands
    }
    
    /// Cursor uses a simpler format: {"hooks": {"event": [{"command": "..."}]}}
    private static func cursorHooksFile(at fileURL: URL) -> [String] {
        guard let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return []
        }

        var commands: [String] = []
        for (_, value) in hooks {
            guard let entries = value as? [[String: Any]] else { continue }
            for entry in entries {
                // Cursor format: direct "command" field, no nested "hooks" array
                if let command = entry["command"] as? String {
                    commands.append(command)
                }
            }
        }
        return commands
    }

    /// Gemini uses settings.json format: {"hooks": {"event": [{"type": "command", "command": "..."}]}}
    /// Same as Cursor format: direct command objects in array
    private static func geminiHooksFile(at fileURL: URL) -> [String] {
        guard let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = json["hooks"] as? [String: Any] else {
            return []
        }

        var commands: [String] = []
        for (_, value) in hooks {
            guard let entries = value as? [[String: Any]] else { continue }
            for entry in entries {
                // Gemini format: direct "command" field, no nested "hooks" array
                if let command = entry["command"] as? String {
                    commands.append(command)
                }
            }
        }
        return commands
    }

    /// Enable hooks in Gemini CLI settings
    /// Adds "hooksConfig": {"enabled": true} to settings.json
    private static func enableGeminiHooks(at fileURL: URL) {
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        var hooksConfig = json["hooksConfig"] as? [String: Any] ?? [:]
        hooksConfig["enabled"] = true
        json["hooksConfig"] = hooksConfig

        writeJSON(json, to: fileURL)
    }

    /// Disable hooks in Gemini CLI settings
    private static func disableGeminiHooks(at fileURL: URL) {
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: fileURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        var hooksConfig = json["hooksConfig"] as? [String: Any] ?? [:]
        hooksConfig["enabled"] = false
        json["hooksConfig"] = hooksConfig

        writeJSON(json, to: fileURL)
    }

    /// Add hook to Gemini's trusted hooks list
    /// This allows the hook to run without user confirmation
    private static func addGeminiTrustedHook(geminiDir: URL, fullCommand: String) {
        let trustedHooksURL = geminiDir.appendingPathComponent("trusted_hooks.json")
        
        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: trustedHooksURL),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = existing
        }

        // Check if already trusted
        var currentTrusted = json["trusted"] as? [String] ?? []
        if !currentTrusted.contains(fullCommand) {
            currentTrusted.append(fullCommand)
            json["trusted"] = currentTrusted
            
            // Also add to project-specific trusted list (empty string for global)
            var projectTrusted = json["projectTrusted"] as? [String: [String]] ?? [:]
            var globalTrusted = projectTrusted[""] ?? []
            if !globalTrusted.contains(fullCommand) {
                globalTrusted.append(fullCommand)
                projectTrusted[""] = globalTrusted
                json["projectTrusted"] = projectTrusted
            }
        }

        guard let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return
        }
        try? data.write(to: trustedHooksURL)
    }

    /// Remove hook command from Gemini settings (direct command format)
    private static func removeGeminiHookCommand(at fileURL: URL, commandIdentifier: String) {
        guard let data = try? Data(contentsOf: fileURL),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var hooks = json["hooks"] as? [String: Any] else {
            return
        }

        for (event, value) in hooks {
            guard var entries = value as? [[String: Any]] else { continue }

            // Gemini format: direct "command" field
            entries.removeAll { entry in
                if let command = entry["command"] as? String {
                    return command.contains(commandIdentifier)
                }
                return false
            }

            if entries.isEmpty {
                hooks.removeValue(forKey: event)
            } else {
                hooks[event] = entries
            }
        }

        if hooks.isEmpty {
            json.removeValue(forKey: "hooks")
        } else {
            json["hooks"] = hooks
        }

        writeJSON(json, to: fileURL)
    }

    /// Remove hook from Gemini's trusted hooks list
    private static func removeGeminiTrustedHook(geminiDir: URL, fullCommand: String) {
        let trustedHooksURL = geminiDir.appendingPathComponent("trusted_hooks.json")
        
        guard let data = try? Data(contentsOf: trustedHooksURL),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        // Remove from global trusted list
        if var currentTrusted = json["trusted"] as? [String] {
            currentTrusted.removeAll { $0 == fullCommand }
            if currentTrusted.isEmpty {
                json.removeValue(forKey: "trusted")
            } else {
                json["trusted"] = currentTrusted
            }
        }
        
        // Remove from project-specific trusted list
        if var projectTrusted = json["projectTrusted"] as? [String: [String]] {
            for (project, var hooks) in projectTrusted {
                hooks.removeAll { $0 == fullCommand }
                if hooks.isEmpty {
                    projectTrusted.removeValue(forKey: project)
                } else {
                    projectTrusted[project] = hooks
                }
            }
            
            if projectTrusted.isEmpty {
                json.removeValue(forKey: "projectTrusted")
            } else {
                json["projectTrusted"] = projectTrusted
            }
        }

        // Write updated file or remove if empty
        if json.isEmpty {
            try? fileManager.removeItem(at: trustedHooksURL)
        } else {
            writeJSON(json, to: trustedHooksURL)
        }
    }

    private static func entryContainsCommand(_ entry: [String: Any], commandIdentifier: String) -> Bool {
        guard let entryHooks = entry["hooks"] as? [[String: Any]] else { return false }
        return entryHooks.contains { hook in
            let command = hook["command"] as? String ?? ""
            return command.contains(commandIdentifier)
        }
    }

    private static func writeJSON(_ json: [String: Any], to fileURL: URL) {
        guard let data = try? JSONSerialization.data(
            withJSONObject: json,
            options: [.prettyPrinted, .sortedKeys]
        ) else {
            return
        }
        try? data.write(to: fileURL)
    }

    // MARK: - TOML Helpers (for Kimi)

    private static func updateTOMLHooks(at fileURL: URL, commandIdentifier: String, hookConfigs: [String]) {
        var content = ""
        if let existing = try? String(contentsOf: fileURL) {
            content = existing
        }

        // Check if already installed
        if content.contains(commandIdentifier) {
            return
        }

        // Append hooks section
        if !content.isEmpty && !content.hasSuffix("\n") {
            content += "\n"
        }
        content += "\n# Agent Island hooks\n"
        content += hookConfigs.joined(separator: "\n")
        content += "\n"

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private static func removeTOMLHooks(at fileURL: URL, commandIdentifier: String) {
        guard let content = try? String(contentsOf: fileURL) else {
            return
        }

        var lines = content.components(separatedBy: .newlines)
        var result: [String] = []
        var skipUntilNextHook = false
        var inOurHook = false

        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("[[hooks]]") {
                skipUntilNextHook = false
                inOurHook = false
            }
            if line.contains(commandIdentifier) {
                skipUntilNextHook = true
                inOurHook = true
                // Remove the previous [[hooks]] line if it exists
                if !result.isEmpty && result.last?.trimmingCharacters(in: .whitespaces).hasPrefix("[[hooks]]") == true {
                    result.removeLast()
                }
                continue
            }
            if skipUntilNextHook {
                // Skip empty lines and comments within our hooks section
                if line.trimmingCharacters(in: .whitespaces).isEmpty ||
                   line.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                    continue
                }
                // If we hit another [[hooks]] or non-hook line, stop skipping
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
                    skipUntilNextHook = false
                } else {
                    continue
                }
            }
            result.append(line)
        }

        // Clean up consecutive empty lines
        var cleaned: [String] = []
        var lastWasEmpty = false
        for line in result {
            let isEmpty = line.trimmingCharacters(in: .whitespaces).isEmpty
            if isEmpty && lastWasEmpty {
                continue
            }
            cleaned.append(line)
            lastWasEmpty = isEmpty
        }

        let newContent = cleaned.joined(separator: "\n")
        try? newContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private static func detectPython() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["python3"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                return "python3"
            }
        } catch {}

        return "python"
    }
}
