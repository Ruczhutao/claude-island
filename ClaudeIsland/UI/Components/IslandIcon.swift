//
//  IslandIcon.swift
//  ClaudeIsland
//
//  Pixel art tropical island icon for Notch display
//  Palm tree + sand mound + ocean waves
//

import Combine
import SwiftUI

struct IslandIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false      // running - palm sway + waves
    var breathe: Bool = false      // sleeping - gentle waves
    var pulse: Bool = false        // waiting - storm/alert

    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0

    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    // MARK: - Color Palette
    private let leafGreen   = Color(red: 0.2, green: 0.82, blue: 0.35)
    private let darkGreen   = Color(red: 0.15, green: 0.6, blue: 0.25)
    private let trunkBrown  = Color(red: 0.55, green: 0.35, blue: 0.18)
    private let coconut     = Color(red: 0.4, green: 0.25, blue: 0.1)
    private let sandGold    = Color(red: 0.95, green: 0.82, blue: 0.45)
    private let sandLight   = Color(red: 1.0, green: 0.92, blue: 0.6)
    private let oceanBlue   = Color(red: 0.2, green: 0.5, blue: 0.88)
    private let waveLight   = Color(red: 0.45, green: 0.7, blue: 0.98)
    private let foam        = Color(white: 0.95)

    // MARK: - Base Frame
    private var baseFrame: [(Int, Int, Color)] {
        let leaves: [(Int, Int, Color)] = [
            // Top cluster
            (7, 0, leafGreen), (8, 0, leafGreen),
            (5, 1, darkGreen), (6, 1, leafGreen), (7, 1, leafGreen),
            (8, 1, leafGreen), (9, 1, leafGreen), (10, 1, darkGreen),
            (4, 2, leafGreen), (5, 2, darkGreen), (9, 2, darkGreen), (10, 2, leafGreen),
            (3, 3, darkGreen), (11, 3, darkGreen),
            (6, 2, coconut), (9, 2, coconut),
        ]
        let trunk: [(Int, Int, Color)] = [
            (7, 3, trunkBrown), (8, 3, trunkBrown),
            (7, 4, trunkBrown), (8, 4, trunkBrown),
            (7, 5, trunkBrown), (8, 5, trunkBrown),
            (7, 6, trunkBrown), (8, 6, trunkBrown),
        ]
        let sand: [(Int, Int, Color)] = [
            (5, 7, sandLight), (6, 7, sandGold), (7, 7, sandGold),
            (8, 7, sandGold), (9, 7, sandGold), (10, 7, sandLight),
            (4, 8, sandLight), (5, 8, sandGold), (6, 8, sandGold),
            (7, 8, sandLight), (8, 8, sandLight),
            (9, 8, sandGold), (10, 8, sandGold), (11, 8, sandLight),
            (3, 9, sandGold), (4, 9, sandGold), (5, 9, sandGold),
            (6, 9, sandGold), (7, 9, sandGold), (8, 9, sandGold),
            (9, 9, sandGold), (10, 9, sandGold), (11, 9, sandGold), (12, 9, sandGold),
            (4, 10, sandLight), (5, 10, sandGold), (6, 10, sandGold),
            (7, 10, sandGold), (8, 10, sandGold),
            (9, 10, sandGold), (10, 10, sandGold), (11, 10, sandLight),
        ]
        let ocean: [(Int, Int, Color)] = [
            (3, 11, oceanBlue), (4, 11, waveLight), (11, 11, waveLight), (12, 11, oceanBlue),
            (2, 12, oceanBlue), (3, 12, waveLight), (4, 12, oceanBlue), (5, 12, oceanBlue),
            (10, 12, oceanBlue), (11, 12, oceanBlue), (12, 12, waveLight), (13, 12, oceanBlue),
            (3, 13, oceanBlue), (4, 13, waveLight), (5, 13, oceanBlue), (6, 13, oceanBlue),
            (9, 13, oceanBlue), (10, 13, oceanBlue), (11, 13, waveLight), (12, 13, oceanBlue),
            (5, 14, oceanBlue), (6, 14, waveLight), (9, 14, waveLight), (10, 14, oceanBlue),
            (2, 11, foam), (13, 11, foam),
            (1, 12, foam), (14, 12, foam),
            (2, 13, foam), (13, 13, foam),
        ]
        return leaves + trunk + sand + ocean
    }

    // MARK: - Animation Frames
    private var animFrames: [[(Int, Int, Color)]] {
        [
            [],  // base
            [(14, 11, foam), (14, 13, waveLight)],
            [(13, 10, waveLight), (2, 10, waveLight)],
            [(1, 11, foam), (1, 13, waveLight), (2, 14, waveLight), (13, 14, waveLight)],
        ]
    }
    
    // Storm frames for waiting
    private let stormColor = Color(red: 0.9, green: 0.9, blue: 1.0)
    private var stormFrames: [[(Int, Int, Color)]] {
        [
            // Lightning flash
            [
                (7, 0, stormColor), (8, 0, stormColor),
                (6, 1, stormColor), (9, 1, stormColor),
                (3, 11, stormColor), (12, 11, stormColor),
            ],
            [],
        ]
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0
            guard scale > 0 else { return }

            for p in baseFrame {
                let rect = CGRect(
                    x: CGFloat(p.0) * scale, y: CGFloat(p.1) * scale,
                    width: max(1, scale), height: max(1, scale)
                )
                context.fill(Path(rect), with: .color(p.2))
            }

            if animate {
                // Running - waves + palm movement
                for p in animFrames[animationPhase % animFrames.count] {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale, y: CGFloat(p.1) * scale,
                        width: max(1, scale), height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(p.2))
                }
            } else if pulse {
                // Waiting - storm flash
                let frame = stormFrames[animationPhase % 2]
                for p in frame {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale, y: CGFloat(p.1) * scale,
                        width: max(1, scale), height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(p.2))
                }
            }
        }
        .frame(width: size, height: size)
        .opacity(breatheOpacity)
        .animation(breathe ? .easeInOut(duration: 2.5).repeatForever(autoreverses: true) :
                   pulse ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                   value: breatheOpacity)
        .onReceive(timer) { _ in
            if animate || pulse { animationPhase = (animationPhase + 1) % 4 }
        }
        .onAppear {
            if breathe { breatheOpacity = 0.45 }
            else if pulse { breatheOpacity = 0.6 }
        }
        .onChange(of: breathe) { _, newValue in
            if newValue { breatheOpacity = 0.45 }
            else if !pulse { breatheOpacity = 1.0 }
        }
        .onChange(of: pulse) { _, newValue in
            if newValue { breatheOpacity = 0.6 }
            else if !breathe { breatheOpacity = 1.0 }
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        VStack(spacing: 10) {
            Text("Idle").font(.caption).foregroundColor(.white)
            IslandIcon(size: 36, color: .white, animate: false, breathe: false)
        }
        VStack(spacing: 10) {
            Text("Processing").font(.caption).foregroundColor(.white)
            IslandIcon(size: 36, color: .white, animate: true, breathe: false)
        }
        VStack(spacing: 10) {
            Text("Breathing").font(.caption).foregroundColor(.white)
            IslandIcon(size: 36, color: .white, animate: false, breathe: true)
        }
    }
    .padding(40)
    .background(.black)
}
