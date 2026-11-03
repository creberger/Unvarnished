import SwiftUI

/// Explains where the ten words come from and how honest the weights are.
struct ResearchView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("There's no research ranking single words by how persuasive they are. Each word stands for a technique tested in published studies, and the evidence varies. The weights are game design choices, roughly ordered by how solid the evidence looked. They are not measured effect sizes.")
                        .font(.callout)
                }
                Section("The ten words") {
                    ForEach(Lever.all) { lever in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(lever.id).font(.headline.monospaced())
                                Spacer()
                                Text("+\(lever.weight)").font(.subheadline.monospaced()).foregroundStyle(.secondary)
                            }
                            Text(lever.technique)
                            Text(lever.source).font(.caption).foregroundStyle(.secondary)
                            Text("\(lever.evidence.rawValue.capitalized) evidence: \(lever.evidenceNote)")
                                .font(.caption)
                                .foregroundStyle(color(for: lever.evidence))
                        }
                        .padding(.vertical, 2)
                    }
                }
                Section("Words that backfire") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("must, have to, insults").font(.headline.monospaced())
                        Text("Controlling language makes people resist. Each pushy message costs \(Game.pushyPenalty) points.")
                        Text(Lever.pushySource).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text("The historical notes summarise well-documented events. Everything the characters say is invented dialogue, not real quotes. The Challenger launch manager is a composite character, not a real person.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Why these words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }

    private func color(for evidence: Lever.Evidence) -> Color {
        switch evidence {
        case .stronger: .green
        case .moderate: .orange
        case .weak: .red
        }
    }
}

#Preview {
    ResearchView()
}
