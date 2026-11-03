# App Store submission checklist

## Done

- [x] App name, icon and bundle ID (`net.reberger.unvarnished`), version 1.0, build 1
- [x] Bundle ID registered with Apple (App ID "XC net reberger unvarnished"), with an App Store distribution profile
- [x] Release archive builds and signs with team M85BW7JMH8, with no build warnings
- [x] Privacy manifest (`PrivacyInfo.xcprivacy`): no tracking, no data collected, UserDefaults declared with reason CA92.1
- [x] Export compliance: `ITSAppUsesNonExemptEncryption = NO`, so uploads skip the encryption question
- [x] App category set to Trivia
- [x] iPhone only, portrait only, iOS 17 or later
- [x] Five screenshots as 72-dpi PNGs without transparency, in all four accepted iPhone sizes (`screenshots/`)
- [x] Listing text, keywords and age-rating notes (`listing.md`)
- [x] Privacy policy text (`privacy-policy.md`)

## Before you submit

1. **Check the facts.** All 1,500 statements and 100 summaries were written without checking museum sources. A wrong "true" answer is the most likely complaint from reviewers and players. At minimum, check the true statements against each museum's own page.
2. **Publish the privacy policy and a support page.** App Store Connect needs a public URL for each. Simple options: a public GitHub Gist, GitHub Pages on a public repository, or a page on your own website. The support page can just be an email address.
3. **Create the app in App Store Connect** (Apps → + → New App) with the name Unvarnished, the bundle ID `net.reberger.unvarnished` and SKU `unvarnished`. If the name is taken, try "Unvarnished: Art Quiz".
4. **Upload the build.** Xcode → Window → Organizer → select the Unvarnished archive → Distribute App → App Store Connect. Or export a signed .ipa with `xcodebuild -exportArchive -archivePath build/Unvarnished.xcarchive -exportOptionsPlist appstore/ExportOptions.plist -exportPath build/export -allowProvisioningUpdates` and upload it with Apple's Transporter app.
5. **Fill in the listing** from `listing.md`, answer the age-rating questions, set App Privacy to "Data Not Collected", and add the screenshots.
6. **Test with TestFlight** before submitting for review, if you'd like a few people to play it first.

## Worth knowing

- **Apple can reject trivia apps as too simple.** Apple's guideline 4.2 covers minimum functionality. Unvarnished has 100 hand-written paintings, a collection and categories, so it should pass. If it's rejected, the reply should stress the original content.
- **Image rights.** Every painting is a public-domain work, and the reproductions are CC0 (the Met, Cleveland) or marked public domain on Wikimedia Commons. Photos of two-dimensional public-domain art are not copyrightable in the US. The credit line in the app names the source of each image.
- **Saved progress.** Progress is stored on the device under the key `retired` (an older name). Don't rename it, or players lose their collections when they update.
