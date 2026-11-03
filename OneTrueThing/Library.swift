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
    /// Painting id → when it was acquired for the collection. Stored under "retired", its original name.
    private(set) var retired: [String: Date]
    /// Paintings the player has started at least once.
    private(set) var played: Set<String>

    private let defaults: UserDefaults
    private static let retiredKey = "retired"
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
        let stored = defaults.dictionary(forKey: Self.retiredKey) as? [String: Double] ?? [:]
        retired = stored.mapValues(Date.init(timeIntervalSince1970:))
        played = Set(defaults.stringArray(forKey: Self.playedKey) ?? [])
    }

    var active: [Painting] { paintings.filter { retired[$0.id] == nil } }

    /// Retired paintings, most recent first.
    var successes: [(painting: Painting, date: Date)] {
        paintings.compactMap { p in retired[p.id].map { (p, $0) } }.sorted { $0.date > $1.date }
    }

    func painting(_ id: String) -> Painting? { paintings.first { $0.id == id } }

    func category(_ id: String?) -> PaintingCategory? { categories.first { $0.id == id } }

    /// Paintings in a category, or all of them for nil.
    func paintings(in category: String?) -> [Painting] {
        guard let category else { return paintings }
        return paintings.filter { $0.category == category }
    }

    func retiredCount(in category: String?) -> Int {
        paintings(in: category).filter { retired[$0.id] != nil }.count
    }

    func isRetired(_ painting: Painting) -> Bool { retired[painting.id] != nil }

    /// A painting still in play in the selected category, preferring ones the player hasn't seen yet.
    func next(after current: Painting? = nil) -> Painting? {
        let inPlay = paintings(in: selectedCategory).filter { retired[$0.id] == nil }
        let candidates = inPlay.filter { $0.id != current?.id }
        let unseen = candidates.filter { !played.contains($0.id) }
        return (unseen.isEmpty ? candidates : unseen).randomElement() ?? inPlay.first
    }

    func markPlayed(_ painting: Painting) {
        guard played.insert(painting.id).inserted else { return }
        defaults.set(Array(played), forKey: Self.playedKey)
    }

    /// Records a finished game. Five out of five retires the painting; returns true if it just did.
    @discardableResult
    func record(_ painting: Painting, score: Int) -> Bool {
        guard score == painting.rounds.count, retired[painting.id] == nil else { return false }
        retired[painting.id] = .now
        defaults.set(retired.mapValues(\.timeIntervalSince1970), forKey: Self.retiredKey)
        return true
    }
}
