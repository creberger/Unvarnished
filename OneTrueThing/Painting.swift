import UIKit

/// One painting and its five rounds. Paintings live in the bundle as JSON files next to their
/// images (`<id>.jpg` and `<id>-thumb.jpg`); a file holds one painting or an array of them,
/// so adding a painting needs no code.
struct Painting: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var artist: String
    var artistDates: String
    var date: String
    var medium: String
    var collection: String
    var objectNumber: String?
    var imageDescription: String
    var credit: String
    /// The id of the `PaintingCategory` it belongs to.
    var category: String
    var rounds: [Round]

    struct Round: Codable, Hashable {
        var focus: Focus
        var `where`: String
        var prompt: String
        var hint: String
        var statements: [Statement]
    }

    /// The point to centre on, as fractions of the image, and how far to zoom in.
    struct Focus: Codable, Hashable {
        var x: Double
        var y: Double
        var zoom: Double

        static let whole = Focus(x: 0.5, y: 0.5, zoom: 1)
    }

    struct Statement: Codable, Hashable {
        var text: String
        var isTrue: Bool = false
        var why: String

        enum CodingKeys: CodingKey { case text, isTrue, why }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            text = try c.decode(String.self, forKey: .text)
            isTrue = try c.decodeIfPresent(Bool.self, forKey: .isTrue) ?? false
            why = try c.decode(String.self, forKey: .why)
        }
    }

    var uiImage: UIImage? { Self.bundleImage("\(id).jpg") }
    var thumbnail: UIImage? { Self.bundleImage("\(id)-thumb.jpg") ?? uiImage }

    /// Width divided by height, read from the image itself.
    var imageAspect: Double {
        guard let size = uiImage?.size, size.height > 0 else { return 0.8 }
        return size.width / size.height
    }

    var caption: String {
        [date, medium, collection, objectNumber].compactMap { $0 }.joined(separator: " · ")
    }

    /// Each round's question with its true answer; short answers only make sense next to the question.
    var trueFacts: [(question: String, answer: String)] {
        rounds.compactMap { round in round.statements.first(where: \.isTrue).map { (round.hint, $0.text) } }
    }

    private static let cache = NSCache<NSString, UIImage>()

    private static func bundleImage(_ name: String) -> UIImage? {
        if let cached = cache.object(forKey: name as NSString) { return cached }
        guard let image = Bundle.main.path(forResource: name, ofType: nil).flatMap(UIImage.init(contentsOfFile:))
        else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }

    /// Every painting in the bundle.
    static func loadAll() -> [Painting] {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .filter { $0.lastPathComponent != PaintingCategory.fileName }
        let decoder = JSONDecoder()
        return urls.flatMap { url -> [Painting] in
            guard let data = try? Data(contentsOf: url) else { return [] }
            if let many = try? decoder.decode([Painting].self, from: data) { return many }
            if let one = try? decoder.decode(Painting.self, from: data) { return [one] }
            assertionFailure("Couldn't read paintings in \(url.lastPathComponent)")
            return []
        }
        .sorted { $0.id < $1.id }
    }
}

/// A group of paintings the player can choose to play, such as Impressionism.
struct PaintingCategory: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    /// The years it covers, for display.
    var span: String

    static let fileName = "categories.json"

    /// The categories in display order.
    static func loadAll() -> [PaintingCategory] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil),
              let data = try? Data(contentsOf: url),
              let categories = try? JSONDecoder().decode([PaintingCategory].self, from: data)
        else { return [] }
        return categories
    }
}
