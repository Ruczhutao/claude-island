//
//  MarqueeStatusProvider.swift
//  ClaudeIsland
//
//  Provides marquee text based on session state.
//  Uses theme packs with per-state random phrase selection.
//

import Combine
import SwiftUI

// MARK: - Theme Definition

enum MarqueeTheme: String, CaseIterable, Identifiable {
    case `default` = "default"
    case doggy = "doggy"
    case sociology = "sociology"
    case peter = "peter"
    case programmer = "programmer"
    case jrpg = "jrpg"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "默认"
        case .doggy: return "汪星人"
        case .sociology: return "社会学"
        case .peter: return "恶搞之家"
        case .programmer: return "大厂码农"
        case .jrpg: return "日式RPG"
        case .custom: return "自定义"
        }
    }
}

// MARK: - Phrase Sets

struct MarqueePhraseSet {
    let working: [String]
    let approval: [String]
    let done: [String]
    let idle: [String]
}

extension MarqueeTheme {
    var phrases: MarqueePhraseSet {
        switch self {
        case .default:
            return MarqueePhraseSet(
                working: [
                    "正在努力搬砖中...",
                    "Agent 正在思考...",
                    "忙活中，请稍候...",
                    "代码正在生成...",
                    "思考中...",
                    "努力工作中...",
                ],
                approval: [
                    "需要你的审批",
                    "有任务等你确认",
                    "Agent 请求许可",
                ],
                done: [
                    "任务完成，请查收",
                    "搞定了！",
                    "任务完成，等你下一步指示",
                    "活干完了！",
                ],
                idle: [
                    "一切安好，静静等待...",
                    "随时待命",
                    "No active sessions",
                    "Ready for your next task",
                ]
            )
        case .doggy:
            return MarqueePhraseSet(
                working: [
                    "汪！正在追代码...",
                    "努力挖骨头中...",
                    "汪汪！忙着跑呢...",
                    "正在巡逻中...",
                    "嗅到代码的味道...",
                ],
                approval: [
                    "汪汪！需要主人确认",
                    "主人，这里怎么办？",
                    "叼来了，请过目！",
                ],
                done: [
                    "任务完成！奖励零食？",
                    "汪！搞定了！",
                    "交差了，可以摸摸头吗？",
                    "好狗狗收工！",
                ],
                idle: [
                    "趴着等你...",
                    "Good boy, standing by",
                    "摇尾巴中...",
                    "打盹中...",
                    "守家中，一切正常",
                ]
            )
        case .sociology:
            return MarqueePhraseSet(
                working: [
                    "正在进行田野观察...",
                    "结构功能主义分析中...",
                    "正在建构理论框架...",
                    "控制变量中...",
                    "布迪厄的场域理论应用中...",
                ],
                approval: [
                    "请通过IRB伦理审查",
                    "研究设计需要你的确认",
                    "方法论需要同行评议",
                ],
                done: [
                    "研究发现已出！",
                    "论文可以投了",
                    "P值显著！",
                    "ANOVA结果出来了",
                    "理论建构完成，欢迎批判",
                ],
                idle: [
                    "More research is needed",
                    "数据收集中，请等待...",
                    "文献综述永无止境...",
                    "The sociological imagination awaits",
                    "默顿说你应该先写literature review",
                ]
            )
        case .peter:
            return MarqueePhraseSet(
                working: [
                    "嘿 Lois! 我在写代码！",
                    "这比去蛤蜊酒馆有意思多了...",
                    "Peter 正在工作！信不信由你！",
                    "我跟你说啊，写代码这事儿...",
                    "诶嘿嘿，看我的！",
                ],
                approval: [
                    "诶嘿嘿，需要你点一下",
                    "快确认！赶着去看球赛",
                    "Lois 让我找你确认一下",
                ],
                done: [
                    "搞定了！跟那天我在 Quahog 一样帅",
                    "嘿嘿嘿，干得不错嘛 Peter",
                    "Freakin' sweet!",
                    "这集到此结束",
                ],
                idle: [
                    "路面老梗时间：还记得那次...",
                    "坐在沙发上...",
                    "啥也没干，perfect",
                    "ahhhh...",
                    "等着 Brian 回来",
                ]
            )
        case .programmer:
            return MarqueePhraseSet(
                working: [
                    "加班到几点不确定，反正不计入工时...",
                    "需求又变了，第三十七版...",
                    "PPT 写完了，代码还没开始...",
                    "正在修复上一个修复的bug...",
                    "这代码能跑就是个奇迹...",
                ],
                approval: [
                    "领导说这个要过一下审批",
                    "老板让你确认，赶紧的",
                    "周报里要写这个，确认一下",
                ],
                done: [
                    "上线了，pray没有事故",
                    "交差了，可以下班了吗？",
                    "又完成了一个没人用的功能",
                    "QA说测过了，用户说没有",
                    "需求完成了，产品又提了新的",
                ],
                idle: [
                    "摸鱼中，别被PM看到...",
                    "等着被裁...",
                    "假装在看技术文档",
                    "技术债暂时没有催",
                    "研究期权什么时候能行权",
                ]
            )
        case .jrpg:
            return MarqueePhraseSet(
                working: [
                    "敌人出现了！战斗中...",
                    "消耗MP咏唱魔法中...",
                    "队友正在发动攻击...",
                    "公会任务执行中...",
                    "正在刷经验值...",
                    "剧情推进中...",
                ],
                approval: [
                    "选择：是 / 否",
                    "队友在等待你的决定",
                    "要执行这个行动吗？ ▶ 是",
                ],
                done: [
                    "战斗结束！获得经验值",
                    "任务完成！获得新称号",
                    "等级提升！",
                    "已存档",
                    "首领已被击败！要开宝箱吗？",
                ],
                idle: [
                    "在旅馆休息中...",
                    "世界树下待机中",
                    "翻阅冒险手册...",
                    "宁静的村庄，什么都没有发生...",
                    "背景音乐在播放中...",
                    "读取中...",
                ]
            )
        case .custom:
            // Custom phrases are read from AppSettings
            return MarqueePhraseSet(
                working: Self.parseLines(AppSettings.customPhrasesWorking),
                approval: Self.parseLines(AppSettings.customPhrasesApproval),
                done: Self.parseLines(AppSettings.customPhrasesDone),
                idle: Self.parseLines(AppSettings.customPhrasesIdle)
            )
        }
    }

    private static func parseLines(_ raw: String) -> [String] {
        raw.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Status Provider

@MainActor
class MarqueeStatusProvider: ObservableObject {
    @Published var marqueeText: String = ""
    @Published var currentPhrase: String = ""
    @Published var isActive: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var flashCancellable: AnyCancellable?
    private var currentPhase: MarqueePhase = .idle
    private var lastEffectMode: MarqueeEffectMode = .scroll

    init() {
        let mode = AppSettings.marqueeEffectMode
        lastEffectMode = mode
        rebuildText(for: mode)
    }

    func startMonitoring(sessionMonitor: ClaudeSessionMonitor) {
        sessionMonitor.$instances
            .receive(on: DispatchQueue.main)
            .sink { [weak self] instances in
                self?.updatePhase(from: instances)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let currentMode = AppSettings.marqueeEffectMode
                guard currentMode != self.lastEffectMode else { return }
                self.lastEffectMode = currentMode
                self.rebuildText(for: currentMode)
            }
            .store(in: &cancellables)
    }

    // MARK: - Phase Detection

    private enum MarqueePhase {
        case working(count: Int)
        case approval
        case done
        case idle
    }

    private func updatePhase(from instances: [SessionState]) {
        let processing = instances.filter { $0.phase == .processing || $0.phase == .compacting }
        let approval = instances.filter { $0.phase.isWaitingForApproval }
        let waiting = instances.filter { $0.phase == .waitingForInput }

        let newPhase: MarqueePhase
        if !approval.isEmpty {
            newPhase = .approval
        } else if !processing.isEmpty {
            newPhase = .working(count: processing.count)
        } else if !waiting.isEmpty {
            newPhase = .done
        } else {
            newPhase = .idle
        }

        let phaseChanged: Bool
        switch (currentPhase, newPhase) {
        case (.working(let a), .working(let b)): phaseChanged = a != b
        case (.idle, .idle): phaseChanged = false
        case (.approval, .approval): phaseChanged = false
        case (.done, .done): phaseChanged = false
        default: phaseChanged = true
        }

        currentPhase = newPhase

        if case .idle = newPhase {
            isActive = false
        } else {
            isActive = true
        }

        if phaseChanged {
            let mode = AppSettings.marqueeEffectMode
            lastEffectMode = mode
            rebuildText(for: mode)
        }
    }

    // MARK: - Phrase Selection

    private var phrasePool: [String] {
        let theme = AppSettings.marqueeTheme
        let phrases = theme.phrases

        switch currentPhase {
        case .working(let count):
            let base = phrases.working
            return count > 1 ? ["\(count) 个 Agent 正在工作"] + base : base
        case .approval:
            return phrases.approval
        case .done:
            return phrases.done
        case .idle:
            return phrases.idle
        }
    }

    private func rebuildText(for mode: MarqueeEffectMode) {
        switch mode {
        case .scroll:
            stopFlashTimer()
            buildScrollingText()
        case .flash, .typewriter, .sparkle, .static:
            stopFlashTimer()
            pickRandomPhrase()
            if mode == .flash {
                startFlashTimer()
            }
        }
    }

    private func buildScrollingText() {
        let pool = phrasePool
        guard !pool.isEmpty else {
            marqueeText = "..."
            currentPhrase = "..."
            return
        }
        marqueeText = pool.shuffled().joined(separator: "  •  ")
        currentPhrase = marqueeText
    }

    private func pickRandomPhrase() {
        let pool = phrasePool
        guard !pool.isEmpty else {
            currentPhrase = "..."
            marqueeText = "..."
            return
        }
        let candidate = pool.randomElement()!
        if candidate == currentPhrase && pool.count > 1 {
            currentPhrase = pool.filter { $0 != candidate }.randomElement()!
        } else {
            currentPhrase = candidate
        }
        // marqueeText 同步为单条，方便静态/打字机直接使用
        marqueeText = currentPhrase
    }

    private func startFlashTimer() {
        stopFlashTimer()
        let interval = 1.2 / AppSettings.marqueeAnimationSpeed
        flashCancellable = Timer.publish(every: interval, tolerance: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pickRandomPhrase()
            }
    }

    private func stopFlashTimer() {
        flashCancellable?.cancel()
        flashCancellable = nil
    }
}
