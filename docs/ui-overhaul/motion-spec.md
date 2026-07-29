# Motion Spec (v2)

## Motion principles
- Keep motion intentional, fast, and meaningful.
- Prioritize state comprehension over flourish.
- Preserve accessibility parity with reduced-motion alternatives.

## Timing presets
- `fast`: 150ms (tap feedback, micro state changes)
- `normal`: 250ms (layout-safe transitions, chip toggles)
- `emphasis`: spring response 450ms (hero transitions only)

## Launch/loading sequence (v2 target)
1. `entry` (0ms-300ms): logo/card motif appears
2. `build` (300ms-1100ms): card stack and calculator motif resolve
3. `handoff` (1100ms-1450ms): dissolve to home/setup

## Reduced-motion variant
- Replace transforms with opacity transitions only.
- Cap total splash time to <= 900ms.
- Disable chained stagger effects.

## In-screen interaction motion
- Buttons/chips: press opacity or scale micro-feedback only.
- Panel transitions: avoid large reflow animations.
- Overlays: fade + slight y-offset, no aggressive bounce.

## Non-goals
- No gameplay timing changes.
- No animations that hide required game state.
- No infinite decorative loops outside optional decorative title effects.
