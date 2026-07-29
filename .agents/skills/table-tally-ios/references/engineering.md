# Engineering Workflow

## Preferred Commands

Use the Makefile instead of raw `xcodebuild` whenever possible.

- `make help`
- `make build`
- `make test`
- `make test-one TEST=flip7calculatorTests/PlayerPaletteTests`
- `make test-one TEST=flip7calculatorTests/PlayerPaletteTests/testEarthPaletteSafeFromReserved`
- `make ui-test`
- `make launch`
- `make build-settings`

Optional overrides:

- `SIMULATOR_NAME="iPhone SE (3rd generation)"`
- `SIMULATOR_OS=18.5`

## Why the Makefile Exists

Raw `xcodebuild test` currently fails early on simulator test-bundle signing for this project.

The local wrapper fixes the common pitfalls by:

- resolving a usable simulator automatically
- passing `CODE_SIGNING_ALLOWED=NO`
- passing `CODE_SIGNING_REQUIRED=NO`
- piping output through `xcbeautify` when it is installed
- storing DerivedData and result bundles under `~/Library/Caches/TableTally/` by default, outside the repo

## Current Local Baseline

Verified on April 10, 2026:

- `make test` runs through the simulator successfully
- the full unit and UI test suite passes on `iPhone 16` / `iOS 18.5`
- Release simulator builds are reliable when DerivedData lives outside the repo
- the earlier `PlayerPaletteTests` failures and test-source warning cluster have been cleaned up

If your task is unrelated to palette generation or test cleanup, do not spend the whole turn fixing these unless the user asks.

## High-Value Files

- `flip7calculator/flip7calculatorApp.swift`
  - app entry and splash routing
- `flip7calculator/ContentView.swift`
  - top-level screen switching and theme plumbing
- `flip7calculator/ViewModels/GameViewModel.swift`
  - game state, persistence, undo/redo, deck enforcement
- `flip7calculator/Scoring/ScoreEngine.swift`
  - pure score math
- `flip7calculator/Stats/GameStats.swift`
  - derived stats and chart inputs
- `flip7calculator/Utilities/AppBrand.swift`
  - shared product strings and rebrand constants
- `flip7calculator/Utilities/DesignTokens.swift`
- `flip7calculator/Utilities/DesignStyles.swift`
  - semantic styling foundation

## Build and Debug Notes

- This app is offline-first; there is no backend or analytics SDK to chase.
- When you need a clean rerun, use `make clean`.
- When debugging a simulator launch issue, run `make launch` so the same resolved simulator is used for both install and launch.
- If you must drop to raw `xcodebuild`, replicate the no-signing flags first before assuming the project is broken.
