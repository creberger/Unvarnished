import Foundation
import Observation

/// Walks through one painting's rounds. A wrong pick is ruled out and the player tries again
/// until they find the true statement; only a first-try find counts toward the score.
@Observable
final class Quiz {
    let painting: Painting
    private(set) var roundIndex = 0
    /// Statement indices in the order they're shown this round.
    private(set) var order: [Int] = []
    /// The true statement's index, once the player has found it this round.
    private(set) var picked: Int?
    /// False statements the player has picked and ruled out this round.
    private(set) var ruledOut: Set<Int> = []
    /// Counts every pick, right or wrong, so the view can react to each one.
    private(set) var attempts = 0
    /// Whether each finished round was solved on the first try.
    private(set) var results: [Bool] = []

    init(painting: Painting) {
        self.painting = painting
        shuffle()
    }

    var isFinished: Bool { roundIndex >= painting.rounds.count }
    var round: Painting.Round? { isFinished ? nil : painting.rounds[roundIndex] }
    var isLastRound: Bool { roundIndex == painting.rounds.count - 1 }
    var score: Int { results.filter { $0 }.count }
    var focus: Painting.Focus { round?.focus ?? .whole }
    var isSolved: Bool { picked != nil }
    var solvedFirstTry: Bool { isSolved && ruledOut.isEmpty }

    func pick(_ index: Int) {
        guard let round, picked == nil, !ruledOut.contains(index) else { return }
        attempts += 1
        if round.statements[index].isTrue {
            picked = index
            results.append(ruledOut.isEmpty)
        } else {
            ruledOut.insert(index)
        }
    }

    func next() {
        guard picked != nil else { return }
        roundIndex += 1
        resetRound()
    }

    func restart() {
        roundIndex = 0
        results = []
        resetRound()
    }

    private func resetRound() {
        picked = nil
        ruledOut = []
        shuffle()
    }

    private func shuffle() {
        order = round.map { Array($0.statements.indices).shuffled() } ?? []
    }
}
