# Live Play, Deck Tracking, and Risk Insights

Product strategy and implementation outline for expanding Flipping Seven Calculator beyond end-of-round score entry.

- Status: Classic Simulator implemented as a Debug-only product preview; calculator Risk Insights implemented and default off; public Simulator discovery remains gated
- Prepared: July 29, 2026; navigation and storyboard refinement: July 30, 2026; implementation checkpoint: July 30, 2026
- Scope: product shape, user experience, rules model, architecture, reliability, rollout, and research evidence
- Change scope: durable product plan plus the first implementation slice; it does not supersede the in-progress Vengeance, rebrand, UI, or release work

## Implementation checkpoint

The first slice deliberately proves the riskiest offline and recovery mechanics without exposing an unapproved public route:

- `GameSetupView` remains the sole starting surface. In Debug, it presents equal-height `Score Calculator` and `Simulator` choices without a second descriptive row; Score Calculator is selected for every legacy/default state and still starts in one tap from the pinned action.
- Release builds hide Simulator discovery. Persisted `digitalDealer` payloads still decode so feature gating can never destroy an existing session.
- `Game.playStyle` separates calculator, future physical tracking, and digital dealer truth. Missing values decode to `scorekeeper`.
- `LiveSession` persists the exact ordered draw pile, discard pile, per-player table zones, dealer, task queue, forced sequences, shuffle seed, last reveal, and bounded table log.
- `LiveGameReducer` is the pure command boundary for opening deals, ordinary draws, staying, Freeze, Flip Three, Second Chance, nested actions, reveal acknowledgment, busts, seven-number completion, dealer rotation, scoring, and discard-only reshuffles.
- `DealerGameView` is a separate Simulator surface with one dominant context-aware action, an explicit target chooser, a compact deck/shuffle indicator, compact visible cards on each player tile, a full-table hand sheet, full undo/redo snapshots, help, table log, keep-awake behavior, and an irreversible emergency fallback to the calculator. The discard count remains modeled but is not shown because it is inferable and added visual noise.
- Every successful draw enters a persisted reveal-acknowledgment task. The recipient can review the card, then must choose `Hide Card & Continue`; only then is the reveal cleared and the next task normalized. A stale pre-acknowledgment save never presents its last reveal beside an already-advanced task.
- Classic target selection includes active players only. Stayed, frozen, and busted players remain visible in the table-hands view but cannot receive Freeze or Flip Three. A nested Freeze or Flip Three is queued until the original Flip Three completes, may then be assigned to any active player, and does not resolve if the forced recipient busts.
- `ProbabilityService` exposes shared next-card risk math. Dealer results are exact immediate-bust risk from its owned pile; calculator results are duplicate-number estimates because physical protection effects and earlier action discards are unknown. The preference defaults to Off.
- Classic is the only Simulator ruleset in this slice. Selecting Vengeance returns setup to Score Calculator rather than creating a disabled or partially supported game.
- Official functional names (`Freeze`, `Flip Three`, and `Second Chance`) are paired with original SF Symbol-based imagery so the rules remain recognizable without reproducing third-party card art or trade dress. Vengeance profile names remain `Just One More`, `Flip Four`, `Swap`, `Steal`, and `Discard`. Public enablement still requires the product/legal gate below.

Deferred from this checkpoint: physical Deck Tracker, public Dealer enablement, Vengeance dealer rules, nearby-device display, sound design, and any networked or account-based feature.

## Executive recommendation

Build one app with **two obvious entry lanes** backed by three explicit internal play styles. Players should make one simple choice—score a physical game or play with the app as dealer—while the data model keeps the sources of truth separate:

1. **Score Calculator** — the current fast calculator and default. The physical table remains authoritative. An optional `Track physical deck` capability can promote the session to the internal Deck Tracker play style after a confirmed fresh shuffle.
2. **Simulator** — the app is the deck and dealer, reveals cards, advances turns, resolves action sequences, scores rounds, and reshuffles automatically.

Internally, retain `scorekeeper`, `physicalDeckTracker`, and `digitalDealer` because they have different truth and recovery rules. Do not present all three as equal setup choices: Deck Tracker is an advanced form of scoring a physical game, not a third reason to open the app.

The recommended delivery order is:

1. Extract an explainable probability service and add carefully labeled risk insights to the calculator.
2. Build the deck ledger and physical Deck Tracker to validate shoe lifecycle, corrections, action resolution, and exact odds without replacing the physical product.
3. Ship a Classic Digital Dealer only after the rules engine, crash recovery, fairness design, user testing, and intellectual-property gate pass.
4. Add Vengeance live play after the Classic state machine has proven reliable.
5. Add optional nearby devices or an external table display only after the single-host experience is excellent.

This sequence is intentionally architecture-led. A superficial Draw button would create a second, divergent game engine and would produce incorrect reshuffles, odds, undo behavior, and action-card handling.

## The product thesis

The core fun is the public decision to push or stop. The app should deepen that moment and remove table chores without making the table stare at a phone.

The product can own these jobs:

- Calculate scores without slowing live play.
- Make the current player, live hand, and next required action unmistakable.
- Maintain a trustworthy draw pile, discard pile, table zones, and reshuffle boundary.
- Resolve complicated action sequences one decision at a time.
- Explain risk without pretending uncertain state is exact.
- Recover from mistaken taps, interruptions, app termination, and low battery without changing the next card.
- Preserve an auditable history of what happened and why a player scored or busted.
- Offer a satisfying table-host experience on one iPhone and a genuinely table-scale experience on iPad.

The app should not initially attempt to own:

- Accounts, cloud sync, public matchmaking, or server-authoritative games.
- AI opponents.
- Camera recognition of third-party cards.
- User-authored action scripts or arbitrary programmable rules.
- A second set of score calculations embedded in SwiftUI.
- Exact win-probability or strategy advice that depends on unmodeled player policies.
- Full digital reproduction of a third-party game without a documented rights decision.

## A non-negotiable product and legal gate

Moving from an independent scorekeeper to an app that supplies the complete deck and rules can make the app a substitute for the physical product. That is a materially different product and risk posture, especially given the existing `APP264401-I` history.

Before public Digital Dealer work:

- Obtain a written product/legal determination about reproducing the complete deck composition and playable rules.
- Prefer a publisher license if the dealer is marketed for a specific third-party game.
- Keep every card face, back, symbol, animation, sound, and term original unless specifically licensed.
- Do not infer that an “independent” disclaimer grants rights.
- If no license is available, position Deck Tracker as the main live companion and limit a Digital Dealer to an original, generic rules profile that stands on its own.

This is product guidance, not legal advice. Apple currently says apps must not use protected third-party material without permission and may reject copycat names, metadata, or representations.

## What the market teaches

### Direct scorekeeper competitors

The direct niche has converged on:

- Card-by-card or manual score entry.
- Automatic modifiers and seven-card bonus calculation.
- Real-time leaderboards.
- Undo.
- Saved games, groups, history, and statistics.
- Vengeance support in newer products.
- Clubs, subscriptions, and online modes in the most expansive competitor.

Those are useful but no longer a defensible destination. Reviews also surface durable table needs:

- Landscape iPad support matters.
- Scores need to scale up when there are fewer players.
- Some groups want one host; others prefer each person to enter their own score.
- Round history and reliable undo are requested repeatedly.
- A single scoring-order bug can invalidate trust in the entire product.

### Generic scorekeepers

Leading generic scorekeepers reinforce these conventions:

- One-touch or natural-gesture scoring.
- Chronological score history and rollback.
- Saved rosters and quick rematches.
- Player colors and labels oriented toward the person around the table.
- Large controls, number-pad escape hatches, and persistent bottom actions.
- Optional timers, starting-player selection, and lightweight game tools.

The current app already has much of the hard foundation: semantic hands, scoring, round history, undo/redo, target progress, per-player color, and persistent rosters.

### Digital deck utilities

Mature deck apps make several table details explicit:

- Tap anywhere or use one dominant control to draw.
- Show remaining-card count only when the user wants it.
- Preserve a card history.
- Mark shuffle boundaries inside history.
- Explain when a settings change requires a new shuffle.
- Offer automatic reshuffle behavior.
- Offer an intentional keep-screen-awake setting.
- Support landscape and iPad rather than stretching an iPhone interface.

These are baseline requirements for Digital Dealer, not polish items.

### Official companion apps

Successful licensed companions remove a role or a chore while leaving the social and tactile core intact:

- One Night automates narration and timing so a player does not have to sit out as narrator.
- HeroQuest can take the game-master role, reveal information gradually, track events, and guide new players while explicitly requiring the physical game.
- Frosthaven's companion emphasizes setup reduction, stateful decks, session resume, optional modules, and undo/redo.

The analogous promise here is “everyone gets to play; the app handles the deck, arithmetic, and housekeeping.”

### Hybrid-board-game research

Recent research classifies digital board-game functions as Timing, Randomizing, Housekeeping, Informing, Teaching, Calculating, Remembering, and Storytelling. This proposal principally uses Randomizing, Housekeeping, Informing, Calculating, and Remembering.

The more important finding is cautionary: automating a physical deck can reduce perceived autonomy, fairness, and challenge when the mechanism becomes opaque. Players in a 2026 study speculated that a digital deck was dynamically changing difficulty even when it was not. The study recommends “just right” hybridity that adds value and deepens the core experience instead of blindly automating components.

Implications for this app:

- Do not hide the deck lifecycle.
- Show draw, discard, and shuffle state in plain language.
- Preserve a chronological table log.
- Never rerandomize because the user undid, relaunched, or changed a visual setting.
- Make odds explainable from visible remaining-card counts.
- Allow groups to turn odds off.
- Keep the push-or-stop decision with the player.
- Test fairness perception, not only mathematical fairness.

## Information architecture

Do not introduce a permanent tab bar that lets users flip between calculator state and dealer state mid-round. The game creation route selects a play style; the active game then presents one authoritative interaction model.

### First-class citizen contract

The dealer must be an addition, not a redesign tax paid by current users:

- A legacy user with no active game lands on the existing setup with `Score Calculator` selected.
- A legacy user with an active game resumes directly into the existing scorekeeper; no interstitial, migration screen, or mode question is inserted.
- Starting an ordinary scorekeeper game requires no additional tap compared with today.
- The current number/modifier grid, card picker, manual scoring, undo/redo, mode selection, roster tools, and midgame score flow remain in their familiar hierarchy.
- Risk Insights are off for legacy users unless they enable them.
- After a player intentionally starts a dealer game, remember that entry-lane preference for future new games. Absence of the preference always decodes to `Score Calculator`.
- Rematch preserves the completed game’s lane. `Change play style` is a quiet setup action, never an interruption during play.
- Both lanes receive the same product quality: offline operation, persistence and resume, history, settings, accessibility, iPhone/iPad support, and undo/recovery appropriate to their source of truth.

First-class does not mean identical. Scorekeeper owns fast entry; Dealer owns draw and resolution. Mixing both control sets would make each line worse.

### Setup

Keep `GameSetupView` as the single starting surface. Add a compact, always-visible `How are you playing?` choice near the top, before lane-specific configuration:

- **Score Calculator** — “Use your physical cards. Enter cards or round scores.”
- **Simulator** — “Draw and play from an app-owned deck on this device.”

The control may be two equal-width selection cards on wide layouts and a compact two-option picker on iPhone. On compact width, show one short explanation for the selected choice below the picker instead of repeating paragraphs inside both choices. It is not a tab bar: it chooses what will be created. Both choices use the same card surface, type scale, and semantic selection treatment so Dealer does not look like the premium future while Scorekeeper looks like a legacy utility. Keep `Game Mode` for Classic/Vengeance rules; do not reuse “mode” for this entry choice.

Below the choice:

- Keep player setup, ruleset, and winning score as shared controls.
- When `Score Calculator` is selected, preserve the current setup order and controls. Add one compact `Deck & Odds` row for optional `Risk Insights` and `Track physical deck`; do not add a third large mode card.
- When `Simulator` is selected, replace only that optional row with simulator-specific settings such as sound/haptics and supported-deck disclosure.
- Use one reserved conditional region so switching choices does not cause a large vertical jump.
- Change the single primary button label to `Start Scoring` or `Start Simulator`.
- Give the two choices explicit accessibility labels and a selected-state trait; color cannot be the only differentiator.
- Hide the public Dealer choice behind a build/feature gate until its rules, recovery, rights, and accessibility release gates pass. Production must never show a dead or “coming soon” primary route.

Compact setup order, grounded in the current pinned-start-button layout:

```text
[ Existing hero ]

How are you playing?
[ Score Calculator ✓ ] [ Simulator ]
Use your physical cards. Enter cards or round scores.

[ Existing Players card ]
[ Existing Game Mode card: Classic / Vengeance ]
[ Existing Target Score card ]
[ Deck & Odds — collapsed row ]

[ Start Scoring — existing pinned safe-area button ]
```

The new selector should stay roughly one compact card-row tall at default text size. The pinned start action remains reachable without scrolling; larger text may stack choices and scroll normally rather than truncate.

Add an optional `Risk Insights` choice:

- Off.
- Heat only: Low, Rising, High, Critical.
- Exact: percentage plus a short explanation.

The setting should be visible to the table at game start. A host can change it later, but the change should be logged so odds do not appear secretly.

### Navigation model

```mermaid
flowchart TD
    Launch["Launch"] --> Active{"Active game?"}
    Active -->|Yes| Resume["Resume its persisted play style"]
    Active -->|No| Setup["Existing Game Setup"]
    Setup --> Score["Score Calculator"]
    Setup --> Dealer["Simulator"]
    Score --> Calculator["Existing GameView"]
    Score --> Tracker["Optional: confirm fresh shuffle and track deck"]
    Tracker --> Calculator
    Dealer --> DealerView["DealerGameView"]
    DealerView --> Fallback["Emergency: continue as Scorekeeper"]
    Fallback --> Calculator
```

`GameSetupView` owns selection and common configuration. An `ActiveGameRoot` routes a persisted game to the existing `GameView` or a new `DealerGameView`. The router does not allow casual mid-round switching. Settings, help, history, and round-summary components may be shared; the primary play surfaces should not be merged.

### Product storyboard

#### 1. Existing scorekeeper after updating

1. Launch into the familiar setup; `Score Calculator` is already selected.
2. See a dismissible, non-modal `New: Simulator` callout at most once. It never covers or disables setup.
3. Add players and choose the same rules and target as before.
4. Tap `Start Scoring` in the same place and at the same tap count as the current start action.
5. Enter the unchanged scorekeeper surface. No dealer controls or persistent promotion compete with scoring.

#### 2. Existing active game after updating

1. Launch.
2. Decode a missing `playStyle` as `scorekeeper`.
3. Resume directly into the existing game at the same state; do not show the entry choice first.

#### 3. New player who owns physical cards

1. On setup, read both plain-language options without needing Help.
2. Keep the default `Score Calculator` selection.
3. Configure players, rules, and target; optionally expand `Deck & Odds`.
4. Tap `Start Scoring` and learn the existing card/score entry line through current affordances.

#### 4. New player using the device as dealer

1. Select `Simulator`; shared setup remains in place while only the conditional options change.
2. Configure players, rules, target, and dealer feedback.
3. Tap `Start Simulator`; opening deal establishes the first player and visible shoe state.
4. Repeatedly use the single contextual action: draw, choose a target, continue a forced sequence, stay, or pass.
5. Review a concise round summary, then start the next round. The app performs the documented drawdown and reshuffle boundary automatically.

#### 5. Scorekeeper who wants exact physical-deck odds

1. Choose `Score Calculator`, open `Deck & Odds`, and enable `Track physical deck`.
2. Confirm that a complete supported deck has just been shuffled. Without this confirmation, the app offers estimates, not exact odds.
3. Record each physical reveal through the shared card picker.
4. See one compact risk pill near the active player; open it only when an explanation is wanted.
5. If a card was missed, correct the ledger from history or abandon exact tracking while preserving scores.

#### 6. Dealer emergency fallback

1. Open the dealer overflow menu and choose `Continue as Scorekeeper`.
2. Confirm that existing scores and known hands will be preserved but the exact dealer shoe will be abandoned.
3. Route into `GameView`; do not allow return to the previous dealer shoe.

#### 7. End game and rematch

1. Show the same winner, standings, history, and rematch affordances for both lanes.
2. `Rematch` retains players, settings, and the prior lane.
3. `Change play style` returns to setup with the two-choice control visible and no active-shoe state carried across.

### Screen composition and clutter budget

| Surface | Shared or stable content | Score Calculator only | Simulator only |
|---|---|---|---|
| Setup | Brand hero, two entry choices, roster, ruleset, target, one CTA | Current configuration plus compact `Deck & Odds` row | Dealer feedback and supported-deck options |
| Active play | Scores, current player, round state, history/help/settings access | Existing number/modifier grid, card picker, manual score, bank/bust | Last card, shoe/discard status, Draw/Stay, guided resolution |
| Round end | Round deltas, standings, corrections, next round | Entry audit as today | Draw/action audit and automatic discard transition |
| Game end | Winner, final standings, history, stats, rematch | No dealer upsell takeover | No calculator migration prompt |

Enforce these limits:

- Two primary entry choices, not three.
- One dominant call to action per screen.
- At most one compact live risk indicator; its detail lives in a sheet.
- Only selected-lane settings are visible.
- No permanent app-level tab bar during a game.
- No full calculator grid on the dealer surface and no draw/discard tableau on the ordinary calculator surface.
- Corrections, audit history, and administrative controls live in sheets or menus, not beside the primary action.
- Selection changes use a short opacity/position transition and respect Reduce Motion; they do not rebuild the entire page or move the start button unexpectedly.
- Use generic SF Symbols or original artwork, never disputed card faces, card backs, logos, or trade dress.

### Discovery without interruption

- The two entry choices do the durable discovery work. Avoid recurring banners, badges, and dealer prompts throughout the calculator.
- A one-time setup callout is acceptable for existing users after the feature ships; dismissal is permanent and local.
- Help contains a short `Choose how to play` comparison and can reopen the explanation.
- After the first intentionally created game, remember the last entry lane locally. Never infer a lane from browsing Help or opening a preview.
- If Dealer is unavailable for the selected ruleset, disable the choice only when a nearby explanation and supported alternative are visible; prefer hiding it entirely before broad availability.
- Do not use novelty animation, louder color, or oversized artwork to privilege Dealer. Its value should be legible from the label and description.

### Lifecycle rules

- `playStyle` is persisted per game and defaults to Scorekeeper for every legacy game.
- Scorekeeper can begin tracking at a confirmed shuffle boundary, not at an arbitrary unknown shoe state.
- Deck Tracker can fall back to Scorekeeper at any time, preserving scores and hands but ending exact deck knowledge.
- Digital Dealer can fall back to Scorekeeper as an emergency escape hatch, but cannot return to the same dealer shoe once deck authority is abandoned.
- Mode or deck-profile changes are locked after a tracked/digital shoe begins. Apply changes only by starting a new game or explicitly rebuilding a shoe at a safe boundary.
- Current calculator mode-switch behavior can remain unchanged; a shuffled live shoe is the reason for the stricter rule.

## The two primary experiences

### Scorekeeper line

Keep the existing selected-player panel and fast number/modifier grid. Add only compact, optional risk information:

- A small `Next draw` risk pill beside the selected player’s round preview.
- Tap the pill for a bottom sheet that explains dangerous ranks and remaining copies.
- Label calculator-only risk as `Estimate` unless the app has tracked the full shoe.
- Do not let the odds panel obscure number entry or add a tap to ordinary scoring.
- Keep manual score, clear, bank/stay, bust, undo, and redo exactly reachable.

### Live line: Deck Tracker and Digital Dealer

Both live styles use the same dealer surface and resolution state machine. Only the source of a revealed card differs:

- Deck Tracker: the host taps the matching card that was physically revealed.
- Digital Dealer: the host taps Draw and the engine removes the committed top card.

This shared pipeline prevents rules drift and makes Deck Tracker a meaningful proof of the later Digital Dealer.

#### Shared dealer surface

- Top: round, target, dealer, draw count, discard count, and an unobtrusive history button.
- Player strip/grid: total score, live round score, number-card count, state, and current-turn emphasis.
- Center: current recipient, last revealed card, and any unresolved instruction.
- Bottom: one dominant context action.
  - `Draw for Maya`
  - `Choose a target`
  - `Continue forced draws (2 left)`
  - `Pass to Leo`
  - `Start next round`
- Secondary action: `Stay` when the current player is allowed to decide.
- Persistent escape: undo last completed table action.
- Risk: a pill close to Draw, never visually larger than the decision controls.

#### iPhone

- Use a vertical host console.
- Keep the current recipient and primary action reachable one-handed near the bottom.
- Allow tapping most of the reveal area to Draw when there is no pending choice.
- Use a horizontally scrolling player strip only if every state remains readable; otherwise use a compact two-column grid.
- Show the live hand as a short horizontal row with an expand affordance.
- Put history, shoe detail, and correction tools in sheets, not the hot path.

#### iPad

- Treat landscape as the primary live-dealer canvas.
- Use a table dashboard: player tiles around or beside a large central deck/reveal area.
- Scale player tiles with roster size; do not leave tiny cards floating in unused space.
- Support portrait, Split View, and Stage Manager without clipping the primary action.
- Consider optional label rotation toward seats only after testing; it helps personal scoreboards but can harm the host’s ability to resolve action choices.

#### Feedback

- Draw: short, neutral haptic and restrained card reveal.
- Bust: distinct error haptic, high-contrast state change, and spoken/visual explanation.
- Seven-card completion: celebratory but brief, with Reduce Motion using a fade and static emphasis.
- Reshuffle: visible interstitial naming how many discarded cards formed the new draw pile.
- Optional spoken dealer: player name, revealed card, and required action. Audio must never be the sole source of state.
- Haptics, sound, spoken dealer, and motion are independently adjustable.

## Exact round and shoe lifecycle

For the supported Classic rules:

1. Create one unique card instance per configured deck count.
2. Shuffle all instances once to form the initial draw pile.
3. Deal one face-up card to every player in turn order, pausing immediately for each action card and then resuming the opening deal.
4. Offer each active player Hit or Stay in turn order.
5. Resolve every revealed card completely before advancing the turn cursor.
6. End the round when no active players remain or a player reaches seven unique number cards.
7. Move all cards from table zones into the discard pile.
8. Pass dealer position left. Do not return the round discard to the draw pile.
9. If the draw pile becomes empty, shuffle the discard pile into a new draw pile while leaving every current-round table card in place.

The official Classic rulebook is explicit that cards from completed rounds remain discarded until the deck runs out and that live table cards stay out during a mid-round reshuffle.

Deck Tracker replaces steps 2 and 9 with human confirmations:

- `I shuffled all available discards` establishes an exact boundary.
- The app then tracks composition, not physical order.
- Every physical reveal subtracts a matching instance from the virtual draw-pile multiset.
- If the recorded card is impossible, stop and offer correction; never silently invent a second copy.

## Resolution state machine

The live engine needs a finite state machine independent of SwiftUI. Suggested phases:

```mermaid
stateDiagram-v2
    [*] --> OpeningDeal
    OpeningDeal --> ResolvingCard: card revealed
    ResolvingCard --> AwaitingTarget: action needs target
    ResolvingCard --> ForcedSequence: action starts forced draws
    ResolvingCard --> OpeningDeal: opening recipient resolved
    ResolvingCard --> AwaitingDecision: normal reveal resolved
    AwaitingTarget --> ResolvingCard: target chosen
    ForcedSequence --> ResolvingCard: next forced card
    AwaitingDecision --> ResolvingCard: hit
    AwaitingDecision --> AwaitingDecision: stay and advance
    ResolvingCard --> RoundComplete: no active players / seven cards
    RoundComplete --> OpeningDeal: next round
```

Every phase declares:

- Allowed commands.
- Eligible targets.
- Visible instruction.
- Whether the primary button is enabled.
- Whether undo or cancel returns to the previous stable decision boundary.
- The next phase after resolution.

Do not encode action sequencing as nested sheets and callbacks. The persisted engine phase must be sufficient to resume after termination in the middle of a target choice or forced sequence.

### Classic action handling

- **Freeze**
  - Choose an active target, including self.
  - Bank the target and remove them from normal turn rotation.
- **Flip Three**
  - Choose an active target.
  - Reveal up to three cards one at a time.
  - Stop early on bust or seven-card completion.
  - Second Chance can be retained during the sequence.
  - Defer revealed Freeze or Flip Three actions until the three-card sequence completes and only if the recipient did not bust, following the official sequencing rule.
- **Second Chance**
  - Keep one in the player’s table zone.
  - If the player already has one, choose another eligible active player; discard it if nobody is eligible.
  - On the next duplicate, discard both the duplicate and Second Chance and keep the player active.
  - Preserve the consumed duplicate in the event log even though it no longer appears in the scoring hand.

### Vengeance handling

Vengeance is not a card-label swap. Its live engine additionally needs:

- Distinct identities and duplicate semantics for regular 7, Unlucky 7, regular 13, and Lucky 13.
- Immediate destructive effects for Unlucky 7 while preserving discarded-card history.
- Swap operations that can bust one or both recipients.
- Steal and Discard operations over individual visible card instances.
- Target eligibility that includes stayed/forced-to-stay players where the rules allow it.
- Deferred Flip Four action resolution in reveal order.
- The Zero’s forced-hit behavior.
- Normal and Brutal modifier eligibility.
- Redirected seven-card bonus decisions.
- Negative round outcomes in Brutal mode.

Ship this only after a complete command/transition table exists and passes the publisher rules and FAQ examples.

## Data model direction

### Current limitation

`RoundHand` is optimized for calculation. Sets and count dictionaries cannot represent:

- Two individual copies of the same number temporarily visible on a bust.
- A duplicate discarded by Second Chance.
- Which physical instance moved through Swap, Steal, or Discard.
- Action cards waiting for deferred resolution.
- Draw pile, discard pile, or cross-round shoe history.
- The precise card that undo must return to the top.

Do not overload `RoundHand` into a dealer engine.

### Proposed concepts

- `GameEntryIntent`
  - `scorePhysicalGame`
  - `playWithDealer`
  - Presentation-only preference for setup and discovery; it is not the authoritative in-game mode.
- `PlayStyle`
  - `scorekeeper`
  - `physicalDeckTracker`
  - `digitalDealer`
- `RulesVersion`
  - Immutable identifier recorded when a live session begins.
- `CardDefinition`
  - Semantic type and value; never a copyrighted face image.
- `CardInstance`
  - Stable UUID plus definition identifier.
- `CardZone`
  - draw pile, discard pile, player table, deferred action queue, consumed/removed if a supported rule needs it.
- `ShoeState`
  - Ordered draw pile for Digital Dealer.
  - Remaining multiset for Deck Tracker.
  - Discard pile.
  - Shuffle generation and shuffle receipt.
- `LiveRoundState`
  - Dealer seat, turn cursor, opening-deal progress, phase, pending target/action, forced-draw count, and per-player table zones.
- `LiveSession`
  - Play style, rules version, shoe, live round, exactness/confidence, and event ledger.
- `GameCommand`
  - Human intent such as draw, record revealed card, stay, choose target, correct last draw, or confirm physical reshuffle.
- `GameEvent`
  - Facts emitted by the pure reducer, such as card revealed, target chosen, player busted, protection consumed, reshuffled, or round ended.

### Source of truth

Use a pure command reducer:

`(state, command) -> validated new state + events`

- Views render state and send commands.
- ScoreEngine consumes a semantic projection of table zones.
- ProbabilityService consumes public hand state plus shoe composition.
- History and stats consume committed events and completed-round snapshots.
- Persistence stores the authoritative snapshot plus a bounded event ledger.
- Existing `RoundHand` remains the calculator representation and can be produced from live table zones through a tested adapter.

This is not a recommendation to rebuild the current app as pure event sourcing. Persisted snapshots keep resume simple; the event ledger supplies auditability, corrections, insights, and deterministic bug reports.

### Persistence and compatibility

- Add `playStyle` with a `.scorekeeper` decode default.
- Store `lastGameEntryIntent` locally only after the user starts a game; absence defaults to `.scorePhysicalGame`.
- Add optional `liveSession`; absence means the legacy calculator model.
- Persist a live state transition before beginning its reveal animation.
- Record a schema version and rules version.
- Keep current games and completed history decodable without generating a fake shoe.
- Do not retroactively infer draw events from legacy hands.
- Consider moving the growing live payload from one `UserDefaults` value to an atomic file-backed Codable store or SwiftData only after measuring payload size and migration cost. The storage mechanism is secondary to atomic snapshots and compatibility tests.

### SwiftUI integration boundary

- Extend `GameSetupView`; do not add a mandatory landing screen in front of it.
- Map `.scorePhysicalGame` to a newly created `.scorekeeper` game unless `Track physical deck` is enabled at a confirmed shuffle.
- Map `.playWithDealer` to `.digitalDealer` only after the dealer availability gate passes.
- Route persisted games through a small `ActiveGameRoot` switch. Keep the current `GameView` as the scorekeeper destination and add `DealerGameView` as a sibling.
- Keep the existing scorekeeper view model and score-entry components intact initially. Share domain services, tokens, and simple components; do not force the two active surfaces into a universal view model.
- Extract a shared live scoreboard or round-summary component only after both surfaces prove the same semantics and accessibility behavior.
- Put the Dealer selector behind one local capability flag while it is incomplete. The flag controls discovery, not stored-game decoding, so internal builds can still resume dealer fixtures.
- Add a one-time announcement key separately from the last-entry preference; dismissing discovery must never change mode.

## Undo, correction, and recovery

### Undo semantics

Undo should operate on human decision boundaries, not internal implementation mutations.

- Undo Hit restores the state before that hit and returns every card in its completed resolution chain to its exact prior zone/order.
- Undo never reshuffles and never produces a different replacement card.
- A pending target choice can be canceled back to the state after the action reveal; it cannot erase the action card unless the full draw is undone.
- Undo Stay restores that player to active and returns the turn cursor.
- Undo round completion restores the live table, discard boundary, scores, and dealer position together.
- Redo must replay the same cards and choices.

### Correction tools

Provide an explicit `Table log` with:

- Last completed action and one-tap undo.
- A chronological card/action timeline.
- `Wrong card` replacement for the most recent physical tracked reveal.
- `Missed a card` insertion for Deck Tracker.
- `Move card` or `Change target` only when the engine can validate the resulting state.
- A visible `Odds exactness` consequence before accepting an unknown or untracked correction.

Avoid a general freeform state editor in Digital Dealer. If an exceptional admin override is necessary, mark the session as corrected, log it, and preserve internal invariants.

### Crash and interruption recovery

- Commit the state transition before presenting animation or audio.
- If the app terminates after Draw, relaunch to the already revealed card and pending resolution; never consume another card.
- Restore pending target and forced-draw progress.
- Disable the idle timer only while an active live surface is visible, make the behavior optional, and restore the system default on exit/background.
- Handle calls, lock screen, and backgrounding without auto-advancing.
- If persistence decoding fails, retain the raw payload for diagnostics and offer Scorekeeper recovery rather than silently starting a new game.

## Risk Insights specification

### The only initial headline metric

Use **chance the next revealed card immediately busts the selected recipient**.

Do not label it simply `Bust odds` because that can be mistaken for:

- Chance of busting before the next voluntary choice.
- Chance of eventually busting if the player keeps hitting.
- Chance of losing the game.
- A strategic recommendation.

### Exact calculation

For a draw pile with `N` remaining card instances:

`P(immediate bust on next card) = unsafe remaining instances / N`

Where `unsafe` is not a hard-coded sum of matching number ranks. It is evaluated by the same pure transition logic used by the rules engine:

`unsafe(card) = would drawing this card transition this recipient to busted?`

That distinction is necessary for:

- Second Chance, where a duplicate consumes protection instead of busting.
- Unlucky 7, which has precedence over an existing regular 7.
- Lucky 13, which can coexist with one regular 13.
- Custom profiles whose number-card composition differs.

Example in a fresh Classic shoe with only `2`, `5`, and `9` visible in the selected hand:

- Unsafe remaining instances: `1 + 4 + 8 = 13`.
- Remaining cards: `94 - 3 = 91`.
- Immediate bust chance: `13 / 91 = 14.3%`.

Other visible table cards and discards alter both numerator and denominator. The app should show the contributing ranks so the result is auditable.

### Confidence labels

- **Exact — Digital deck**
  - App owns the order and every zone.
- **Exact — Tracked physical deck**
  - User confirmed a shuffle and every reveal has been recorded consistently.
- **Estimate — Current table only**
  - Based on configured deck and app-visible current cards; prior physical discards are not tracked.
- **Unavailable**
  - Recorded state is impossible, deck profile changed mid-shoe, or an unknown card was skipped.

Never display an unlabeled percentage.

### Risk presentation

The compact pill shows one of:

- `14% next-card risk · Exact`
- `Rising risk · Estimate`
- `Risk unavailable · deck state incomplete`

The expanded sheet shows:

- Exact metric definition.
- Unsafe card instances and total draw-pile count.
- Dangerous ranks with remaining counts.
- Second Chance or special-number effect on the calculation.
- Safe new-number probability and chance the next draw advances toward seven, as a secondary metric.
- A brief note that action and modifier cards may change the turn but do not immediately bust the recipient.

Use redundant encodings: percentage/text, symbol, and a restrained color scale. Do not use green as “you should hit” or red as “you should stay.” The app provides information, not the decision.

### What to defer

- `Expected value if you draw then stay` until every action-target policy is defined.
- `Bust before your next choice` until forced sequences are solved exactly.
- `Chance to reach seven if you always hit` until action selection and protection policies are explicit.
- Match win probability until turn policies, opponent decisions, target choices, and score-position effects are modeled and validated.
- Strategy prescriptions such as “always hit under 20%.” They are opinionated and can be wrong near the target score.

An Odds Lab can later expose those models with stated assumptions, separate from live play.

## Fairness and randomization

### Required

- Materialize unique card instances, then use an unbiased in-place shuffle with Swift's system random generator.
- Inject a deterministic generator in tests.
- Persist the complete shuffled order before the first reveal.
- Never regenerate order during undo, redo, relaunch, visual setting changes, or device rotation.
- Keep shuffle boundaries and counts in the table log.
- Explain in Help that outcomes are not adjusted for score, player, streak, or difficulty.

Apple documents that `SystemRandomNumberGenerator` is automatically seeded and uses a cryptographically secure algorithm whenever possible; Apple platforms use `arc4random_buf`.

### Optional differentiator: shuffle receipt

At shuffle time:

- Serialize ordered card-instance definitions plus a random nonce.
- Store and display a short SHA-256 commitment code.
- At game end or shoe exhaustion, allow export/reveal of the nonce and order for verification.

This proves that the order was not changed after commitment, not that the app's code is globally trustworthy. Position it as an audit receipt, not cryptographic theater. Validate whether real players understand or value it before investing beyond a prototype.

## Statistics and features unlocked by the event ledger

High-value post-game insights:

- Risk percentage accepted on each Hit.
- Average risk at Stay and at Bust.
- Highest-risk safe draw.
- Lowest-probability bust.
- Protection cards gained and consumed.
- Seven-card attempts and completions.
- Cards remaining at every reshuffle.
- Action targets and outcomes.
- Round decision replay with score and risk progression.
- Host correction count, useful for product research and session confidence.

Avoid reducing players to a single “skill” score. Luck and social targeting are central, and opaque rankings would overstate what the data means.

## Opportunity backlog

### Foundation / must-have

- Two visible entry lanes with three explicit internal play styles: Scorekeeper, Deck Tracker, and Digital Dealer.
- Legacy-safe setup defaults and direct active-game resume.
- Separate `GameView` and `DealerGameView` destinations behind one persisted router.
- Immutable card instances and exact zones.
- Pure resolution state machine.
- Classic opening deal, turns, actions, forced sequences, round end, and deck exhaustion.
- Persisted resume at every phase.
- Decision-boundary undo/redo.
- Chronological table log and correction path.
- Exact/estimate/unavailable probability contract.
- iPhone host console and iPad landscape table layout.
- VoiceOver, Dynamic Type, contrast, Reduce Motion, optional sound/haptics.
- Keep-screen-awake option scoped to live play.
- Rules-version and schema-version compatibility.

### Strong second-wave features

- Risk heat mode for groups that dislike explicit percentages.
- Odds Lab / practice sandbox with adjustable hands and deck profiles.
- Post-game decision replay.
- Spoken dealer with adjustable verbosity.
- AirPlay or external-display public scoreboard while the phone remains the host controller.
- Shareable, original-branded game summary image.
- JSON/CSV event export for debugging and playtesting.
- Shuffle receipt.
- A “teach this action” explanation embedded only when a card is first encountered.
- House-rule presets built from supported semantic parameters, not arbitrary scripts.

### Scalable later opportunities

- Nearby read-only player devices joined by QR code.
- Nearby Hit/Stay voting/control with the host as the single authoritative reducer.
- Local peer-to-peer state replication using current Network framework guidance; do not build new work on deprecated Multipeer APIs.
- Apple Watch or lock-screen remote for the host only if it materially reduces table reach friction.
- Original additional rules profiles implemented behind a `Ruleset` interface.
- Solo practice bots only after live human play is complete and legally cleared.
- Tournament/club statistics only if users demonstrate demand; competitors already crowd this lane.
- Accessibility presets for low vision, color differentiation, one-switch input, and spoken-only dealer support.

### Deliberately defer or reject

- Camera scanning at launch: lighting, sleeves, occlusion, languages, training imagery, and IP create a fragile dependency.
- Cloud accounts as a prerequisite: violates the offline-first strength and adds no value to a shared table MVP.
- Public matchmaking: turns a table companion into a live service with moderation, identity, cheating, latency, and uptime obligations.
- An animated 3D table: spectacle does not justify reduced glanceability or slower decisions.
- Hidden dynamic difficulty or “luck balancing”: destroys trust.
- Reroll after undo: enables card fishing and makes history non-deterministic.
- One blended screen containing full calculator controls and a Draw button: two authorities create impossible state.

## Ruleset scalability

Define an internal ruleset boundary that supplies:

- Deck factory and supported customizations.
- Card definitions and labels.
- Valid commands by phase.
- Target eligibility.
- Pure card-resolution transitions.
- End conditions.
- Semantic hand projection for ScoreEngine.
- Immediate-risk evaluation.
- Help copy and accessibility descriptions.

Do not build a general user-facing rules DSL. Strongly typed Classic and Vengeance implementations are easier to validate, migrate, and explain. Generalize only from two proven rulesets and original future profiles, not from imagined extensibility.

Custom deck behavior:

- Scorekeeper can continue accepting custom counts.
- Deck Tracker/Digital Dealer should only start if every configured definition has implemented live semantics.
- Changing counts requires a new shoe.
- Unknown action keys make live play unavailable with a clear reason; they must not be treated as inert cards.

## Verification strategy

### Pure rules and model tests

- Exact default deck instances and unique IDs.
- Shuffle preserves the multiset and count.
- Every card is in exactly one zone.
- Draw + undo + redo preserves order and identity.
- Round end moves only table cards to discard.
- Mid-round exhaustion reshuffles discard but excludes all live table cards.
- Opening-deal actions pause and resume the correct recipient.
- Every Classic action and nested Flip Three sequence.
- Second Chance consumption and reassignment.
- Seven-card completion at every point in a forced sequence.
- No-active-player round completion.
- Decode fixtures for every live schema version and legacy calculator games.

### Probability tests

- Hand-calculated fixtures such as `2, 5, 9` in a fresh shoe.
- Current-table cards removed from numerator and denominator correctly.
- Second Chance changes immediate bust probability to zero while reporting protection-consumption risk separately.
- Special 7 and 13 transitions use rule semantics, not labels.
- Exhaustive comparison: probability numerator equals the count of individual remaining instances that cause the reducer to bust.
- Monte Carlo checks detect gross shuffle or probability errors without replacing exact unit assertions.
- No NaN, negative, above-100%, or nonzero risk with an empty/unavailable pile.

### State-machine tests

- Invalid commands leave state unchanged and return a precise reason.
- Every pending phase survives encode/decode.
- Commands are idempotent where duplicate delivery is possible.
- A draw cannot be accepted twice from a double tap.
- Correction commands preserve zone counts.
- Mode/profile changes are rejected once the shoe is live.
- Rules version remains fixed across app upgrades and resume.

### Fault and endurance tests

- Terminate after every transition boundary and verify exact resume.
- Interrupt during reveal animation, target selection, forced draw, round end, and reshuffle.
- Hundreds of seeded full games with zone and score invariants checked after every event.
- Maximum player count, custom deck limits, repeated reshuffles, and long game histories.
- Corrupt/truncated persistence fixture with non-destructive recovery.
- Rapid repeated Draw taps and accessibility activation.

### UI and table tests

- Upgraded user starts an ordinary scorekeeper game in the same number of taps as the current baseline.
- Missing entry preference and missing `playStyle` both select Scorekeeper without showing a migration prompt.
- Existing active scorekeeper games resume directly without visiting setup.
- Both setup choices are recognizable within five seconds in unmoderated first-use testing.
- Switching the setup choice changes only the conditional panel and CTA label; player, rules, and target values are preserved.
- Dealer cannot be started accidentally by tapping its explanatory copy or one-time announcement.
- iPhone SE-class compact height, standard iPhone, and large iPhone.
- iPad mini and regular iPad in portrait and landscape.
- Split View and Stage Manager widths.
- 2, 4, and 8 players; extend to every supported live roster size before release.
- Light/dark, largest useful Dynamic Type, VoiceOver, Voice Control, Switch Control where feasible, Reduce Motion, and haptics/sound disabled.
- Card reveal visible to players across a real table.
- Primary action usable one-handed by a seated host.
- No state conveyed solely through card animation, color, haptic, or audio.

Use existing Make targets and add narrow reducer/probability suites. A release candidate should escalate through the repository's full verification and physical-device checks.

## Product research plan

Do not validate only with internal demos. Test these distinct cohorts:

- Existing users who want the fastest possible calculator.
- One designated host using an iPhone.
- Groups sharing an iPad in landscape.
- New players who need action guidance.
- Experienced players who count cards and care about odds.
- Players who explicitly dislike phones at the table.
- VoiceOver and large-text users.

Run comparison sessions:

1. Physical deck + current Scorekeeper.
2. Physical deck + Deck Tracker.
3. Digital Dealer.

Measure:

- Time from setup to first draw.
- Seconds and taps per ordinary Hit/Stay cycle.
- Host attention on device versus people/table.
- Wrong-player, wrong-card, and wrong-target errors.
- Recovery time from a deliberate mistaken tap.
- Ability to explain why the last outcome occurred.
- Confidence that the deck was fair.
- Understanding of the probability label.
- Preference by task, not just overall novelty.
- Whether odds increase thoughtful tension or drain it.
- Whether the app removes a chore or becomes the center of attention.

Release only when Scorekeeper remains no slower, both entry lanes are immediately understandable, Deck Tracker produces exact state without unacceptable input burden, and Digital Dealer feels fair and socially legible.

## Phased delivery and exit gates

### Phase 0 — decision and prototype specification

- Choose licensed-specific versus original-generic Digital Dealer direction.
- Finalize public terminology and original card visual language.
- Prototype the two-choice setup within the current `GameSetupView`; establish the current scorekeeper tap count as a regression budget.
- Build a complete Classic transition table on paper.
- Prototype the iPhone and iPad live surfaces without production persistence.
- Conduct fairness and table-attention tests.

Exit: legal/product direction decided; existing users start scoring with no added tap; new users can identify both entry lanes; users can identify current player/action instantly; transition table has no unresolved Classic rule.

### Phase 1 — probability foundation

- Pure ProbabilityService using deck profile and semantic transitions.
- Estimate confidence contract.
- Compact calculator risk pill and explanation sheet.
- Odds off by default for existing users until preference is chosen.
- Odds Lab optional if it does not delay live foundations.

Exit: exact fixtures and reducer-comparison tests pass; no metric is presented without definition/confidence.

### Phase 2 — physical Deck Tracker

- Card instances, zones, shoe multiset, event ledger, state machine, table log, and corrections.
- Classic actions and round/deck lifecycle.
- Exact physical-deck odds after confirmed shuffle.
- Persisted resume and decision-boundary undo.

Exit: complete seeded and real-table Classic sessions survive corrections, exhaustion, and termination with no zone divergence.

### Phase 3 — Classic Digital Dealer

- Ordered committed shoe and one-tap Draw.
- Fairness explanation and optional shuffle receipt.
- Live iPhone/iPad layouts, feedback, accessibility, keep-awake behavior.
- Emergency fallback to Scorekeeper.

Exit: rights gate passed; rules audit passes; fairness perception and table usability meet research thresholds; full regression suite passes.

### Phase 4 — Vengeance live engine

- Special numbers, all action transfers, deferred sequences, stayed-player eligibility, and Brutal rules.
- Rules examples and official FAQ encoded as fixtures.
- Vengeance-specific probability semantics.

Exit: full command table and official examples pass; no Classic regression; mixed existing history remains stable.

### Phase 5 — shared displays and nearby clients

- External public scoreboard first.
- Read-only nearby clients second.
- Player Hit/Stay input last, with host authority and disconnect fallback.

Exit: single-device play remains complete; connectivity never blocks or corrupts a local game.

## Decision register

Decisions recommended now:

- Preserve Scorekeeper as the default and fastest line.
- Expose `Score Calculator` and `Simulator` as the two setup choices.
- Name and model Deck Tracker separately from Digital Dealer internally, but expose tracking inside `Deck & Odds` rather than as a third primary choice.
- Extend the existing setup instead of adding a new home screen or permanent tab bar.
- Remember the last intentionally used lane while retaining Scorekeeper as every legacy/default decode path.
- Use one rules reducer for both live styles.
- Make immediate next-card bust probability the first and only headline risk metric.
- Display confidence on every probability.
- Lock deck/mode after a live shoe begins.
- Ship Classic before Vengeance live play.
- Keep a snapshot plus event ledger; do not rewrite the current app into event sourcing.
- Keep online/multi-device out of the MVP.

Decisions that require owner input before implementation:

- Whether a playable third-party-specific digital deck will be licensed, legally reviewed, or replaced by an original generic profile.
- Whether exact odds default to off, heat, or percentage for new games.
- Whether Deck Tracker is valuable enough despite recording every physical reveal.
- Whether Digital Dealer should require physical product ownership even if technically unnecessary.
- Whether the app should speak card/player names by default or remain quiet.

## Sources

### Primary rules and product

- [Classic product page and official rules download](https://www.asmodee.ca/en/product/flip-7/)
- [Classic rulebook, ruleset edition 3.1](https://cdn.svc.asmodee.net/production-asmodeeca/uploads/2025/12/FLIP_7-RULES.pdf)
- [Asmodee UK gameplay and deck lifecycle overview](https://www.asmodee.co.uk/blogs/news/how-to-play-flip-7)
- [The Op Games Classic FAQ](https://theop.games/pages/flip-7-faqs)
- [Vengeance official product page](https://theop.games/products/flip-7-with-a-vengeance)
- [Vengeance official FAQ](https://theop.games/pages/flip-7-wav-faqs)
- [Vengeance ruleset edition 1](https://gamers-hq.de/media/pdf/fd/17/0a/26_FLIP_7_VENGEANCE_RULES_C.pdf)

### Direct and adjacent products

- [Flip & Score App Store listing](https://apps.apple.com/us/app/flip7-score/id6747075064)
- [FlipScore App Store listing](https://apps.apple.com/us/app/flipscore-flip-7-scorekeeper/id6760599005)
- [Flip 7 Score App Store listing](https://apps.apple.com/us/app/flip-7-score-keeper/id6760317673)
- [Flip 7 Score Google Play listing](https://play.google.com/store/apps/details?id=com.flip7score)
- [Unofficial browser-based full digital implementation](https://flip7cards.com/)
- [Board Game Stats App Store listing](https://apps.apple.com/us/app/board-game-stats/id892542000)
- [Board Game Stats score sheets](https://www.bgstatsapp.com/score-sheets/)
- [Score Anything App Store listing](https://apps.apple.com/us/app/score-anything-scorekeeper/id1541777240)
- [GameScore App Store listing](https://apps.apple.com/us/app/gamescore-scorekeeper/id1164683696)
- [Score Keeper for Game Night App Store listing](https://apps.apple.com/us/app/score-keeper-2020/id1245390236)
- [Deck of Cards virtual dealer App Store listing](https://apps.apple.com/us/app/deck-of-cards-virtual-deal/id1191150977)
- [Draw a Card custom-deck App Store listing](https://apps.apple.com/us/app/draw-a-card-deck/id838900770)
- [One Night official companion App Store listing](https://apps.apple.com/us/app/one-night/id728175611)
- [HeroQuest official companion overview](https://apps.hasbro.com/en-IN/heroquest-companion-app)
- [Frosthaven official companion App Store listing](https://apps.apple.com/us/app/frosthaven-official-companion/id6443837203)

### Research and platform guidance

- [Hybrid technologies for tabletop games — University of Melbourne](https://cis.unimelb.edu.au/research/hci/projects/hybrid-digital-boardgames)
- [Unpacking Boardgames with Apps: The Hybrid Digital Boardgame Model](https://doi.org/10.1145/3411764.3445077)
- [Getting Hybridity Just Right: The Goldilocks Factor in Hybrid Digital Boardgames](https://doi.org/10.1145/3772318.3791963)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple Human Interface Guidelines: Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games/)
- [Apple Human Interface Guidelines: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/)
- [Apple Human Interface Guidelines: Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics/)
- [Swift SystemRandomNumberGenerator](https://developer.apple.com/documentation/swift/systemrandomnumbergenerator)
- [CryptoKit SHA-256](https://developer.apple.com/documentation/cryptokit/sha256)
- [SwiftUI state restoration](https://developer.apple.com/documentation/swiftui/restoring-your-app-s-state-with-swiftui)
- [UIApplication idle timer behavior](https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled)
- [Apple Network framework](https://developer.apple.com/documentation/network)
