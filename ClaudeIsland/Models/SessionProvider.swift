//
//  SessionProvider.swift
//  ClaudeIsland
//
//  Supported CLI providers that can feed session events into the app.
//

import Foundation

enum SessionProvider: String, Codable, Equatable, Sendable {
    case claude
    case codex
    case kimi

    var displayName: String {
        switch self {
        case .claude:
            return "Claude 代码助手"
        case .codex:
            return "Codex 代码助手"
        case .kimi:
            return "Kimi 代码助手"
        }
    }
}
