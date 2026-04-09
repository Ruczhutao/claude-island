//
//  MarqueeText.swift
//  ClaudeIsland
//
//  Multi-effect marquee text component for the closed notch state.
//

import SwiftUI
import Combine

// MARK: - Typewriter Controller

@MainActor
final class TypewriterController: ObservableObject {
    @Published var typedText: String = ""
    @Published var isCursorVisible: Bool = true

    private var typingCancellable: AnyCancellable?
    private var target: String = ""
    private var index: Int = 0
    private var phase: Phase = .typing
    private var speedMultiplier: Double = 1.0

    private enum Phase {
        case typing
        case waiting
        case nextPhrase
    }

    func start(with text: String, speed: Double) {
        typingCancellable?.cancel()
        target = text
        index = 0
        typedText = ""
        isCursorVisible = true
        phase = .typing
        speedMultiplier = max(0.2, min(2.0, speed))

        let typingInterval = 0.08 / speedMultiplier
        typingCancellable = Timer.publish(every: typingInterval, tolerance: 0.02, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func stop() {
        typingCancellable?.cancel()
        typingCancellable = nil
    }

    private func tick() {
        switch phase {
        case .typing:
            if index < target.count {
                let idx = target.index(target.startIndex, offsetBy: index)
                typedText.append(target[idx])
                index += 1
            } else {
                phase = .waiting
                let cursorInterval = 0.35 / speedMultiplier
                let waitDuration = 1.5 / speedMultiplier

                Timer.scheduledTimer(withTimeInterval: cursorInterval, repeats: true) { [weak self] cursorTimer in
                    guard let self else {
                        cursorTimer.invalidate()
                        return
                    }
                    if self.phase != .waiting {
                        cursorTimer.invalidate()
                        self.isCursorVisible = false
                        return
                    }
                    self.isCursorVisible.toggle()
                }

                Timer.scheduledTimer(withTimeInterval: waitDuration, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    self.phase = .nextPhrase
                }
            }

        case .waiting:
            break

        case .nextPhrase:
            typingCancellable?.cancel()
            typingCancellable = nil
            start(with: target, speed: speedMultiplier)
        }
    }
}

// MARK: - Marquee Text

struct MarqueeText: View {
    let text: String
    let font: Font
    let fontSize: CGFloat
    let color: Color
    let speed: CGFloat
    let maxWidth: CGFloat
    let effectMode: MarqueeEffectMode

    @StateObject private var typewriter = TypewriterController()
    @State private var sparkleIndex: Int = 0
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var lastUpdateTime: Date = .distantPast

    private let fadeWidth: CGFloat = 16

    var body: some View {
        ZStack(alignment: .leading) {
            switch effectMode {
            case .scroll:
                scrollContent
            case .flash:
                flashContent
            case .typewriter:
                typewriterContent
            case .sparkle:
                sparkleContent
            case .static:
                staticContent
            }
        }
        .frame(width: maxWidth, alignment: .center)
        .mask(fadeMask)
        .clipped()
        .onAppear {
            handleAppear()
        }
        .onChange(of: text) { _, _ in
            handleTextChange()
        }
        .onChange(of: effectMode) { _, _ in
            handleTextChange()
        }
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        measureText()
        offset = maxWidth
        sparkleIndex = 0
        if effectMode == .typewriter {
            typewriter.start(with: text, speed: AppSettings.marqueeAnimationSpeed)
            stopSparkleTimer()
        } else if effectMode == .sparkle {
            typewriter.stop()
            startSparkleTimer()
        } else {
            typewriter.stop()
            stopSparkleTimer()
        }
    }

    private func handleTextChange() {
        measureText()
        offset = maxWidth
        sparkleIndex = 0
        if effectMode == .typewriter {
            typewriter.start(with: text, speed: AppSettings.marqueeAnimationSpeed)
            stopSparkleTimer()
        } else if effectMode == .sparkle {
            typewriter.stop()
            startSparkleTimer()
        } else {
            typewriter.stop()
            stopSparkleTimer()
        }
    }

    // MARK: - Fade Mask

    private var fadeMask: some View {
        let ratio = fadeWidth / max(maxWidth, 1)
        return LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: min(ratio, 0.5)),
                .init(color: .black, location: max(1 - ratio, 0.5)),
                .init(color: .clear, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Scroll Effect

    @ViewBuilder
    private var scrollContent: some View {
        let shouldScroll = textWidth > maxWidth
        if shouldScroll {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: text.isEmpty)) { timeline in
                let gap: CGFloat = 40
                HStack(spacing: gap) {
                    textView(for: text)
                    textView(for: text)
                }
                .offset(x: offset)
                .onChange(of: timeline.date) { _, newDate in
                    let delta = newDate.timeIntervalSince(lastUpdateTime)
                    guard delta > 0 && delta < 0.1 else {
                        lastUpdateTime = newDate
                        return
                    }
                    lastUpdateTime = newDate

                    let totalWidth = textWidth + gap
                    let scrollSpeed = speed * Double(speedMultiplier)
                    let newOffset = offset - scrollSpeed * CGFloat(delta)
                    if newOffset < -totalWidth {
                        offset = newOffset + totalWidth
                    } else {
                        offset = newOffset
                    }
                }
            }
        } else {
            staticContent
        }
    }

    // MARK: - Flash Effect

    @ViewBuilder
    private var flashContent: some View {
        textView(for: text)
            .frame(width: maxWidth, alignment: .center)
            .id("flash_\(text)")
            .transition(.opacity.animation(.easeInOut(duration: 0.25 / Double(speedMultiplier))))
    }

    // MARK: - Typewriter Effect

    @ViewBuilder
    private var typewriterContent: some View {
        HStack(spacing: 0) {
            Text(typewriter.typedText + (typewriter.isCursorVisible ? "_" : ""))
                .font(font)
                .foregroundColor(color)
                .lineLimit(1)
        }
        .frame(width: maxWidth, alignment: .center)
    }

    // MARK: - Sparkle Effect (逐星)

    @State private var sparkleCancellable: AnyCancellable?

    private func startSparkleTimer() {
        sparkleCancellable?.cancel()
        let interval = 0.1 / speedMultiplier
        sparkleCancellable = Timer.publish(every: interval, tolerance: 0.02, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if !text.isEmpty {
                    sparkleIndex = (sparkleIndex + 1) % max(text.count, 1)
                }
            }
    }

    private func stopSparkleTimer() {
        sparkleCancellable?.cancel()
        sparkleCancellable = nil
    }

    /// Get color for a character at given index, with tail trail effect
    private func sparkleColor(for index: Int, count: Int) -> Color {
        let current = sparkleIndex % max(count, 1)
        let distance = (index - current + count) % count  // circular distance forward

        if distance == 0 {
            // Current highlight - brightest
            return .white
        } else if distance == 1 {
            // Trail 1
            return color.opacity(0.7)
        } else if distance == 2 {
            // Trail 2
            return color.opacity(0.5)
        } else {
            // Rest
            return color.opacity(0.3)
        }
    }

    @ViewBuilder
    private var sparkleContent: some View {
        let chars = Array(text)
        if chars.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 0) {
                ForEach(0..<chars.count, id: \.self) { i in
                    Text(String(chars[i]))
                        .font(font)
                        .foregroundColor(sparkleColor(for: i, count: chars.count))
                        .lineLimit(1)
                }
            }
            .frame(width: maxWidth, alignment: .center)
        }
    }

    // MARK: - Static Effect

    @ViewBuilder
    private var staticContent: some View {
        textView(for: text)
            .frame(width: maxWidth, alignment: .center)
    }

    // MARK: - Text View

    @ViewBuilder
    private func textView(for content: String) -> some View {
        Text(content)
            .font(font)
            .foregroundColor(color)
            .lineLimit(1)
            .fixedSize()
    }

    // MARK: - Speed Multiplier

    private var speedMultiplier: CGFloat {
        let base = AppSettings.marqueeAnimationSpeed
        return CGFloat(max(0.2, min(2.0, base)))
    }

    // MARK: - Text Measurement

    private func measureText() {
        let nsFont = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: nsFont
        ]
        let nsString = text as NSString
        let size = nsString.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
        )
        textWidth = ceil(size.width)
    }
}

#Preview("Marquee Scrolling") {
    MarqueeText(
        text: "Writing test cases for the new authentication module...",
        font: .system(size: 11, weight: .medium),
        fontSize: 11,
        color: Color(red: 0.85, green: 0.47, blue: 0.34).opacity(0.8),
        speed: 30,
        maxWidth: 200,
        effectMode: .scroll
    )
    .frame(width: 200, height: 38)
    .background(.black)
}

#Preview("Marquee Static") {
    MarqueeText(
        text: "Idle",
        font: .system(size: 11, weight: .medium),
        fontSize: 11,
        color: .white.opacity(0.35),
        speed: 30,
        maxWidth: 200,
        effectMode: .static
    )
    .frame(width: 200, height: 38)
    .background(.black)
}
