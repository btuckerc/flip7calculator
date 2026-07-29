# App Experience Rubric

Use this checklist when designing, reviewing, or refactoring UI in this repo.

## 1. Fast Input First

- The most common scoring actions should remain obvious and low-friction.
- Important live-play controls should not be buried behind sheets, nested menus, or long scrolls.
- Score entry should reward glanceability over decorative complexity.

## 2. State Must Be Legible

- A player's round state should be obvious without extra taps.
- Current totals, round previews, and target progress should stay easy to scan.
- Feedback for `bank`, `bust`, `hold`, undo, and manual override should be immediate and unambiguous.

## 3. Accessibility Is Part of Correctness

- Touched screens should still work at larger Dynamic Type sizes.
- VoiceOver labels and traits should describe controls in gameplay terms, not only visual terms.
- Contrast should remain strong in both light and dark appearances.
- Motion-heavy changes need a reduced-motion equivalent, not just a smaller animation.

## 4. iPhone and iPad Both Matter

- Avoid solving a layout problem only for one size class.
- Large-screen layouts should use extra space intentionally instead of stretching cramped phone layouts.
- Tap targets must stay comfortable on both compact and regular layouts.

## 5. Performance Is User Experience

- Avoid unstable identity in lists and `ForEach`.
- Avoid recomputing heavy view state in hot paths without a reason.
- Keep animations meaningful and short; do not trade clarity for spectacle.
- If a refactor complicates state flow, it should buy a measurable UX or maintainability win.

## 6. Brand and Trust

- UI should feel like `Flipping Seven Calculator`, not a thin reskin of the old single-game brand.
- Copy should sound generic, helpful, and confident.
- Do not add fake-generic visuals that still clearly mirror old protected branding.

## UI Review Prompts

Before closing a UI task, ask:

- Is score entry faster, slower, or unchanged?
- Can a new player understand the current game state in under a few seconds?
- Did I improve or damage accessibility?
- Does the change still make sense on iPad?
- Did I add a new hard-coded style that should have been tokenized instead?
