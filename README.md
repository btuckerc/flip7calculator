# Flipping Seven Calculator

Flipping Seven Calculator is an offline SwiftUI scorekeeper for card nights and push-your-luck table games. It supports iPhone and iPad, local persistence, undo/redo, separate Classic and Vengeance deck profiles, mid-game mode switching, round history, and post-game statistics.

The public product name is `Flipping Seven Calculator`. Internal project, target, module, bundle, and App Store identifiers still use `flip7calculator` to preserve the existing app record and avoid migration risk.

## Quick Start

Requirements:

- macOS with Xcode 26 or newer for current App Store compatibility
- An installed iOS simulator runtime
- `jq` (required by simulator discovery)
- `xcbeautify` recommended for readable build and test output

Run:

```bash
make doctor
make test-unit
make launch
```

The workflow keeps DerivedData and `.xcresult` bundles under `~/Library/Caches/FlippingSevenCalculator/`. Keeping them outside this repository avoids filesystem and Release-build instability previously observed under `Documents/.../.build`.

## Command Guide

| Need | Command |
|---|---|
| Discover all workflows | `make help` |
| Validate local setup | `make doctor` |
| Build or launch | `make build`, `make launch` |
| List discovered tests | `make list-tests` |
| Fast unit target | `make test-unit` |
| One suite or test | `make test-one TEST=flip7calculatorTests/ScoreEngineTests` |
| Repeat a suspected flaky suite | `make test-repeat TEST=flip7calculatorTests/ScoreEngineTests ITERATIONS=20` |
| UI target only | `make ui-test` |
| Full unit and UI plan | `make test` |
| Full tests plus Release build | `make verify` |
| Inspect the latest full result | `make test-summary` or `make open-results` |
| Measure build work | `make build-timed` |
| Validate listing assets | `make release-assets` |
| Release readiness without upload | `make release-preflight` |

Use `SIMULATOR_NAME="iPhone SE (3rd generation)"` or `SIMULATOR_OS=18.5` to override the destination. `SIMULATOR_NAME=auto` selects the first available iPhone on the newest installed runtime and is useful for hosted CI. Run `make destinations` to list valid choices.

## Working In This Repo

Start with these in order:

1. `AGENTS.md` for durable guardrails and test escalation.
2. `.agents/skills/table-tally-ios/SKILL.md` for task routing and progressive references.
3. `docs/AGENT_PLAYBOOK.md` for feature, bug, UI, research, and release workflows.
4. `docs/ARCHITECTURE.md` before changing state, persistence, scoring, stats, or rules.
5. `docs/RELEASE_RUNBOOK.md` before signing, uploading, TestFlight, screenshots, or App Review work.

Branding and public copy also require `docs/APP264401-I-path-forward.md`. Vengeance behavior and its verified sources are recorded in `docs/vengeance-support.md`.

## Architecture At A Glance

- `flip7calculator/flip7calculatorApp.swift`: app entry and opening presentation
- `flip7calculator/ContentView.swift`: setup/live-game routing and theme environment
- `flip7calculator/ViewModels/GameViewModel.swift`: state mutation, persistence, undo/redo, deck enforcement, mode switching
- `flip7calculator/Models/`: persisted game, round, hand, roster, and deck types
- `flip7calculator/Scoring/ScoreEngine.swift`: pure scoring rules
- `flip7calculator/Stats/GameStats.swift`: history-derived statistics and chart inputs
- `flip7calculator/Utilities/AppBrand.swift`: reusable product identity and public copy
- `flip7calculator/Utilities/DesignTokens.swift` and `DesignStyles.swift`: semantic visual system
- `flip7calculator/Utilities/AppStoreCaptureFixture.swift`: deterministic Debug-only screenshot states

See `docs/ARCHITECTURE.md` for data flow, persistence keys, compatibility requirements, and change-impact recipes.

## Automation And Xcode

GitHub Actions runs unit tests for pull requests and adds UI tests plus a Release simulator build on `main`, using the current `macos-26` hosted runner. Failed jobs retain `.xcresult` diagnostics.

The Make/xcodebuild path is the default because it is deterministic and CI-compatible. Apple’s native external-agent bridge requires Xcode 26.3 or newer; `make doctor` reports whether `mcpbridge` is available on the current machine. Follow the version-gated setup in `.agents/skills/table-tally-ios/references/engineering.md` rather than replacing the repeatable Make workflow.

## Release State

Do not infer the live App Store state from this README. Query App Store Connect before every release operation, then record the result in `APP_STORE_LISTING.md`, the versioned asset directory, and `AppStoreAssets/release-state.json` after an upload. A binary upload, build attachment, App Review submission, and public release are separate operations.

Use `docs/RELEASE_RUNBOOK.md` for the complete sequence. Release commands intentionally refuse a dirty worktree by default so an uploaded binary can be reproduced from source.
