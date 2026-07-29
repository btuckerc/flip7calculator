# Screen Blueprints (Full Sweep)

## 1. Launch / Loading
- Primary:
  - Branded card-to-calculator reveal animation
  - Strong focal point with short time-to-content
- Compact:
  - Reduced visual density on smaller devices
- Reduced motion:
  - Static/fade variant with same information hierarchy

## 2. Setup
- Primary:
  - Hero title, player roster, target score controls, single dominant CTA
- Compact:
  - Tight spacing and one-line labels for narrow widths
- Empty state:
  - Two default player slots, disabled start CTA until valid

## 3. Active Game
- Primary:
  - Player grid + anchored selected-player control panel
  - Bottom action bar: next round, undo/redo, continue
- Compact:
  - Reduced chip/button density, preserved tap targets
- Edge states:
  - Winner detected
  - Bust/freeze/banked visual states
  - No selection fallback

## 4. Rules
- Primary:
  - Paged educational flow with visual cards and examples
- Compact:
  - Collapsed spacing and typography for smaller devices
- Edge states:
  - First/last page controls, pagination clarity

## 5. Settings
- Primary:
  - Theme + visual theme controls
  - Player palette, game options, accessibility, support, about
- Compact:
  - Shorter section footers and tighter row spacing
- Edge states:
  - Current-game target score edits vs default score edits

## 6. Game Over + Stats
- Primary:
  - Winner emphasis, leaderboard hierarchy, trend charts
- Compact:
  - Scroll-first layout with summary-first ordering
- Edge states:
  - Ties, low-data chart states

## 7. Player Management
- Primary:
  - Editable roster list with previews
- Compact:
  - Simplified tile previews
- Edge states:
  - Empty roster and reset flow

## 8. Deck Management
- Primary:
  - Deck profile controls and card-count summaries
- Compact:
  - Grouped controls with single-column density
- Edge states:
  - Invalid/min-max counts and reset defaults

## 9. Global overlays / transient UI
- Confirmation overlays
- Inline bust/freeze banners
- Toast-level feedback (when applicable)

## Implementation order
1. Tokens and semantic styles
2. Shared controls (buttons/chips/cards)
3. Setup
4. Active game
5. Loading/splash
6. Settings
7. Rules
8. Game over/stats
9. Player/deck management
