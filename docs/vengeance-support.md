# Vengeance Rules and App Support

Research and implementation record for the app's Vengeance mode. Verified July 29, 2026 against the publisher's product page, ruleset edition 1, and official FAQ.

## Product distinction

`Flip 7: With a Vengeance` is a standalone sequel with its own 108-card deck, not an expansion pack mixed into the 94-card Classic deck. The app therefore models Classic and Vengeance as separate game modes with separate saved deck profiles.

The publisher labels the product for `3+ Players`. The rulebook also gives groups of two or fewer an explicit challenge: count how many rounds it takes to reach 200. The app continues to allow two-player setup rather than presenting it as invalid.

## Verified deck composition

### Number cards: 92

| Card | Count |
| --- | ---: |
| Regular 1 through 6 | 1, 2, 3, 4, 5, 6 |
| Regular 7 | 6 |
| Unlucky 7 | 1 |
| Regular 8 through 12 | 8, 9, 10, 11, 12 |
| Regular 13 | 12 |
| Lucky 13 | 1 |
| The Zero | 1 |

The three special numbers replace the last expected copy of their value. That yields 89 regular number cards plus 3 special number cards.

### Modifier cards: 6

There is one each of `-2`, `-4`, `-6`, `-8`, `-10`, and `Divide by 2`.

### Action cards: 10

There are two each of `Just One More`, `Flip Four`, `Swap`, `Steal`, and `Discard`.

### Total

`92 number + 6 modifier + 10 action = 108 cards`.

## Core round and scoring rules

- The target remains 200 points by default.
- A player stays, busts on a duplicate number, or reaches seven different number cards to end the round immediately.
- Stayed and forced-to-stay players remain exposed to eligible action and modifier cards until the round ends.
- Score in this exact order: add number values; divide by two and round down; subtract negative modifiers; clamp the subtotal to zero in normal mode; then add the 15-point seven-card bonus.
- Modifier and action cards do not count toward the seven-card bonus.
- Cards from completed rounds remain discarded until the draw deck runs out. More than 18 players is the publisher's threshold for recommending a second deck.

## Special number cards

### The Zero

- The hand's number-card subtotal becomes zero.
- The player must continue to hit on their normal turn.
- The card counts toward seven number cards.
- Reaching seven cards still scores the 15-point bonus.
- A `Just One More` can force the player to stay before seven cards are reached.

### Unlucky 7

- Immediately discard every other Number and Modifier card in front of the recipient and keep only Unlucky 7.
- It takes precedence over an existing 7, so receiving it does not itself bust the player.
- A later regular 7 does bust that player.
- During `Flip Four`, apply the discard immediately, then complete the remaining flips unless a normal stop condition occurs.

### Lucky 13

- It may coexist with one regular 13.
- Both 13s score and both count toward seven cards.
- A third 13 causes a bust.
- Like the other special numbers, it may be stolen, swapped, or discarded; its effect applies only while possessed.

## Action and modifier handling

- Revealed actions are mandatory when there is a valid target and resolve immediately, except for the documented `Flip Four` sequencing.
- Actions can target any player who has not busted, including the acting player and anyone who stayed or was forced to stay.
- `Just One More` forces one additional card and then a stay. Any revealed action still resolves.
- `Flip Four` deals up to four cards one at a time, stopping on a bust or seven-card completion. If the player survives, revealed actions and modifiers resolve afterward in reveal order.
- A player who already stayed remains inactive after resolving `Flip Four` and its actions.
- `Swap` exchanges two face-up cards and can bust one or both recipients.
- `Steal` moves one face-up card into the acting player's line.
- `Discard` removes a chosen card from a chosen non-busted player.
- If an action has no valid target early in a round, discard it.
- Normal-mode modifiers can target non-busted players, including stayed players. The divide modifier applies before all negative modifiers.

The app remains a scorekeeper rather than a dealer simulator. Users record the resulting number and modifier cards after resolving physical Action cards. This avoids a second, potentially divergent game-state engine while still supporting Swap, Steal, Discard, Just One More, and Flip Four outcomes. To support those outcomes, Vengeance hands remain editable after a player stays; Brutal mode also allows modifiers on busted players.

## Brutal mode

- Brutal is an optional, more cutthroat variant; standard non-Brutal Vengeance is the default.
- Round scores may be negative.
- Modifier cards may target busted players.
- A player who reaches seven cards chooses either to keep the 15-point bonus or give another player a 15-point penalty.

The app records redirected bonuses explicitly so both the live score and post-game stats preserve who kept or sent the bonus. A busted player's Brutal modifier score starts at zero and can be reduced below zero; this follows the rulebook's combined instructions that busted players may receive modifiers and round scores may go below zero.

## App behavior

### Setup and Settings

- `Classic` and `Vengeance` are selectable on the setup screen.
- The Vengeance setup description notes that additional `With a Vengeance` cards are required.
- A default mode can be chosen in Settings.
- Brutal mode is off by default, available only for Vengeance, and cannot leak into Classic.
- A running game can switch modes from Settings without resetting players, scores, target, round number, or completed history.
- Shared regular numbers stay with each player's current hand. Mode-only numbers, modifiers, special cards, manual overrides, and Brutal redirects are saved separately and return if the player switches back during the same round.
- Switching is persisted and participates in Undo/Redo. Per-mode current-round snapshots are cleared when the round is completed so cards cannot leak into the next round.

### Deck management

- Classic and Vengeance custom profiles are stored separately.
- Vengeance exposes regular 1-13 cards, all three special numbers, six negative modifiers, and five action types.
- Reset restores only the selected mode: 94 cards for Classic or 108 cards for Vengeance.
- An active game's mode can be switched from Deck Profile; each mode restores its matching saved deck profile.
- Action counts contribute to total deck size even though actions are resolved at the physical table.

### Live score entry

- Vengeance replaces positive modifiers and `x2` with negative modifiers and `Divide by 2`.
- Special number chips record Zero, Unlucky 7, and Lucky 13 distinctly.
- Adding Unlucky 7 clears the modeled hand exactly as the physical effect requires.
- Stayed players remain editable so later actions can change their cards.
- Brutal mode accepts negative manual scores and permits negative modifiers on busted players.
- A seven-card Brutal choice can keep the bonus or redirect it as `-15` to another player.

### History and stats

- Completed rounds persist the rules used, negative modifiers, divide cards, special numbers, score adjustments, and redirected bonus target.
- Mixed-mode games retain the correct terminology and card-stat sections for each completed round.
- Stats use `Stayed` and `Forced to Stay` terminology for Vengeance.
- Post-game details count special numbers, divide cards, negative modifier points, and redirected bonuses.
- Negative safe rounds and negative Brutal busts remain visible in charts and round history.

## Compatibility decisions

- Existing games and deck profiles without a ruleset decode as Classic.
- Existing Classic scoring and its 94-card default remain unchanged.
- Internal target and bundle identifiers remain unchanged to preserve the existing App Store record.
- User-facing app copy calls the new mode `Vengeance`; it does not restore the exact disputed mark or publisher branding covered by `APP264401-I`.

## Verification checklist

- Exact 94- and 108-card defaults are unit-tested.
- Scoring order, floor division, normal-mode clamping, and Brutal negatives are unit-tested.
- Zero, Unlucky 7, Lucky 13, busted modifiers, and redirected bonuses are unit-tested.
- Mid-game switching, shared-number carryover, mode-only restoration, over-cap deck handling, persistence, Undo/Redo, and round-boundary cleanup are unit-tested.
- Legacy deck, hand, round, and game decoding is covered.
- Simulator build, unit tests, UI tests, iPhone layout, iPad layout, Dynamic Type, VoiceOver labels, and reduced-motion parity must pass before release.

### Completed Layout Validation

- Automated live-game layout coverage exercises 4, 5, 6, 7, and 8 players in Vengeance mode.
- The matrix passes on an iPhone SE (3rd generation), iPhone 16, and iPad mini (A17 Pro).
- Player tiles retain a readable minimum height and the player grid becomes vertically scrollable only when a compact-height device cannot display both rows without clipping.
- The selected-player header, Stay/Bust/Forced Stay actions, special numbers, all six Vengeance modifiers, and bottom controls remain visible and inside the window at every tested roster size.

## Sources

- [The Op Games product page](https://theop.games/products/flip-7-with-a-vengeance)
- [Ruleset edition 1 PDF](https://gamers-hq.de/media/pdf/fd/17/0a/26_FLIP_7_VENGEANCE_RULES_C.pdf)
- [The Op Games official FAQ](https://theop.games/pages/flip-7-wav-faqs)
