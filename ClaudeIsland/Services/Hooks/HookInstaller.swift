//
//  HookInstaller.swift
//  ClaudeIsland
//
//  Auto-installs supported CLI hooks on app launch.
//

import Foundation

enum CLIProvider: String, CaseIterable, Identifiable {
    // 已支持
    case claude = "Claude Code"
    case codex = "Codex"
    case kimi = "Kimi"
    
    // 即将支持
    case qwen = "Qwen"
    case gemini = "Gemini CLI"
    case cursor = "Cursor Agent"
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
        case .claude, .codex, .kimi:
            return true
        case .qwen, .gemini, .cursor, .copilot:
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
    }

    static func isInstalled() -> Bool {
        isClaudeInstalled() || isCodexInstalled() || isKimiInstalled()
    }

    static func uninstall() {
        uninstallClaudeHooks()
        uninstallCodexHooks()
        uninstallKimiHooks()
    }
    
    // MARK: - Per-Provider API
    
    static func isInstalled(_ provider: CLIProvider) -> Bool {
        guard provider.isSupported else { return false }
        switch provider {
        case .claude: return isClaudeInstalled()
        case .codex: return isCodexInstalled()
        case .kimi: return isKimiInstalled()
        default: return false
        }
    }
    
    static func install(_ provider: CLIProvider) {
        guard provider.isSupported else { return }
        switch provider {
        case .claude: installClaudeHooks()
        case .codex: installCodexHooks()
        case .kimi: installKimiHooks()
        default: break
        }
    }
    
    static func uninstall(_ provider: CLIProvider) {
        guard provider.isSupported else { return }
        switch provider {
        case .claude: uninstallClaudeHooks()
        case .codex: uninstallCodexHooks()
        case .kimi: uninstallKimiHooks()
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
