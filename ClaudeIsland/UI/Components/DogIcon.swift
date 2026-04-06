//
//  DogIcon.swift
//  ClaudeIsland
//
//  Full-body pixel art dog for Notch display
//  Pure dog icon - animations: idle / breathing / running / pulsing
//

import Combine
import SwiftUI

/// Pure dog icon - animations based on status
/// - idle: lying still
/// - sleeping: slow breathing
/// - running: running animation
/// - waiting: fast pulsing (alert)
struct DogIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false      // running animation
    var breathe: Bool = false      // slow breathing (sleeping)
    var pulse: Bool = false        // fast pulsing (waiting)
    
    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    private let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()
    
    // MARK: - Color Palette
    private let furLight  = Color(red: 0.95, green: 0.65, blue: 0.35)
    private let furDark   = Color(red: 0.75, green: 0.45, blue: 0.20)
    private let furWhite  = Color(red: 0.98, green: 0.95, blue: 0.90)
    private let earPink   = Color(red: 1.0,  green: 0.75, blue: 0.70)
    private let noseBlack = Color(red: 0.15, green: 0.12, blue: 0.10)
    
    // MARK: - Body Parts (all facing RIGHT - flipped in render)
    
    // Idle/Sleeping/Waiting pose - lying down (same pose, different animations)
    private var idleBody: [(Int, Int, Color)] {
        let head: [(Int, Int, Color)] = [
            (2, 5, furDark),  (3, 5, furLight), (4, 5, furLight),
            (1, 6, furDark),  (2, 6, furLight), (3, 6, furLight), (4, 6, furLight), (5, 6, furDark),
            (1, 7, furLight), (2, 7, furLight), (3, 7, earPink),  (4, 7, furLight), (5, 7, furDark),
            (2, 8, furDark),  (3, 8, noseBlack),(4, 8, furLight), (5, 8, furDark),
            (3, 9, furDark),  (4, 9, furDark),  (5, 9, furDark),
        ]
        let body: [(Int, Int, Color)] = [
            (6, 6, furDark),  (7, 6, furLight), (8, 6, furLight), (9, 6, furDark),
            (6, 7, furLight), (7, 7, furWhite), (8, 7, furLight), (9, 7, furLight), (10, 7, furDark),
            (6, 8, furDark),  (7, 8, furWhite), (8, 8, furWhite), (9, 8, furLight), (10, 8, furDark),
            (7, 9, furDark),  (8, 9, furDark),  (9, 9, furDark),
        ]
        let paws: [(Int, Int, Color)] = [
            (3, 9, furWhite), (4, 9, furWhite), (5, 9, furDark),
            (3, 10, furDark), (4, 10, furDark),
            (11, 9, furLight), (12, 9, furWhite),
            (11, 10, furDark), (12, 10, furDark),
        ]
        let tail: [(Int, Int, Color)] = [
            (13, 6, furDark), (14, 6, furLight),
            (14, 7, furDark),
        ]
        return head + body + paws + tail
    }
    
    // Running animation frames
    private var runningFrames: [[(Int, Int, Color)]] {
        [
            [
                (4, 5, furDark),  (5, 5, furLight), (6, 5, furLight),
                (3, 6, furDark),  (4, 6, furLight), (5, 6, earPink),  (6, 6, furLight), (7, 6, furDark),
                (3, 7, furLight), (4, 7, noseBlack),(5, 7, furLight), (6, 7, furLight), (7, 7, furDark),
                (4, 8, furDark),  (5, 8, furDark),  (6, 8, furDark),
                (7, 5, furDark),  (8, 5, furLight), (9, 5, furLight), (10, 5, furDark),
                (7, 6, furLight), (8, 6, furWhite), (9, 6, furLight), (10, 6, furDark),
                (8, 7, furDark),  (9, 7, furWhite), (10, 7, furLight), (11, 7, furDark),
                (9, 8, furDark),  (10, 8, furDark), (11, 8, furDark),
                (6, 9, furWhite), (7, 9, furDark),
                (7, 10, furDark), (8, 10, furDark),
                (10, 9, furLight), (11, 9, furDark),
                (12, 5, furDark), (13, 5, furLight), (14, 5, furLight),
                (13, 6, furDark),
            ],
            [
                (4, 6, furDark),  (5, 6, furLight), (6, 6, furLight),
                (3, 7, furDark),  (4, 7, furLight), (5, 7, earPink),  (6, 7, furLight), (7, 7, furDark),
                (3, 8, furLight), (4, 8, noseBlack),(5, 8, furLight), (6, 8, furLight), (7, 8, furDark),
                (4, 9, furDark),  (5, 9, furDark),  (6, 9, furDark),
                (7, 6, furDark),  (8, 6, furLight), (9, 6, furLight), (10, 6, furDark),
                (7, 7, furLight), (8, 7, furWhite), (9, 7, furLight), (10, 7, furDark),
                (8, 8, furDark),  (9, 8, furWhite), (10, 8, furLight), (11, 8, furDark),
                (9, 9, furDark),  (10, 9, furDark), (11, 9, furDark),
                (5, 9, furLight), (6, 9, furDark),
                (8, 10, furWhite), (9, 10, furDark),
                (9, 11, furDark),
                (10, 10, furLight), (11, 10, furDark),
                (12, 10, furWhite), (13, 10, furDark),
                (12, 6, furDark), (13, 6, furLight),
                (12, 7, furLight), (13, 7, furDark),
            ],
            [
                (4, 5, furDark),  (5, 5, furLight), (6, 5, furLight),
                (3, 6, furDark),  (4, 6, furLight), (5, 6, earPink),  (6, 6, furLight), (7, 6, furDark),
                (3, 7, furLight), (4, 7, noseBlack),(5, 7, furLight), (6, 7, furLight), (7, 7, furDark),
                (4, 8, furDark),  (5, 8, furDark),  (6, 8, furDark),
                (7, 4, furDark),  (8, 4, furLight), (9, 4, furLight), (10, 4, furDark),
                (7, 5, furLight), (8, 5, furWhite), (9, 5, furLight), (10, 5, furDark),
                (8, 6, furDark),  (9, 6, furWhite), (10, 6, furLight), (11, 6, furDark),
                (9, 7, furDark),  (10, 7, furDark), (11, 7, furDark),
                (5, 7, furWhite), (6, 7, furDark),
                (10, 7, furLight), (11, 7, furDark),
                (11, 8, furDark),
                (12, 3, furLight), (13, 3, furLight),
                (12, 4, furDark),
            ],
            [
                (4, 6, furDark),  (5, 6, furLight), (6, 6, furLight),
                (3, 7, furDark),  (4, 7, furLight), (5, 7, earPink),  (6, 7, furLight), (7, 7, furDark),
                (3, 8, furLight), (4, 8, noseBlack),(5, 8, furLight), (6, 8, furLight), (7, 8, furDark),
                (4, 9, furDark),  (5, 9, furDark),  (6, 9, furDark),
                (7, 6, furDark),  (8, 6, furLight), (9, 6, furLight), (10, 6, furDark),
                (7, 7, furLight), (8, 7, furWhite), (9, 7, furLight), (10, 7, furDark),
                (8, 8, furDark),  (9, 8, furWhite), (10, 8, furLight), (11, 8, furDark),
                (9, 9, furDark),  (10, 9, furDark), (11, 9, furDark),
                (6, 9, furWhite), (7, 9, furDark),
                (10, 9, furLight), (11, 9, furDark),
                (7, 10, furDark),
                (11, 10, furDark),
                (12, 5, furDark), (13, 5, furLight), (14, 5, furDark),
            ],
        ]
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0
            guard scale > 0 else { return }
            
            // Flip horizontally so dog faces RIGHT
            let pixels = animate 
                ? runningFrames[animationPhase % runningFrames.count]
                : idleBody
            
            for p in pixels {
                let flippedX = 15 - p.0
                let rect = CGRect(
                    x: CGFloat(flippedX) * scale,
                    y: CGFloat(p.1) * scale,
                    width: max(1, scale),
                    height: max(1, scale)
                )
                context.fill(Path(rect), with: .color(p.2))
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(scale)
        .opacity(breatheOpacity)
        // Combined animations: scale + opacity for more expressive states
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: scale)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: breatheOpacity)
        .onReceive(timer) { _ in
            if animate {
                animationPhase += 1
            }
        }
        .onAppear {
            updateAnimationState()
        }
        .onChange(of: breathe) { _, _ in updateAnimationState() }
        .onChange(of: pulse) { _, _ in updateAnimationState() }
    }
    
    private func updateAnimationState() {
        if breathe {
            // Sleeping: gentle scale breathing + slight dim
            scale = 0.92
            breatheOpacity = 0.85
        } else if pulse {
            // Waiting: more noticeable scale pulse
            scale = 0.88
            breatheOpacity = 1.0
        } else {
            // Idle or Running: normal
            scale = 1.0
            breatheOpacity = 1.0
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        VStack(spacing: 10) {
            Text("Idle").font(.caption).foregroundColor(.white)
            DogIcon(size: 36, color: .white, animate: false, breathe: false, pulse: false)
        }
        VStack(spacing: 10) {
            Text("Sleeping").font(.caption).foregroundColor(.white)
            DogIcon(size: 36, color: .white, animate: false, breathe: true, pulse: false)
        }
        VStack(spacing: 10) {
            Text("Running").font(.caption).foregroundColor(.white)
            DogIcon(size: 36, color: .white, animate: true, breathe: false, pulse: false)
        }
        VStack(spacing: 10) {
            Text("Waiting").font(.caption).foregroundColor(.white)
            DogIcon(size: 36, color: .white, animate: false, breathe: false, pulse: true)
        }
    }
    .padding(40)
    .background(.black)
}
