#!/usr/bin/env swift
//
//  Test script for Cursor window focusing
//  Run: swift scripts/test-cursor-focus.swift
//

import AppKit
import Foundation

print("=== Agent Island - Cursor Focus Test ===\n")

// Test 1: Check if Cursor is installed
let cursorBundleId = "com.todesktop.230313mzl4w4u92"
if let cursorUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: cursorBundleId) {
    print("✅ Cursor is installed at: \(cursorUrl.path)")
} else {
    print("❌ Cursor is not installed")
    print("   Please install Cursor from: https://cursor.com")
    exit(1)
}

// Test 2: Check if Cursor is running
let runningApps = NSWorkspace.shared.runningApplications
if let cursorApp = runningApps.first(where: { $0.bundleIdentifier == cursorBundleId }) {
    print("✅ Cursor is running")
    print("   PID: \(cursorApp.processIdentifier)")
    print("   Active: \(cursorApp.isActive)")
    print("   Hidden: \(cursorApp.isHidden)")
} else {
    print("⚠️  Cursor is not running")
    print("   Please start Cursor to test window focusing")
}

// Test 3: Check yabai availability
let yabaiPaths = ["/opt/homebrew/bin/yabai", "/usr/local/bin/yabai"]
var yabaiAvailable = false
for path in yabaiPaths {
    if FileManager.default.isExecutableFile(atPath: path) {
        print("✅ yabai is available at: \(path)")
        yabaiAvailable = true
        break
    }
}
if !yabaiAvailable {
    print("⚠️  yabai is not installed")
    print("   Install for better window focusing: brew install koekeishiya/formulae/yabai")
}

// Test 4: Try to activate Cursor
print("\n🧪 Testing window activation...")
print("   Attempting to activate Cursor...")

if let cursorApp = runningApps.first(where: { $0.bundleIdentifier == cursorBundleId }) {
    cursorApp.activate(options: [.activateIgnoringOtherApps])
    print("✅ Activation request sent")
    print("\n💡 If Cursor is running, it should now be in focus")
} else {
    // Try to launch Cursor
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: cursorBundleId) {
        print("   Launching Cursor...")
        NSWorkspace.shared.open(url)
        print("✅ Launch request sent")
    }
}

print("\n=== Test Complete ===")
print("\nTo fully test Cursor focusing from Agent Island:")
print("1. Build and run Agent Island")
print("2. Open Cursor with a project")
print("3. Click on a Cursor session in the Notch panel")
print("4. Cursor should come to focus with the correct window")
