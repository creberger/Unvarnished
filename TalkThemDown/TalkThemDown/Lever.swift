import Foundation

/// One of the ten persuasive words. Each stands for a technique from the persuasion literature.
/// Weights are game-design choices, roughly ordered by how solid the evidence looked. They are not measured effect sizes.
struct Lever: Identifiable, Hashable {
    enum Evidence: String {
        case stronger, moderate, weak
    }

    /// The word itself, shown once found.
    let id: String
    /// Clue shown while the word is still hidden.
    let hint: String
    /// Word forms that count as using it.
    let forms: Set<String>
    let weight: Int
    let technique: String
    let source: String
    let evidence: Evidence
    let evidenceNote: String

    static let all: [Lever] = [
        Lever(id: "opposite", hint: "Flip the question", forms: ["opposite"], weight: 14,
              technique: "Consider the opposite",
              source: "Lord, Lepper & Preston (1984), Journal of Personality and Social Psychology 47(6)",
              evidence: .stronger, evidenceNote: "Experimental; reduced biased judgment"),
        Lever(id: "suppose", hint: "Picture it already failed", forms: ["suppose", "supposed", "supposing"], weight: 12,
              technique: "Premortem / prospective hindsight",
              source: "Klein (2007), Harvard Business Review; Mitchell, Russo & Pennington (1989)",
              evidence: .moderate, evidenceNote: "About 30% more reasons generated, per secondary sources"),
        Lever(id: "imagine", hint: "Make it vivid", forms: ["imagine", "imagined", "imagines", "imagining"], weight: 12,
              technique: "Imagined scenarios",
              source: "Gregory, Cialdini & Carpenter (1982), Journal of Personality and Social Psychology 43",
              evidence: .moderate, evidenceNote: "Field study; reported percentages not checked against the paper"),
        Lever(id: "evidence", hint: "Bring proof", forms: ["evidence"], weight: 11,
              technique: "Strong arguments when the stakes are high",
              source: "Petty & Cacioppo, Elaboration Likelihood Model (from memory, not checked)",
              evidence: .moderate, evidenceNote: "Widely cited; source not verified here"),
        Lever(id: "others", hint: "What everyone else thinks", forms: ["others"], weight: 11,
              technique: "Social norms",
              source: "Goldstein, Cialdini & Griskevicius (2008), Journal of Consumer Research 35",
              evidence: .stronger, evidenceNote: "Two field experiments"),
        Lever(id: "admire", hint: "Respect who they are", forms: ["admire", "admired", "admires", "admiring", "admiration"], weight: 10,
              technique: "Self-affirmation lowers defensiveness",
              source: "Cohen & Sherman (2014), Annual Review of Psychology 65",
              evidence: .moderate, evidenceNote: "Supported, with boundary conditions"),
        Lever(id: "because", hint: "Give a reason", forms: ["because"], weight: 9,
              technique: "Giving a reason",
              source: "Langer, Blank & Chanowitz (1978), Journal of Personality and Social Psychology 36",
              evidence: .moderate, evidenceNote: "Classic study of small requests; replication status unclear"),
        Lever(id: "lose", hint: "Name the cost", forms: ["lose", "loses", "losing", "lost", "loss"], weight: 8,
              technique: "Loss framing",
              source: "Tversky & Kahneman (1981), Science (from memory, not checked)",
              evidence: .weak, evidenceNote: "Evidence for persuasion is mixed (from memory)"),
        Lever(id: "choice", hint: "Hand back control", forms: ["choice", "choose", "chosen"], weight: 7,
              technique: "\u{201C}But you are free\u{201D} / choice language",
              source: "Carpenter (2013) meta-analysis; 2020 reanalysis in Meta-Psychology",
              evidence: .weak, evidenceNote: "Reanalysis of low-risk studies found no clear effect"),
        Lever(id: "instead", hint: "Offer another path", forms: ["instead"], weight: 6,
              technique: "Offer an alternative",
              source: "No verified source",
              evidence: .weak, evidenceNote: "Design choice, not evidence"),
    ]

    /// Controlling language and insults, which tend to provoke resistance (reactance).
    static let pushyWords: Set<String> = ["must", "stupid", "idiot", "idiotic", "fool", "foolish",
                                          "insane", "crazy", "moron", "dumb"]
    static let pushyPhrases = ["have to", "has to", "got to"]
    static let pushySource = "Ma, Ebesu & Dillard meta-analysis (Journal of Communication); Reynolds-Tylus (2020)"
}
