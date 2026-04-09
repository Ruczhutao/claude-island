//
//  Settings.swift
//  ClaudeIsland
//
//  App settings manager using UserDefaults
//

import Foundation
import SwiftUI

/// Available notification sounds
enum NotificationSound: String, CaseIterable {
    case none = "None"
    case pop = "Pop"
    case ping = "Ping"
    case tink = "Tink"
    case glass = "Glass"
    case blow = "Blow"
    case bottle = "Bottle"
    case frog = "Frog"
    case funk = "Funk"
    case hero = "Hero"
    case morse = "Morse"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case submarine = "Submarine"
    case basso = "Basso"

    /// The system sound name to use with NSSound, or nil for no sound
    var soundName: String? {
        self == .none ? nil : rawValue
    }
}

enum MarqueeEffectMode: String, CaseIterable, Identifiable {
    case scroll = "scroll"
    case flash = "flash"
    case typewriter = "typewriter"
    case sparkle = "sparkle"
    case `static` = "static"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .scroll: return "滚动"
        case .flash: return "快闪"
        case .typewriter: return "打字机"
        case .sparkle: return "逐星"
        case .static: return "静态"
        }
    }
}

enum AppSettings {
    private static let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let notificationSound = "notificationSound"
        static let marqueeEnabled = "marqueeEnabled"
        static let marqueeTheme = "marqueeTheme"
        static let customPhrasesWorking = "customPhrasesWorking"
        static let customPhrasesApproval = "customPhrasesApproval"
        static let customPhrasesDone = "customPhrasesDone"
        static let customPhrasesIdle = "customPhrasesIdle"
        static let marqueeFontSize = "marqueeFontSize"
        static let marqueeFontDesign = "marqueeFontDesign"
        static let marqueeColorActive = "marqueeColorActive"
        static let marqueeColorIdle = "marqueeColorIdle"
        static let marqueeEffectMode = "marqueeEffectMode"
        static let marqueeAnimationSpeed = "marqueeAnimationSpeed"
    }

    // MARK: - Notification Sound

    /// The sound to play when Claude finishes and is ready for input
    static var notificationSound: NotificationSound {
        get {
            guard let rawValue = defaults.string(forKey: Keys.notificationSound),
                  let sound = NotificationSound(rawValue: rawValue) else {
                return .pop // Default to Pop
            }
            return sound
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.notificationSound)
        }
    }

    // MARK: - Marquee

    static var marqueeEnabled: Bool {
        get { defaults.object(forKey: Keys.marqueeEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.marqueeEnabled) }
    }

    static var marqueeTheme: MarqueeTheme {
        get {
            guard let raw = defaults.string(forKey: Keys.marqueeTheme),
                  let theme = MarqueeTheme(rawValue: raw) else { return .default }
            return theme
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.marqueeTheme) }
    }

    static var customPhrasesWorking: String {
        get { defaults.string(forKey: Keys.customPhrasesWorking) ?? "" }
        set { defaults.set(newValue, forKey: Keys.customPhrasesWorking) }
    }

    static var customPhrasesApproval: String {
        get { defaults.string(forKey: Keys.customPhrasesApproval) ?? "" }
        set { defaults.set(newValue, forKey: Keys.customPhrasesApproval) }
    }

    static var customPhrasesDone: String {
        get { defaults.string(forKey: Keys.customPhrasesDone) ?? "" }
        set { defaults.set(newValue, forKey: Keys.customPhrasesDone) }
    }

    static var customPhrasesIdle: String {
        get { defaults.string(forKey: Keys.customPhrasesIdle) ?? "" }
        set { defaults.set(newValue, forKey: Keys.customPhrasesIdle) }
    }

    static var marqueeFontSize: Double {
        get { defaults.double(forKey: Keys.marqueeFontSize).clamped(to: 9...16) }
        set { defaults.set(newValue, forKey: Keys.marqueeFontSize) }
    }

    static var marqueeFontDesign: FontDesign {
        get {
            guard let raw = defaults.string(forKey: Keys.marqueeFontDesign) else { return .default }
            return FontDesign(rawValue: raw) ?? .default
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.marqueeFontDesign) }
    }

    static var marqueeColorActive: String {
        get { defaults.string(forKey: Keys.marqueeColorActive) ?? "auto" }
        set { defaults.set(newValue, forKey: Keys.marqueeColorActive) }
    }

    static var marqueeColorIdle: String {
        get { defaults.string(forKey: Keys.marqueeColorIdle) ?? "dimWhite" }
        set { defaults.set(newValue, forKey: Keys.marqueeColorIdle) }
    }

    static var marqueeEffectMode: MarqueeEffectMode {
        get {
            guard let raw = defaults.string(forKey: Keys.marqueeEffectMode),
                  let mode = MarqueeEffectMode(rawValue: raw) else { return .scroll }
            return mode
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.marqueeEffectMode) }
    }

    static var marqueeAnimationSpeed: Double {
        get { defaults.double(forKey: Keys.marqueeAnimationSpeed).clamped(to: 0.2...2.0) }
        set { defaults.set(newValue, forKey: Keys.marqueeAnimationSpeed) }
    }
}

/// Font design options for marquee text
enum FontDesign: String, CaseIterable, Identifiable {
    case `default` = "default"
    case monospaced = "monospaced"
    case rounded = "rounded"
    case serif = "serif"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "默认"
        case .monospaced: return "等宽"
        case .rounded: return "圆润"
        case .serif: return "衬线"
        }
    }

    var swiftUIDesign: Font.Design {
        switch self {
        case .default: return .default
        case .monospaced: return .monospaced
        case .rounded: return .rounded
        case .serif: return .serif
        }
    }
}

/// Preset colors for marquee text
enum MarqueePresetColor: String, CaseIterable, Identifiable {
    case auto = "auto"
    case orange = "orange"
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case yellow = "yellow"
    case white = "white"
    case dimWhite = "dimWhite"
    case dimGray = "dimGray"
    case dimBlue = "dimBlue"
    case dimGreen = "dimGreen"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .auto: return Color(red: 0.85, green: 0.47, blue: 0.34) // Will be overridden by provider
        case .orange: return Color(red: 0.85, green: 0.47, blue: 0.34)
        case .blue: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .purple: return Color(red: 0.4, green: 0.4, blue: 1.0)
        case .green: return Color(red: 0.3, green: 0.8, blue: 0.5)
        case .yellow: return Color(red: 1.0, green: 0.85, blue: 0.3)
        case .white: return .white
        case .dimWhite: return .white.opacity(0.3)
        case .dimGray: return .gray.opacity(0.4)
        case .dimBlue: return Color(red: 0.3, green: 0.5, blue: 0.8).opacity(0.5)
        case .dimGreen: return Color(red: 0.2, green: 0.6, blue: 0.4).opacity(0.4)
        }
    }

    var displayName: String {
        switch self {
        case .auto: return "自动"
        case .orange: return "橙色"
        case .blue: return "蓝色"
        case .purple: return "紫色"
        case .green: return "绿色"
        case .yellow: return "黄色"
        case .white: return "白色"
        case .dimWhite: return "淡白"
        case .dimGray: return "淡灰"
        case .dimBlue: return "淡蓝"
        case .dimGreen: return "淡绿"
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
