# Flipping Seven Calculator

Flipping Seven Calculator is an offline SwiftUI scorekeeper for card nights and push-your-luck style table games. It supports iPhone and iPad, local persistence, round history, undo/redo, deck profiles, and post-game stats.

The public product is being updated in place from its former title to `Flipping Seven Calculator`. Internal names still use `flip7calculator`, while reusable public copy routes through `AppBrand`.

## Quick Start

Requirements:

- Xcode 18+
- An iOS simulator runtime
- `xcbeautify` recommended for readable build/test output

Common commands:

- `make help`
- `make build`
- `make test`
- `make test-one TEST=flip7calculatorTests/PlayerPaletteTests`
- `make ui-test`
- `make launch`
- `make clean`

The Makefile uses a no-signing simulator path by default and stores DerivedData under `~/Library/Caches/FlippingSevenCalculator/`. That matters here because raw `xcodebuild test` still fails early on simulator bundle signing, and keeping build products out of the repo avoids the filesystem issues we saw when DerivedData lived under `Documents/.../.build`.

## Agent Setup

Start here before non-trivial changes:

- `AGENTS.md`
- `.agents/skills/table-tally-ios/SKILL.md`
- `docs/APP264401-I-path-forward.md`

Repo-local agent references live under `.agents/skills/table-tally-ios/references/`:

- `product.md`
- `experience-rubric.md`
- `engineering.md`
- `research.md`

## Product Priorities

- Fast, trustworthy score entry during live play
- Clear round state and cumulative score visibility
- iPhone and iPad parity
- Accessibility: Dynamic Type, VoiceOver, reduced motion, contrast
- Original branding and artwork that do not reuse third-party logos or trade dress

## Architecture Snapshot

- App entry: `flip7calculator/flip7calculatorApp.swift`
- Game orchestration and persistence: `flip7calculator/ViewModels/GameViewModel.swift`
- Scoring: `flip7calculator/Scoring/ScoreEngine.swift`
- Stats: `flip7calculator/Stats/GameStats.swift`
- Rebrand/product copy: `flip7calculator/Utilities/AppBrand.swift`
- Tokenized styling: `flip7calculator/Utilities/DesignTokens.swift`, `flip7calculator/Utilities/DesignStyles.swift`

## Known Baseline

As verified locally on July 28, 2026:

- `make test` passes 133 unit tests with no failures or skips on `iPhone 16` / `iOS 18.5`.
- `make ui-test` passes all 3 UI test methods across 4 executions with no failures or skips.
- `make build CONFIGURATION=Release` succeeds with simulator signing disabled and DerivedData outside the repo.
- The built bundle reports `Flipping Seven Calculator`, version `1.3 (9)`, Utilities category, and iPhone/iPad support.
- Stable dark-appearance layouts were visually checked on compact iPhone and regular-width iPad simulators.
- Light appearance, large Dynamic Type, full VoiceOver operation, physical-device behavior, distribution signing, and App Store upload remain release checks rather than assumed successes.
