# APP264401-I Path Forward

> **Decision update — July 28, 2026:** The owner approved `Flipping Seven Calculator` as the public product name, accepting the documented trademark and App Review risk. Implementation must not use the exact `FLIP 7` mark or restore the former box-art-inspired wordmark, card backs, modifier graphics, publisher artwork, or other trade dress. The approved direction restores only generic seven-card deal/flip motion in the app's original blue, cream, and gold design language. The historical audit and earlier recommendation below remain preserved as the decision record.

This is a working product and repo plan for responding to the Apple/USAopoly trademark complaint, re-evaluating the app, and deciding what we should build next.

This is product/engineering guidance, not legal advice.

## Correspondence rule

Any future email to Apple about this matter should include `APP264401-I` in the subject line and copy the claimant, per Apple's notice.

Suggested subject template:

- `APP264401-I - Status update on app rebrand and trademark remediation`

## Working assumptions

- Until USAopoly gives written permission otherwise, assume we should remove the `FLIP 7` mark from all visible app surfaces, App Store metadata, screenshots, branding, and in-app educational content.
- The fastest practical path is probably an update-in-place to the existing app record, not a brand new bundle/app record.
- Internal identifiers that are not user-facing are lower priority than visible trademarked content, but they should still be tracked as cleanup debt.
- The goal should not be "minimum wording swap." The goal should be "ship a product that clearly stands on its own."

## What the repo is today

After reading the repo end to end, this is not just a neutral calculator with an unfortunate title. It is a polished, single-purpose companion app built around one specific card game.

Core product shape today:

- Offline iPhone/iPad SwiftUI scorekeeper.
- Multi-player game setup, round tracking, undo/redo, manual score override, end-game stats, theme settings, deck profile management.
- A rules/tutorial flow that teaches the specific game.
- Branding and motion that intentionally echo the physical game's look and feel.

The strongest reusable parts are real and valuable:

- `ScoreEngine.swift`: clear scoring logic.
- `GameViewModel.swift`: game lifecycle, persistence, undo/redo, deck-limit enforcement.
- `GameStats.swift` + `GameOverStatsView.swift`: genuinely good stats/summary layer.
- `PlayerManagementView`, `PlayersEditorCard`, roster persistence, target score controls.
- The in-progress design-token work (`DesignTokens.swift`, `DesignStyles.swift`) is a useful modernization path.

## Repo audit findings

### 1. Trademark exposure is deep, not superficial

Highest-risk visible surfaces:

- App display name still uses the mark:
  - `flip7calculator.xcodeproj/project.pbxproj`
- App Store listing doc is entirely mark-centered:
  - `APP_STORE_LISTING.md`
- Privacy policy still uses the disputed title throughout:
  - `PRIVACY_POLICY.md`
- Main setup screen uses a recreated branded title component:
  - `flip7calculator/Views/GameSetupView.swift`
  - `flip7calculator/Views/Components/Flip7TitleView.swift`
- Splash screen is explicitly styled after the game's card backs/box art:
  - `flip7calculator/Views/OpeningSplashView.swift`
- Rules/tutorial teaches the disputed game's rules and includes `Flip 7 © The Op Games`:
  - `flip7calculator/Views/RulesView.swift`
- Deck management text says "Restore the default Flip 7 deck composition":
  - `flip7calculator/Views/DeckManagementView.swift`
- Stats and UI copy repeatedly say `Flip 7`, `Flip7`, and similar:
  - `flip7calculator/Views/GameOverStatsView.swift`
  - `flip7calculator/Stats/GameStats.swift`
  - `flip7calculator/Models/RoundHand.swift`
  - `flip7calculator/Scoring/ScoreEngine.swift`

Important detail: some comments are also risky because they document intent to imitate the official product's visual identity. The splash and title code repeatedly reference "official" card backs, "box art," and matching the real game aesthetic.

### 2. The current product is more than a score tracker

This matters for risk and for product strategy.

The app currently combines:

- scorekeeping
- rules reference
- branded tutorial/onboarding
- themed motion/branding
- game-specific deck modeling
- game-specific terminology in stats

That means a compliant rebrand is not just a metadata edit. It is a product repositioning effort.

### 3. The codebase is structurally salvageable

Good news:

- No package-manager dependency sprawl.
- No backend.
- No analytics SDKs.
- Data is local via `UserDefaults`.
- The core state/scoring layer is compact enough to refactor.

This is a manageable app to rebrand and reposition.

### 4. The repo already has non-trademark cleanup work

I ran the test suite with:

- `xcodebuild test -project flip7calculator.xcodeproj -scheme flip7calculator -destination 'id=427C5AE8-DCAA-471C-98BC-872B7569BA91'`

Current result:

- 135 total tests
- 12 failing
- the app builds and launches, but the suite is not green

Failure buckets:

- `PlayerPaletteTests`: multiple failures around reserved-color safety, inter-color distinctness, and legacy migration expectations
- `GameViewModelUndoTests/testUndoRedoX2Changes()`: test expects two `x2` cards to be addable, but the current standard `DeckProfile` only includes one

Interpretation:

- The app is not broken end to end, but the repo has drift between product rules, palette design, and test expectations.
- We should not ship a major rebrand without cleaning this up.

### 5. Metadata and release docs are inconsistent

Examples:

- `APP_STORE_LISTING.md` still talks like a `1.0` submission in places, while the project is at `MARKETING_VERSION = 1.2` and `CURRENT_PROJECT_VERSION = 8`
- `APP_STORE_LISTING.md` recommends `Utilities` as primary category, while the Xcode project is configured with `public.app-category.card-games`
- Project-level and target-level `DEVELOPMENT_TEAM` values are not fully aligned in `project.pbxproj`

None of these are the main legal issue, but they are good indicators that release/admin cleanup is overdue.

## What should change vs. what we can keep

### Keep

- Core score/state engine
- Offline-first architecture
- round history
- undo/redo model
- manual overrides
- post-game stats
- roster management
- design-token migration work

### Change immediately

- App name
- in-app title/logo treatment
- splash animation visuals
- rules/tutorial content
- all screenshots and marketing images
- App Store text, keywords, subtitle, review notes
- privacy/support copy that still uses the old name

### Change soon after

- game-specific labels like `Flip 7 bonus`
- deck-management copy tied to the branded game
- docs/UI-overhaul files that still use `Flip7` naming
- failing tests and drifted product assumptions

### Probably not a blocker for the first compliance update

- internal module name `flip7calculator`
- existing bundle identifier
- target/test target internal names

Reason: visible trademark usage is the urgent problem. Changing the bundle identifier would mean a more disruptive App Store path.

## External research and lessons

### Apple and trademark guidance

Relevant Apple guidance:

- App Review Guidelines `2.3.7`: app names/metadata should be unique and should not be packed with trademarked terms
- App Review Guidelines `2.3.9`: developers are responsible for securing rights to materials used in icons, screenshots, and previews
- App Review Guidelines `5.2.1`: apps should only include content you have permission to use

Sources:

- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [USPTO trademark search portal](https://www.uspto.gov/trademarks/search)

Practical lesson:

- The current issue is not just the title. Apple explicitly cares about names, screenshots, previews, and imagery rights.

### How people reportedly react to the game online

What I found across review/forum/search sources:

- The game is praised for being extremely easy to teach, fast to play, and good with mixed groups/non-gamers.
- Its "one more card" tension is a major part of the appeal.
- Repeated criticism is high luck variance, early bust frustration, and limited strategic depth.
- Players explicitly mention that scorekeeping matters more than expected, especially in mixed groups and repeated play.
- At least one BoardGameGeek entry links to a fan-made score tracker, which is evidence that helper-tool demand is real.

Sources:

- [Reddit thread: "Flip 7 - My new favorite game to play with non-gamers!"](https://www.reddit.com/r/boardgames/comments/1kcerta/flip_7_my_new_favorite_game_to_play_with_nongamers/)
- [Meeple Mountain overview/review hub for Flip 7](https://www.meeplemountain.com/boardgame/flip-7/)
- [Looking Glass Adventures holiday games article](https://www.lookingglassadventures.com/blog/-5-holiday-games-that-wont-start-a-family-feud-probably)
- [BoardGameGeek web link: fan-made Flip 7 score tracker](https://boardgamegeek.com/wiki/page/weblink%3A366644)

Product lessons for us:

- Preserve fast, low-friction input above all else.
- Lean into history/stats because scorekeeping is part of the pain point.
- Avoid subscription-y or bloated positioning; players clearly like lightweight helpers.
- A generic scorekeeper can still win if it feels fast, trustworthy, and made for real game-night use.

### What similar apps suggest

There are viable generic scorekeeper apps in the App Store, and there are also niche score apps for specific games. The broad lesson is that "generic but useful" is a legitimate lane.

Useful references:

- [Little Scorekeeper](https://apps.apple.com/pl/app/little-scorekeeper/id6746059246)
- [Flip & Score](https://apps.apple.com/de/app/flip-score/id6747075064)
- [Current app listing for Flip 7 Calculator](https://apps.apple.com/jp/app/flip-7-calculator/id6756905042)

Product lesson:

- We do not need the disputed trademark to justify the app's existence. The market already supports generic scorekeeping products and narrowly-scoped helper apps.

## Recommended direction

### Recommendation

Rebrand this into a generic, premium-feeling card/table scorekeeper with a configurable press-your-luck scoring profile, not a disguised branded companion.

In plain terms:

- Keep the scoring flow and stats engine.
- Remove brand mimicry, game-name references, and rules teaching.
- Reposition the app as a broader card-game scorekeeper/reference tool.
- Make the first release safe and generic.
- Decide later whether to add multiple profiles, custom presets, or licensed game integrations.

### What I do not recommend

- `Flip Card Game Calculator`

Why not:

- It still foregrounds `Flip`
- it still sounds like a renamed version of the same branded app
- it does not clearly create distance from the complaint

### Naming directions worth exploring

These are product names, not trademark-cleared recommendations.

Best working-name candidates:

- `Lucky Ledger`
- `Round Ledger`
- `Card Night Scorekeeper`
- `QuickScore Cards`

My current favorite:

- `Lucky Ledger`

Why:

- distinct from the disputed mark
- still has game-night personality
- flexible if the app broadens beyond one ruleset
- works better as a real product than a purely descriptive utility name

If we want safer-but-clearer instead of brandier:

- `Card Night Scorekeeper`

## Product strategy options

### Option A: Fastest safe path

Ship a generic rebrand that keeps the current math but removes branded names, art, and rules.

Pros:

- fastest route to a response/update
- preserves most code
- lowest engineering risk

Cons:

- product may still feel oddly specific unless we also rewrite terminology
- legal risk is reduced, not guaranteed eliminated

### Option B: Recommended path

Ship a generic rebrand plus one broader framing change: make the app about scorekeeping for card/party games, with the current ruleset framed as a default profile rather than a branded game.

Pros:

- stronger product story
- better distance from the complaint
- sets up future multi-profile support

Cons:

- more copy/UI refactoring
- requires terminology cleanup across the app

### Option C: Highest-upside product path

Turn this into a multi-profile game-night scoring app with custom or built-in profiles.

Pros:

- strongest long-term business/product position
- broadest audience
- least dependent on one game's popularity

Cons:

- materially more work
- not the fastest response to the current dispute

## Suggested change map

### Phase 0: Immediate containment

- Decide whether to temporarily remove territories if we cannot submit a compliant update quickly.
- Do not send any new external copy that uses the disputed mark casually.
- Treat "limited factual reference" as disallowed unless USAopoly explicitly says yes in writing.

### Phase 1: Compliance rebrand release

- Rename the visible app:
  - `project.pbxproj`
  - App Store metadata
  - privacy/support pages
- Replace `Flip7TitleView` with a new generic wordmark/title component
- Replace `OpeningSplashView` visuals so they do not mirror the physical game's look
- Remove or fully rewrite `RulesView`
  - safest version: make this an "How to Use the App" guide instead
- Update stats labels and bonus language
  - example: `Flip 7 bonus` -> `7-card bonus` or a profile-defined label
- Update screenshots and any in-app images before resubmission
- Update `APP_STORE_LISTING.md` and `PRIVACY_POLICY.md`

### Phase 2: Product hardening

- Resolve failing palette tests
- Resolve the `x2` undo/test mismatch
- Audit all remaining user-facing strings for old branding
- Rename leftover docs and Figma references where needed
- Align release/admin docs with actual project version/category

### Phase 3: Product upgrade

- Add configurable profiles
- Make scoring labels profile-driven instead of hardcoded to one game
- Replace game-specific rules text with reusable scoring/profile explanations
- Consider house rules, alternate targets, and saved presets

## Concrete repo tasks

### High priority files

- `flip7calculator.xcodeproj/project.pbxproj`
- `APP_STORE_LISTING.md`
- `PRIVACY_POLICY.md`
- `flip7calculator/Views/Components/Flip7TitleView.swift`
- `flip7calculator/Views/OpeningSplashView.swift`
- `flip7calculator/Views/RulesView.swift`
- `flip7calculator/Views/DeckManagementView.swift`
- `flip7calculator/Views/GameSetupView.swift`
- `flip7calculator/Views/GameOverStatsView.swift`

### Medium priority files

- `flip7calculator/Stats/GameStats.swift`
- `flip7calculator/Scoring/ScoreEngine.swift`
- `flip7calculator/Models/DeckProfile.swift`
- `docs/ui-overhaul/*`

### Test/quality files

- `flip7calculatorTests/PlayerPaletteTests.swift`
- `flip7calculatorTests/GameViewModelUndoTests.swift`
- `flip7calculator/Utilities/PlayerPalette.swift`

## Suggested collaboration decisions

We should decide these before implementation:

- Do we want the first response release to be "fastest safe patch" or "broader generic scorekeeper"?
- Which working name do we want to use?
- Do we remove `RulesView` entirely for the first release, or convert it to app-help only?
- Do we temporarily pull availability while the update is prepared?
- Do we keep one default scoring profile only, or start the profile/generalization work immediately?

## My recommendation in one paragraph

The app is worth saving, but not under its current identity. The repo already contains a good offline scorekeeping product with strong stats and usable architecture; the real problem is that the product is visually, verbally, and structurally framed as a branded companion to a trademarked game. The best move is to rebrand decisively, remove all visible `FLIP 7` references and lookalike branding, ship a generic scorekeeper release quickly, then use that release as the foundation for a broader "game night scorekeeper" product rather than trying to stay as close as possible to the disputed mark.
