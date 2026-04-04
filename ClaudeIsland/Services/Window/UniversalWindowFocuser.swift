//
//  UniversalWindowFocuser.swift
//  ClaudeIsland
//
//  Universal window focusing supporting terminals, VS Code, Cursor, Codex Desktop, etc.
//

import AppKit
import Foundation

/// Supported client types for session focusing
enum ClientType {
    case terminal    // iTerm2, Terminal.app, Ghostty, etc.
    case vscode      // VS Code, Cursor, Windsurf, etc.
    case codexDesktop // Codex Desktop app
    case unknown
}

/// Universal window focuser supporting multiple client types
actor UniversalWindowFocuser {
    static let shared = UniversalWindowFocuser()

    private init() {}

    // MARK: - Public API

    /// Focus the window for a session using multiple strategies
    func focusSession(_ session: SessionState) async -> Bool {
        // Strategy 1: Try yabai-based focusing (most precise)
        if await WindowFinder.shared.isYabaiAvailable() {
            if let pid = session.pid {
                let focused = await YabaiController.shared.focusWindow(forClaudePid: pid)
                if focused { return true }
            }

            // Try by working directory for tmux
            if session.isInTmux {
                let focused = await YabaiController.shared.focusWindow(forWorkingDirectory: session.cwd)
                if focused { return true }
            }
        }

        // Strategy 2: Detect client type and use app-specific focusing
        let clientType = detectClientType(session: session)
        switch clientType {
        case .vscode:
            return await focusVSCode(cwd: session.cwd)
        case .codexDesktop:
            return await focusCodexDesktop(cwd: session.cwd)
        case .terminal:
            return await focusTerminal()
        case .unknown:
            break
        }

        // Strategy 3: Generic - try to find app by window title matching cwd/project name
        return await focusByWindowTitle(hint: session.windowHint, cwd: session.cwd)
    }

    // MARK: - Client Detection

    private func detectClientType(session: SessionState) -> ClientType {
        // Check transcript path for clues
        if let transcriptPath = session.transcriptPath {
            let path = transcriptPath.lowercased()

            // Codex Desktop stores sessions in ~/.codex/sessions/
            if path.contains(".codex/sessions") {
                return .codexDesktop
            }
        }

        // Check model/display title for IDE hints
        let model = session.model?.lowercased() ?? ""
        let title = session.displayTitle.lowercased()

        // VS Code / Cursor detection
        if model.contains("copilot") || title.contains("vscode") || title.contains("cursor") {
            return .vscode
        }

        // Terminal detection (default for most CLI sessions)
        if session.provider == .claude || session.provider == .codex || session.provider == .kimi {
            // Check if running in terminal by tty presence
            if session.tty != nil {
                return .terminal
            }
        }

        return .unknown
    }

    // MARK: - App-Specific Focusing

    /// Focus VS Code / Cursor window
    private func focusVSCode(cwd: String) async -> Bool {
        // Try Cursor first (more specific), then VS Code
        let apps = ["Cursor", "Visual Studio Code", "Code"]

        for appName in apps {
            if await activateApplication(named: appName) {
                // TODO: Could add logic to switch to specific folder/workspace
                return true
            }
        }

        return false
    }

    /// Focus Codex Desktop
    private func focusCodexDesktop(cwd: String) async -> Bool {
        return await activateApplication(named: "Codex")
    }

    /// Focus Terminal (generic)
    private func focusTerminal() async -> Bool {
        // Try common terminals in order of popularity
        let terminals = [
            "iTerm2", "iTerm",
            "Ghostty",
            "Warp",
            "WezTerm",
            "Alacritty",
            "Terminal"
        ]

        for terminal in terminals {
            if await activateApplication(named: terminal) {
                return true
            }
        }

        return false
    }

    /// Generic window focus - activate frontmost non-system app
    private func focusByWindowTitle(hint: String, cwd: String) async -> Bool {
        // Get running apps, frontmost first
        let runningApps = NSWorkspace.shared.runningApplications

        // Priority 1: Try to find app whose title matches cwd or hint
        for app in runningApps where app.activationPolicy == .regular {
            guard let appName = app.localizedName else { continue }

            // Skip system apps
            if ["Dock", "Finder", "SystemUIServer", "WindowServer", "Claude Island"].contains(appName) {
                continue
            }

            // Try to match by project name in window title
            let projectName = URL(fileURLWithPath: cwd).lastPathComponent
            if appName.lowercased().contains(projectName.lowercased()) ||
               hint.lowercased().contains(appName.lowercased()) {
                app.activate(options: [.activateIgnoringOtherApps])
                return true
            }
        }

        // Priority 2: Just activate any terminal-like app that's running
        let terminalKeywords = ["Terminal", "iTerm", "Ghostty", "Warp", "WezTerm", "Alacritty", "Kitty", "Hyper"]
        for app in runningApps where app.activationPolicy == .regular {
            guard let appName = app.localizedName else { continue }

            if terminalKeywords.contains(where: { appName.contains($0) }) {
                app.activate(options: [.activateIgnoringOtherApps])
                return true
            }
        }

        // Priority 3: Activate frontmost non-system app
        for app in runningApps where app.activationPolicy == .regular {
            guard let appName = app.localizedName else { continue }

            if !["Dock", "Finder", "SystemUIServer", "WindowServer", "Claude Island"].contains(appName) {
                app.activate(options: [.activateIgnoringOtherApps])
                return true
            }
        }

        return false
    }

    // MARK: - Helpers

    /// Activate application by name using NSWorkspace
    private func activateApplication(named appName: String) async -> Bool {
        // Find running application by name
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps where app.activationPolicy == .regular {
            if let name = app.localizedName, name.contains(appName) {
                app.activate(options: [.activateIgnoringOtherApps])
                return true
            }
        }

        // Try to launch if not running (for some known apps)
        let bundleId = bundleIdentifier(for: appName)
        if !bundleId.isEmpty,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.open(url)
            return true
        }

        return false
    }

    /// Map app name to bundle identifier
    private func bundleIdentifier(for appName: String) -> String {
        let mapping: [String: String] = [
            "Terminal": "com.apple.Terminal",
            "iTerm": "com.googlecode.iterm2",
            "iTerm2": "com.googlecode.iterm2",
            "Ghostty": "com.mitchellh.ghostty",
            "Warp": "dev.warp.Warp-Stable",
            "Code": "com.microsoft.VSCode",
            "Visual Studio Code": "com.microsoft.VSCode",
            "Cursor": "com.todesktop.230313mzl4w4u92",
            "Codex": "com.openai.Codex"
        ]
        return mapping[appName] ?? ""
    }
}
