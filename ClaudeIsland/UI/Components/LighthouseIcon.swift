//
//  LighthouseIcon.swift
//  ClaudeIsland
//
//  Pixel art lighthouse icon for Notch display
//  Lighthouse with red/white stripes, light beam, ocean waves
//

import Combine
import SwiftUI

struct LighthouseIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false      // running - fast beam rotation
    var breathe: Bool = false      // sleeping - slow dim beam
    var pulse: Bool = false        // waiting - red alert flash

    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0

    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    // MARK: - Color Palette
    private let lightYellow = Color(red: 1.0, green: 0.95, blue: 0.35)
    private let lightBright = Color(red: 1.0, green: 1.0, blue: 0.7)
    private let lightDim    = Color(red: 0.8, green: 0.75, blue: 0.3)
    private let redStripe   = Color(red: 0.9, green: 0.22, blue: 0.18)
    private let whiteStripe = Color(red: 0.92, green: 0.92, blue: 0.94)
    private let windowColor = Color(red: 1.0, green: 0.85, blue: 0.4)
    private let baseGray    = Color(red: 0.55, green: 0.55, blue: 0.58)
    private let oceanDeep   = Color(red: 0.12, green: 0.32, blue: 0.68)
    private let oceanWave   = Color(red: 0.25, green: 0.52, blue: 0.85)
    private let oceanFoam   = Color(red: 0.7, green: 0.82, blue: 0.95)
    private let borderDark  = Color(red: 0.3, green: 0.3, blue: 0.32)

    // MARK: - Base Frame
    private var baseFrame: [(Int, Int, Color)] {
        let lantern: [(Int, Int, Color)] = [
            (6, 1, lightDim), (7, 1, lightYellow), (8, 1, lightYellow), (9, 1, lightDim),
            (5, 2, lightDim), (6, 2, lightBright), (7, 2, lightBright),
            (8, 2, lightBright), (9, 2, lightBright), (10, 2, lightDim),
            (5, 3, borderDark), (6, 3, lightYellow), (7, 3, lightBright),
            (8, 3, lightBright), (9, 3, lightYellow), (10, 3, borderDark),
        ]
        let red1: [(Int, Int, Color)] = [
            (6, 4, borderDark), (7, 4, borderDark), (8, 4, borderDark), (9, 4, borderDark),
            (6, 5, redStripe), (7, 5, redStripe), (8, 5, redStripe), (9, 5, redStripe),
        ]
        let white1: [(Int, Int, Color)] = [
            (6, 6, whiteStripe), (7, 6, whiteStripe), (8, 6, whiteStripe), (9, 6, whiteStripe),
            (6, 7, whiteStripe), (7, 7, windowColor), (8, 7, windowColor), (9, 7, whiteStripe),
        ]
        let red2: [(Int, Int, Color)] = [
            (6, 8, redStripe), (7, 8, redStripe), (8, 8, redStripe), (9, 8, redStripe),
            (6, 9, redStripe), (7, 9, redStripe), (8, 9, redStripe), (9, 9, redStripe),
        ]
        let base: [(Int, Int, Color)] = [
            (5, 10, whiteStripe), (6, 10, whiteStripe), (7, 10, whiteStripe),
            (8, 10, whiteStripe), (9, 10, whiteStripe), (10, 10, whiteStripe),
            (4, 11, baseGray), (5, 11, baseGray), (6, 11, baseGray), (7, 11, baseGray),
            (8, 11, baseGray), (9, 11, baseGray), (10, 11, baseGray), (11, 11, baseGray),
        ]
        let ocean: [(Int, Int, Color)] = [
            (2, 12, oceanDeep), (3, 12, oceanWave), (4, 12, oceanFoam),
            (5, 12, oceanWave), (6, 12, oceanDeep), (7, 12, oceanDeep),
            (8, 12, oceanDeep), (9, 12, oceanDeep), (10, 12, oceanWave),
            (11, 12, oceanFoam), (12, 12, oceanWave), (13, 12, oceanDeep),
            (1, 13, oceanDeep), (2, 13, oceanWave), (3, 13, oceanDeep),
            (4, 13, oceanWave), (5, 13, oceanDeep), (6, 13, oceanFoam),
            (7, 13, oceanWave), (8, 13, oceanWave), (9, 13, oceanFoam),
            (10, 13, oceanDeep), (11, 13, oceanWave), (12, 13, oceanDeep),
            (13, 13, oceanWave), (14, 13, oceanDeep),
        ]
        return lantern + red1 + white1 + red2 + base + ocean
    }

    // MARK: - Processing Animation
    private var processingFrames: [[(Int, Int, Color)]] {
        [
            // Flash left beam
            [
                (6, 1, lightBright), (7, 1, lightBright), (8, 1, lightBright), (9, 1, lightBright),
                (4, 0, lightBright), (5, 0, lightBright), (6, 0, lightBright),
            ],
            // Dim + right beam
            [
                (6, 1, lightDim), (7, 1, lightDim), (8, 1, lightDim), (9, 1, lightDim),
                (9, 0, lightBright), (10, 0, lightBright), (11, 0, lightBright),
            ],
            // Flash both beams
            [
                (6, 1, lightBright), (7, 1, lightBright), (8, 1, lightBright), (9, 1, lightBright),
                (4, 0, lightBright), (5, 0, lightBright), (6, 0, lightBright),
                (9, 0, lightBright), (10, 0, lightBright), (11, 0, lightBright),
            ],
            // Dim
            [
                (6, 1, lightDim), (7, 1, lightDim), (8, 1, lightDim), (9, 1, lightDim),
            ],
        ]
    }

    // Idle: slow light beam rotation
    private var idleFrames: [[(Int, Int, Color)]] {
        [
            [],
            [(4, 0, lightBright.opacity(0.6)), (5, 0, lightBright.opacity(0.4)),
             (3, 1, lightBright.opacity(0.3))],
            [],
            [(11, 0, lightBright.opacity(0.6)), (10, 0, lightBright.opacity(0.4)),
             (12, 1, lightBright.opacity(0.3))],
        ]
    }
    
    // Alert flash for waiting - red light
    private let alertRed = Color(red: 1.0, green: 0.1, blue: 0.1)
    private var alertFrames: [[(Int, Int, Color)]] {
        [
            // Red flash
            [
                (6, 1, alertRed), (7, 1, alertRed), (8, 1, alertRed), (9, 1, alertRed),
                (5, 2, alertRed), (6, 2, alertRed), (7, 2, alertRed), (8, 2, alertRed), (9, 2, alertRed), (10, 2, alertRed),
                (5, 3, alertRed), (6, 3, alertRed), (7, 3, alertRed), (8, 3, alertRed), (9, 3, alertRed), (10, 3, alertRed),
            ],
            // Off
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
                // Running - fast beam rotation
                for p in processingFrames[animationPhase % processingFrames.count] {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale, y: CGFloat(p.1) * scale,
                        width: max(1, scale), height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(p.2))
                }
            } else if pulse {
                // Waiting - red alert flash
                let frame = alertFrames[animationPhase % 2]
                for p in frame {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale, y: CGFloat(p.1) * scale,
                        width: max(1, scale), height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(p.2))
                }
            } else if breathe {
                // Sleeping - slow beam
                let frame = idleFrames[(animationPhase / 6) % idleFrames.count]
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
        .onReceive(timer) { _ in animationPhase += 1 }
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
            LighthouseIcon(size: 36, color: .white, animate: false, breathe: false)
        }
        VStack(spacing: 10) {
            Text("Processing").font(.caption).foregroundColor(.white)
            LighthouseIcon(size: 36, color: .white, animate: true, breathe: false)
        }
        VStack(spacing: 10) {
            Text("Breathing").font(.caption).foregroundColor(.white)
            LighthouseIcon(size: 36, color: .white, animate: false, breathe: true)
        }
    }
    .padding(40)
    .background(.black)
}
