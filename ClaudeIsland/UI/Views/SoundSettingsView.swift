//
//  SoundSettingsView.swift
//  ClaudeIsland
//
//  Sound settings with all available sounds
//

import SwiftUI

struct SoundSettingsView: View {
    @StateObject private var soundManager = SoundManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Master Controls
            SettingsSection(title: "全局") {
                // Master Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("启用音效")
                            .font(.system(size: 13, weight: .medium))
                        Text("播放提示音和完成音效")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $soundManager.isEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                }
                
                // Volume Control
                if soundManager.isEnabled {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $soundManager.volume, in: 0...1, step: 0.05)
                            .onChange(of: soundManager.volume) { _, newValue in
                                soundManager.setVolume(newValue)
                            }
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(soundManager.volume * 100))%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            
            // Individual Event Sounds
            if soundManager.isEnabled {
                SettingsSection(title: "事件") {
                    VStack(spacing: 16) {
                        ForEach(SoundEvent.allCases) { event in
                            SoundEventRow(event: event)
                        }
                    }
                }
            }
            
            // Custom Sound Folder
            SettingsSection(title: "自定义") {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        openSoundsFolder()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "folder")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.secondary.opacity(0.15))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("打开音效文件夹")
                                    .font(.system(size: 13, weight: .medium))
                                Text("添加 MP3 文件，自动生效")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Show custom sounds count
                    Text("已添加 \(soundManager.availableSounds.filter { $0.isCustom }.count) 个自定义音效")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .opacity(soundManager.availableSounds.filter { $0.isCustom }.count > 0 ? 1 : 0)
                }
            }
        }
    }
    
    private func openSoundsFolder() {
        // Get the Sounds directory in the app bundle
        if let soundsDir = Bundle.main.resourceURL?.appendingPathComponent("Sounds") {
            // Create directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: soundsDir.path) {
                try? FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            }
            
            // Open in Finder
            NSWorkspace.shared.open(soundsDir)
        }
    }
}

// MARK: - Sound Event Row

struct SoundEventRow: View {
    let event: SoundEvent
    @ObservedObject var soundManager = SoundManager.shared
    @State private var isEnabled: Bool = true
    @State private var selectedSoundId: String = ""
    @State private var showPicker: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Main row
            HStack(spacing: 12) {
                // Icon
                Image(systemName: event.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.15))
                    )
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.rawValue)
                        .font(.system(size: 13, weight: .medium))
                    
                    Text(event.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 8) {
                    // Preview button
                    Button {
                        if let sound = soundManager.getSound(byId: selectedSoundId) {
                            soundManager.preview(sound)
                        }
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white)
                            .frame(width: 26, height: 26)
                            .background(
                                Circle()
                                    .fill(Color.secondary.opacity(0.4))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Sound selector button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedSoundId)
                                .font(.system(size: 12))
                            Image(systemName: showPicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Toggle
                    Toggle("", isOn: $isEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                        .labelsHidden()
                        .onChange(of: isEnabled) { _, newValue in
                            soundManager.setEnabled(newValue, for: event)
                        }
                }
            }
            
            // Sound picker (expanded) - flat list, no grouping
            if showPicker {
                VStack(spacing: 2) {
                    ForEach(soundManager.availableSounds) { sound in
                        Button {
                            soundManager.setSound(sound.id, for: event)
                            soundManager.preview(sound)
                            selectedSoundId = sound.id
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPicker = false
                            }
                        } label: {
                            HStack {
                                HStack(spacing: 4) {
                                    Text(sound.name)
                                        .font(.system(size: 12))
                                    if sound.isCustom {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(.yellow)
                                    }
                                }
                                .foregroundColor(selectedSoundId == sound.id ? .accentColor : .primary)
                                
                                Spacer()
                                
                                if selectedSoundId == sound.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedSoundId == sound.id ? Color.accentColor.opacity(0.1) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 36)
                .padding(.top, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .onAppear {
            loadConfig()
        }
    }
    
    private func loadConfig() {
        let config = soundManager.getConfig(for: event)
        isEnabled = config.isEnabled
        selectedSoundId = config.selectedSound
    }
}
