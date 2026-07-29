---
name: table-tally-ios
description: Use when working in this repository to build, review, or refine the Table Tally SwiftUI app. Covers product intent, rebrand constraints, UX quality bar, local simulator workflow, architecture anchors, and external iOS agent-skill research.
---

# Table Tally iOS

Use this skill for any non-trivial work in this repository.

## Quick Start

1. Read `README.md` and `AGENTS.md`.
2. Use `make help` instead of reaching for raw `xcodebuild`.
3. Load only the reference file that matches the task:
   - `references/product.md` for product intent, rebrand constraints, and non-goals
   - `references/experience-rubric.md` for UI, accessibility, and performance expectations
   - `references/engineering.md` for build/test workflow, simulator handling, and file map
   - `references/research.md` for external sources, optional global skill installs, and why this repo is set up this way
4. Before changing branding, screenshots, rules/help content, App Store copy, or other visible product surfaces, also read `docs/APP264401-I-path-forward.md`.

## Working Principles

- Prefer small, validated changes. This repo already has active rebrand and design-token work in flight.
- Keep visible product copy generic and centralized in `flip7calculator/Utilities/AppBrand.swift` where reuse makes sense.
- Preserve the app's strongest behavior: fast shared scorekeeping during live play.
- When touching SwiftUI surfaces, optimize for correct state flow, stable identity, accessibility, and reduced-motion parity.
- When touching tests or palette work, account for the current known palette failures rather than assuming a clean baseline.

## Architecture Anchors

- App entry: `flip7calculator/flip7calculatorApp.swift`
- Game orchestration and persistence: `flip7calculator/ViewModels/GameViewModel.swift`
- Scoring: `flip7calculator/Scoring/ScoreEngine.swift`
- Stats: `flip7calculator/Stats/GameStats.swift`
- Rebrand constants: `flip7calculator/Utilities/AppBrand.swift`
- Tokenized styling: `flip7calculator/Utilities/DesignTokens.swift`, `flip7calculator/Utilities/DesignStyles.swift`

## Local Workflow

- `make build`
- `make test`
- `make test-one TEST=flip7calculatorTests/PlayerPaletteTests`
- `make ui-test`
- `make launch`

The Makefile resolves a usable simulator automatically, disables code signing for simulator test runs, and uses `xcbeautify` when available.
