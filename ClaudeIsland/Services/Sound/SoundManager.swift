//
//  SoundManager.swift
//  ClaudeIsland
//
//  Manages sound effects - both system sounds and custom MP3s
//

import AVFoundation
import Foundation
import AppKit
import Combine

/// Available sound sources
enum AvailableSound: String, CaseIterable, Identifiable {
    // System sounds
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
    
    // Custom MP3 sounds
    case eightBit1 = "8bit1"
    case eightBit2 = "8bit2"
    case eightBit3 = "8bit3"
    
    var id: String { rawValue }
    
    var isSystem: Bool {
        switch self {
        case .pop, .ping, .tink, .glass, .blow, .bottle, 
             .frog, .funk, .hero, .morse, .purr, .sosumi, .submarine:
            return true
        case .eightBit1, .eightBit2, .eightBit3:
            return false
        }
    }
}

/// Sound effect types for different events
enum SoundEvent: String, CaseIterable, Identifiable {
    case sessionStart = "会话开始"
    case taskComplete = "任务完成"
    case needApproval = "需要审批"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .sessionStart: return "play.circle"
        case .taskComplete: return "checkmark.circle"
        case .needApproval: return "hand.raised"
        }
    }
    
    var description: String {
        switch self {
        case .sessionStart: return "新的 Claude / Codex 会话"
        case .taskComplete: return "AI 完成了本轮回复"
        case .needApproval: return "需要权限审批或回答问题"
        }
    }
    
    var defaultSound: AvailableSound {
        switch self {
        case .sessionStart: return .eightBit1
        case .taskComplete: return .eightBit3
        case .needApproval: return .eightBit2
        }
    }
}

/// Sound configuration for an event
struct SoundConfig: Codable {
    var isEnabled: Bool
    var selectedSound: String
    
    static let `default` = SoundConfig(isEnabled: true, selectedSound: AvailableSound.eightBit1.rawValue)
}

/// Manages sound playback
@MainActor
class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var isEnabled = true
    @Published var volume: Float = 1.0
    
    private var configs: [SoundEvent: SoundConfig] = [:]
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        isEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        volume = defaults.object(forKey: "soundVolume") as? Float ?? 1.0
        
        for event in SoundEvent.allCases {
            let key = "sound_\(event.rawValue)"
            if let data = defaults.data(forKey: key),
               let config = try? JSONDecoder().decode(SoundConfig.self, from: data) {
                configs[event] = config
            } else {
                configs[event] = SoundConfig(isEnabled: true, selectedSound: event.defaultSound.rawValue)
            }
        }
    }

    /// Get path to MP3 file
    private func mp3Path(for filename: String) -> URL? {
        // Try multiple locations
        let paths = [
            // Direct in Resources
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(filename).mp3"),
            // In Sounds subdirectory
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Sounds/\(filename).mp3"),
            // Using Bundle API
            Bundle.main.url(forResource: filename, withExtension: "mp3"),
            Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: "Sounds")
        ]
        
        for path in paths {
            if let url = path, FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        return nil
    }

    /// Play sound for an event
    func play(_ event: SoundEvent) {
        guard isEnabled else { return }
        
        let config = configs[event] ?? .default
        guard config.isEnabled else { return }
        
        guard let sound = AvailableSound(rawValue: config.selectedSound) else { return }
        
        playSound(sound)
    }
    
    /// Play a specific sound
    func playSound(_ sound: AvailableSound) {
        if sound.isSystem {
            playSystemSound(sound)
        } else {
            playMP3(sound)
        }
    }
    
    /// Play system sound using NSSound
    private func playSystemSound(_ sound: AvailableSound) {
        guard let nssound = NSSound(named: sound.rawValue) else {
            print("❌ System sound not found: \(sound.rawValue)")
            return
        }
        nssound.volume = volume
        nssound.play()
        print("🔊 System sound: \(sound.rawValue)")
    }
    
    /// Play MP3 using AVAudioPlayer
    private func playMP3(_ sound: AvailableSound) {
        guard let url = mp3Path(for: sound.rawValue) else {
            print("❌ MP3 not found: \(sound.rawValue).mp3")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            let played = player.play()
            print("🔊 MP3 \(played ? "playing" : "failed"): \(sound.rawValue)")
            
            // Keep player alive until done
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                _ = player.duration // Just to keep reference
            }
        } catch {
            print("❌ MP3 error: \(error)")
        }
    }
    
    /// Preview a sound
    func preview(_ sound: AvailableSound) {
        print("🔊 Preview: \(sound.rawValue)")
        playSound(sound)
    }

    /// Set global enabled
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "soundEnabled")
    }
    
    /// Set volume
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        UserDefaults.standard.set(volume, forKey: "soundVolume")
    }
    
    /// Get config for an event
    func getConfig(for event: SoundEvent) -> SoundConfig {
        configs[event] ?? SoundConfig(isEnabled: true, selectedSound: event.defaultSound.rawValue)
    }
    
    /// Set config for an event
    func setConfig(_ config: SoundConfig, for event: SoundEvent) {
        configs[event] = config
        
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "sound_\(event.rawValue)")
        }
    }
    
    /// Set enabled for an event
    func setEnabled(_ enabled: Bool, for event: SoundEvent) {
        var config = getConfig(for: event)
        config.isEnabled = enabled
        setConfig(config, for: event)
    }
    
    /// Set sound for an event
    func setSound(_ sound: AvailableSound, for event: SoundEvent) {
        var config = getConfig(for: event)
        config.selectedSound = sound.rawValue
        setConfig(config, for: event)
    }
}
