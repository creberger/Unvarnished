import Foundation
import Observation

/// All the paintings, and which ones the player has acquired for their collection by getting all five rounds right.
@Observable
final class Library {
    let paintings: [Painting]
    let categories: [PaintingCategory]
    /// The category the player is playing, or nil for all paintings.
    var selectedCategory: String? {
        didSet { defaults.set(selectedCategory, forKey: Self.categoryKey) }
    }
    /// Painting id → when it was acquired for the collection.
    private(set) var acquired: [String: Date]
    /// Paintings the player has started at least once.
    private(set) var played: Set<String>

    private let defaults: UserDefaults
    private static let acquiredKey = "retired"  // the original name, kept so saved progress still loads
    private static let playedKey = "played"
    private static let categoryKey = "category"

    init(paintings: [Painting] = Painting.loadAll(),
         categories: [PaintingCategory] = PaintingCategory.loadAll(),
         defaults: UserDefaults = .standard) {
        self.paintings = paintings
        self.categories = categories
        self.defaults = defaults
        selectedCategory = defaults.string(forKey: Self.categoryKey).flatMap { id in
            categories.contains { $0.id == id } ? id : nil
        }
        let stored = defaults.dictionary(forKey: Self.acquiredKey) as? [String: Double] ?? [:]
        acquired = stored.mapValues(Date.init(timeIntervalSince1970:))
        played = Set(defaults.stringArray(forKey: Self.playedKey) ?? [])
    }

    /// Acquired paintings, most recent first.
    var collection: [(painting: Painting, date: Date)] {
        paintings.compactMap { p in acquired[p.id].map { (p, $0) } }.sorted { $0.date > $1.date }
    }

    func painting(_ id: String) -> Painting? { paintings.first { $0.id == id } }

    /// Paintings in a category, or all of them for nil.
    func paintings(in category: String?) -> [Painting] {
        guard let category else { return paintings }
        return paintings.filter { $0.category == category }
    }

    func acquiredCount(in category: String?) -> Int {
        paintings(in: category).filter { acquired[$0.id] != nil }.count
    }

    func isAcquired(_ painting: Painting) -> Bool { acquired[painting.id] != nil }

    /// A painting still in play in the selected category, preferring ones the player hasn't seen yet.
    func next(after current: Painting? = nil) -> Painting? {
        let inPlay = paintings(in: selectedCategory).filter { acquired[$0.id] == nil }
        let candidates = inPlay.filter { $0.id != current?.id }
        let unseen = candidates.filter { !played.contains($0.id) }
        return (unseen.isEmpty ? candidates : unseen).randomElement() ?? inPlay.first
    }

    func markPlayed(_ painting: Painting) {
        guard played.insert(painting.id).inserted else { return }
        defaults.set(Array(played), forKey: Self.playedKey)
    }

    /// Records a finished game. Five out of five acquires the painting; returns true if it just did.
    @discardableResult
    func record(_ painting: Painting, score: Int) -> Bool {
        guard score == painting.rounds.count, acquired[painting.id] == nil else { return false }
        acquired[painting.id] = .now
        defaults.set(acquired.mapValues(\.timeIntervalSince1970), forKey: Self.acquiredKey)
        return true
    }
}
