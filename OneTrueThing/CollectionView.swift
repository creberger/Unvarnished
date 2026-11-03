import SwiftUI

/// Paintings the player has acquired by getting all five rounds right.
struct CollectionView: View {
    let library: Library

    private let columns = [GridItem(.flexible(), spacing: 16, alignment: .top),
                           GridItem(.flexible(), spacing: 16, alignment: .top)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Collection")
                        .font(Theme.display(32))
                    Text("\(library.collection.count) of \(library.paintings.count) acquired")
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.muted)
                }

                if library.collection.isEmpty {
                    Text("Get all five rounds of a painting right and it's acquired for your collection, out of the game.")
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(sections, id: \.category.id) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(section.category.name)
                                    .font(Theme.display(21))
                                Spacer()
                                Text("\(section.items.count) of \(library.paintings(in: section.category.id).count)")
                                    .font(Theme.mono(12))
                                    .foregroundStyle(Theme.muted)
                            }
                            .padding(.bottom, 6)
                            .overlay(alignment: .bottom) { Theme.rule.frame(height: 1) }
                            grid(section.items)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Theme.wall.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.wall, for: .navigationBar)
    }

    private struct Section {
        let category: PaintingCategory
        let items: [(painting: Painting, date: Date)]
    }

    /// Acquired paintings grouped by category, in category order, skipping empty ones.
    private var sections: [Section] {
        let collection = library.collection
        return library.categories.compactMap { category -> Section? in
            let items = collection.filter { $0.painting.category == category.id }
            return items.isEmpty ? nil : Section(category: category, items: items)
        }
    }

    private func grid(_ items: [(painting: Painting, date: Date)]) -> some View {
        LazyVGrid(columns: columns, spacing: 22) {
            ForEach(items, id: \.painting.id) { item in
                NavigationLink(value: Route.collected(item.painting.id)) {
                    VStack(alignment: .leading, spacing: 8) {
                        FramedThumbnail(painting: item.painting)
                            .frame(maxWidth: .infinity, maxHeight: 170, alignment: .bottom)
                            .frame(height: 170, alignment: .bottom)
                        Text(item.painting.title)
                            .font(Theme.display(16))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(item.painting.artist)
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// An acquired painting with the five true things learned about it.
struct CollectionDetailView: View {
    let painting: Painting
    let library: Library

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PaintingView(painting: painting, focus: .whole, label: "In your collection")
                    .frame(maxHeight: 420)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(painting.artist) (\(painting.artistDates))".uppercased())
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(Theme.muted)
                    Text(painting.title)
                        .font(Theme.display(30))
                    Text(painting.caption)
                        .font(Theme.mono(11.5))
                        .foregroundStyle(Theme.muted)
                    if let date = library.acquired[painting.id] {
                        Label("Acquired \(date.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.truth)
                            .padding(.top, 6)
                    }
                }

                if let summary = painting.summary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About the painting")
                            .font(Theme.display(21))
                        Text(summary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Five true things")
                        .font(Theme.display(21))
                    ForEach(Array(painting.trueFacts.enumerated()), id: \.offset) { _, fact in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Theme.truth)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fact.question)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.muted)
                                Text(fact.answer)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                NavigationLink("Play it again", value: Route.play(painting.id))
                    .buttonStyle(SecondaryButton())

                Text(painting.credit)
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Theme.wall.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.wall, for: .navigationBar)
    }
}
