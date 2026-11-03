# Talk Them Down

A historical figure is about to make a famously bad decision. Their photo and a speech bubble say what they plan to do. You reply in your own bubble and try to talk them out of it.

Ten persuasive words are hidden in each case, each standing for a technique from the persuasion literature (consider the opposite, premortem, imagined scenarios, social norms and so on). Each word you use adds its weight to a persuasion score. Reach 75% within 8 messages and they change their mind. Controlling words ("must", "have to") and insults cost points. When the game ends you see what really happened.

The weights are game-design choices, not measured effect sizes. The in-app "Why these words" screen lists the research behind each word and how solid it is.

## Project

SwiftUI, iOS 17+, no dependencies. Open `TalkThemDown.xcodeproj` and run.

- `Lever.swift`: the ten words, their weights and sources, and the pushy words
- `Scenario.swift`: the cases and all character dialogue (invented, not real quotes)
- `Game.swift`: scoring and replies
- `HomeView.swift`, `GameView.swift`, `ResearchView.swift`: the screens

## Photos

Each case looks for an image asset named by `Scenario.photo` (`wilde`, `challenger`). Until one is added to `Assets.xcassets`, a sepia placeholder is shown. Use only public-domain images, and check each one's rights.

## Before shipping

- Add an app icon (1024×1024, no transparency).
- Check the research citations marked "from memory, not checked" in `Lever.swift`.
- Check the historical notes in `Scenario.swift`.
