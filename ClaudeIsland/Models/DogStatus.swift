//
//  DogStatus.swift
//  ClaudeIsland
//
//  Status enum for DogIcon + StatusPixelIcon combination
//

import Foundation

/// Dog status for unified indicator design
/// Used by DogIcon (pure dog) + StatusPixelIcon (status indicator)
enum DogStatus {
    case idle           // Just lying down, ready
    case sleeping       // Lying down + breathing
    case running        // Running animation
    case waiting        // Alert pose / waiting for approval
}
