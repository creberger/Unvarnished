import SwiftUI
import UIKit

/// The conversation: their photo and plan, the persuasion meter, the ten word slots, and the chat.
struct GameView: View {
    @State private var game: Game
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    init(scenario: Scenario) {
        _game = State(initialValue: Game(scenario: scenario))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    meter
                    slots
                    ForEach(game.messages) { message in
                        MessageBubble(message: message)
                    }
                    if game.isOver { endCard }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding()
            }
            .onChange(of: game.messages.count) {
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
        .safeAreaInset(edge: .bottom) { inputBar }
        .navigationTitle(game.scenario.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Restart") {
                game.reset()
                draft = ""
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Portrait(scenario: game.scenario)
                .frame(width: 110)
            VStack(alignment: .leading, spacing: 8) {
                Text(game.scenario.when)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(game.scenario.opening)
                    .padding(12)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(.primary, lineWidth: 1.5))
                MoodBadge(mood: game.mood)
            }
        }
    }

    private var meter: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(game.percent)%")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .monospacedDigit()
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(game.found.count)/\(Lever.all.count) words found")
                    Text("\(game.turnsLeft) messages left")
                }
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule().fill(Color.accentColor)
                        .frame(width: geo.size.width * CGFloat(game.percent) / 100)
                    Rectangle().fill(.primary)
                        .frame(width: 2, height: 22)
                        .offset(x: geo.size.width * CGFloat(Game.threshold) / 100 - 1)
                }
            }
            .frame(height: 14)
            .animation(.easeOut(duration: 0.4), value: game.percent)
            Text("Changes their mind at \(Game.threshold)%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var slots: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(Lever.all) { lever in
                WordSlot(lever: lever, found: game.found.contains(lever.id))
            }
        }
    }

    private var endCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.won ? "You talked them down" : "They went ahead")
                .font(.title2.weight(.semibold))
                .fontDesign(.serif)
            Text("\(game.won ? "Final score" : "You reached") \(game.percent)% with \(game.found.count) of \(Lever.all.count) words in \(game.turns) message\(game.turns == 1 ? "" : "s").")
            Text(game.scenario.history)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.primary, lineWidth: 1.5))
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Talk them out of it…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit(send)
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
            Button("Say it", action: send)
                .buttonStyle(.borderedProminent)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || game.isOver)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .disabled(game.isOver)
    }

    private func send() {
        game.say(draft)
        draft = ""
        if game.isOver { inputFocused = false }
    }
}

// MARK: - Pieces

/// A public-domain photo if the asset exists, otherwise a sepia placeholder.
private struct Portrait: View {
    let scenario: Scenario

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if UIImage(named: scenario.photo) != nil {
                    Image(scenario.photo).resizable().scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(colors: [Color(red: 0.79, green: 0.69, blue: 0.55),
                                                Color(red: 0.43, green: 0.35, blue: 0.25)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
            }
            .aspectRatio(4 / 5, contentMode: .fit)
            .clipped()
            .border(Color(white: 0.95), width: 4)
            .accessibilityHidden(true)
            Text(scenario.photoCaption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MoodBadge: View {
    let mood: Game.Mood

    var color: Color {
        switch mood {
        case .determined: .red
        case .wavering: .orange
        case .persuaded: .green
        }
    }

    var body: some View {
        Text(mood.label.uppercased())
            .font(.caption2.monospaced().weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .overlay(Capsule().stroke(color))
    }
}

private struct WordSlot: View {
    let lever: Lever
    let found: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(found ? lever.id : String(repeating: "_", count: lever.id.count))
                .font(.subheadline.monospaced().weight(.semibold))
                .tracking(found ? 0.5 : 2)
                .foregroundStyle(found ? Color.accentColor : .primary)
            Text(lever.hint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("+\(lever.weight)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(found ? Color.accentColor.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(found ? Color.accentColor : Color(.separator),
                        style: StrokeStyle(lineWidth: 1, dash: found ? [] : [4]))
        )
        .animation(.spring(duration: 0.4), value: found)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(found ? "\(lever.id), found" : "Hidden word, \(lever.id.count) letters. Hint: \(lever.hint)")
    }
}

private struct MessageBubble: View {
    let message: Game.Message

    var body: some View {
        HStack {
            if message.fromPlayer { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 6) {
                Text(message.text)
                if !message.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(message.tags, id: \.self) { tag in
                            Text(tag.text)
                                .font(.caption2.monospaced())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(background(for: tag.kind), in: RoundedRectangle(cornerRadius: 4))
                                .foregroundStyle(tag.kind == .used ? Color.primary : Color.white)
                        }
                    }
                }
            }
            .padding(12)
            .background(message.fromPlayer ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.primary, lineWidth: 1.5))
            if !message.fromPlayer { Spacer(minLength: 40) }
        }
    }

    private func background(for kind: Game.Tag.Kind) -> Color {
        switch kind {
        case .gain: .accentColor
        case .used: Color(.systemFill)
        case .pushy: .red
        }
    }
}

#Preview {
    NavigationStack {
        GameView(scenario: .wilde)
    }
}
