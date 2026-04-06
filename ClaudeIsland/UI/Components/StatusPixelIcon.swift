//
//  StatusPixelIcon.swift
//  ClaudeIsland
//
//  Simplified status indicator - minimal and clear
//  Shows only essential states: ? ! ✓
//

import Combine
import SwiftUI

/// Simplified status icon - only shows non-idle states
/// - Idle: invisible (no icon)
/// - Running: "!" (exclamation) - processing
/// - Waiting: "?" (question) - needs approval
/// - Sleeping/Done: "✓" (checkmark) - completed
struct StatusPixelIcon: View {
    let status: DogStatus
    let size: CGFloat
    
    @State private var animationPhase: Int = 0
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    
    // Colors - high contrast against black notch
    private let amber    = Color(red: 1.0,  green: 0.75, blue: 0.0)   // Waiting - attention
    private let green    = Color(red: 0.3,  green: 0.9,  blue: 0.4)   // Done - success
    private let blue     = Color(red: 0.4,  green: 0.7,  blue: 1.0)   // Processing - active
    
    // Simple 3x5 pixel font for symbols
    
    // Exclamation mark (!) - Running state
    private var exclamationPixels: [(Int, Int)] {
        [
            (1, 0), (2, 0),
            (1, 1), (2, 1),
            (1, 2), (2, 2),
            (1, 3), (2, 3),
            (1, 5), (2, 5),
        ]
    }
    
    // Question mark (?) - Waiting state
    private var questionPixels: [(Int, Int)] {
        [
            (0, 0), (1, 0), (2, 0),
            (3, 1),
            (3, 2),
            (2, 3), (1, 4),
            (1, 6),
        ]
    }
    
    // Checkmark (✓) - Done/Sleeping state
    private var checkmarkPixels: [(Int, Int)] {
        [
            (0, 4),
            (1, 5),
            (2, 6), (3, 5), (4, 4), (5, 3), (6, 2),
        ]
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 8.0  // Smaller canvas for simple symbols
            guard scale > 0 else { return }
            
            switch status {
            case .idle:
                // No icon for idle state - completely invisible
                break
                
            case .running:
                // Pulsing blue exclamation
                let pulse = 0.4 + 0.6 * abs(sin(Double(animationPhase) * 0.4))
                let color = blue.opacity(pulse)
                
                // Draw glow
                for p in exclamationPixels {
                    let glowRect = CGRect(
                        x: CGFloat(p.0) * scale - scale/2,
                        y: CGFloat(p.1) * scale - scale/2,
                        width: scale * 2,
                        height: scale * 2
                    )
                    context.fill(Path(glowRect), with: .color(blue.opacity(0.3 * pulse)))
                }
                
                // Draw symbol
                for p in exclamationPixels {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale,
                        y: CGFloat(p.1) * scale,
                        width: max(1, scale),
                        height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(color))
                }
                
            case .waiting:
                // Fast pulsing amber question mark
                let pulse = 0.3 + 0.7 * abs(sin(Double(animationPhase) * 0.6))
                let color = amber.opacity(pulse)
                
                // Draw glow
                for p in questionPixels {
                    let glowRect = CGRect(
                        x: CGFloat(p.0) * scale - scale/2,
                        y: CGFloat(p.1) * scale - scale/2,
                        width: scale * 2,
                        height: scale * 2
                    )
                    context.fill(Path(glowRect), with: .color(amber.opacity(0.4 * pulse)))
                }
                
                // Draw symbol
                for p in questionPixels {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale,
                        y: CGFloat(p.1) * scale,
                        width: max(1, scale),
                        height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(color))
                }
                
            case .sleeping:
                // Steady green checkmark (slow fade)
                let fade = 0.7 + 0.3 * sin(Double(animationPhase) * 0.15)
                let color = green.opacity(fade)
                
                for p in checkmarkPixels {
                    let rect = CGRect(
                        x: CGFloat(p.0) * scale,
                        y: CGFloat(p.1) * scale,
                        width: max(1, scale),
                        height: max(1, scale)
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            animationPhase += 1
        }
    }
}

#Preview {
    HStack(spacing: 30) {
        VStack(spacing: 10) {
            Text("Idle").font(.caption).foregroundColor(.white)
            StatusPixelIcon(status: .idle, size: 28)
                .background(Color.gray.opacity(0.2))
        }
        VStack(spacing: 10) {
            Text("Running").font(.caption).foregroundColor(.white)
            StatusPixelIcon(status: .running, size: 28)
        }
        VStack(spacing: 10) {
            Text("Waiting").font(.caption).foregroundColor(.white)
            StatusPixelIcon(status: .waiting, size: 28)
        }
        VStack(spacing: 10) {
            Text("Done").font(.caption).foregroundColor(.white)
            StatusPixelIcon(status: .sleeping, size: 28)
        }
    }
    .padding(40)
    .background(.black)
}
