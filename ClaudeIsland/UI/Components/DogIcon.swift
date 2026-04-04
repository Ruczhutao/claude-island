//
//  DogIcon.swift
//  ClaudeIsland
//
//  Pixel art dog icon for Notch display
//  Corgi-style dog with big ears, based on pixel art drawing
//

import Combine
import SwiftUI

struct DogIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false
    var breathe: Bool = false  // Breathing animation (fade in/out)
    
    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0
    
    // Animation timer
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    
    // Pixel art corgi dog - lying down with paws on table
    // Based on the pixel art drawing
    
    // Dog body and head outline
    private let dogOutline: [(Int, Int)] = [
        // Left ear (pointed, tall)
        (2, 2), (3, 2),
        (1, 3), (2, 3), (3, 3), (4, 3),
        (1, 4), (2, 4), (3, 4), (4, 4),
        (2, 5), (3, 5), (4, 5),
        
        // Right ear (pointed, tall)
        (12, 2), (13, 2),
        (11, 3), (12, 3), (13, 3), (14, 3),
        (11, 4), (12, 4), (13, 4), (14, 4),
        (11, 5), (12, 5), (13, 5),
        
        // Top of head
        (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2), (11, 2),
        (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3),
        
        // Face sides
        (2, 6), (3, 6), (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (10, 6), (11, 6), (12, 6), (13, 6),
        (2, 7), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (8, 7), (9, 7), (10, 7), (11, 7), (12, 7), (13, 7),
        
        // Body/shoulders
        (2, 8), (3, 8), (4, 8), (5, 8), (6, 8), (7, 8), (8, 8), (9, 8), (10, 8), (11, 8), (12, 8), (13, 8),
        (2, 9), (3, 9), (4, 9), (5, 9), (6, 9), (7, 9), (8, 9), (9, 9), (10, 9), (11, 9), (12, 9), (13, 9),
        
        // Front paws on table
        (1, 10), (2, 10), (3, 10), (4, 10),
        (1, 11), (2, 11), (3, 11),
        (11, 10), (12, 10), (13, 10), (14, 10),
        (12, 11), (13, 11), (14, 11),
    ]
    
    // Eyes (black)
    private let eyes: [(Int, Int)] = [
        (5, 5), (6, 5),
        (9, 5), (10, 5),
    ]
    
    // Nose (black)
    private let nose: [(Int, Int)] = [
        (7, 6), (8, 6),
        (7, 7), (8, 7),
    ]
    
    // Animation: ear wiggle
    private let earWiggle: [[(dx: Int, dy: Int)]] = [
        [(0, 0)],      // Neutral
        [(0, -1)],     // Ears up
        [(0, 0)],      // Neutral
        [(0, 1)],      // Ears down
    ]
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0
            
            let wiggle = animate ? earWiggle[animationPhase % earWiggle.count] : [(0, 0)]
            
            // Draw dog outline with ear wiggle
            for pixel in dogOutline {
                // Apply wiggle to ear pixels only (y < 6)
                let wiggleY = pixel.1 < 6 ? wiggle[0].dy : 0
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1 + wiggleY) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(color))
            }
            
            // Draw eyes (black)
            for pixel in eyes {
                let wiggleY = 0  // Eyes don't wiggle
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1 + wiggleY) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(Color.black))
            }
            
            // Draw nose (black)
            for pixel in nose {
                let rect = CGRect(
                    x: CGFloat(pixel.0) * scale,
                    y: CGFloat(pixel.1) * scale,
                    width: scale,
                    height: scale
                )
                context.fill(Path(rect), with: .color(Color.black))
            }
        }
        .frame(width: size, height: size)
        .opacity(breatheOpacity)
        .animation(breathe ? .easeInOut(duration: 2).repeatForever(autoreverses: true) : .default, value: breatheOpacity)
        .onReceive(timer) { _ in
            if animate {
                animationPhase = (animationPhase + 1) % 8
            }
        }
        .onAppear {
            if breathe {
                // Start breathing animation
                breatheOpacity = 0.4
            }
        }
        .onChange(of: breathe) { _, newValue in
            if newValue {
                breatheOpacity = 0.4
            } else {
                breatheOpacity = 1.0
            }
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        VStack(spacing: 20) {
            Text("静止")
                .font(.caption)
                .foregroundColor(.white)
            DogIcon(size: 36, color: Color(red: 0.85, green: 0.47, blue: 0.34), animate: false)
        }
        VStack(spacing: 20) {
            Text("耳朵动")
                .font(.caption)
                .foregroundColor(.white)
            DogIcon(size: 36, color: Color(red: 0.85, green: 0.47, blue: 0.34), animate: true)
        }
    }
    .padding(40)
    .background(.black)
}
