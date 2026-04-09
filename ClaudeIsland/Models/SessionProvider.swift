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
    case cursor
    case gemini
    case qwen

    var displayName: String {
        switch self {
        case .claude:
            return "Claude 代码助手"
        case .codex:
            return "Codex 代码助手"
        case .kimi:
            return "Kimi 代码助手"
        case .cursor:
            return "Cursor 编辑器"
        case .gemini:
            return "Gemini 代码助手"
        case .qwen:
            return "Qwen 代码助手"
        }
    }
}
