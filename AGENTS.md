# Flipping Seven Calculator Repo Instructions

This repository contains `Flipping Seven Calculator`, an offline SwiftUI scorekeeping app for iPhone and iPad. Internal target and module names still use `flip7calculator` to preserve the existing App Store record and avoid unnecessary build churn.

Before substantial work:

1. Read `README.md`.
2. Load `.agents/skills/table-tally-ios/SKILL.md` if your tool supports project skills.
3. Read `docs/APP264401-I-path-forward.md` before touching branding, help content, App Store metadata, screenshots, or other visible product copy.

## Working Rules

- Prefer `make build`, `make test`, `make test-one TEST=...`, and `make ui-test` over raw `xcodebuild`. The local workflow disables simulator signing by default and pipes output through `xcbeautify` when available.
- Route reusable product strings through `flip7calculator/Utilities/AppBrand.swift`.
- Do not reintroduce the exact `FLIP 7` mark, third-party logos, box-art styling, card-back designs, or publisher artwork on public product surfaces.
- Generic card flipping, seven numbered cards, scorekeeping controls, dice, and the approved blue/cream/gold palette are intentional product motifs.
- Preserve the app's strongest trait: fast, low-friction score entry during live play. Extra taps, hidden state, or slow round flow need strong justification.
- Validate touched UI for iPhone and iPad layout, Dynamic Type, VoiceOver labels, contrast, and reduced-motion parity.
- Extend the in-progress design-token migration (`DesignTokens.swift`, `DesignStyles.swift`) instead of adding more one-off styling.
- Treat existing dirty-worktree changes as intentional unless the user asks you to revert them.

## Current Baseline

- The user-facing app name is `Flipping Seven Calculator`.
- The app is offline-first and stores its state locally.
- `make test` passes on the simulator with the current rebrand branch.
- The preferred local build cache lives under `~/Library/Caches/FlippingSevenCalculator/` instead of repo-local `.build/DerivedData`, because Release builds were unstable when DerivedData lived under `Documents/...`.
