---
name: Vector Flip7 wordmark
overview: Replace the title’s Text-based rendering with a custom vector wordmark so letterforms match the box art (pointed 7, wider P counter) and we can add true per-letter spacing while keeping the existing iridescence + animations.
todos:
  - id: vector-glyphs
    content: Implement vector paths for F/L/I/P and 7, with box-like proportions.
    status: completed
  - id: stroke-stack
    content: Replace text-stacking outline with true stroke/fill rendering.
    status: completed
    dependencies:
      - vector-glyphs
  - id: spacing-tuning
    content: Add explicit spacing between F–L–I–P.
    status: completed
    dependencies:
      - vector-glyphs
  - id: seven-shape-anim
    content: Pointed 7 + smooth wobble + flip every 7s + iridescent mask.
    status: completed
    dependencies:
      - vector-glyphs
      - stroke-stack
  - id: reduced-motion
    content: Frozen high-quality static state for Reduce Motion / Reduce Animations.
    status: completed
    dependencies:
      - stroke-stack
      - seven-shape-anim
---

# Vector Flip7 wordmark

## Goals

- Match the box-art letterforms more closely by switching from `Text` to a **custom vector wordmark**:
- **Pointed top-right on the 7**
- Slightly rounded internal angles
- **Wider P counter** (less “D”-like)
- **More spacing within FLIP** (F–L–I–P)
- Preserve the existing look/behavior:
- Outline color order: **yellow fill → blue → red → blue**
- Blue drop shadow down-right
- Iridescent background stays same size
- 7 has iridescent pass + idle wobble + flip every **7s**
- Respect `animateMainMenuTitle`, `reduceAnimations`, and iOS Reduce Motion

## Implementation

### 1) Add vector glyph shapes

- Update [`flip7calculator/Views/Components/Flip7TitleView.swift`](/Users/tucker/Documents/GitHub/flip-7/flip7calculator/flip7calculator/Views/Components/Flip7TitleView.swift) to introduce:
- `Flip7WordmarkShape` (composes `F`, `L`, `I`, `P`, `Seven` as separate Paths in a normalized coordinate space)
- `Flip7SevenShape` (separate shape so it can wobble/flip independently)

### 2) Render the multi-outline stack correctly

- Replace the current “outlineLayer via 16 Text copies” with shape stroking:
- **Drop shadow layer**: filled `Flip7Style.blue.opacity(...)` offset down-right
- **Outer stroke**: blue
- **Middle stroke**: red
- **Inner stroke**: blue
- **Fill**: yellow

### 3) Implement box-like letter spacing

- Because we’re composing letters explicitly, apply a **per-letter x-offset** table (e.g. `letterSpacing: CGFloat`) to widen F–L–I–P spacing without changing background size.

### 4) Make the 7 match the box and animate cleanly

- In `Flip7SevenShape`:
- Add the **pointed corner** by extending the top-right vertex and using a small chamfer/round at interior joints.
- Apply animation only to the 7 group:
- **Idle**: 3D yaw wobble (Y axis)
- **Flip**: smoother spring/ease at an exact **7s cadence**
- Keep the iridescent pass masked to the 7 shape.

### 5) Reduced motion

- Render the same vector wordmark but freeze:
- No wobble/flip
- Background/7 iridescence frozen at a pleasant phase

## Acceptance criteria

- The wordmark reads closer to the box (notably the **7 shape** and **P counter**).
- Spacing within **F–L–I–P** is noticeably more comfortable.
- Outlines look like true strokes (not stacked text artifacts).
- Only the 7 animates; background stays consistent and lightweight.