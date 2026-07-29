# Lucky Ledger

Lucky Ledger is an offline SwiftUI scorekeeper for card nights and push-your-luck style table games. It supports iPhone and iPad, local persistence, round history, undo/redo, deck profiles, and post-game stats.

The repo is in the middle of a rebrand away from the old `Flip 7` identity. Internal names still use `flip7calculator`, but user-facing copy should stay generic and route through `AppBrand` where possible.

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

The Makefile uses a no-signing simulator path by default and stores DerivedData under `~/Library/Caches/LuckyLedger/`. That matters here because raw `xcodebuild test` still fails early on simulator bundle signing, and keeping build products out of the repo avoids the filesystem issues we saw when DerivedData lived under `Documents/.../.build`.

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
- Generic branding that avoids old game-specific trademark exposure

## Architecture Snapshot

- App entry: `flip7calculator/flip7calculatorApp.swift`
- Game orchestration and persistence: `flip7calculator/ViewModels/GameViewModel.swift`
- Scoring: `flip7calculator/Scoring/ScoreEngine.swift`
- Stats: `flip7calculator/Stats/GameStats.swift`
- Rebrand/product copy: `flip7calculator/Utilities/AppBrand.swift`
- Tokenized styling: `flip7calculator/Utilities/DesignTokens.swift`, `flip7calculator/Utilities/DesignStyles.swift`

## Known Baseline

As verified locally on April 10, 2026:

- Raw `xcodebuild test` fails early on simulator signing for the test bundle.
- `make test` passes the full unit and UI suite on `iPhone 16` / `iOS 18.5`.
- `xcodebuild build` for `Release` succeeds when DerivedData is outside the repo; the local workflow now defaults to `~/Library/Caches/LuckyLedger/DerivedData` for that reason.
- The earlier palette regressions and test-source warnings have been cleaned up.
