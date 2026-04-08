//
//  FullscreenDetector.swift
//  ClaudeIsland
//
//  Enhanced fullscreen detection for browsers and other apps
//

import AppKit
import Combine

/// Detects fullscreen state changes using multiple detection methods
class FullscreenDetector: ObservableObject {
    static let shared = FullscreenDetector()
    
    @Published private(set) var isAnyAppInFullscreen: Bool = false
    
    private var timer: Timer?
    private var workspaceObserver: NSObjectProtocol?
    private var lastCheckResult: Bool = false
    
    private init() {
        // Only enable if user explicitly turns it on
        let enabled = UserDefaults.standard.bool(forKey: "hideInFullscreen")
        if enabled {
            setupDetection()
        }
        
        // Watch for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    private func setupDetection() {
        setupTimer()
        setupWorkspaceNotifications()
        // Initial check
        checkFullscreenState()
    }
    
    private func setupTimer() {
        timer?.invalidate()
        // Check more frequently for better responsiveness
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkFullscreenState()
        }
        timer?.tolerance = 0.2
    }
    
    private func setupWorkspaceNotifications() {
        // Listen for application activation changes
        workspaceObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Check immediately when app changes
            self?.checkFullscreenState()
        }
        
        // Listen for screen configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkFullscreenState),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func settingsChanged() {
        let enabled = UserDefaults.standard.bool(forKey: "hideInFullscreen")
        if enabled && timer == nil {
            setupDetection()
        } else if !enabled && timer != nil {
            timer?.invalidate()
            timer = nil
            if let observer = workspaceObserver {
                NotificationCenter.default.removeObserver(observer)
                workspaceObserver = nil
            }
            isAnyAppInFullscreen = false
        }
    }
    
    deinit {
        timer?.invalidate()
        if let observer = workspaceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @objc private func checkFullscreenState() {
        let isFullscreen = detectFullscreenOnAnyScreen()
        if lastCheckResult != isFullscreen {
            lastCheckResult = isFullscreen
            isAnyAppInFullscreen = isFullscreen
        }
    }
    
    /// Check all screens for fullscreen windows
    private func detectFullscreenOnAnyScreen() -> Bool {
        for screen in NSScreen.screens {
            if detectFullscreen(on: screen) {
                return true
            }
        }
        return false
    }
    
    /// Detect fullscreen on a specific screen
    private func detectFullscreen(on targetScreen: NSScreen) -> Bool {
        let screenFrame = targetScreen.frame
        
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        
        // Get frontmost app name for prioritization
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let frontmostAppName = frontmostApp?.localizedName ?? ""
        _ = frontmostApp?.bundleIdentifier ?? ""
        
        // Known browsers that use fullscreen
        let browserIdentifiers = ["Safari", "Chrome", "Firefox", "Edge", "Arc", "Brave"]
        let isBrowserFrontmost = browserIdentifiers.contains { frontmostAppName.contains($0) }
        
        for window in windowList {
            // Get owner name
            guard let ownerName = window[kCGWindowOwnerName as String] as? String,
                  !ownerName.isEmpty,
                  ownerName != "Window Server",
                  ownerName != "Dock",
                  ownerName != "Agent Island",
                  ownerName != "Claude Island" else {
                continue
            }
            
            // Check if this is a known browser
            let isBrowserWindow = browserIdentifiers.contains { ownerName.contains($0) }
            
            // Get layer - browsers in fullscreen may use different layers
            let layer = window[kCGWindowLayer as String] as? Int ?? 0
            
            // Skip non-normal layers except for browsers (which may use layer -1 in fullscreen)
            if layer != 0 && layer != -1 && layer != 1 {
                continue
            }
            
            // Get bounds
            guard let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let w = bounds["Width"] as? CGFloat,
                  let h = bounds["Height"] as? CGFloat else {
                continue
            }
            
            // Check if window is on target screen
            let windowCenterX = x + w/2
            let windowCenterY = y + h/2
            
            if windowCenterX < screenFrame.minX || windowCenterX > screenFrame.maxX ||
               windowCenterY < screenFrame.minY || windowCenterY > screenFrame.maxY {
                continue
            }
            
            // Calculate window area relative to screen
            let windowArea = w * h
            let screenArea = screenFrame.width * screenFrame.height
            let coverage = windowArea / screenArea
            
            // Calculate screen-local coordinates
            let screenLocalX = x - screenFrame.minX
            let screenLocalY = y - screenFrame.minY
            
            // Check for exact fullscreen match
            let widthMatch = abs(w - screenFrame.width) < 10
            let heightMatch = abs(h - screenFrame.height) < 10
            let originAtZero = abs(screenLocalX) < 10 && abs(screenLocalY) < 10
            
            // Method 1: Exact screen match (most reliable)
            if originAtZero && widthMatch && heightMatch {
                return true
            }
            
            // Method 2: High coverage for frontmost app
            let isFrontmost = (ownerName == frontmostAppName)
            let threshold: CGFloat = isFrontmost ? 0.85 : 0.95
            
            if coverage > threshold {
                return true
            }
            
            // Method 3: Browser-specific detection
            // Browsers in fullscreen often have slightly different dimensions
            if isBrowserWindow || (isBrowserFrontmost && isFrontmost) {
                // Browser fullscreen: window fills screen but may have slight variations
                let nearFullWidth = w >= screenFrame.width - 20
                let nearFullHeight = h >= screenFrame.height - 50  // Account for browser UI
                let nearOriginZero = abs(screenLocalX) < 20 && abs(screenLocalY) < 50
                
                if nearOriginZero && nearFullWidth && nearFullHeight && coverage > 0.80 {
                    return true
                }
            }
            
            // Method 4: Check for video presentation mode
            // Apps playing fullscreen video often create windows that exactly match screen
            if coverage > 0.98 {
                return true
            }
        }
        
        return false
    }
    
    /// Find the screen containing the cursor
    private func screenWithCursor() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        for screen in NSScreen.screens {
            if screen.frame.contains(mouseLocation) {
                return screen
            }
        }
        return NSScreen.main
    }
}

// MARK: - Settings Integration

extension FullscreenDetector {
    var shouldHideNotch: Bool {
        let hidePreference = UserDefaults.standard.bool(forKey: "hideInFullscreen")
        return hidePreference && isAnyAppInFullscreen
    }
}
