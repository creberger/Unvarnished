import SwiftUI

@main
struct OneTrueThingApp: App {
    @State private var library = Library()

    var body: some Scene {
        WindowGroup {
            RootView(library: library)
        }
    }
}

enum Route: Hashable {
    case play(String)
    case collection
    case collected(String)
}

struct RootView: View {
    let library: Library
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(library: library, path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .play(let id):
                        if let painting = library.painting(id) {
                            QuizScreen(painting: painting, library: library) {
                                // Swap this game for the next painting rather than stacking games up.
                                if let next = library.next(after: painting) {
                                    path = [.play(next.id)]
                                } else {
                                    path = [.collection]
                                }
                            }
                            .id(id)
                        }
                    case .collection:
                        CollectionView(library: library)
                    case .collected(let id):
                        if let painting = library.painting(id) {
                            CollectionDetailView(painting: painting, library: library)
                        }
                    }
                }
        }
        .tint(Theme.ultramarine)
    }
}
