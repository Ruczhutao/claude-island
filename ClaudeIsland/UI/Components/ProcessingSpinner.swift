//
//  ProcessingSpinner.swift
//  ClaudeIsland
//
//  Animated ellipsis for processing state
//

import Combine
import SwiftUI

struct ProcessingSpinner: View {
    @State private var phase: Int = 0
    
    var color: Color = Color(red: 0.85, green: 0.47, blue: 0.34) // Default Claude orange
    
    private let ellipsisStates = ["", ".", "..", "..."]
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(ellipsisStates[phase % ellipsisStates.count])
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(color)
            .frame(width: 16, height: 10, alignment: .leading)
            .clipped()
            .onReceive(timer) { _ in
                phase = (phase + 1) % ellipsisStates.count
            }
    }
}

#Preview {
    ProcessingSpinner()
        .frame(width: 30, height: 30)
        .background(.black)
}
