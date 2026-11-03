import Foundation

/// A historical bad decision, and the person about to make it.
/// All dialogue is invented. None of it is a real quote.
struct Scenario: Identifiable, Hashable {
    let id: String
    let name: String
    let when: String
    /// Asset name for a public-domain photo. Falls back to a placeholder if the asset isn't in the catalog.
    let photo: String
    let photoCaption: String
    let opening: String
    /// Reply for each lever id.
    let lines: [String: String]
    let pushyReplies: [String]
    let deflections: [String]
    let repeatReply: String
    let win: String
    let lose: String
    let history: String

    func line(for leverID: String) -> String { lines[leverID] ?? "" }

    static let all: [Scenario] = [wilde, challenger]

    static let wilde = Scenario(
        id: "wilde",
        name: "Oscar Wilde",
        when: "London, March 1895",
        photo: "wilde",
        photoCaption: "Photo placeholder: a public-domain portrait of Wilde, such as Napoleon Sarony's 1882 photographs.",
        opening: "The Marquess of Queensberry left a card at my club accusing me of… well, you've heard. I'm going to prosecute him for criminal libel. Bosie says we'll crush him. The law will vindicate me.",
        lines: [
            "because": "A reason. Most people only bring me disapproval. Go on, I'm listening.",
            "imagine": "Imagine it… the court gallery full, every letter I ever wrote read aloud. I had pictured it rather differently.",
            "opposite": "The opposite? That I wouldn't be proving him wrong; he'd be proving himself right. What an unpleasant inversion.",
            "suppose": "Suppose it's all gone wrong and I'm looking back… the first thing to fail would be the witnesses. Theirs, not mine.",
            "lose": "Lose. I'd only thought about what I'd win. What would I lose? The plays. My name on the bills. My sons.",
            "evidence": "Evidence. His lawyers will go looking for it, won't they? Detectives. Hotel staff. Young men with long memories.",
            "admire": "You admire the plays? Then perhaps I've nothing to prove in a courtroom. My reputation lives on the stage.",
            "others": "Others… my friends all say drop it. Only Bosie says fight, and Bosie wants a war with his father more than he wants me safe.",
            "choice": "My choice. No one has said it was still a choice. It had begun to feel like a duty.",
            "instead": "Instead… Paris, perhaps. Let the card sit in a drawer. Let the Marquess shout at no one.",
        ],
        pushyReplies: [
            "Must? I have spent my life declining to do what I must. Try again.",
            "Insults are my trade, and you're not very good at it.",
        ],
        deflections: [
            "Charming. I'm still going to court.",
            "You sound like my solicitor before his fee arrived.",
            "Words, words. Give me something that changes the picture.",
            "How very sensible. I've never trusted sensible.",
        ],
        repeatReply: "You've said that already, and it was better the first time.",
        win: "Very well. I'll tell my solicitor to withdraw. Bosie will be furious. I find I can bear Bosie's fury better than the alternative.",
        lose: "Enough. The warrant is signed. I shall see you at the Old Bailey, from the better side of the dock, naturally.",
        history: "What actually happened: Wilde went ahead. Friends including Frank Harris and George Bernard Shaw reportedly urged him to drop it; Lord Alfred Douglas (Bosie) urged him on. The libel case collapsed within days once the defence prepared evidence about his private life. Queensberry was acquitted, Wilde was bankrupted by the costs, and on 25 May 1895 he was sentenced to two years' hard labour for gross indecency."
    )

    static let challenger = Scenario(
        id: "challenger",
        name: "Launch manager",
        when: "Night of 27 January 1986 · composite character",
        photo: "challenger",
        photoCaption: "Photo placeholder: a NASA photo of Challenger on the pad (NASA images are generally public domain in the US).",
        opening: "The forecast says it'll be below freezing at launch. The booster engineers are nervous about the seals in the cold, but they can't prove it'll fail. We've slipped this flight enough times. I'm signing off on launching in the morning.",
        lines: [
            "because": "Because… all right, that's a reason I could write in the log. It's more than a bad feeling.",
            "imagine": "Imagine the seal not seating at ignition. Hot gas finding the gap. With a schoolteacher on board and classrooms watching.",
            "opposite": "Flip it: they shouldn't have to prove it's unsafe, we should have to prove it's safe. …We can't. Nobody's flown this cold.",
            "suppose": "Suppose there's an inquiry next month and they play back tonight's call. What I just said would sound like pressure.",
            "lose": "We lose a day if we scrub. If we're wrong the other way, we lose the crew, and maybe the whole programme.",
            "evidence": "The evidence… the coldest launch so far was 53 degrees, and it showed the worst seal damage we've had. Tomorrow will be far colder.",
            "admire": "I do take pride in this team's record. I'd rather keep that than keep the schedule.",
            "others": "Others… every engineer who built that joint recommended against. When the builders say no, maybe that's the answer.",
            "choice": "It is my call. Nobody upstairs ordered a launch. I can stop this.",
            "instead": "Instead we wait for it to warm up. A day, two days. The shuttle isn't going anywhere.",
        ],
        pushyReplies: [
            "Don't tell me what I have to do. Everyone tonight is telling me what I have to do.",
            "Name-calling won't get the engineers back on the line.",
        ],
        deflections: [
            "Nobody's shown me data that says it fails. I need data, not nerves.",
            "We've flown with seal erosion before and come home fine.",
            "Every scrub costs us. I need something stronger than that.",
            "The schedule matters too. Give me a better argument.",
        ],
        repeatReply: "You already said that. I heard you the first time.",
        win: "All right. I'm calling it. No launch until it's above 53 degrees. Get the engineers back on the line.",
        lose: "I've heard enough. We're go for the morning.",
        history: "What actually happened: on the night of 27 January 1986, Morton Thiokol engineers recommended against launching below 53°F, the coldest previous launch. After NASA pushed back, Thiokol's managers met off the line and reversed the recommendation. Challenger launched on 28 January 1986 in near-freezing weather and broke apart 73 seconds after liftoff, killing all seven crew. The investigation traced it to an O-ring seal failure in the right solid rocket booster."
    )
}
