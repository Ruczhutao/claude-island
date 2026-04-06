//
//  FullscreenDetector.swift
//  ClaudeIsland
//
//  Simple fullscreen detection based on window size
//

import AppKit
import Combine

/// Detects fullscreen state changes
class FullscreenDetector: ObservableObject {
    static let shared = FullscreenDetector()
    
    @Published private(set) var isAnyAppInFullscreen: Bool = false
    
    private var timer: Timer?
    
    private init() {
        // Only enable if user explicitly turns it on
        let enabled = UserDefaults.standard.bool(forKey: "hideInFullscreen")
        if enabled {
            setupTimer()
        }
        
        // Watch for settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    private func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkFullscreenState()
        }
        timer?.tolerance = 1.0
        checkFullscreenState()
    }
    
    @objc private func settingsChanged() {
        let enabled = UserDefaults.standard.bool(forKey: "hideInFullscreen")
        if enabled && timer == nil {
            setupTimer()
        } else if !enabled && timer != nil {
            timer?.invalidate()
            timer = nil
            isAnyAppInFullscreen = false
        }
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func checkFullscreenState() {
        let isFullscreen = detectFullscreen()
        if isAnyAppInFullscreen != isFullscreen {
            isAnyAppInFullscreen = isFullscreen
        }
    }
    
    private func detectFullscreen() -> Bool {
        // Get screen with cursor (most likely where user is working)
        guard let targetScreen = screenWithCursor() else { return false }
        let screenFrame = targetScreen.frame
        
        // Get all windows
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        
        // Check each window
        for window in windowList {
            // Must be a normal window (layer 0)
            guard let layer = window[kCGWindowLayer as String] as? Int,
                  layer == 0 else {
                continue
            }
            
            // Must have owner
            guard let ownerName = window[kCGWindowOwnerName as String] as? String,
                  !ownerName.isEmpty,
                  ownerName != "Window Server",
                  ownerName != "Dock",
                  ownerName != "Agent Island",
                  ownerName != "Claude Island" else {
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
            
            // Check if window covers most of the screen
            let windowArea = w * h
            let screenArea = screenFrame.width * screenFrame.height
            let coverage = windowArea / screenArea
            
            // If window covers 95%+ of screen, consider it fullscreen
            if coverage > 0.95 {
                // Make sure it's on the target screen
                let windowCenterX = x + w/2
                let windowCenterY = y + h/2
                
                if windowCenterX >= screenFrame.minX && windowCenterX <= screenFrame.maxX &&
                   windowCenterY >= screenFrame.minY && windowCenterY <= screenFrame.maxY {
                    return true
                }
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
