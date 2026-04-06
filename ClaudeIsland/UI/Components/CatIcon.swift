//
//  CatIcon.swift
//  ClaudeIsland
//
//  Pixel art orange tabby cat for Notch display
//  Status support: idle / sleeping / running / waiting
//

import Combine
import SwiftUI

struct CatIcon: View {
    let size: CGFloat
    let color: Color
    var animate: Bool = false      // running - tail wag + ear twitch
    var breathe: Bool = false      // sleeping - eyes closed, slow breathing
    var pulse: Bool = false        // waiting - ears alert, fast blink
    
    @State private var animationPhase: Int = 0
    @State private var breatheOpacity: Double = 1.0
    
    private let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    // MARK: - Color Palette
    private let furOrange    = Color(red: 0.95, green: 0.58, blue: 0.22)
    private let furDark      = Color(red: 0.8,  green: 0.45, blue: 0.15)
    private let innerEarPink = Color(red: 1.0,  green: 0.55, blue: 0.65)
    private let eyeWhite     = Color(white: 0.95)
    private let eyeGreen     = Color(red: 0.2,  green: 0.82, blue: 0.3)
    private let pupilBlack   = Color(white: 0.08)
    private let nosePink     = Color(red: 1.0,  green: 0.45, blue: 0.55)
    private let chinCream    = Color(red: 1.0,  green: 0.95, blue: 0.82)
    private let whiskerColor = Color(white: 0.75)
    private let alertRed     = Color(red: 1.0,  green: 0.3,  blue: 0.3)
    
    // MARK: - Base Cat Head
    private func baseFrame(eyesOpen: Bool, earsAlert: Bool) -> [(Int, Int, Color)] {
        // Ears - alert mode raises them
        let earOffset = earsAlert ? -1 : 0
        let leftEar: [(Int, Int, Color)] = [
            (3, 0 + earOffset, furOrange), (4, 0 + earOffset, furOrange),
            (2, 1 + earOffset, furOrange), (3, 1 + earOffset, furOrange), (4, 1 + earOffset, furOrange), (5, 1 + earOffset, furOrange),
            (2, 2 + earOffset, innerEarPink), (3, 2 + earOffset, innerEarPink), (4, 2 + earOffset, innerEarPink), (5, 2 + earOffset, furOrange),
        ]
        let rightEar: [(Int, Int, Color)] = [
            (11, 0 + earOffset, furOrange), (12, 0 + earOffset, furOrange),
            (10, 1 + earOffset, furOrange), (11, 1 + earOffset, furOrange), (12, 1 + earOffset, furOrange), (13, 1 + earOffset, furOrange),
            (10, 2 + earOffset, furOrange), (11, 2 + earOffset, innerEarPink), (12, 2 + earOffset, innerEarPink), (13, 2 + earOffset, innerEarPink),
        ]
        
        let forehead: [(Int, Int, Color)] = [
            (4, 3, furOrange), (5, 3, furOrange), (6, 3, furOrange), (7, 3, furOrange),
            (8, 3, furOrange), (9, 3, furOrange), (10, 3, furOrange), (11, 3, furOrange),
            (2, 3, furDark), (3, 3, furOrange), (12, 3, furOrange), (13, 3, furDark),
            (2, 4, furOrange), (3, 4, furDark), (4, 4, furOrange),
            (5, 4, furDark), (9, 4, furDark),
            (10, 4, furOrange), (11, 4, furDark), (12, 4, furOrange), (13, 4, furOrange),
        ]
        
        // Eyes - open or closed (sleeping)
        let eyes: [(Int, Int, Color)]
        if eyesOpen {
            eyes = [
                (3, 5, furOrange), (4, 5, furOrange),
                (5, 5, eyeWhite), (6, 5, eyeGreen),
                (7, 5, furOrange), (8, 5, furOrange),
                (9, 5, eyeWhite), (10, 5, eyeGreen),
                (11, 5, furOrange), (12, 5, furOrange),
                (3, 6, furOrange), (4, 6, furOrange),
                (5, 6, eyeGreen), (6, 6, pupilBlack),
                (7, 6, furOrange), (8, 6, furOrange),
                (9, 6, eyeGreen), (10, 6, pupilBlack),
                (11, 6, furOrange), (12, 6, furOrange),
            ]
        } else {
            // Closed eyes (sleeping)
            eyes = [
                (3, 5, furOrange), (4, 5, furOrange),
                (5, 5, furDark), (6, 5, furDark),
                (7, 5, furOrange), (8, 5, furOrange),
                (9, 5, furDark), (10, 5, furDark),
                (11, 5, furOrange), (12, 5, furOrange),
                (3, 6, furOrange), (4, 6, furOrange),
                (5, 6, furOrange), (6, 6, furOrange),
                (7, 6, furOrange), (8, 6, furOrange),
                (9, 6, furOrange), (10, 6, furOrange),
                (11, 6, furOrange), (12, 6, furOrange),
            ]
        }
        
        let cheeks: [(Int, Int, Color)] = [
            (3, 7, furOrange), (4, 7, furOrange), (5, 7, furOrange),
            (6, 7, furOrange), (7, 7, furOrange), (8, 7, furOrange),
            (9, 7, furOrange), (10, 7, furOrange), (11, 7, furOrange), (12, 7, furOrange),
            (1, 7, whiskerColor), (14, 7, whiskerColor),
        ]
        let nose: [(Int, Int, Color)] = [
            (3, 8, furOrange), (4, 8, furOrange), (5, 8, furOrange),
            (6, 8, Color(red: 1.0, green: 0.88, blue: 0.7)), (7, 8, nosePink), (8, 8, nosePink),
            (9, 8, Color(red: 1.0, green: 0.88, blue: 0.7)),
            (10, 8, furOrange), (11, 8, furOrange), (12, 8, furOrange),
            (1, 8, whiskerColor), (14, 8, whiskerColor),
        ]
        let chin: [(Int, Int, Color)] = [
            (4, 9, furOrange), (5, 9, furOrange), (6, 9, furOrange),
            (7, 9, furOrange), (8, 9, furOrange), (9, 9, furOrange), (10, 9, furOrange), (11, 9, furOrange),
            (5, 10, chinCream), (6, 10, chinCream), (7, 10, chinCream), (8, 10, chinCream), (9, 10, chinCream), (10, 10, chinCream),
            (6, 11, chinCream), (7, 11, chinCream), (8, 11, chinCream), (9, 11, chinCream),
        ]
        
        return leftEar + rightEar + forehead + eyes + cheeks + nose + chin
    }
    
    // MARK: - Animation Frames
    
    // Running: ear twitch + tail wag frames
    private var runningFrames: [[(Int, Int, Color)]] {
        let base = baseFrame(eyesOpen: true, earsAlert: false)
        let frame0 = base + [
            // Tail frame 0
            (1, 10, furOrange), (2, 10, furOrange),
            (0, 11, furOrange), (1, 11, furDark),
            (0, 12, furDark),
        ]
        let frame1 = base + [
            // Tail frame 1 (up)
            (1, 9, furOrange), (2, 10, furOrange),
            (0, 10, furOrange), (1, 11, furDark),
        ]
        return [frame0, frame1, frame0, frame1]
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = size / 16.0
            guard scale > 0 else { return }
            
            let pixels: [(Int, Int, Color)]
            
            if animate {
                // Running - tail wag
                pixels = runningFrames[animationPhase % runningFrames.count]
            } else if breathe {
                // Sleeping - eyes closed
                pixels = baseFrame(eyesOpen: false, earsAlert: false)
            } else if pulse {
                // Waiting - alert ears + open eyes
                pixels = baseFrame(eyesOpen: true, earsAlert: true)
            } else {
                // Idle - normal
                pixels = baseFrame(eyesOpen: true, earsAlert: false)
            }
            
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
        .opacity(breatheOpacity)
        .animation(breathe ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true) :
                   pulse ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : .default,
                   value: breatheOpacity)
        .onReceive(timer) { _ in
            if animate || pulse {
                animationPhase += 1
            }
        }
        .onAppear {
            if breathe {
                breatheOpacity = 0.5
            } else if pulse {
                breatheOpacity = 0.4
            }
        }
        .onChange(of: breathe) { _, newValue in
            breatheOpacity = newValue ? 0.5 : 1.0
        }
        .onChange(of: pulse) { _, newValue in
            if newValue {
                breatheOpacity = 0.4
            } else if !breathe {
                breatheOpacity = 1.0
            }
        }
    }
}

#Preview {
    HStack(spacing: 30) {
        VStack(spacing: 10) {
            Text("Idle").font(.caption).foregroundColor(.white)
            CatIcon(size: 36, color: .white)
        }
        VStack(spacing: 10) {
            Text("Sleeping").font(.caption).foregroundColor(.white)
            CatIcon(size: 36, color: .white, breathe: true)
        }
        VStack(spacing: 10) {
            Text("Running").font(.caption).foregroundColor(.white)
            CatIcon(size: 36, color: .white, animate: true)
        }
        VStack(spacing: 10) {
            Text("Waiting").font(.caption).foregroundColor(.white)
            CatIcon(size: 36, color: .white, pulse: true)
        }
    }
    .padding(40)
    .background(.black)
}
