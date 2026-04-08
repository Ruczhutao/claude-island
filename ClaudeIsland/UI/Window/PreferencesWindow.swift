//
//  PreferencesWindow.swift
//  ClaudeIsland
//
//  Pop-up preferences window with sidebar navigation
//

import AppKit
import Combine
import SwiftUI

/// Manages the preferences window
class PreferencesWindowController: NSObject {
    static let shared = PreferencesWindowController()
    
    private var window: NSWindow?
    
    private override init() {
        super.init()
    }
    
    /// Show the preferences window
    func show() {
        // 如果窗口已存在，关闭并清理
        if let window = window {
            window.close()
            self.window = nil
        }
        
        // Create the preferences view
        let preferencesView = PreferencesView()
            .frame(minWidth: 700, minHeight: 500)
        
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Agent Island 设置"
        window.contentView = NSHostingView(rootView: preferencesView)
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.toolbarStyle = .unifiedCompact
        
        // Set minimum size
        window.minSize = NSSize(width: 700, height: 500)
        
        // Apply dark appearance
        window.appearance = NSAppearance(named: .darkAqua)
        
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Close the preferences window
    func close() {
        window?.close()
    }
}

// MARK: - Preferences View Model

@MainActor
class PreferencesViewModel: ObservableObject {
    static let shared = PreferencesViewModel()
    
    @Published var selectedCategory: PreferenceCategory = .general
    
    private init() {}
}

// MARK: - Preference Categories

enum PreferenceCategory: String, CaseIterable, Identifiable {
    case general = "通用"
    case display = "显示"
    case sound = "声音"
    case about = "关于"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general:
            return "gear"
        case .display:
            return "display"
        case .sound:
            return "speaker.wave.2"
        case .about:
            return "info.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .general:
            return Color(red: 0.35, green: 0.55, blue: 0.95) // Blue
        case .display:
            return Color(red: 0.55, green: 0.35, blue: 0.95) // Purple
        case .sound:
            return Color(red: 0.35, green: 0.85, blue: 0.55) // Green
        case .about:
            return Color(red: 0.95, green: 0.55, blue: 0.35) // Orange
        }
    }
}
