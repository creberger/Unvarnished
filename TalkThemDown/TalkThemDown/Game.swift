import Foundation
import Observation

/// One attempt at talking someone out of a decision.
@Observable
final class Game {
    static let threshold = 75
    static let maxTurns = 8
    static let pushyPenalty = 8

    struct Tag: Hashable {
        enum Kind { case gain, used, pushy }
        let text: String
        let kind: Kind
    }

    struct Message: Identifiable {
        let id = UUID()
        let fromPlayer: Bool
        let text: String
        var tags: [Tag] = []
    }

    enum Mood {
        case determined, wavering, persuaded
        var label: String {
            switch self {
            case .determined: "Determined"
            case .wavering: "Wavering"
            case .persuaded: "Changed their mind"
            }
        }
    }

    let scenario: Scenario
    private(set) var found: Set<String> = []
    private(set) var score = 0
    private(set) var turns = 0
    private(set) var messages: [Message] = []
    private(set) var isOver = false
    private var deflectionIndex = 0

    init(scenario: Scenario) {
        self.scenario = scenario
    }

    /// Score clamped to 0–100 for display.
    var percent: Int { min(100, max(0, score)) }
    var won: Bool { score >= Self.threshold }
    var turnsLeft: Int { Self.maxTurns - turns }

    var mood: Mood {
        if score >= Self.threshold { return .persuaded }
        if score >= 40 { return .wavering }
        return .determined
    }

    func reset() {
        found = []
        score = 0
        turns = 0
        messages = []
        isOver = false
        deflectionIndex = 0
    }

    /// Scores the player's message and appends the character's reply.
    func say(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isOver else { return }

        let tokens = text.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
        let words = Set(tokens)
        let normalized = " " + tokens.joined(separator: " ") + " "

        let hits = Lever.all.filter { !$0.forms.isDisjoint(with: words) }
        let newHits = hits.filter { !found.contains($0.id) }.sorted { $0.weight > $1.weight }
        let repeats = hits.filter { found.contains($0.id) }
        let pushy = !Lever.pushyWords.isDisjoint(with: words)
            || Lever.pushyPhrases.contains { normalized.contains(" \($0) ") }

        var tags: [Tag] = []
        for lever in newHits {
            found.insert(lever.id)
            score += lever.weight
            tags.append(Tag(text: "\(lever.id) +\(lever.weight)", kind: .gain))
        }
        for lever in repeats {
            tags.append(Tag(text: "\(lever.id) (used)", kind: .used))
        }
        if pushy {
            score -= Self.pushyPenalty
            tags.append(Tag(text: "pushy −\(Self.pushyPenalty)", kind: .pushy))
        }
        turns += 1
        messages.append(Message(fromPlayer: true, text: text, tags: tags))

        var reply: String
        if score >= Self.threshold {
            let lead = newHits.first.map { scenario.line(for: $0.id) + " " } ?? ""
            reply = lead + scenario.win
            isOver = true
        } else if let top = newHits.first {
            reply = scenario.line(for: top.id)
            if newHits.count > 1 {
                let rest = newHits.dropFirst().map { "\u{201C}\($0.id)\u{201D}" }.joined(separator: " and ")
                reply += " And you mentioned \(rest) too. Noted."
            }
            if pushy { reply += " But less of the lecturing, please." }
        } else if pushy {
            reply = scenario.pushyReplies[turns % scenario.pushyReplies.count]
        } else if !repeats.isEmpty {
            reply = scenario.repeatReply
        } else {
            reply = scenario.deflections[deflectionIndex % scenario.deflections.count]
            deflectionIndex += 1
        }

        if !isOver && turns >= Self.maxTurns {
            reply += " " + scenario.lose
            isOver = true
        }
        messages.append(Message(fromPlayer: false, text: reply))
    }
}
