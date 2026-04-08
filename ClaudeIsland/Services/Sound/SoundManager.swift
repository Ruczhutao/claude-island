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
struct AvailableSound: Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let isSystem: Bool
    let isCustom: Bool
    
    // System sounds
    static let pop = AvailableSound(id: "Pop", name: "Pop", isSystem: true, isCustom: false)
    static let ping = AvailableSound(id: "Ping", name: "Ping", isSystem: true, isCustom: false)
    static let tink = AvailableSound(id: "Tink", name: "Tink", isSystem: true, isCustom: false)
    static let glass = AvailableSound(id: "Glass", name: "Glass", isSystem: true, isCustom: false)
    static let blow = AvailableSound(id: "Blow", name: "Blow", isSystem: true, isCustom: false)
    static let bottle = AvailableSound(id: "Bottle", name: "Bottle", isSystem: true, isCustom: false)
    static let frog = AvailableSound(id: "Frog", name: "Frog", isSystem: true, isCustom: false)
    static let funk = AvailableSound(id: "Funk", name: "Funk", isSystem: true, isCustom: false)
    static let hero = AvailableSound(id: "Hero", name: "Hero", isSystem: true, isCustom: false)
    static let morse = AvailableSound(id: "Morse", name: "Morse", isSystem: true, isCustom: false)
    static let purr = AvailableSound(id: "Purr", name: "Purr", isSystem: true, isCustom: false)
    static let sosumi = AvailableSound(id: "Sosumi", name: "Sosumi", isSystem: true, isCustom: false)
    static let submarine = AvailableSound(id: "Submarine", name: "Submarine", isSystem: true, isCustom: false)
    
    // Built-in custom sounds
    static let eightBit1 = AvailableSound(id: "8bit1", name: "8bit1", isSystem: false, isCustom: false)
    static let eightBit2 = AvailableSound(id: "8bit2", name: "8bit2", isSystem: false, isCustom: false)
    static let eightBit3 = AvailableSound(id: "8bit3", name: "8bit3", isSystem: false, isCustom: false)
    
    static var defaultSystemSounds: [AvailableSound] {
        [pop, ping, tink, glass, blow, bottle, frog, funk, hero, morse, purr, sosumi, submarine]
    }
    
    static var defaultCustomSounds: [AvailableSound] {
        [eightBit1, eightBit2, eightBit3]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    
    var defaultSoundId: String {
        switch self {
        case .sessionStart: return "8bit1"
        case .taskComplete: return "8bit3"
        case .needApproval: return "8bit2"
        }
    }
}

/// Sound configuration for an event
struct SoundConfig: Codable {
    var isEnabled: Bool
    var selectedSound: String
    
    static let `default` = SoundConfig(isEnabled: true, selectedSound: "8bit1")
}

/// Manages sound playback
@MainActor
class SoundManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = SoundManager()

    @Published var isEnabled = true
    @Published var volume: Float = 1.0
    @Published var availableSounds: [AvailableSound] = []
    
    private var configs: [SoundEvent: SoundConfig] = [:]
    private var fileMonitor: Timer?
    private var activePlayers: [AVAudioPlayer] = []  // Keep players alive while playing
    
    private override init() {
        super.init()
        loadSettings()
        scanCustomSounds()
        startFileMonitoring()
    }
    
    /// Scan for custom MP3 files in the Sounds directory
    func scanCustomSounds() {
        var sounds: [AvailableSound] = []
        
        // Add default sounds first
        sounds.append(contentsOf: AvailableSound.defaultSystemSounds)
        sounds.append(contentsOf: AvailableSound.defaultCustomSounds)
        
        // Scan for custom MP3 files
        if let soundsDir = getSoundsDirectory() {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: soundsDir, includingPropertiesForKeys: nil)
                let mp3Files = files.filter { $0.pathExtension.lowercased() == "mp3" }
                
                for file in mp3Files {
                    let filename = file.deletingPathExtension().lastPathComponent
                    // Skip built-in sounds that are already added
                    if !sounds.contains(where: { $0.id == filename }) {
                        let customSound = AvailableSound(
                            id: filename,
                            name: filename,
                            isSystem: false,
                            isCustom: true
                        )
                        sounds.append(customSound)
                        print("🔊 Found custom sound: \(filename)")
                    }
                }
            } catch {
                print("❌ Error scanning sounds directory: \(error)")
            }
        }
        
        availableSounds = sounds
        print("🔊 Total available sounds: \(sounds.count)")
    }
    
    /// Get the Sounds directory path
    private func getSoundsDirectory() -> URL? {
        // Try app bundle Resources/Sounds first
        if let bundleSounds = Bundle.main.resourceURL?.appendingPathComponent("Sounds") {
            return bundleSounds
        }
        return nil
    }
    
    /// Start monitoring for file changes
    private func startFileMonitoring() {
        fileMonitor?.invalidate()
        fileMonitor = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.scanCustomSounds()
        }
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
                configs[event] = SoundConfig(isEnabled: true, selectedSound: event.defaultSoundId)
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
        
        for (index, path) in paths.enumerated() {
            if let url = path {
                let exists = FileManager.default.fileExists(atPath: url.path)
                print("🔊 Path \(index): \(url.path) - \(exists ? "EXISTS" : "not found")")
                if exists {
                    return url
                }
            }
        }
        
        print("🔊 MP3 not found: \(filename).mp3")
        return nil
    }

    /// Play sound for an event
    func play(_ event: SoundEvent) {
        print("🔊 SoundManager.play(\(event.rawValue)) called")
        guard isEnabled else {
            print("🔊 Sound disabled")
            return
        }
        
        let config = configs[event] ?? .default
        guard config.isEnabled else {
            print("🔊 Sound event disabled: \(event.rawValue)")
            return
        }
        
        print("🔊 Playing sound: \(config.selectedSound)")
        playSound(id: config.selectedSound)
    }
    
    /// Play a sound by ID
    func playSound(id: String) {
        // Check if it's a system sound
        if AvailableSound.defaultSystemSounds.contains(where: { $0.id == id }) {
            playSystemSound(name: id)
        } else {
            // Try to play as MP3
            playMP3(filename: id)
        }
    }
    
    /// Play a specific sound
    func playSound(_ sound: AvailableSound) {
        if sound.isSystem {
            playSystemSound(name: sound.id)
        } else {
            playMP3(filename: sound.id)
        }
    }
    
    /// Play system sound using NSSound
    private func playSystemSound(name: String) {
        guard let nssound = NSSound(named: name) else {
            print("❌ System sound not found: \(name)")
            return
        }
        nssound.volume = volume
        nssound.play()
        print("🔊 System sound: \(name)")
    }
    
    /// Play MP3 using AVAudioPlayer
    private func playMP3(filename: String) {
        guard let url = mp3Path(for: filename) else {
            print("❌ MP3 not found: \(filename).mp3")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            
            // Keep strong reference to player while playing
            activePlayers.append(player)
            
            // Set up delegate to remove from array when done
            player.delegate = self
            
            let played = player.play()
            print("🔊 MP3 \(played ? "playing" : "failed"): \(filename), volume: \(volume)")
            
            // Clean up finished players after duration + buffer
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.5) { [weak self] in
                self?.cleanupFinishedPlayers()
            }
        } catch {
            print("❌ MP3 error: \(error)")
        }
    }
    
    /// Remove finished players from active array
    private func cleanupFinishedPlayers() {
        activePlayers.removeAll { !$0.isPlaying }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.activePlayers.removeAll { $0 === player }
            print("🔊 Finished playing, active players: \(self.activePlayers.count)")
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("❌ Audio decode error: \(error)")
        }
        Task { @MainActor in
            self.activePlayers.removeAll { $0 === player }
        }
    }
    
    /// Preview a sound
    func preview(_ sound: AvailableSound) {
        print("🔊 Preview: \(sound.id)")
        playSound(sound)
    }
    
    /// Preview a sound by ID
    func preview(id: String) {
        print("🔊 Preview: \(id)")
        playSound(id: id)
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
        configs[event] ?? SoundConfig(isEnabled: true, selectedSound: event.defaultSoundId)
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
    func setSound(_ soundId: String, for event: SoundEvent) {
        var config = getConfig(for: event)
        config.selectedSound = soundId
        setConfig(config, for: event)
    }
    
    /// Get sound by ID
    func getSound(byId id: String) -> AvailableSound? {
        return availableSounds.first { $0.id == id }
    }
}
