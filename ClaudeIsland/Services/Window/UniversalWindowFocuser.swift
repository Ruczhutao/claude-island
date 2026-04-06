//
//  UniversalWindowFocuser.swift
//  ClaudeIsland
//
//  Universal window focusing supporting terminals, VS Code, Cursor, Codex Desktop, etc.
//

import AppKit
import Foundation
import os.log

/// Supported client types for session focusing
enum ClientType {
    case terminal    // iTerm2, Terminal.app, Ghostty, etc.
    case vscode      // VS Code, Cursor, Windsurf, etc.
    case codexDesktop // Codex Desktop app
    case cursor      // Cursor IDE
    case unknown
}

/// Universal window focuser supporting multiple client types
actor UniversalWindowFocuser {
    static let shared = UniversalWindowFocuser()
    
    /// Logger for window focusing
    private let logger = Logger(subsystem: "com.claudeisland", category: "WindowFocus")

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
        case .cursor:
            return await focusCursorEnhanced(cwd: session.cwd)
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

        // VS Code / Cursor detection by title/model
        if model.contains("copilot") || title.contains("vscode") {
            return .vscode
        }
        
        // Cursor IDE detection by title or provider
        if title.contains("cursor") || session.provider == .cursor {
            return .cursor
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

    /// Focus VS Code window
    private func focusVSCode(cwd: String) async -> Bool {
        let apps = ["Visual Studio Code", "Code"]

        for appName in apps {
            if await activateApplication(named: appName) {
                // TODO: Could add logic to switch to specific folder/workspace
                return true
            }
        }

        return false
    }
    
    /// Focus Cursor window
    private func focusCursor(cwd: String) async -> Bool {
        logger.info("Focusing Cursor window for cwd: \(cwd, privacy: .public)")
        
        // Strategy 1: Try to find and activate a running Cursor window matching the cwd
        if let cursorWindow = await findCursorWindow(forCwd: cwd) {
            logger.info("Found matching Cursor window, activating...")
            cursorWindow.activate(options: [.activateIgnoringOtherApps])
            return true
        }
        
        // Strategy 2: Try to activate Cursor by bundle ID first (more reliable)
        let cursorBundleId = "com.todesktop.230313mzl4w4u92"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: cursorBundleId) {
            logger.info("Opening Cursor via bundle ID...")
            NSWorkspace.shared.open(url)
            return true
        }
        
        // Strategy 3: Fallback to app name
        logger.info("Trying to activate Cursor by name...")
        if await activateApplication(named: "Cursor") {
            return true
        }

        logger.warning("Failed to focus Cursor window")
        return false
    }
    
    /// Find a Cursor window matching the given working directory
    private func findCursorWindow(forCwd cwd: String) async -> NSRunningApplication? {
        let projectName = URL(fileURLWithPath: cwd).lastPathComponent.lowercased()
        let runningApps = NSWorkspace.shared.runningApplications
        
        // Find Cursor app
        guard let cursorApp = runningApps.first(where: { app in
            guard let bundleId = app.bundleIdentifier else { return false }
            return bundleId == "com.todesktop.230313mzl4w4u92"
        }) else {
            logger.debug("Cursor app not running")
            return nil
        }
        
        // If we have yabai, try to find a window with matching title
        if await WindowFinder.shared.isYabaiAvailable() {
            let windows = await WindowFinder.shared.getAllWindows()
            let pid = Int(cursorApp.processIdentifier)
            let cursorWindows = windows.filter { $0.pid == pid }
            
            // Try to find window with project name in title
            for window in cursorWindows {
                let titleLower = window.title.lowercased()
                if titleLower.contains(projectName) {
                    logger.info("Found Cursor window with matching project: \(window.title, privacy: .public)")
                    // Focus the specific window using yabai
                    if await focusWindowWithYabai(windowId: window.id) {
                        return cursorApp
                    }
                }
            }
            
            // If no match, use the first visible window
            if let firstWindow = cursorWindows.first(where: { $0.isVisible }) {
                logger.info("Using first visible Cursor window: \(firstWindow.title, privacy: .public)")
                _ = await focusWindowWithYabai(windowId: firstWindow.id)
                return cursorApp
            }
        }
        
        return cursorApp
    }
    
    /// Focus a specific window using yabai
    private func focusWindowWithYabai(windowId: Int) async -> Bool {
        guard let yabaiPath = await WindowFinder.shared.getYabaiPath() else { return false }
        
        do {
            _ = try await ProcessExecutor.shared.run(
                yabaiPath,
                arguments: ["-m", "window", "--focus", String(windowId)]
            )
            logger.info("Focused window \(windowId) via yabai")
            return true
        } catch {
            logger.error("Failed to focus window via yabai: \(error.localizedDescription, privacy: .public)")
            return false
        }
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
