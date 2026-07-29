# Product Context

## What Flipping Seven Calculator Is

Flipping Seven Calculator is an offline-first SwiftUI scorekeeper for card-night and push-your-luck style games. It is optimized for fast shared use at a real table, not for long-form data management, social features, or cloud sync.

Current strengths:

- Fast round entry
- Clear score math and history
- Undo/redo support
- Deck-profile customization
- End-of-game stats
- iPhone and iPad support

## What Matters Most

Future changes should strengthen these outcomes:

- A player can glance at the screen and immediately understand whose turn it is, what their round state is, and how close everyone is to the target score.
- Common actions stay tap-efficient during live play.
- The app feels trustworthy: score math is clear, mistakes are reversible, and state changes are obvious.
- The experience stays lightweight and offline. Do not assume a backend, account system, analytics pipeline, or remote sync.

## Rebrand Constraint

This repo uses the public name `Flipping Seven Calculator` while intentionally avoiding the exact disputed mark and third-party visual assets.

Implications:

- Avoid introducing the exact `Flip 7` or `Flip7` mark on public product surfaces.
- Prefer reusable generic wording such as `7-card bonus`, `score profile`, `scoring guide`, and `table game`.
- Use `AppBrand` for repeated app name, tagline, and shared labels.
- Keep all card, wordmark, motion, and icon artwork original; generic card-flip mechanics do not justify copying product trade dress.
- Treat `docs/APP264401-I-path-forward.md` as the authoritative repo note before changing visible branding, screenshots, App Store text, or tutorial/help surfaces.

## Non-Goals

Usually avoid:

- Feature creep that slows down score entry
- Generic dashboard UI that obscures gameplay state
- Mandatory onboarding or account creation
- Network-coupled features
- Theme or animation work that ignores Reduce Motion, contrast, or iPad parity

## Internal Naming Reality

The user-facing brand is `Flipping Seven Calculator`, but internal project identifiers still use `flip7calculator`. That is expected for now. Visible product surfaces matter more than internal module names.

## Architecture Map

- `flip7calculator/Views/`
  - App surfaces: setup, live game, help, settings, stats, deck management
- `flip7calculator/ViewModels/GameViewModel.swift`
  - game lifecycle, persistence, undo/redo, deck constraints
- `flip7calculator/Models/`
  - game, round, player, and persisted configuration types
- `flip7calculator/Scoring/ScoreEngine.swift`
  - pure score calculation
- `flip7calculator/Stats/GameStats.swift`
  - aggregate and per-player stats
- `flip7calculator/Utilities/AppBrand.swift`
  - centralized product naming and shared labels
- `flip7calculator/Utilities/DesignTokens.swift`
- `flip7calculator/Utilities/DesignStyles.swift`
  - tokenized styling foundation for ongoing UI cleanup
