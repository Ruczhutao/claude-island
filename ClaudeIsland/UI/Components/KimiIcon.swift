//
//  KimiIcon.swift
//  ClaudeIsland
//
//  Animated pixel art Kimi icon for Notch display
//  Based on Kimi logo: blue square with two eyes
//

import Combine
import SwiftUI

struct KimiIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false
    
    @State private var animationPhase: Int = 0
    
    // Animation timer
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    // Kimi logo: blue rounded square with two eyes
    // 16x16 pixel grid - simplified pixel art version
    
    // Main face (rounded square) - filled area
    private let facePixels: [(Int, Int)] = [
        // Top rounded corners
        (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2), (11, 2), (12, 2),
        // Full body rows
        (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3), (12, 3), (13, 3),
        (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4), (12, 4), (13, 4),
        (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5), (11, 5), (12, 5), (13, 5),
        (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6), (12, 6), (13, 6),
        (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7), (13, 7),
        (2, 8), (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8), (12, 8), (13, 8),
        (2, 9), (3, 9), (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9), (12, 9), (13, 9),
        (2, 10), (3, 10), (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10), (12, 10), (13, 10),
        (2, 11), (3, 11), (4, 11), (5, 11), (6, 11), (7, 11), (8, 11), (9, 11), (10, 11), (11, 11), (12, 11), (13, 11),
        // Bottom rounded corners
        (3, 12), (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12), (10, 12), (11, 12), (12, 12),
    ]
    
    // Eyes (two vertical rectangles) - animated for blinking
    private let eyesOpen: [(Int, Int)] = [
        // Left eye
        (5, 5), (5, 6), (5, 7),
        // Right eye
        (10, 5), (10, 6), (10, 7),
    ]
    
    private let eyesClosed: [(Int, Int)] = [
        // Left eye (single pixel when blinking)
        (5, 6),
        // Right eye (single pixel when blinking)
        (10, 6),
    ]
    
    // Animation: subtle face bounce
    private let bounceOffsets: [[(dx: Int, dy: Int)]] = [
        [(0, 0)],      // Neutral
        [(0, -1)],     // Up
        [(0, 0)],      // Neutral
        [(0, 1)],      // Down
    ]
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0  // Base grid is 16x16
            
            // Get current animation state
            let bounceOffset = animate ? bounceOffsets[animationPhase % bounceOffsets.count] : [(0, 0)]
            let isBlinking = animate && (animationPhase % 6 == 0)  // Blink every 6 frames
            
            // Draw face with bounce animation
            for pixel in facePixels {
                let rect = CGRect(
                    x: CGFloat(pixel.0 + bounceOffset[0].dx) * scale,
                    y: CGFloat(pixel.1 + bounceOffset[0].dy) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw eyes (open or closed based on blink)
            let eyePixels = isBlinking ? eyesClosed : eyesOpen
            for pixel in eyePixels {
                let rect = CGRect(
                    x: CGFloat(pixel.0 + bounceOffset[0].dx) * scale,
                    y: CGFloat(pixel.1 + bounceOffset[0].dy) * scale,
                    width: scale,
                    height: scale
                )
                // Eyes are dark (almost black)
                context.fill(Path(rect), with: .color(Color.black.opacity(0.8)))
            }
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            if animate {
                animationPhase = (animationPhase + 1) % 12
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        KimiIcon(size: 18, color: Color(red: 0.0, green: 0.5, blue: 1.0), animate: false)
        KimiIcon(size: 18, color: Color(red: 0.0, green: 0.5, blue: 1.0), animate: true)
    }
    .padding()
    .background(.black)
}
