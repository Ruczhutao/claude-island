//
//  CodexIcon.swift
//  ClaudeIsland
//
//  Animated pixel art Codex icon for Notch display
//  Based on Codex logo: cloud shape with terminal prompt (>_)
//

import Combine
import SwiftUI

struct CodexIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false
    
    @State private var animationPhase: Int = 0
    
    // Animation timer
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    // Codex logo: cloud/flower shape with terminal prompt
    // 16x16 pixel grid - simplified pixel art version
    
    // Cloud outline (rounded flower shape)
    private let cloudPixels: [(Int, Int)] = [
        // Top petals
        (5, 1), (6, 1), (7, 1), (8, 1), (9, 1), (10, 1),
        (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2), (11, 2), (12, 2),
        // Upper sides
        (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3), (12, 3), (13, 3),
        (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4), (12, 4), (13, 4), (14, 4),
        // Middle body
        (1, 5), (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5), (11, 5), (12, 5), (13, 5), (14, 5),
        (1, 6), (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6), (12, 6), (13, 6), (14, 6),
        (1, 7), (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7), (13, 7), (14, 7),
        (1, 8), (2, 8), (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8), (12, 8), (13, 8), (14, 8),
        (1, 9), (2, 9), (3, 9), (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9), (12, 9), (13, 9), (14, 9),
        (1, 10), (2, 10), (3, 10), (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10), (12, 10), (13, 10), (14, 10),
        // Lower sides
        (2, 11), (3, 11), (4, 11), (5, 11), (6, 11), (7, 11), (8, 11), (9, 11), (10, 11), (11, 11), (12, 11), (13, 11),
        (3, 12), (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12), (10, 12), (11, 12), (12, 12),
        // Bottom petal
        (5, 13), (6, 13), (7, 13), (8, 13), (9, 13), (10, 13),
    ]
    
    // Terminal prompt: > symbol
    private let promptArrow: [(Int, Int)] = [
        (4, 5),
        (4, 6), (5, 6),
        (4, 7), (5, 7), (6, 7),
        (4, 8), (5, 8),
        (4, 9),
    ]
    
    // Terminal prompt: _ symbol (cursor)
    private let promptCursor: [(Int, Int)] = [
        (8, 9), (9, 9), (10, 9),
    ]
    
    // Animation: bounce offsets
    private let bounceOffsets: [[(dx: Int, dy: Int)]] = [
        [(0, 0)],      // Neutral
        [(0, -1)],     // Up
        [(0, 0)],      // Neutral
        [(0, 1)],      // Down
    ]
    
    // Animation: cursor blink states
    private let cursorStates: [[(Int, Int)]] = [
        [(8, 9), (9, 9), (10, 9)],  // Visible
        [],                          // Hidden (blink)
    ]
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0  // Base grid is 16x16
            
            // Get current animation state
            let bounceOffset = animate ? bounceOffsets[animationPhase % bounceOffsets.count] : [(0, 0)]
            let isCursorVisible = !animate || (animationPhase % 4 != 0)  // Blink cursor every 4 frames
            
            // Draw cloud shape with bounce animation
            for pixel in cloudPixels {
                let rect = CGRect(
                    x: CGFloat(pixel.0 + bounceOffset[0].dx) * scale,
                    y: CGFloat(pixel.1 + bounceOffset[0].dy) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw prompt arrow (>)
            for pixel in promptArrow {
                let rect = CGRect(
                    x: CGFloat(pixel.0 + bounceOffset[0].dx) * scale,
                    y: CGFloat(pixel.1 + bounceOffset[0].dy) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(Color.white))
            }
            
            // Draw cursor (_) with blink
            if isCursorVisible {
                for pixel in promptCursor {
                    let rect = CGRect(
                        x: CGFloat(pixel.0 + bounceOffset[0].dx) * scale,
                        y: CGFloat(pixel.1 + bounceOffset[0].dy) * scale,
                        width: scale,
                        height: scale
                    )
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
        CodexIcon(size: 18, color: Color(red: 0.2, green: 0.6, blue: 1.0), animate: false)
        CodexIcon(size: 18, color: Color(red: 0.2, green: 0.6, blue: 1.0), animate: true)
    }
    .padding()
    .background(.black)
}
