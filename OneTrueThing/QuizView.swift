import SwiftUI

/// Plays one painting. Owns its own quiz so each painting starts fresh.
struct QuizScreen: View {
    let library: Library
    let onNext: () -> Void
    @State private var quiz: Quiz
    @State private var acquiredNow = false

    init(painting: Painting, library: Library, onNext: @escaping () -> Void) {
        self.library = library
        self.onNext = onNext
        _quiz = State(initialValue: Quiz(painting: painting))
    }

    var body: some View {
        QuizView(quiz: quiz, acquiredNow: acquiredNow, alreadyAcquired: library.isAcquired(quiz.painting) && !acquiredNow, onNext: onNext)
            .onAppear { library.markPlayed(quiz.painting) }
            .onChange(of: quiz.isFinished) { _, finished in
                guard finished else { acquiredNow = false; return }
                acquiredNow = library.record(quiz.painting, score: quiz.score)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.wall, for: .navigationBar)
    }
}

struct QuizView: View {
    let quiz: Quiz
    var acquiredNow = false
    var alreadyAcquired = false
    var onNext: () -> Void = {}

    var body: some View {
        // One scroll view with the painting pinned as its header: the zoom stays in view while the
        // wall label scrolls beneath it, and a swipe that starts on the painting still scrolls.
        GeometryReader { screen in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Color.clear.frame(height: 0).id("top")
                        Section {
                            VStack(alignment: .leading, spacing: 20) {
                                caption
                                progress

                                if let round = quiz.round {
                                    RoundView(quiz: quiz, round: round)
                                } else {
                                    EndView(quiz: quiz, acquiredNow: acquiredNow, alreadyAcquired: alreadyAcquired, onNext: onNext)
                                }

                                Text("\(quiz.painting.credit). One statement per detail is true.")
                                    .font(Theme.mono(11))
                                    .foregroundStyle(Theme.muted)
                                    .padding(.top, 8)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        } header: {
                            PaintingView(painting: quiz.painting,
                                         focus: quiz.focus,
                                         label: quiz.round?.where ?? "Full painting")
                                // Once the game is over there's nothing left to zoom into, so the
                                // painting shrinks to leave room for reading the summary.
                                .frame(height: screen.size.height * (quiz.isFinished ? 0.24 : 0.46))
                                .animation(.easeInOut(duration: 0.5), value: quiz.isFinished)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                                .background(Theme.wall)
                        }
                    }
                }
                .onChange(of: quiz.roundIndex) {
                    withAnimation(.easeInOut(duration: 0.4)) { proxy.scrollTo("top", anchor: .top) }
                }
            }
        }
        .background(Theme.wall.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(quiz.painting.artist) (\(quiz.painting.artistDates))".uppercased())
                .font(.system(size: 12, weight: .medium))
                .tracking(1)
                .foregroundStyle(Theme.muted)
            Text(quiz.painting.title)
                .font(Theme.display(32))
            Text(quiz.painting.caption)
                .font(Theme.mono(11.5))
                .foregroundStyle(Theme.muted)
        }
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { Theme.rule.frame(height: 1) }
    }

    private var progress: some View {
        HStack(spacing: 12) {
            Text(quiz.isFinished ? "DONE" : "DETAIL \(quiz.roundIndex + 1) OF \(quiz.painting.rounds.count)")
                .font(Theme.mono(12, weight: .medium))
                .foregroundStyle(Theme.muted)
            HStack(spacing: 6) {
                ForEach(quiz.painting.rounds.indices, id: \.self) { i in
                    Rectangle()
                        .fill(dotColor(i))
                        .frame(width: 22, height: 6)
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func dotColor(_ i: Int) -> Color {
        if i < quiz.results.count { return quiz.results[i] ? Theme.truth : Theme.falsehood }
        return i == quiz.roundIndex ? Theme.ultramarine : Theme.rule
    }
}

private struct RoundView: View {
    let quiz: Quiz
    let round: Painting.Round
    /// When the true statement was found, which starts the countdown to the next detail.
    @State private var solvedAt: Date?

    /// Once the true statement is found, the next detail starts by itself after this long.
    private static let autoAdvanceDelay: Double = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(round.prompt)
                .font(Theme.display(23))
                .fixedSize(horizontal: false, vertical: true)
            Text(round.hint)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)

            if quiz.isSolved {
                Text(quiz.solvedFirstTry ? "Right. That one is true." : "That's the one.")
                    .font(Theme.display(19))
                    .foregroundStyle(quiz.solvedFirstTry ? Theme.truth : Theme.ink)
            } else if !quiz.ruledOut.isEmpty {
                Text("Not that one. Try again.")
                    .font(Theme.display(19))
                    .foregroundStyle(Theme.falsehood)
            }

            VStack(spacing: 10) {
                ForEach(Array(quiz.order.enumerated()), id: \.element) { position, index in
                    StatementButton(letter: ["A", "B", "C", "D"][position],
                                    statement: round.statements[index],
                                    revealed: quiz.isSolved,
                                    ruledOut: quiz.ruledOut.contains(index),
                                    picked: quiz.picked == index) {
                        withAnimation(.easeOut(duration: 0.25)) { quiz.pick(index) }
                    }
                }
            }

            if quiz.isSolved {
                Button { withAnimation { quiz.next() } } label: {
                    CountdownLabel(title: quiz.isLastRound ? "See your score" : "Look closer →",
                                   start: solvedAt, duration: Self.autoAdvanceDelay)
                }
                .buttonStyle(CountdownButton())
                .padding(.top, 4)
            }
        }
        .task(id: quiz.picked) {
            solvedAt = nil
            guard let picked = quiz.picked else { return }
            solvedAt = .now
            try? await Task.sleep(for: .seconds(Self.autoAdvanceDelay))
            // Cancelled if the player moved on themselves or left the screen.
            guard !Task.isCancelled, quiz.picked == picked else { return }
            withAnimation { quiz.next() }
        }
        .sensoryFeedback(trigger: quiz.attempts) { _, _ in
            quiz.isSolved ? .success : .error
        }
    }
}

private struct StatementButton: View {
    let letter: String
    let statement: Painting.Statement
    /// The round is solved: every statement shows whether it's true and why.
    let revealed: Bool
    /// The player picked this false statement; it's greyed out and can't be picked again.
    let ruledOut: Bool
    /// The player picked this true statement.
    let picked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Text(letter)
                    .font(Theme.mono(13, weight: .medium))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(revealed && statement.isTrue ? Theme.label : keyColor)
                    .background(revealed && statement.isTrue ? Theme.truth : .clear)
                    .overlay(Rectangle().stroke(keyColor, lineWidth: 1))

                VStack(alignment: .leading, spacing: 6) {
                    if revealed {
                        Text(statement.isTrue ? "TRUE" : "FALSE")
                            .font(Theme.mono(11, weight: .semibold))
                            .tracking(0.8)
                            .foregroundStyle(statement.isTrue ? Theme.truth : Theme.falsehood)
                    }
                    Text(statement.text)
                        .font(.body)
                    if revealed {
                        Text(statement.why)
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(Theme.label)
            .overlay(Rectangle().stroke(borderColor, lineWidth: picked ? 1.5 : 1))
            .opacity(ruledOut ? 0.4 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!revealed && !ruledOut)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(picked ? .isSelected : [])
    }

    private var accessibilityText: String {
        if revealed { return "\(statement.isTrue ? "True" : "False"). \(statement.text) \(statement.why)" }
        return ruledOut ? "Ruled out. \(statement.text)" : statement.text
    }

    private var keyColor: Color {
        guard revealed else { return Theme.muted }
        return statement.isTrue ? Theme.truth : Theme.falsehood
    }

    private var borderColor: Color {
        revealed && statement.isTrue ? Theme.truth : Theme.rule
    }
}

private struct EndView: View {
    let quiz: Quiz
    let acquiredNow: Bool
    let alreadyAcquired: Bool
    let onNext: () -> Void

    private let verdicts = ["A fresh pair of eyes.", "You noticed something.", "A good look.",
                            "A careful looker.", "Nearly a curator.", "Curator-level."]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(quiz.score)")
                    .font(Theme.display(64))
                    .foregroundStyle(Theme.ultramarine)
                Text("/ \(quiz.painting.rounds.count)")
                    .font(Theme.display(24))
                    .foregroundStyle(Theme.muted)
            }
            .accessibilityElement(children: .combine)

            Text(verdicts[min(quiz.score, verdicts.count - 1)])
                .font(Theme.display(19))

            if acquiredNow {
                Label("Five in a row. Acquired for your collection.", systemImage: "checkmark.seal.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.truth)
            } else if alreadyAcquired {
                Text("This painting is already in your collection.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            } else {
                Text("Get all five right to acquire it for your collection.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }

            HStack(spacing: 12) {
                Button("Next painting", action: onNext)
                    .buttonStyle(PrimaryButton())
                if !acquiredNow {
                    Button("Try again") { withAnimation { quiz.restart() } }
                        .buttonStyle(SecondaryButton())
                }
            }
            .padding(.top, 4)

            if let summary = quiz.painting.summary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About the painting")
                        .font(Theme.display(21))
                    Text(summary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)
            }

            Text("Your five answers")
                .font(Theme.display(21))
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(quiz.painting.rounds.indices, id: \.self) { i in
                    let right = quiz.results[i]
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: right ? "checkmark" : "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(right ? Theme.truth : Theme.falsehood)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(quiz.painting.rounds[i].hint)
                                .foregroundStyle(Theme.muted)
                            Text(quiz.painting.rounds[i].statements.first(where: \.isTrue)?.text ?? "")
                        }
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

/// The button's label with the countdown shown inside it: the button fills from left to right
/// and the seconds left count down, so it's clear the next detail is coming by itself.
private struct CountdownLabel: View {
    let title: String
    let start: Date?
    let duration: Double

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { context in
            let elapsed = start.map { context.date.timeIntervalSince($0) } ?? 0
            let progress = min(1, max(0, elapsed / duration))
            let secondsLeft = Int(ceil(duration - elapsed))
            HStack(spacing: 10) {
                Text(title)
                if start != nil, secondsLeft > 0 {
                    Text("\(secondsLeft)")
                        .font(Theme.mono(15, weight: .medium))
                        .monospacedDigit()
                        .opacity(0.8)
                        .contentTransition(.numericText(countsDown: true))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(alignment: .leading) {
                GeometryReader { geo in
                    Theme.ultramarine
                        .frame(width: geo.size.width * progress)
                }
            }
            .background(Theme.ultramarine.opacity(0.6))
        }
        .accessibilityLabel(title)
    }
}

private struct CountdownButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.label)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct SecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.ultramarine)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .overlay(Rectangle().stroke(Theme.ultramarine, lineWidth: 1.5))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.label)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Theme.ultramarine.opacity(configuration.isPressed ? 0.8 : 1))
    }
}
