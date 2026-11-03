import SwiftUI

/// The first screen: pick a category, and the first painting from it opens straight away.
struct HomeView: View {
    let library: Library
    @Binding var path: [Route]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Unvarnished")
                        .font(Theme.display(36))
                    Text("A painting, five details, three statements each. Only one is true.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("CHOOSE A CATEGORY")
                        .font(Theme.mono(12, weight: .medium))
                        .foregroundStyle(Theme.muted)
                    ForEach(library.categories) { category in
                        categoryRow(id: category.id, name: category.name, span: category.span)
                    }
                    categoryRow(id: nil, name: "All paintings", span: "Any period, at random")
                }

                collectionRow

                Text("Images from the Met, the Cleveland Museum of Art and Wikimedia Commons. Every painting shown is in the public domain.")
                    .font(Theme.mono(11))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background { MosaicBackground().ignoresSafeArea() }
        .foregroundStyle(Theme.ink)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Choosing a category plays its next painting; once all are acquired it opens the collection.
    private func start(_ id: String?) {
        library.selectedCategory = id
        if let painting = library.next() {
            path.append(.play(painting.id))
        } else {
            path.append(.collection)
        }
    }

    private func categoryRow(id: String?, name: String, span: String) -> some View {
        let total = library.paintings(in: id).count
        let done = library.retiredCount(in: id)
        let complete = done == total
        return Button { start(id) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(Theme.display(21))
                        Text(span)
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    if complete {
                        Label("Complete", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.truth)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.muted)
                    }
                }
                HStack(spacing: 10) {
                    // Progress toward acquiring every painting in the category.
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Theme.rule
                            (complete ? Theme.truth : Theme.ultramarine)
                                .frame(width: total > 0 ? geo.size.width * CGFloat(done) / CGFloat(total) : 0)
                        }
                    }
                    .frame(height: 4)
                    Text("\(done) of \(total)")
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 72, alignment: .trailing)
                }
            }
            .padding(16)
            .background(Theme.label.opacity(0.88))
            .overlay(Rectangle().stroke(Theme.rule, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name), \(span). \(done) of \(total) acquired.")
        .accessibilityHint(complete ? "Opens your collection" : "Starts the next painting")
    }

    private var collectionRow: some View {
        Button { path.append(.collection) } label: {
            HStack(spacing: 14) {
                Image(systemName: "building.columns.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.ultramarine)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Collection")
                        .font(.body.weight(.semibold))
                    Text("\(library.successes.count) of \(library.paintings.count) acquired")
                        .font(Theme.mono(12))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.muted)
            }
            .padding(16)
            .background(Theme.label.opacity(0.88))
            .overlay(Rectangle().stroke(Theme.rule, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Every painting in black and white, tiled and faded into the gallery wall behind the start screen.
/// The image is made by tools/make_mosaic.py.
private struct MosaicBackground: View {
    private static let image = UIImage(named: "home-mosaic.jpg")

    var body: some View {
        ZStack {
            Theme.wall
            if let image = Self.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.24)
                    .accessibilityHidden(true)
            }
            // Fade the mosaic out behind the title, where the text sits straight on it.
            LinearGradient(colors: [Theme.wall, Theme.wall.opacity(0)], startPoint: .top, endPoint: .init(x: 0.5, y: 0.3))
        }
    }
}

/// A painting's thumbnail in a thin dark frame.
struct FramedThumbnail: View {
    let painting: Painting

    var body: some View {
        Group {
            if let image = painting.thumbnail {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fit)
            } else {
                Theme.rule
            }
        }
        .padding(6)
        .background(Theme.frame)
        .shadow(color: .black.opacity(0.25), radius: 8, y: 5)
    }
}
