import SwiftUI

struct HomeView: View {
    let library: Library
    @Binding var path: [Route]
    @State private var upNextID: String?

    /// The painting on offer, if it's still in play in the chosen category.
    private var upNext: Painting? {
        guard let painting = upNextID.flatMap(library.painting), !library.isRetired(painting) else { return nil }
        if let category = library.selectedCategory, painting.category != category { return nil }
        return painting
    }

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

                categoryPicker

                if let painting = upNext {
                    upNextCard(painting)
                } else {
                    allDone
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
        .background(Theme.wall.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { if upNext == nil { upNextID = library.next()?.id } }
    }

    private func upNextCard(_ painting: Painting) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("NEXT PAINTING")
                    .font(Theme.mono(12, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .accessibilityLabel("Next painting, from \(library.category(painting.category)?.name ?? "")")
                Spacer()
                Button {
                    withAnimation { upNextID = library.next(after: painting)?.id }
                } label: {
                    Label("Another", systemImage: "shuffle")
                        .font(.subheadline.weight(.medium))
                }
            }

            Button { path.append(.play(painting.id)) } label: {
                FramedThumbnail(painting: painting)
                    .frame(maxHeight: 340)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(painting.title)")

            VStack(alignment: .leading, spacing: 2) {
                Text(painting.title)
                    .font(Theme.display(24))
                Text("\(painting.artist), \(painting.date)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }

            Button("Look closer →") { path.append(.play(painting.id)) }
                .buttonStyle(PrimaryButton())
        }
    }

    private var allDone: some View {
        let category = library.category(library.selectedCategory)
        let count = library.paintings(in: library.selectedCategory).count
        return VStack(alignment: .leading, spacing: 8) {
            Text(category.map { "Every painting in \($0.name) is in your collection." } ?? "Every painting is in your collection.")
                .font(Theme.display(24))
                .fixedSize(horizontal: false, vertical: true)
            Text("All \(count) are acquired. You can replay any of them from your collection, or pick another category.")
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Chips for choosing which category the next painting comes from, with progress in each.
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(id: nil, name: "All")
                ForEach(library.categories) { category in
                    chip(id: category.id, name: category.name)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
    }

    private func chip(id: String?, name: String) -> some View {
        let selected = library.selectedCategory == id
        let total = library.paintings(in: id).count
        let done = library.retiredCount(in: id)
        return Button {
            withAnimation {
                library.selectedCategory = id
                upNextID = library.next()?.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                Text("\(done)/\(total)")
                    .font(Theme.mono(11))
                    .opacity(0.75)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? Theme.label : Theme.ink)
            .background(selected ? Theme.ultramarine : Theme.label)
            .overlay(Rectangle().stroke(selected ? Theme.ultramarine : Theme.rule, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name), \(done) of \(total) acquired")
        .accessibilityAddTraits(selected ? .isSelected : [])
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
            .background(Theme.label)
            .overlay(Rectangle().stroke(Theme.rule, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
