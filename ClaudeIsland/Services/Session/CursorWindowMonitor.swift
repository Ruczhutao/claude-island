//
//  CursorWindowMonitor.swift
//  ClaudeIsland
//
//  Provides Cursor IDE window focusing capabilities
//  Note: Cursor 3.0+ now supports hooks for session state detection.
//  This class is kept for window focusing functionality only.
//

import AppKit
import Combine
import Foundation
import os.log

/// Logger for Cursor window operations
private let logger = Logger(subsystem: "com.claudeisland", category: "CursorWindow")

/// Cursor window information
struct CursorWindowInfo: Sendable {
    let windowId: Int
    let title: String
    let projectName: String
    let isVisible: Bool
    let hasFocus: Bool
}

/// Manages Cursor window detection and focusing
actor CursorWindowMonitor {
    static let shared = CursorWindowMonitor()
    
    /// Cursor bundle identifier
    private let cursorBundleId = "com.todesktop.230313mzl4w4u92"
    
    /// Cache of last detected Cursor windows
    private var lastKnownWindows: [CursorWindowInfo] = []
    
    /// Timestamp of last window check
    private var lastCheckTime: Date = .distantPast
    
    /// Cache validity duration
    private let cacheValidity: TimeInterval = 2.0
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check if Cursor app is installed
    func isCursorInstalled() -> Bool {
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: cursorBundleId) != nil
    }
    
    /// Check if Cursor is currently running
    func isCursorRunning() -> Bool {
        return findCursorApp() != nil
    }
    
    /// Get information about all Cursor windows
    func getCursorWindows() async -> [CursorWindowInfo] {
        // Check cache
        let now = Date()
        if now.timeIntervalSince(lastCheckTime) < cacheValidity && !lastKnownWindows.isEmpty {
            return lastKnownWindows
        }
        
        guard let cursorApp = findCursorApp() else {
            lastKnownWindows = []
            return []
        }
        
        let windows = await fetchWindowInfos(cursorApp: cursorApp)
        lastKnownWindows = windows
        lastCheckTime = now
        return windows
    }
    
    /// Find the best window to focus for a given project path
    func findBestWindow(forProjectPath path: String) async -> CursorWindowInfo? {
        let windows = await getCursorWindows()
        let projectName = URL(fileURLWithPath: path).lastPathComponent.lowercased()
        
        // Priority 1: Window with matching project name in title
        if let match = windows.first(where: { $0.title.lowercased().contains(projectName) }) {
            logger.info("Found Cursor window matching project '\(projectName, privacy: .public)': \(match.title, privacy: .public)")
            return match
        }
        
        // Priority 2: First visible window
        if let visible = windows.first(where: { $0.isVisible }) {
            logger.info("Using first visible Cursor window: \(visible.title, privacy: .public)")
            return visible
        }
        
        // Priority 3: Any window
        return windows.first
    }
    
    /// Focus a specific Cursor window
    func focusWindow(_ windowInfo: CursorWindowInfo) async -> Bool {
        guard let cursorApp = findCursorApp() else {
            logger.warning("Cannot focus: Cursor not running")
            return false
        }
        
        // Activate the app first
        cursorApp.activate(options: [.activateIgnoringOtherApps])
        
        // Try to focus specific window via yabai if available
        if await WindowFinder.shared.isYabaiAvailable() {
            if await focusWithYabai(windowId: windowInfo.windowId) {
                return true
            }
        }
        
        // Fallback: just activating the app should bring it to front
        logger.info("Focused Cursor app (yabai not available or failed)")
        return true
    }
    
    // MARK: - Private Methods
    
    private func findCursorApp() -> NSRunningApplication? {
        return NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == cursorBundleId }
    }
    
    private func fetchWindowInfos(cursorApp: NSRunningApplication) async -> [CursorWindowInfo] {
        var infos: [CursorWindowInfo] = []
        
        // Try yabai first
        if await WindowFinder.shared.isYabaiAvailable() {
            let windows = await WindowFinder.shared.getAllWindows()
            let pid = Int(cursorApp.processIdentifier)
            for window in windows where window.pid == pid {
                if let info = parseWindowInfo(window) {
                    infos.append(info)
                }
            }
        }
        
        // If no windows found, create a generic entry
        // Note: Use cursorApp.isActive as a hint, but create entry even if not active
        // as long as the app is running (we already checked findCursorApp() above)
        if infos.isEmpty {
            infos.append(CursorWindowInfo(
                windowId: 0,
                title: "Cursor",
                projectName: "Cursor",
                isVisible: cursorApp.isActive,
                hasFocus: cursorApp.isActive
            ))
        }
        
        return infos
    }
    
    private func parseWindowInfo(_ window: YabaiWindow) -> CursorWindowInfo? {
        // Parse project name from title
        // Common patterns:
        // "filename - ProjectName — Cursor"
        // "ProjectName — Cursor"
        // "Welcome — Cursor"
        
        let title = window.title
        var projectName = "Cursor"
        
        // Try to extract project name
        if title.contains(" — Cursor") {
            let parts = title.components(separatedBy: " — ")
            if parts.count >= 2 {
                let projectPart = parts[parts.count - 2]
                // Handle "filename - ProjectName" format
                if projectPart.contains(" - ") {
                    let subParts = projectPart.components(separatedBy: " - ")
                    projectName = subParts.last?.trimmingCharacters(in: .whitespaces) ?? projectPart
                } else {
                    projectName = projectPart.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        return CursorWindowInfo(
            windowId: window.id,
            title: title,
            projectName: projectName,
            isVisible: window.isVisible,
            hasFocus: window.hasFocus
        )
    }
    
    private func focusWithYabai(windowId: Int) async -> Bool {
        guard windowId > 0,
              let yabaiPath = await WindowFinder.shared.getYabaiPath() else {
            return false
        }
        
        do {
            _ = try await ProcessExecutor.shared.run(
                yabaiPath,
                arguments: ["-m", "window", "--focus", String(windowId)]
            )
            logger.info("Focused Cursor window \(windowId) via yabai")
            return true
        } catch {
            logger.error("Failed to focus window via yabai: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}

// MARK: - UniversalWindowFocuser Integration

extension UniversalWindowFocuser {
    /// Enhanced focus for Cursor with project matching
    func focusCursorEnhanced(cwd: String) async -> Bool {
        logger.info("Focusing Cursor for path: \(cwd, privacy: .public)")
        
        // Use CursorWindowMonitor for intelligent window selection
        if let windowInfo = await CursorWindowMonitor.shared.findBestWindow(forProjectPath: cwd) {
            return await CursorWindowMonitor.shared.focusWindow(windowInfo)
        }
        
        // Fallback: Try bundle ID
        let cursorBundleId = "com.todesktop.230313mzl4w4u92"
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: cursorBundleId) {
            NSWorkspace.shared.open(url)
            return true
        }
        
        // Final fallback: activate by name
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps where app.activationPolicy == .regular {
            if let name = app.localizedName, name.contains("Cursor") {
                app.activate(options: [.activateIgnoringOtherApps])
                return true
            }
        }
        
        return false
    }
}
