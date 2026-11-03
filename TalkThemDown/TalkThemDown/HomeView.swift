import SwiftUI

/// Lists the cases. Choosing one opens the conversation.
struct HomeView: View {
    @State private var showingResearch = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Scenario.all) { scenario in
                        NavigationLink {
                            GameView(scenario: scenario)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(scenario.name).font(.headline)
                                Text(scenario.when).font(.subheadline).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } footer: {
                    Text("Find the ten persuasive words hidden in each case. Get them past \(Game.threshold)% in \(Game.maxTurns) messages.")
                }
            }
            .navigationTitle("Talk Them Down")
            .toolbar {
                Button("Why these words") { showingResearch = true }
            }
            .sheet(isPresented: $showingResearch) {
                ResearchView()
            }
        }
    }
}

#Preview {
    HomeView()
}
