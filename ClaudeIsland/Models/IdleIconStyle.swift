//
//  IdleIconStyle.swift
//  ClaudeIsland
//
//  Defines available idle icon styles for the notch display
//

import SwiftUI

enum IdleIconStyle: String, CaseIterable, Identifiable {
    case dog = "dog"
    case island = "island"
    case robot = "robot"
    case cat = "cat"
    case ghost = "ghost"
    case lighthouse = "lighthouse"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dog:       return "Dog"
        case .island:    return "Island"
        case .robot:     return "Robot"
        case .cat:       return "Cat"
        case .ghost:     return "Ghost"
        case .lighthouse: return "Lighthouse"
        }
    }

    var description: String {
        switch self {
        case .dog:        return "Pixel corgi"
        case .island:     return "Tropical island"
        case .robot:      return "Retro robot"
        case .cat:        return "Orange tabby"
        case .ghost:      return "Cute ghost"
        case .lighthouse: return "Lighthouse tower"
        }
    }

    @ViewBuilder
    func iconView(size: CGFloat, animate: Bool = false, breathe: Bool = false, pulse: Bool = false) -> some View {
        switch self {
        case .dog:
            DogIcon(size: size, color: .white, animate: animate, breathe: breathe, pulse: pulse)
        case .island:
            IslandIcon(size: size, color: .white, animate: animate, breathe: breathe, pulse: pulse)
        case .robot:
            RobotIcon(size: size, color: .white, animate: animate, breathe: breathe, pulse: pulse)
        case .cat:
            CatIcon(size: size, color: .white, animate: animate, breathe: breathe, pulse: pulse)
        case .ghost:
            GhostIcon(size: size, color: .white, animate: animate, breathe: breathe, pulse: pulse)
        case .lighthouse:
            LighthouseIcon(size: size, color: .white, animate: animate, breathe: breathe, pulse: pulse)
        }
    }
}
