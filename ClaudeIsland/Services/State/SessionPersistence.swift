//
//  SessionPersistence.swift
//  ClaudeIsland
//
//  Session state persistence - saves and restores sessions across app launches
//

import Foundation
import os.log

/// Logger for session persistence
private let logger = Logger(subsystem: "com.claudeisland", category: "Persistence")

/// Simplified session data for persistence
struct PersistedSession: Codable, Equatable {
    let sessionId: String
    let cwd: String
    let projectName: String
    let providerRawValue: String
    let transcriptPath: String?
    let model: String?
    let pid: Int?
    let tty: String?
    let isInTmux: Bool
    let phaseRawValue: String
    let summary: String?
    let lastMessage: String?
    let lastMessageRole: String?
    let lastToolName: String?
    let firstUserMessage: String?
    let lastUserMessageDate: Date?
    let lastActivity: Date
    let createdAt: Date
    let savedAt: Date
}

/// Manages persistence of session state
actor SessionPersistence {
    static let shared = SessionPersistence()
    
    private let userDefaultsKey = "com.claudeisland.persisted-sessions"
    private let maxSessionAge: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {}
    
    // MARK: - Public API
    
    /// Save all current sessions to persistence
    func saveSessions(_ sessions: [SessionState]) {
        let persistedSessions = sessions
            .filter { shouldPersist($0) }
            .map { PersistedSession(from: $0) }
        
        do {
            let data = try JSONEncoder().encode(persistedSessions)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            logger.info("Saved \(persistedSessions.count) sessions to persistence")
        } catch {
            logger.error("Failed to save sessions: \(error.localizedDescription)")
        }
    }
    
    /// Load persisted sessions and convert to SessionState
    func loadSessions() -> [SessionState] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            logger.info("No persisted sessions found")
            return []
        }
        
        do {
            let persistedSessions = try JSONDecoder().decode([PersistedSession].self, from: data)
            let now = Date()
            
            // Filter out expired sessions
            let validSessions = persistedSessions.filter { shouldRestore($0, now: now) }
            
            // Clean up expired sessions if any were filtered out
            if validSessions.count < persistedSessions.count {
                logger.info("Removed \(persistedSessions.count - validSessions.count) expired sessions")
                // Re-save without expired sessions
                let cleanData = try JSONEncoder().encode(validSessions)
                UserDefaults.standard.set(cleanData, forKey: userDefaultsKey)
            }
            
            let sessionStates = validSessions.map { $0.toSessionState() }
            logger.info("Loaded \(sessionStates.count) persisted sessions")
            return sessionStates
            
        } catch {
            logger.error("Failed to load sessions: \(error.localizedDescription)")
            // Clear corrupted data
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            return []
        }
    }
    
    /// Clear all persisted sessions
    func clearAllSessions() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        logger.info("Cleared all persisted sessions")
    }
    
    /// Check if a session should be persisted
    private func shouldPersist(_ session: SessionState) -> Bool {
        // Codex conversations should not come back after restart once they are idle.
        if session.provider == .codex {
            switch session.phase {
            case .processing, .compacting, .waitingForApproval:
                break
            case .waitingForInput, .idle, .ended:
                return false
            }
        }

        // Don't persist sessions that are ended or very old
        if session.phase == .ended {
            return false
        }
        
        // Don't persist sessions without any activity in the last hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        if session.lastActivity < oneHourAgo {
            return false
        }
        
        return true
    }

    /// Check if a persisted session should be restored on launch
    private func shouldRestore(_ session: PersistedSession, now: Date) -> Bool {
        let age = now.timeIntervalSince(session.savedAt)
        guard age < maxSessionAge else {
            return false
        }

        if session.providerRawValue == SessionProvider.codex.rawValue {
            switch session.phaseRawValue {
            case "processing", "compacting", "waitingForApproval":
                return true
            default:
                return false
            }
        }

        return true
    }
}

// MARK: - Conversion Extensions

// MARK: - Optional String Helper

extension Optional where Wrapped == String {
    nonisolated var isNilOrEmpty: Bool {
        switch self {
        case .none: return true
        case .some(let value): return value.isEmpty
        }
    }
}

// MARK: - Conversion Extensions

extension PersistedSession {
    /// Create PersistedSession from SessionState
    init(from session: SessionState) {
        self.sessionId = session.sessionId
        self.cwd = session.cwd
        self.projectName = session.projectName
        self.providerRawValue = session.provider.rawValue
        self.transcriptPath = session.transcriptPath
        self.model = session.model
        self.pid = session.pid
        self.tty = session.tty
        self.isInTmux = session.isInTmux
        self.phaseRawValue = Self.encodePhase(session.phase)
        self.summary = session.conversationInfo.summary
        self.lastMessage = session.conversationInfo.lastMessage
        self.lastMessageRole = session.conversationInfo.lastMessageRole
        self.lastToolName = session.conversationInfo.lastToolName
        self.firstUserMessage = session.conversationInfo.firstUserMessage
        self.lastUserMessageDate = session.conversationInfo.lastUserMessageDate
        self.lastActivity = session.lastActivity
        self.createdAt = session.createdAt
        self.savedAt = Date()
    }
    
    /// Convert back to SessionState
    func toSessionState() -> SessionState {
        SessionState(
            sessionId: sessionId,
            cwd: cwd,
            projectName: projectName,
            provider: SessionProvider(rawValue: providerRawValue) ?? .claude,
            transcriptPath: transcriptPath,
            model: model,
            pid: pid,
            tty: tty,
            isInTmux: isInTmux,
            phase: Self.decodePhase(phaseRawValue),
            chatItems: [], // Chat items are not persisted, will be reloaded from file
            toolTracker: ToolTracker(),
            subagentState: SubagentState(),
            conversationInfo: ConversationInfo(
                summary: summary,
                lastMessage: lastMessage,
                lastMessageRole: lastMessageRole,
                lastToolName: lastToolName,
                firstUserMessage: firstUserMessage,
                lastUserMessageDate: lastUserMessageDate
            ),
            needsClearReconciliation: false,
            lastActivity: lastActivity,
            createdAt: createdAt
        )
    }
    
    /// Encode phase to string
    private static func encodePhase(_ phase: SessionPhase) -> String {
        switch phase {
        case .idle: return "idle"
        case .processing: return "processing"
        case .waitingForInput: return "waitingForInput"
        case .waitingForApproval: return "waitingForApproval"
        case .compacting: return "compacting"
        case .ended: return "ended"
        }
    }
    
    /// Decode phase from string
    private static func decodePhase(_ rawValue: String) -> SessionPhase {
        switch rawValue {
        case "idle": return .idle
        case "processing": return .processing
        case "waitingForInput": return .waitingForInput
        case "waitingForApproval": return .idle // Approval context is lost, reset to idle
        case "compacting": return .compacting
        case "ended": return .ended
        default: return .idle
        }
    }
}
