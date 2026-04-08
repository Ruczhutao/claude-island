//
//  GeminiIcon.swift
//  ClaudeIsland
//
//  Animated pixel art Gemini icon for Notch display
//  Based on Gemini logo: star/diamond shape with sparkle
//

import Combine
import SwiftUI

struct GeminiIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false
    
    @State private var animationPhase: Int = 0
    
    // Animation timer
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    // Gemini logo: diamond/star shape with gradient sparkle effect
    // 16x16 pixel grid - simplified pixel art version
    
    // Main diamond shape
    private let diamondPixels: [(Int, Int)] = [
        // Top point
        (8, 0),
        // Upper diamond
        (7, 1), (8, 1), (9, 1),
        (6, 2), (7, 2), (8, 2), (9, 2), (10, 2),
        (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3),
        // Middle wide section
        (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4), (12, 4),
        (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5), (11, 5), (12, 5), (13, 5),
        (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6), (12, 6), (13, 6), (14, 6),
        // Center
        (1, 7), (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7), (13, 7), (14, 7), (15, 7),
        (0, 8), (1, 8), (2, 8), (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8), (12, 8), (13, 8), (14, 8), (15, 8),
        (1, 9), (2, 9), (3, 9), (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9), (12, 9), (13, 9), (14, 9), (15, 9),
        // Lower diamond
        (2, 10), (3, 10), (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10), (12, 10), (13, 10), (14, 10),
        (3, 11), (4, 11), (5, 11), (6, 11), (7, 11), (8, 11), (9, 11), (10, 11), (11, 11), (12, 11), (13, 11),
        (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12), (10, 12), (11, 12), (12, 12),
        (5, 13), (6, 13), (7, 13), (8, 13), (9, 13), (10, 13), (11, 13),
        (6, 14), (7, 14), (8, 14), (9, 14), (10, 14),
        // Bottom point
        (7, 15), (8, 15), (9, 15),
    ]
    
    // Sparkle pixels (animated)
    private let sparklePixels: [(Int, Int)] = [
        (2, 2), (13, 3), (3, 12), (12, 13),
    ]
    
    // Animation: sparkle twinkle
    private let twinklePattern: [[Bool]] = [
        [true, false, true, false],
        [false, true, false, true],
        [true, false, true, false],
        [false, true, false, true],
    ]
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0  // Base grid is 16x16
            
            // Get current animation state
            let sparklesVisible = animate ? twinklePattern[animationPhase % twinklePattern.count] : [true, true, true, true]
            
            // Draw main diamond shape
            for pixel in diamondPixels {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw sparkle pixels with animation
            for (index, pixel) in sparklePixels.enumerated() {
                let shouldShow = sparklesVisible[index % sparklesVisible.count]
                if shouldShow {
                    let rect = CGRect(
                        x: CGFloat(pixel.0) * scale,
                        y: CGFloat(pixel.1) * scale,
                        width: scale,
                        height: scale
                    )
                    // Sparkles are brighter
                    context.fill(Path(rect), with: .color(Color.white))
                }
            }
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            if animate {
                animationPhase = (animationPhase + 1) % 16
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        GeminiIcon(size: 18, color: Color(red: 0.4, green: 0.4, blue: 1.0), animate: false)
        GeminiIcon(size: 18, color: Color(red: 0.4, green: 0.4, blue: 1.0), animate: true)
    }
    .padding()
    .background(.black)
}
