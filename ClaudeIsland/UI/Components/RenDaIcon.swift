//
//  RenDaIcon.swift
//  ClaudeIsland
//
//  Renmin University "Three People" pixel art icon
//  Three flowing calligraphic "人" characters
//

import Combine
import SwiftUI

struct RenDaIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false
    
    @State private var animationPhase: Int = 0
    private let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    // Three "人" characters - each is a single flowing stroke
    // Like calligraphy brush strokes, wider at top, tapering at bottom
    
    // Left "人" - starts center-left, curves up and left
    private let leftPerson: [(Int, Int)] = [
        // Top - wide and sweeping left
        (5, 0), (6, 0),
        (4, 1), (5, 1), (6, 1),
        (3, 2), (4, 2), (5, 2), (6, 2),
        // Upper body - maintaining width
        (3, 3), (4, 3), (5, 3),
        (3, 4), (4, 4), (5, 4),
        // Mid body - tapering
        (3, 5), (4, 5),
        (2, 6), (3, 6), (4, 6),
        (2, 7), (3, 7),
        // Lower - narrow
        (2, 8), (3, 8),
        (2, 9),
        (1, 10), (2, 10),
        (1, 11),
    ]
    
    // Center "人" - tallest, straight, commanding presence
    private let centerPerson: [(Int, Int)] = [
        // Top - widest point
        (8, 0), (9, 0),
        (7, 1), (8, 1), (9, 1), (10, 1),
        (7, 2), (8, 2), (9, 2), (10, 2),
        // Strong vertical body
        (8, 3), (9, 3),
        (8, 4), (9, 4),
        (8, 5), (9, 5),
        (8, 6), (9, 6),
        (8, 7), (9, 7),
        (8, 8), (9, 8),
        (8, 9), (9, 9),
        (8, 10), (9, 10),
        (8, 11), (9, 11),
        (8, 12),
    ]
    
    // Right "人" - mirror of left
    private let rightPerson: [(Int, Int)] = [
        // Top - wide and sweeping right
        (11, 0), (12, 0),
        (11, 1), (12, 1), (13, 1),
        (11, 2), (12, 2), (13, 2), (14, 2),
        // Upper body
        (11, 3), (12, 3), (13, 3),
        (11, 4), (12, 4), (13, 4),
        // Mid body - tapering
        (12, 5), (13, 5),
        (12, 6), (13, 6), (14, 6),
        (13, 7), (14, 7),
        // Lower - narrow
        (13, 8), (14, 8),
        (14, 9),
        (14, 10), (15, 10),
        (15, 11),
    ]
    
    // Gentle breathing - characters spread and come together
    private func getOffset(for phase: Int, side: String) -> Int {
        let cycle = phase % 10
        switch side {
        case "left":
            return [-1, -1, 0, 0, 0, 0, 0, -1, -1, -1][cycle] ?? 0
        case "right":
            return [1, 1, 0, 0, 0, 0, 0, 1, 1, 1][cycle] ?? 0
        default:
            return 0
        }
    }
    
    var body: some View {
        Canvas { context, _ in
            let scale = size / 16.0
            let offset = animate ? animationPhase : 0
            
            // Draw left person
            for p in leftPerson {
                let rect = CGRect(
                    x: CGFloat(p.0 + getOffset(for: offset, side: "left")) * scale,
                    y: CGFloat(p.1) * scale,
                    width: scale, height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw center (fixed)
            for p in centerPerson {
                let rect = CGRect(
                    x: CGFloat(p.0) * scale,
                    y: CGFloat(p.1) * scale,
                    width: scale, height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw right person
            for p in rightPerson {
                let rect = CGRect(
                    x: CGFloat(p.0 + getOffset(for: offset, side: "right")) * scale,
                    y: CGFloat(p.1) * scale,
                    width: scale, height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            if animate { animationPhase = (animationPhase + 1) % 20 }
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        VStack {
            Text("静止").font(.caption).foregroundColor(.white)
            RenDaIcon(size: 40, color: Color(red: 0.75, green: 0.15, blue: 0.15), animate: false)
        }
        VStack {
            Text("呼吸").font(.caption).foregroundColor(.white)
            RenDaIcon(size: 40, color: Color(red: 0.75, green: 0.15, blue: 0.15), animate: true)
        }
    }
    .padding(40)
    .background(.black)
}
