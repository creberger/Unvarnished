import Foundation
import Observation

/// Walks through one painting's rounds: pick a statement, see which was true, move on.
@Observable
final class Quiz {
    let painting: Painting
    private(set) var roundIndex = 0
    /// Statement indices in the order they're shown this round.
    private(set) var order: [Int] = []
    /// The statement index the player picked this round, once they have.
    private(set) var picked: Int?
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

    func pick(_ index: Int) {
        guard let round, picked == nil else { return }
        picked = index
        results.append(round.statements[index].isTrue)
    }

    func next() {
        guard picked != nil else { return }
        roundIndex += 1
        picked = nil
        shuffle()
    }

    func restart() {
        roundIndex = 0
        picked = nil
        results = []
        shuffle()
    }

    private func shuffle() {
        order = round.map { Array($0.statements.indices).shuffled() } ?? []
    }
}
