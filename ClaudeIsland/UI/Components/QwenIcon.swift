//
//  QwenIcon.swift
//  ClaudeIsland
//
//  Animated pixel art Qwen icon for Notch display
//  Based on Qwen logo: six-pointed starburst with colorful gradient petals
//

import Combine
import SwiftUI

struct QwenIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false      // Running - 花瓣旋转动画
    var breathe: Bool = false      // Sleeping - 呼吸缩放动画
    var pulse: Bool = false        // Waiting - 脉冲闪烁动画

    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0
    @State private var scale: CGFloat = 1.0

    // Timer for animation (12fps for smooth rotation)
    private let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    // MARK: - Color Palette (from Qwen logo gradient)

    private let petalTop       = Color(red: 0.55, green: 0.36, blue: 0.96)  // 紫罗兰 #8B5CF6
    private let petalTopRight  = Color(red: 0.66, green: 0.33, blue: 0.97)  // 粉紫   #A855F7
    private let petalBottomRight = Color(red: 0.93, green: 0.28, blue: 0.60) // 玫红   #EC4899
    private let petalBottom    = Color(red: 0.98, green: 0.45, blue: 0.09)  // 橙红   #F97316
    private let petalBottomLeft = Color(red: 0.98, green: 0.44, blue: 0.52) // 橙粉   #FB7185
    private let petalTopLeft   = Color(red: 0.49, green: 0.23, blue: 0.93)  // 紫色   #7C3AED
    private let centerWhite    = Color.white

    // MARK: - Pixel Layout: 6-Petal Starburst (16x16 grid)

    // 6 petals around center, each with 3 layers: tip, body, base
    // Petal directions: Top, Top-Right, Bottom-Right, Bottom, Bottom-Left, Top-Left

    private var idlePetals: [(Int, Int, Color)] {
        var pixels: [(Int, Int, Color)] = []

        // ===== Petal 1: Top (紫罗兰) =====
        // Tip
        pixels += [(7, 0, petalTop), (8, 0, petalTop)]
        // Body
        pixels += [(6, 1, petalTop), (7, 1, petalTop), (8, 1, petalTop), (9, 1, petalTop)]
        pixels += [(6, 2, petalTop), (7, 2, petalTop), (8, 2, petalTop), (9, 2, petalTop)]
        // Base
        pixels += [(5, 3, petalTop), (6, 3, petalTop), (7, 3, petalTop), (8, 3, petalTop), (9, 3, petalTop), (10, 3, petalTop)]

        // ===== Petal 2: Top-Right (粉紫) =====
        // Tip
        pixels += [(14, 5, petalTopRight), (15, 5, petalTopRight)]
        // Body
        pixels += [(13, 5, petalTopRight), (12, 6, petalTopRight), (13, 6, petalTopRight), (14, 6, petalTopRight)]
        pixels += [(13, 7, petalTopRight), (14, 7, petalTopRight)]
        // Base
        pixels += [(10, 5, petalTopRight), (11, 5, petalTopRight), (11, 6, petalTopRight)]
        pixels += [(10, 7, petalTopRight), (11, 7, petalTopRight)]
        pixels += [(10, 8, petalTopRight), (11, 8, petalTopRight)]

        // ===== Petal 3: Bottom-Right (玫红) =====
        // Tip
        pixels += [(14, 11, petalBottomRight), (15, 11, petalBottomRight)]
        // Body
        pixels += [(13, 10, petalBottomRight), (14, 10, petalBottomRight)]
        pixels += [(13, 9, petalBottomRight), (14, 9, petalBottomRight)]
        pixels += [(12, 9, petalBottomRight), (13, 9, petalBottomRight)]
        // Base
        pixels += [(10, 9, petalBottomRight), (11, 9, petalBottomRight)]
        pixels += [(10, 10, petalBottomRight), (11, 10, petalBottomRight)]
        pixels += [(10, 8, petalBottomRight), (11, 8, petalBottomRight)]

        // ===== Petal 4: Bottom (橙红) =====
        // Tip
        pixels += [(7, 15, petalBottom), (8, 15, petalBottom)]
        // Body
        pixels += [(6, 14, petalBottom), (7, 14, petalBottom), (8, 14, petalBottom), (9, 14, petalBottom)]
        pixels += [(6, 13, petalBottom), (7, 13, petalBottom), (8, 13, petalBottom), (9, 13, petalBottom)]
        // Base
        pixels += [(5, 12, petalBottom), (6, 12, petalBottom), (7, 12, petalBottom), (8, 12, petalBottom), (9, 12, petalBottom), (10, 12, petalBottom)]

        // ===== Petal 5: Bottom-Left (橙粉) =====
        // Tip
        pixels += [(0, 11, petalBottomLeft), (1, 11, petalBottomLeft)]
        // Body
        pixels += [(2, 10, petalBottomLeft), (3, 10, petalBottomLeft)]
        pixels += [(2, 9, petalBottomLeft), (3, 9, petalBottomLeft)]
        pixels += [(3, 9, petalBottomLeft), (4, 9, petalBottomLeft)]
        // Base
        pixels += [(4, 9, petalBottomLeft), (5, 9, petalBottomLeft)]
        pixels += [(4, 10, petalBottomLeft), (5, 10, petalBottomLeft)]
        pixels += [(4, 8, petalBottomLeft), (5, 8, petalBottomLeft)]

        // ===== Petal 6: Top-Left (紫色) =====
        // Tip
        pixels += [(0, 5, petalTopLeft), (1, 5, petalTopLeft)]
        // Body
        pixels += [(2, 6, petalTopLeft), (3, 6, petalTopLeft)]
        pixels += [(2, 7, petalTopLeft), (3, 7, petalTopLeft)]
        pixels += [(3, 7, petalTopLeft), (4, 7, petalTopLeft)]
        // Base
        pixels += [(4, 5, petalTopLeft), (5, 5, petalTopLeft)]
        pixels += [(4, 6, petalTopLeft), (5, 6, petalTopLeft)]
        pixels += [(4, 8, petalTopLeft), (5, 8, petalTopLeft)]

        // ===== Center (白色亮点) =====
        pixels += [(7, 6, centerWhite), (8, 6, centerWhite)]
        pixels += [(7, 7, centerWhite), (8, 7, centerWhite)]
        pixels += [(7, 8, centerWhite), (8, 8, centerWhite)]
        pixels += [(7, 9, centerWhite), (8, 9, centerWhite)]

        // ===== Inner ring (连接花瓣，较浅色) =====
        // Top inner
        pixels += [(7, 3, petalTop.opacity(0.7)), (8, 3, petalTop.opacity(0.7))]
        // Top-Right inner
        pixels += [(9, 5, petalTopRight.opacity(0.7)), (9, 6, petalTopRight.opacity(0.7)), (9, 7, petalTopRight.opacity(0.7))]
        // Bottom-Right inner
        pixels += [(9, 9, petalBottomRight.opacity(0.7)), (9, 10, petalBottomRight.opacity(0.7))]
        // Bottom inner
        pixels += [(7, 12, petalBottom.opacity(0.7)), (8, 12, petalBottom.opacity(0.7))]
        // Bottom-Left inner
        pixels += [(6, 10, petalBottomLeft.opacity(0.7)), (6, 9, petalBottomLeft.opacity(0.7))]
        // Top-Left inner
        pixels += [(6, 7, petalTopLeft.opacity(0.7)), (6, 6, petalTopLeft.opacity(0.7))]

        return pixels
    }

    // Running animation frames - petals rotate clockwise
    private var runningFrames: [[(Int, Int, Color)]] {
        // 6 frames: one bright highlight per petal for a full clockwise loop
        var frames: [[(Int, Int, Color)]] = []

        let brightPetals = [
            [(7, 0), (8, 0), (7, 1), (8, 1)],              // Top
            [(14, 5), (15, 5), (13, 5), (14, 6)],          // Top-Right
            [(14, 11), (15, 11), (13, 10), (14, 10)],      // Bottom-Right
            [(7, 15), (8, 15), (7, 14), (8, 14)],          // Bottom
            [(0, 11), (1, 11), (2, 10), (3, 10)],          // Bottom-Left
            [(0, 5), (1, 5), (2, 6), (3, 6)],              // Top-Left
        ]

        for highlightPetals in brightPetals {
            var framePixels: [(Int, Int, Color)] = []

            // Base shape always present
            framePixels += idlePetals

            // Add bright overlay
            for pixel in highlightPetals {
                framePixels.append((pixel.0, pixel.1, .white.opacity(0.8)))
            }

            frames.append(framePixels)
        }

        return frames
    }

    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0
            guard scale > 0 else { return }

            // Get current pixel data
            let pixels: [(Int, Int, Color)]
            if animate {
                pixels = runningFrames[animationPhase % runningFrames.count]
            } else {
                pixels = idlePetals
            }

            // Draw all pixels
            for p in pixels {
                let rect = CGRect(
                    x: CGFloat(p.0) * scale,
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
        // Combined animations: scale + opacity for expressive states
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
            QwenIcon(size: 36, color: .white, animate: false, breathe: false, pulse: false)
        }
        VStack(spacing: 10) {
            Text("Sleeping").font(.caption).foregroundColor(.white)
            QwenIcon(size: 36, color: .white, animate: false, breathe: true, pulse: false)
        }
        VStack(spacing: 10) {
            Text("Running").font(.caption).foregroundColor(.white)
            QwenIcon(size: 36, color: .white, animate: true, breathe: false, pulse: false)
        }
        VStack(spacing: 10) {
            Text("Waiting").font(.caption).foregroundColor(.white)
            QwenIcon(size: 36, color: .white, animate: false, breathe: false, pulse: true)
        }
    }
    .padding(40)
    .background(.black)
}
