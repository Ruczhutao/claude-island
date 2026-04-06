//
//  NotchView.swift
//  ClaudeIsland
//
//  The main dynamic island SwiftUI view with accurate notch shape
//

import AppKit
import CoreGraphics
import SwiftUI

// Corner radius constants
private let cornerRadiusInsets = (
    opened: (top: CGFloat(19), bottom: CGFloat(24)),
    closed: (top: CGFloat(6), bottom: CGFloat(14))
)

struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    @StateObject private var sessionMonitor = ClaudeSessionMonitor()
    @StateObject private var activityCoordinator = NotchActivityCoordinator.shared
    @ObservedObject private var updateManager = UpdateManager.shared
    @AppStorage("idleIconStyle") private var idleIconStyle: String = IdleIconStyle.dog.rawValue
    @State private var previousPendingIds: Set<String> = []
    @State private var previousWaitingForInputIds: Set<String> = []
    @State private var waitingForInputTimestamps: [String: Date] = [:]  // sessionId -> when it entered waitingForInput
    @State private var approvalSoundDelays: [String: Task<Void, Never>] = [:]  // Delayed sound tasks for Kimi/Codex
    @State private var isVisible: Bool = false
    @State private var isHovering: Bool = false
    @State private var isBouncing: Bool = false

    @Namespace private var activityNamespace

    /// Whether any Claude session is currently processing or compacting
    private var isAnyProcessing: Bool {
        sessionMonitor.instances.contains { $0.phase == .processing || $0.phase == .compacting }
    }

    /// Whether any Claude session has a pending permission request
    private var hasPendingPermission: Bool {
        sessionMonitor.instances.contains { $0.phase.isWaitingForApproval }
    }

    /// Current idle icon style
    private var idleStyle: IdleIconStyle {
        IdleIconStyle(rawValue: idleIconStyle) ?? .dog
    }

    /// Whether any Claude session is waiting for user input (done/ready state) within the display window
    private var hasWaitingForInput: Bool {
        let now = Date()
        let displayDuration: TimeInterval = 30  // Show checkmark for 30 seconds

        return sessionMonitor.instances.contains { session in
            guard session.phase == .waitingForInput else { return false }
            // Only show if within the 30-second display window
            if let enteredAt = waitingForInputTimestamps[session.stableId] {
                return now.timeIntervalSince(enteredAt) < displayDuration
            }
            return false
        }
    }

    // MARK: - Sizing

    private var closedNotchSize: CGSize {
        CGSize(
            width: viewModel.deviceNotchRect.width,
            height: viewModel.deviceNotchRect.height
        )
    }

    /// Extra width for expanding activities (like Dynamic Island)
    private var expansionWidth: CGFloat {
        // Permission indicator adds width on left side only
        let permissionIndicatorWidth: CGFloat = hasPendingPermission ? 18 : 0

        // Expand for processing activity
        if activityCoordinator.expandingActivity.show {
            switch activityCoordinator.expandingActivity.type {
            case .claude:
                let baseWidth = 2 * max(0, closedNotchSize.height - 12) + 20
                return baseWidth + permissionIndicatorWidth
            case .none:
                break
            }
        }

        // Expand for pending permissions (left indicator) or waiting for input (checkmark on right)
        if hasPendingPermission {
            return 2 * max(0, closedNotchSize.height - 12) + 20 + permissionIndicatorWidth
        }

        // Waiting for input just shows checkmark on right, no extra left indicator
        if hasWaitingForInput {
            return 2 * max(0, closedNotchSize.height - 12) + 20
        }

        return 0
    }

    private var notchSize: CGSize {
        switch viewModel.status {
        case .closed, .popping:
            return closedNotchSize
        case .opened:
            return viewModel.openedSize
        }
    }

    /// Width of the closed content (notch + any expansion)
    private var closedContentWidth: CGFloat {
        closedNotchSize.width + expansionWidth
    }

    // MARK: - Corner Radii

    private var topCornerRadius: CGFloat {
        viewModel.status == .opened
            ? cornerRadiusInsets.opened.top
            : cornerRadiusInsets.closed.top
    }

    private var bottomCornerRadius: CGFloat {
        viewModel.status == .opened
            ? cornerRadiusInsets.opened.bottom
            : cornerRadiusInsets.closed.bottom
    }

    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: bottomCornerRadius
        )
    }

    // Animation springs
    private let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
    private let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Outer container does NOT receive hits - only the notch content does
            VStack(spacing: 0) {
                notchLayout
                    .frame(
                        maxWidth: viewModel.status == .opened ? notchSize.width : nil,
                        alignment: .top
                    )
                    .padding(
                        .horizontal,
                        viewModel.status == .opened
                            ? cornerRadiusInsets.opened.top
                            : cornerRadiusInsets.closed.bottom
                    )
                    .padding([.horizontal, .bottom], viewModel.status == .opened ? 12 : 0)
                    .background(.black)
                    .clipShape(currentNotchShape)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.black)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .shadow(
                        color: (viewModel.status == .opened || isHovering) ? .black.opacity(0.7) : .clear,
                        radius: 6
                    )
                    .frame(
                        maxWidth: viewModel.status == .opened ? notchSize.width : nil,
                        maxHeight: viewModel.status == .opened ? notchSize.height : nil,
                        alignment: .top
                    )
                    .animation(viewModel.status == .opened ? openAnimation : closeAnimation, value: viewModel.status)
                    .animation(openAnimation, value: notchSize) // Animate container size changes between content types
                    .animation(.smooth, value: activityCoordinator.expandingActivity)
                    .animation(.smooth, value: hasPendingPermission)
                    .animation(.smooth, value: hasWaitingForInput)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isBouncing)
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
                            isHovering = hovering
                        }
                    }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .preferredColorScheme(.dark)
        .onAppear {
            sessionMonitor.startMonitoring()
            // On non-notched devices, keep visible so users have a target to interact with
            if !viewModel.hasPhysicalNotch {
                isVisible = true
            }
        }
        .onChange(of: viewModel.status) { oldStatus, newStatus in
            handleStatusChange(from: oldStatus, to: newStatus)
        }
        .onChange(of: sessionMonitor.pendingInstances) { _, sessions in
            // Only handle sessions that are actually waiting for approval (not waitingForInput)
            let approvalSessions = sessions.filter { $0.phase.isWaitingForApproval }
            handlePendingSessionsChange(approvalSessions)
        }
        .onChange(of: sessionMonitor.instances) { _, instances in
            handleProcessingChange()
            handleWaitingForInputChange(instances)
        }
    }

    // MARK: - Notch Layout

    private var isProcessing: Bool {
        activityCoordinator.expandingActivity.show && activityCoordinator.expandingActivity.type == .claude
    }

    /// Whether to show the expanded closed state (processing, pending permission, or waiting for input)
    private var showClosedActivity: Bool {
        isProcessing || hasPendingPermission || hasWaitingForInput
    }
    
    /// Current state with priority: waiting > running > sleeping > idle
    private var currentState: (status: DogStatus, animate: Bool, breathe: Bool, pulse: Bool) {
        // Priority 1: Waiting for approval
        if hasPendingPermission {
            return (.waiting, false, false, true)
        }
        // Priority 2: Processing
        else if isProcessing {
            return (.running, true, false, false)
        }
        // Priority 3: Done/ready
        else if hasWaitingForInput {
            let shouldBreathe = viewModel.status != .opened
            return (.sleeping, false, shouldBreathe, false)
        }
        // Priority 4: Idle
        else {
            return (.idle, false, false, false)
        }
    }
    
    /// Convenience accessors
    private var dogStatus: DogStatus { currentState.status }
    private var dogAnimate: Bool { currentState.animate }
    private var dogBreathe: Bool { currentState.breathe }
    private var dogPulse: Bool { currentState.pulse }
    
    /// Get the dominant provider for current activity (for icon color)
    private var dominantProvider: SessionProvider {
        // Priority: processing > pending > waiting for input
        if isProcessing || hasPendingPermission {
            // Find the first processing or pending session
            if let session = sessionMonitor.instances.first(where: { 
                $0.phase == .processing || $0.phase.isWaitingForApproval 
            }) {
                return session.provider
            }
        }
        // Default to claude
        return .claude
    }
    
    /// Provider color for current activity
    private var activityColor: Color {
        switch dominantProvider {
        case .claude:
            return Color(red: 0.85, green: 0.47, blue: 0.34) // Orange
        case .codex:
            return Color(red: 0.2, green: 0.6, blue: 1.0) // Blue
        case .kimi:
            return Color(red: 0.0, green: 0.55, blue: 1.0) // Kimi blue
        case .cursor:
            return Color(red: 0.95, green: 0.95, blue: 0.95) // White/Silver
        }
    }
    
    /// Provider letter for current activity
    private var activityLetter: String {
        switch dominantProvider {
        case .claude:
            return "C"
        case .codex:
            return "X"
        case .kimi:
            return "K"
        case .cursor:
            return "⦿"
        }
    }
    
    /// Provider icon view based on dominant provider
    @ViewBuilder
    private func providerIcon(size: CGFloat, animate: Bool) -> some View {
        switch dominantProvider {
        case .claude:
            ClaudeIcon(size: size, color: activityColor, animate: animate)
        case .codex:
            CodexIcon(size: size, color: activityColor, animate: animate)
        case .kimi:
            KimiIcon(size: size, color: activityColor, animate: animate)
        case .cursor:
            CursorIcon(size: size, color: activityColor, animate: animate)
        }
    }

    @ViewBuilder
    private var notchLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row - always present, contains crab and spinner that persist across states
            headerRow
                .frame(height: max(24, closedNotchSize.height))

            // Main content only when opened
            if viewModel.status == .opened {
                contentView
                    .frame(width: notchSize.width - 24) // Fixed width to prevent reflow
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .top)
                                .combined(with: .opacity)
                                .animation(.smooth(duration: 0.35)),
                            removal: .opacity.animation(.easeOut(duration: 0.15))
                        )
                    )
            }
        }
    }

    // MARK: - Header Row (persists across states)

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 0) {
            // Left side - Main icon + simplified status indicator
            // Status icon: Idle=hidden, Running=!, Waiting=?, Done=✓
            HStack(alignment: .center, spacing: dogStatus == .idle ? 0 : 4) {
                // Main icon (Dog/Cat/Robot/etc) - animation shows state
                idleStyle.iconView(size: 32, animate: dogAnimate, breathe: dogBreathe, pulse: dogPulse)
                    .matchedGeometryEffect(id: "crab", in: activityNamespace, isSource: showClosedActivity)
                
                // Status symbol - only visible when not idle
                if dogStatus != .idle {
                    StatusPixelIcon(status: dogStatus, size: 18)
                        .matchedGeometryEffect(id: "status", in: activityNamespace, isSource: showClosedActivity)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: viewModel.status == .opened ? nil : (dogStatus == .idle ? 32 : 54), alignment: .leading)
            .padding(.leading, viewModel.status == .opened ? 8 : 0)

            // Center content
            if viewModel.status == .opened {
                // Opened: show header content
                openedHeaderContent
            } else if !showClosedActivity {
                // Closed without activity: show dog icon with subtle breathing animation
                // The dog icon is already shown on the left, just use black spacer here
                Rectangle()
                    .fill(.black)
                    .frame(width: closedNotchSize.width - cornerRadiusInsets.closed.top)
            } else {
                // Closed with activity: black spacer (with optional bounce)
                Rectangle()
                    .fill(.black)
                    .frame(width: closedNotchSize.width - cornerRadiusInsets.closed.top + (isBouncing ? 16 : 0))
            }

            // Right side indicator removed - only show in conversation list, not in notch header
        }
        .frame(height: closedNotchSize.height)
    }

    private var sideWidth: CGFloat {
        max(0, closedNotchSize.height - 12) + 10
    }

    // MARK: - Opened Header Content

    @ViewBuilder
    private var openedHeaderContent: some View {
        HStack(spacing: 12) {
            // Main icon + status symbol (if not idle)
            HStack(alignment: .center, spacing: dogStatus == .idle ? 0 : 4) {
                idleStyle.iconView(size: 32, animate: dogAnimate, breathe: dogBreathe, pulse: dogPulse)
                    .matchedGeometryEffect(id: "crab", in: activityNamespace, isSource: !showClosedActivity)
                
                if dogStatus != .idle {
                    StatusPixelIcon(status: dogStatus, size: 18)
                        .matchedGeometryEffect(id: "status", in: activityNamespace, isSource: !showClosedActivity)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.leading, 8)

            Spacer()

            // Settings button - directly opens preferences window
            Button {
                viewModel.notchClose()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    PreferencesWindowController.shared.show()
                    updateManager.markUpdateSeen()
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "gear")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())

                    // Green dot for unseen update
                    if updateManager.hasUnseenUpdate {
                        Circle()
                            .fill(TerminalColors.green)
                            .frame(width: 5, height: 5)
                            .offset(x: 1, y: -1)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Content View (Opened State)

    @ViewBuilder
    private var contentView: some View {
        Group {
            switch viewModel.contentType {
            case .instances:
                ClaudeInstancesView(
                    sessionMonitor: sessionMonitor,
                    viewModel: viewModel
                )
            case .menu:
                NotchMenuView(viewModel: viewModel)
            case .chat(let session):
                ChatView(
                    sessionId: session.sessionId,
                    initialSession: session,
                    sessionMonitor: sessionMonitor,
                    viewModel: viewModel
                )
            }
        }
        .frame(width: notchSize.width - 24) // Fixed width to prevent text reflow
        // Removed .id() - was causing view recreation and performance issues
    }

    // MARK: - Event Handlers

    private func handleProcessingChange() {
        if isAnyProcessing || hasPendingPermission {
            // Show claude activity when processing or waiting for permission
            activityCoordinator.showActivity(type: .claude)
            isVisible = true
        } else if hasWaitingForInput {
            // Keep visible for waiting-for-input but hide the processing spinner
            activityCoordinator.hideActivity()
            isVisible = true
        } else {
            // Hide activity when done
            activityCoordinator.hideActivity()

            // Delay hiding the notch until animation completes
            // Don't hide on non-notched devices - users need a visible target
            if viewModel.status == .closed && viewModel.hasPhysicalNotch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                    if !isAnyProcessing && !hasPendingPermission && !hasWaitingForInput && viewModel.status == .closed {
                        // Check if "hide when no active session" is enabled
                        let hideWhenNoActive = UserDefaults.standard.bool(forKey: "hideWhenNoActiveSession")
                        if hideWhenNoActive {
                            isVisible = false
                        }
                    }
                }
            }
        }
    }

    private func handleStatusChange(from oldStatus: NotchStatus, to newStatus: NotchStatus) {
        switch newStatus {
        case .opened, .popping:
            isVisible = true
            // Clear waiting-for-input timestamps only when manually opened (user acknowledged)
            if viewModel.openReason == .click || viewModel.openReason == .hover {
                waitingForInputTimestamps.removeAll()
            }
        case .closed:
            // Don't hide on non-notched devices - users need a visible target
            guard viewModel.hasPhysicalNotch else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if viewModel.status == .closed && !isAnyProcessing && !hasPendingPermission && !hasWaitingForInput && !activityCoordinator.expandingActivity.show {
                    isVisible = false
                }
            }
        }
    }

    private func handlePendingSessionsChange(_ sessions: [SessionState]) {
        let currentIds = Set(sessions.map { $0.stableId })
        let newPendingIds = currentIds.subtracting(previousPendingIds)

        for sessionId in newPendingIds {
            guard let session = sessions.first(where: { $0.stableId == sessionId }) else { continue }
            
            // For Claude: play sound immediately (user approves in Notch)
            // For Kimi/Codex: delay 0.5s - if still waiting, then play sound
            // (This avoids sound for yolo mode or quick terminal approvals)
            let delay: TimeInterval = session.supportsInNotchApproval ? 0 : 0.5
            
            if delay == 0 {
                SoundManager.shared.play(.needApproval)
            } else {
                // Cancel any existing delay for this session
                approvalSoundDelays[sessionId]?.cancel()
                
                // Schedule new delayed sound
                // Capture sessionMonitor to check state when task runs
                let monitor = sessionMonitor
                approvalSoundDelays[sessionId] = Task { [sessionId] in
                    try? await Task.sleep(for: .seconds(delay))
                    
                    // Check if still waiting for approval (not approved in terminal yet)
                    let stillPending = monitor.pendingInstances.contains {
                        $0.stableId == sessionId && $0.phase.isWaitingForApproval
                    }
                    if stillPending {
                        await MainActor.run {
                            SoundManager.shared.play(.needApproval)
                        }
                    }
                }
            }
            
            // Auto-open notch for new approvals
            if viewModel.status == .closed &&
               !TerminalVisibilityDetector.isTerminalVisibleOnCurrentSpace() {
                viewModel.notchOpen(reason: .notification)
            }
        }

        // Clean up sound delays for sessions no longer pending
        let staleDelayIds = Set(approvalSoundDelays.keys).subtracting(currentIds)
        for staleId in staleDelayIds {
            approvalSoundDelays[staleId]?.cancel()
            approvalSoundDelays.removeValue(forKey: staleId)
        }

        previousPendingIds = currentIds
    }

    private func handleWaitingForInputChange(_ instances: [SessionState]) {
        // Get sessions that are now waiting for input
        let waitingForInputSessions = instances.filter { $0.phase == .waitingForInput }
        let currentIds = Set(waitingForInputSessions.map { $0.stableId })
        let newWaitingIds = currentIds.subtracting(previousWaitingForInputIds)

        // Track timestamps for newly waiting sessions
        let now = Date()
        for session in waitingForInputSessions where newWaitingIds.contains(session.stableId) {
            waitingForInputTimestamps[session.stableId] = now
        }

        // Clean up timestamps for sessions no longer waiting
        let staleIds = Set(waitingForInputTimestamps.keys).subtracting(currentIds)
        for staleId in staleIds {
            waitingForInputTimestamps.removeValue(forKey: staleId)
        }

        // Bounce the notch when a session newly enters waitingForInput state
        if !newWaitingIds.isEmpty {
            // Get the sessions that just entered waitingForInput
            let newlyWaitingSessions = waitingForInputSessions.filter { newWaitingIds.contains($0.stableId) }

            // Play complete sound for finished tasks
            SoundManager.shared.play(.taskComplete)

            // Also play system notification sound if configured
            if let soundName = AppSettings.notificationSound.soundName {
                // Check if we should play sound (async check for tmux pane focus)
                Task {
                    let shouldPlaySound = await shouldPlayNotificationSound(for: newlyWaitingSessions)
                    if shouldPlaySound {
                        await MainActor.run {
                            NSSound(named: soundName)?.play()
                        }
                    }
                }
            }

            // Trigger bounce animation to get user's attention
            DispatchQueue.main.async {
                isBouncing = true
                // Bounce back after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isBouncing = false
                }
            }

            // Schedule hiding the checkmark after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [self] in
                // Trigger a UI update to re-evaluate hasWaitingForInput
                handleProcessingChange()
            }
        }

        previousWaitingForInputIds = currentIds
    }

    /// Determine if notification sound should play for the given sessions
    /// Returns true if ANY session is not actively focused
    private func shouldPlayNotificationSound(for sessions: [SessionState]) async -> Bool {
        for session in sessions {
            guard let pid = session.pid else {
                // No PID means we can't check focus, assume not focused
                return true
            }

            let isFocused = await TerminalVisibilityDetector.isSessionFocused(sessionPid: pid)
            if !isFocused {
                return true
            }
        }

        return false
    }
}
