//
//  GhostIcon.swift
//  ClaudeIsland
//
//  Pixel art cute ghost icon for Notch display
//  Classic ghost shape with dot eyes and wavy bottom
//

import Combine
import SwiftUI

struct GhostIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false      // running - fast wavy movement
    var breathe: Bool = false      // sleeping - float up/down
    var pulse: Bool = false        // waiting - solidify/blink

    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0

    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    // MARK: - Color Palette
    private let ghostWhite = Color(red: 0.93, green: 0.93, blue: 0.98)
    private let ghostLight = Color(red: 0.98, green: 0.98, blue: 1.0)
    private let ghostEdge  = Color(red: 0.8, green: 0.8, blue: 0.9)
    private let eyeDark    = Color(red: 0.12, green: 0.12, blue: 0.18)
    private let blushPink  = Color(red: 1.0, green: 0.7, blue: 0.75)

    // MARK: - Base Frame
    private var baseFrame: [(Int, Int, Color)] {
        let dome: [(Int, Int, Color)] = [
            (6, 1, ghostEdge), (7, 1, ghostLight), (8, 1, ghostLight), (9, 1, ghostEdge),
            (5, 2, ghostEdge),
            (6, 2, ghostWhite), (7, 2, ghostLight), (8, 2, ghostLight), (9, 2, ghostWhite),
            (10, 2, ghostEdge),
            (4, 3, ghostEdge),
            (5, 3, ghostWhite), (6, 3, ghostWhite), (7, 3, ghostLight), (8, 3, ghostLight),
            (9, 3, ghostWhite), (10, 3, ghostWhite),
            (11, 3, ghostEdge),
        ]
        let eyes: [(Int, Int, Color)] = [
            (4, 4, ghostWhite),
            (5, 4, eyeDark), (6, 4, eyeDark),
            (7, 4, ghostWhite), (8, 4, ghostWhite),
            (9, 4, eyeDark), (10, 4, eyeDark),
            (11, 4, ghostWhite),
            (4, 5, ghostWhite),
            (5, 5, eyeDark), (6, 5, eyeDark),
            (7, 5, ghostWhite), (8, 5, ghostWhite),
            (9, 5, eyeDark), (10, 5, eyeDark),
            (11, 5, ghostWhite),
        ]
        let blush: [(Int, Int, Color)] = [
            (4, 6, ghostWhite), (5, 6, blushPink),
            (6, 6, ghostWhite), (7, 6, ghostWhite),
            (8, 6, ghostWhite), (9, 6, ghostWhite),
            (10, 6, blushPink), (11, 6, ghostWhite),
        ]
        var body: [(Int, Int, Color)] = []
        for y in 7...10 {
            body.append(contentsOf: [
                (4, y, ghostEdge),
                (5, y, ghostWhite), (6, y, ghostWhite), (7, y, ghostLight),
                (8, y, ghostLight), (9, y, ghostWhite), (10, y, ghostWhite),
                (11, y, ghostEdge),
            ])
        }
        let bottom: [(Int, Int, Color)] = [
            (4, 11, ghostWhite), (5, 11, ghostEdge),
            (6, 11, ghostWhite), (7, 11, ghostWhite),
            (8, 11, ghostWhite), (9, 11, ghostWhite),
            (10, 11, ghostEdge), (11, 11, ghostWhite),
            (4, 12, ghostWhite), (7, 12, ghostWhite),
            (8, 12, ghostWhite), (11, 12, ghostWhite),
        ]
        return dome + eyes + blush + body + bottom
    }

    // MARK: - Animation Frames
    private var animFrames: [[(Int, Int, Color)]] {
        [
            [(4, 12, ghostWhite), (7, 12, ghostWhite), (8, 12, ghostWhite), (11, 12, ghostWhite)],
            [(5, 12, ghostWhite), (8, 12, ghostWhite), (9, 12, ghostWhite), (12, 12, ghostWhite)],
            [(4, 12, ghostWhite), (7, 12, ghostWhite), (8, 12, ghostWhite), (11, 12, ghostWhite)],
            [(3, 12, ghostWhite), (6, 12, ghostWhite), (7, 12, ghostWhite), (10, 12, ghostWhite)],
        ]
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0
            guard scale > 0 else { return }

            // Float offset for breathing or pulse
            let floatOffset: CGFloat
            if breathe {
                floatOffset = CGFloat((animationPhase / 5) % 3 - 1) * scale
            } else if pulse {
                floatOffset = CGFloat(animationPhase % 2) * scale * 0.5
            } else {
                floatOffset = 0
            }

            for p in baseFrame {
                let rect = CGRect(
                    x: CGFloat(p.0) * scale,
                    y: CGFloat(p.1) * scale + floatOffset,
                    width: max(1, scale), height: max(1, scale)
                )
                context.fill(Path(rect), with: .color(p.2))
            }

            if animate {
                // Running - wavy bottom
                for p in animFrames[animationPhase % animFrames.count] {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale,
                        y: CGFloat(p.1) * scale + floatOffset,
                        width: max(1, scale), height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(p.2))
                }
            }
        }
        .frame(width: size, height: size)
        .opacity(breatheOpacity)
        .animation(breathe ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true) :
                   pulse ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default,
                   value: breatheOpacity)
        .onReceive(timer) { _ in animationPhase += 1 }
        .onAppear {
            if breathe { breatheOpacity = 0.4 }
            else if pulse { breatheOpacity = 0.5 }
        }
        .onChange(of: breathe) { _, newValue in
            if newValue { breatheOpacity = 0.4 }
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
            GhostIcon(size: 36, color: .white, animate: false, breathe: false)
        }
        VStack(spacing: 10) {
            Text("Processing").font(.caption).foregroundColor(.white)
            GhostIcon(size: 36, color: .white, animate: true, breathe: false)
        }
        VStack(spacing: 10) {
            Text("Breathing").font(.caption).foregroundColor(.white)
            GhostIcon(size: 36, color: .white, animate: false, breathe: true)
        }
    }
    .padding(40)
    .background(.black)
}
