//
//  RobotIcon.swift
//  ClaudeIsland
//
//  Pixel art cute robot head icon for Notch display
//  Retro robot with antenna, LED eyes, grid mouth
//

import Combine
import SwiftUI

struct RobotIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false      // running - full system active
    var breathe: Bool = false      // sleeping - core pulse
    var pulse: Bool = false        // waiting - alert blink

    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0

    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    // MARK: - Color Palette
    private let bodySilver = Color(red: 0.72, green: 0.72, blue: 0.76)
    private let bodyLight  = Color(red: 0.85, green: 0.85, blue: 0.88)
    private let bodyDark   = Color(red: 0.45, green: 0.45, blue: 0.5)
    private let eyeCyan    = Color(red: 0.0, green: 0.92, blue: 0.92)
    private let antennaRed = Color(red: 1.0, green: 0.25, blue: 0.2)
    private let antennaOff = Color(red: 0.5, green: 0.15, blue: 0.12)
    private let mouthGreen = Color(red: 0.0, green: 0.85, blue: 0.3)
    private let mouthOff   = Color(red: 0.0, green: 0.3, blue: 0.1)
    private let earAccent  = Color(red: 0.5, green: 0.5, blue: 0.58)
    private let borderDark = Color(red: 0.3, green: 0.3, blue: 0.35)

    // MARK: - Base Frame
    private var baseFrame: [(Int, Int, Color)] {
        let antenna: [(Int, Int, Color)] = [
            (7, 1, bodyDark), (7, 0, antennaOff),
        ]
        let headTop: [(Int, Int, Color)] = [
            (4, 2, borderDark), (5, 2, borderDark), (6, 2, borderDark),
            (7, 2, borderDark), (8, 2, borderDark), (9, 2, borderDark),
            (10, 2, borderDark), (11, 2, borderDark),
            (3, 3, borderDark),
            (4, 3, bodyLight), (5, 3, bodySilver), (6, 3, bodySilver),
            (7, 3, bodySilver), (8, 3, bodySilver),
            (9, 3, bodySilver), (10, 3, bodySilver),
            (11, 3, bodyLight), (12, 3, borderDark),
        ]
        let eyes: [(Int, Int, Color)] = [
            (3, 4, borderDark), (4, 4, bodySilver), (5, 4, bodySilver),
            (6, 4, eyeCyan), (7, 4, eyeCyan),
            (8, 4, bodySilver),
            (9, 4, eyeCyan), (10, 4, eyeCyan),
            (11, 4, bodySilver), (12, 4, borderDark),
            (3, 5, borderDark), (4, 5, bodySilver), (5, 5, bodySilver),
            (6, 5, eyeCyan), (7, 5, eyeCyan),
            (8, 5, bodySilver),
            (9, 5, eyeCyan), (10, 5, eyeCyan),
            (11, 5, bodySilver), (12, 5, borderDark),
        ]
        let face: [(Int, Int, Color)] = [
            (3, 6, borderDark),
            (4, 6, bodySilver), (5, 6, bodySilver), (6, 6, bodySilver),
            (7, 6, bodySilver), (8, 6, bodySilver),
            (9, 6, bodySilver), (10, 6, bodySilver), (11, 6, bodySilver),
            (12, 6, borderDark),
        ]
        let mouth: [(Int, Int, Color)] = [
            (3, 7, borderDark),
            (4, 7, bodySilver), (5, 7, bodySilver),
            (6, 7, mouthOff), (7, 7, mouthOff), (8, 7, mouthOff), (9, 7, mouthOff),
            (10, 7, bodySilver), (11, 7, bodySilver),
            (12, 7, borderDark),
            (4, 8, borderDark), (5, 8, bodySilver),
            (6, 8, mouthOff), (7, 8, bodyDark), (8, 8, bodyDark), (9, 8, mouthOff),
            (10, 8, bodySilver), (11, 8, borderDark),
        ]
        let chin: [(Int, Int, Color)] = [
            (4, 9, borderDark),
            (5, 9, bodyLight), (6, 9, bodySilver), (7, 9, bodySilver),
            (8, 9, bodySilver), (9, 9, bodySilver), (10, 9, bodyLight),
            (11, 9, borderDark),
            (5, 10, borderDark),
            (6, 10, bodyDark), (7, 10, bodyDark), (8, 10, bodyDark), (9, 10, bodyDark),
            (10, 10, borderDark),
        ]
        let ears: [(Int, Int, Color)] = [
            (2, 4, earAccent), (2, 5, earAccent),
            (13, 4, earAccent), (13, 5, earAccent),
        ]
        return antenna + headTop + eyes + face + mouth + chin + ears
    }

    // MARK: - Animation Frames
    private var animFrames: [[(Int, Int, Color)]] {
        [
            // Frame 0: antenna on, mouth corners
            [
                (7, 0, antennaRed),
                (6, 7, mouthGreen), (9, 7, mouthGreen),
                (7, 8, mouthGreen), (8, 8, mouthGreen),
            ],
            // Frame 1: eyes scan left, mouth center
            [
                (5, 4, eyeCyan), (6, 4, eyeCyan), (8, 4, eyeCyan), (9, 4, eyeCyan),
                (5, 5, eyeCyan), (6, 5, eyeCyan), (8, 5, eyeCyan), (9, 5, eyeCyan),
                (7, 7, mouthGreen), (8, 7, mouthGreen),
                (6, 8, mouthGreen), (9, 8, mouthGreen),
            ],
            // Frame 2: antenna on, mouth full
            [
                (7, 0, antennaRed),
                (6, 7, mouthGreen), (7, 7, mouthGreen), (8, 7, mouthGreen), (9, 7, mouthGreen),
            ],
            // Frame 3: eyes scan right, mouth center
            [
                (7, 4, eyeCyan), (8, 4, eyeCyan), (10, 4, eyeCyan), (11, 4, eyeCyan),
                (7, 5, eyeCyan), (8, 5, eyeCyan), (10, 5, eyeCyan), (11, 5, eyeCyan),
                (7, 7, mouthGreen), (8, 7, mouthGreen),
                (6, 8, mouthGreen), (9, 8, mouthGreen),
            ],
        ]
    }

    // Idle blink
    private var idleFrames: [[(Int, Int, Color)]] {
        [
            [(7, 0, antennaRed)],
            [(7, 0, antennaOff)],
        ]
    }

    // Alert frames for waiting - all lights blink
    private var alertFrames: [[(Int, Int, Color)]] {
        [
            // Frame 0: lights on
            [
                (7, 0, antennaRed),
                (6, 4, eyeCyan), (7, 4, eyeCyan), (9, 4, eyeCyan), (10, 4, eyeCyan),
                (6, 5, eyeCyan), (7, 5, eyeCyan), (9, 5, eyeCyan), (10, 5, eyeCyan),
                (6, 7, mouthGreen), (7, 7, mouthGreen), (8, 7, mouthGreen), (9, 7, mouthGreen),
            ],
            // Frame 1: lights off
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
                // Running - full animation
                for p in animFrames[animationPhase % animFrames.count] {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale, y: CGFloat(p.1) * scale,
                        width: max(1, scale), height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(p.2))
                }
            } else if pulse {
                // Waiting - alert blink
                let frame = alertFrames[animationPhase % 2]
                for p in frame {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale, y: CGFloat(p.1) * scale,
                        width: max(1, scale), height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(p.2))
                }
            } else if breathe {
                // Sleeping - slow antenna blink
                let frame = idleFrames[(animationPhase / 4) % idleFrames.count]
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
                   pulse ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default,
                   value: breatheOpacity)
        .onReceive(timer) { _ in
            if animate || pulse {
                animationPhase += 1
            }
        }
        .onAppear {
            if breathe { breatheOpacity = 0.45 }
            else if pulse { breatheOpacity = 0.5 }
        }
        .onChange(of: breathe) { _, newValue in
            if newValue { breatheOpacity = 0.45 }
            else if !pulse { breatheOpacity = 1.0 }
        }
        .onChange(of: pulse) { _, newValue in
            if newValue { breatheOpacity = 0.5 }
            else if !breathe { breatheOpacity = 1.0 }
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        VStack(spacing: 10) {
            Text("Idle").font(.caption).foregroundColor(.white)
            RobotIcon(size: 36, color: .white, animate: false, breathe: false)
        }
        VStack(spacing: 10) {
            Text("Processing").font(.caption).foregroundColor(.white)
            RobotIcon(size: 36, color: .white, animate: true, breathe: false)
        }
        VStack(spacing: 10) {
            Text("Breathing").font(.caption).foregroundColor(.white)
            RobotIcon(size: 36, color: .white, animate: false, breathe: true)
        }
    }
    .padding(40)
    .background(.black)
}
