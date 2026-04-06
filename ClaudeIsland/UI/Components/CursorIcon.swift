//
//  CursorIcon.swift
//  ClaudeIsland
//
//  Animated pixel art Cursor icon for Notch display
//  Based on Cursor logo: hexagonal diamond with 3D cube effect
//

import Combine
import SwiftUI

struct CursorIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false
    
    @State private var animationPhase: Int = 0
    
    // Animation timer - faster for sparkle effect
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    
    // Cursor logo: hexagonal diamond shape (pixel art version)
    // 16x16 pixel grid
    
    // Main hexagon outline
    private let hexagonPixels: [(Int, Int)] = [
        // Top point
        (7, 0), (8, 0),
        (6, 1), (7, 1), (8, 1), (9, 1),
        (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2),
        (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3), (11, 3),
        (3, 4), (4, 4), (5, 4), (6, 4), (7, 4), (8, 4), (9, 4), (10, 4), (11, 4), (12, 4),
        (2, 5), (3, 5), (4, 5), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (10, 5), (11, 5), (12, 5), (13, 5),
        (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6), (12, 6), (13, 6),
        (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7), (13, 7),
        (2, 8), (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8), (12, 8), (13, 8),
        (2, 9), (3, 9), (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9), (12, 9), (13, 9),
        (2, 10), (3, 10), (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10), (10, 10), (11, 10), (12, 10), (13, 10),
        (3, 11), (4, 11), (5, 11), (6, 11), (7, 11), (8, 11), (9, 11), (10, 11), (11, 11), (12, 11),
        (4, 12), (5, 12), (6, 12), (7, 12), (8, 12), (9, 12), (10, 12), (11, 12),
        (5, 13), (6, 13), (7, 13), (8, 13), (9, 13), (10, 13),
        (6, 14), (7, 14), (8, 14), (9, 14),
        (7, 15), (8, 15),
    ]
    
    // Inner 3D cube effect - left face (darker)
    private let cubeLeftPixels: [(Int, Int)] = [
        (4, 5), (5, 5),
        (3, 6), (4, 6), (5, 6), (6, 6),
        (3, 7), (4, 7), (5, 7), (6, 7), (7, 7),
        (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8),
        (3, 9), (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9),
        (4, 10), (5, 10), (6, 10), (7, 10), (8, 10), (9, 10),
        (5, 11), (6, 11), (7, 11), (8, 11),
    ]
    
    // Inner 3D cube effect - right face (lighter)
    private let cubeRightPixels: [(Int, Int)] = [
        (8, 5), (9, 5),
        (7, 6), (8, 6), (9, 6), (10, 6),
        (8, 7), (9, 7), (10, 7), (11, 7),
        (9, 8), (10, 8), (11, 8), (12, 8),
        (10, 9), (11, 9), (12, 9), (13, 9),
        (10, 10), (11, 10), (12, 10), (13, 10),
        (9, 11), (10, 11), (11, 11), (12, 11),
    ]
    
    // Sparkle pixels for animation (strategic positions on the hexagon)
    private let sparklePixels: [(Int, Int)] = [
        (7, 1), (8, 1),
        (5, 3), (10, 3),
        (2, 6), (13, 6),
        (2, 9), (13, 9),
        (7, 14), (8, 14),
    ]
    
    // Animation phases for sparkle effect
    // IMPORTANT: Must have same count as sparklePixels (10 elements)
    private let sparklePhases: [[Bool]] = [
        [true, false, true, false, true, false, true, false, true, false],   // Phase 0
        [false, true, false, true, false, true, false, true, false, true],   // Phase 1
        [true, true, false, false, true, true, false, false, true, true],    // Phase 2
        [false, false, true, true, false, false, true, true, false, false],  // Phase 3
        [true, false, false, true, true, false, false, true, true, false],   // Phase 4
        [false, true, true, false, false, true, true, false, false, true],   // Phase 5
    ]
    
    var body: some View {
        Canvas { context, canvasSize in
            // Safety check for size
            guard size > 0 else { return }
            
            let scale = size / 16.0  // Base grid is 16x16
            
            // Safety check for scale
            guard scale > 0 else { return }
            
            // Get current sparkle state
            let currentSparkles = animate ? sparklePhases[animationPhase % sparklePhases.count] : Array(repeating: false, count: sparklePixels.count)
            
            // Draw main hexagon outline (bright white)
            for pixel in hexagonPixels {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1) * scale,
                    width: max(1, scale),  // Ensure minimum width of 1
                    height: max(1, scale)  // Ensure minimum height of 1
                )
                
                // Check if this pixel should sparkle
                var isSparkle = false
                if let sparkleIndex = sparklePixels.firstIndex(where: { $0 == pixel }) {
                    // Safety check for array bounds
                    if sparkleIndex < currentSparkles.count {
                        isSparkle = currentSparkles[sparkleIndex]
                    }
                }
                
                if isSparkle && animate {
                    // Sparkle effect - brighter white
                    context.fill(Path(rect), with: .color(Color.white))
                } else {
                    // Normal hexagon color
                    context.fill(Path(rect), with: .color(color))
                }
            }
            
            // Draw left face (darker gray for 3D effect)
            for pixel in cubeLeftPixels {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1) * scale,
                    width: max(1, scale),
                    height: max(1, scale)
                )
                context.fill(Path(rect), with: .color(Color.gray.opacity(0.4)))
            }
            
            // Draw right face (lighter gray for 3D effect)
            for pixel in cubeRightPixels {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1) * scale,
                    width: max(1, scale),
                    height: max(1, scale)
                )
                context.fill(Path(rect), with: .color(Color.white.opacity(0.6)))
            }
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            if animate {
                animationPhase = (animationPhase + 1) % sparklePhases.count
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        VStack(spacing: 10) {
            Text("静止")
                .font(.caption)
                .foregroundColor(.white)
            CursorIcon(size: 26, color: Color.white, animate: false)
        }
        VStack(spacing: 10) {
            Text("闪烁")
                .font(.caption)
                .foregroundColor(.white)
            CursorIcon(size: 26, color: Color.white, animate: true)
        }
    }
    .padding(40)
    .background(.black)
}
