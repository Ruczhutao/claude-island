//
//  ClaudeIcon.swift
//  ClaudeIsland
//
//  Animated pixel art Claude icon for Notch display
//  Based on Claude logo: pixel crab with claws
//

import Combine
import SwiftUI

struct ClaudeIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false
    
    @State private var animationPhase: Int = 0
    
    // Animation timer
    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    // Claude logo: pixel crab with body, eyes, claws and legs
    // 16x16 pixel grid
    
    // Main body (large rectangle)
    private let bodyPixels: [(Int, Int)] = [
        // Main body block
        (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3),
        (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4),
        (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5), (11, 5),
        (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6),
        (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7),
        (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8),
        (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9),
        (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10),
    ]
    
    // Eyes (two small squares on top)
    private let eyes: [(Int, Int)] = [
        (5, 2), (6, 2),
        (9, 2), (10, 2),
    ]
    
    // Left claw (extends left with pincers)
    private let leftClaw: [(Int, Int)] = [
        (2, 5), (3, 5),
        (1, 6), (2, 6), (3, 6),
        (1, 7), (2, 7),
    ]
    
    // Right claw (extends right with pincers)
    private let rightClaw: [(Int, Int)] = [
        (12, 5), (13, 5),
        (12, 6), (13, 6), (14, 6),
        (13, 7), (14, 7),
    ]
    
    // Left legs
    private let leftLegs: [(Int, Int)] = [
        (2, 8), (3, 8),
        (2, 9), (3, 9),
        (3, 10), (3, 11),
    ]
    
    // Right legs
    private let rightLegs: [(Int, Int)] = [
        (12, 8), (13, 8),
        (12, 9), (13, 9),
        (12, 10), (12, 11),
    ]
    
    // Animation: body pulse
    private let pulseOffsets: [[CGFloat]] = [
        [1.0],      // Normal
        [1.05],     // Expanded
        [1.0],      // Normal
        [0.95],     // Contracted
    ]
    
    // Animation: claw wiggle
    private let clawWiggle: [[(dx: Int, dy: Int)]] = [
        [(0, 0)],      // Neutral
        [(0, -1)],     // Up
        [(0, 0)],      // Neutral
        [(0, 1)],      // Down
    ]
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0  // Base grid is 16x16
            
            // Get current animation state
            let pulseScale = animate ? pulseOffsets[animationPhase % pulseOffsets.count][0] : 1.0
            let clawOffset = animate ? clawWiggle[animationPhase % clawWiggle.count] : [(0, 0)]
            
            // Calculate center for scaling
            let centerX = 8.0 * scale
            let centerY = 6.5 * scale
            
            // Draw body with pulse animation
            let bodyScale = scale * pulseScale
            let bodyOffsetX = centerX - (8.0 * bodyScale)
            let bodyOffsetY = centerY - (6.5 * bodyScale)
            
            for pixel in bodyPixels {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * bodyScale + bodyOffsetX,
                    y: CGFloat(pixel.1) * bodyScale + bodyOffsetY,
                    width: bodyScale,
                    height: bodyScale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw eyes (black, fixed position)
            for pixel in eyes {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(Color.black.opacity(0.7)))
            }
            
            // Draw left claw with wiggle
            for pixel in leftClaw {
                let rect = CGRect(
                    x: CGFloat(pixel.0 + clawOffset[0].dx) * scale,
                    y: CGFloat(pixel.1 + clawOffset[0].dy) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw right claw with wiggle (opposite direction)
            for pixel in rightClaw {
                let rect = CGRect(
                    x: CGFloat(pixel.0 - clawOffset[0].dx) * scale,
                    y: CGFloat(pixel.1 + clawOffset[0].dy) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw left legs
            for pixel in leftLegs {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw right legs
            for pixel in rightLegs {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
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
        ClaudeIcon(size: 18, color: Color(red: 0.85, green: 0.47, blue: 0.34), animate: false)
        ClaudeIcon(size: 18, color: Color(red: 0.85, green: 0.47, blue: 0.34), animate: true)
    }
    .padding()
    .background(.black)
}
