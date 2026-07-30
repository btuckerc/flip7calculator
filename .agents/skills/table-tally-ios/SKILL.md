---
name: table-tally-ios
description: Use for feature, bug, UI, rules, persistence, testing, Xcode, CI, screenshot, or release work in the Flipping Seven Calculator SwiftUI repository. Routes tasks to the smallest safe implementation and verification workflow while preserving rebrand, offline, accessibility, and App Store constraints.
---

# Flipping Seven Calculator iOS

Use this skill for non-trivial work in this repository. It is a router: load only the references required by the task instead of filling context with every historical document.

## Start

1. Run `git status --short`; preserve existing changes.
2. Read `README.md` and root `AGENTS.md`.
3. Run `make doctor` for build, simulator, test, signing, Xcode, or release tasks.
4. Classify the task below and load the listed references.
5. Reproduce or trace current behavior before editing.

## Route The Task

- Product behavior, feature shape, or prioritization: `references/product.md` and `docs/AGENT_PLAYBOOK.md`
- SwiftUI, layout, animation, accessibility, or visual review: `references/experience-rubric.md` and relevant `docs/ui-overhaul/` specifications
- Models, state, scoring, stats, persistence, undo/redo, or architecture: `docs/ARCHITECTURE.md`
- Classic or Vengeance rules/deck behavior: `docs/vengeance-support.md` and its primary sources
- Build, simulator, tests, Xcode, CI, or performance: `references/engineering.md`
- Signing, TestFlight, upload, screenshots, metadata, App Review, or release: `docs/RELEASE_RUNBOOK.md`; also load the global `app-store-connect-ops` skill when available
- Branding, icon, help/rules wording, screenshots, search discovery, or public metadata: `docs/APP264401-I-path-forward.md` plus the relevant strategy/listing record
- External tool or workflow research: `references/research.md`

## Execute

1. Identify invariants and all affected layers.
2. Research unstable or uncertain facts from primary sources; record rule/release sources in durable docs.
3. Implement at the correct boundary: models for shape, `ScoreEngine` for arithmetic, `GameViewModel` for undoable mutation/persistence, views for presentation, design tokens for shared styling.
4. Run one relevant test or suite while iterating.
5. Escalate to `make test-unit`, relevant UI coverage, `make test`, or `make verify` according to `docs/AGENT_PLAYBOOK.md`.
6. Inspect real rendered UI for visual changes and report unperformed device/accessibility checks honestly.

## Product Guardrails

- Keep common live-score actions obvious and low-friction.
- Keep the app offline-first unless the user explicitly changes the product direction.
- Preserve Codable compatibility for existing games and settings.
- Keep score math pure, mutations undoable, and completed history semantically stable.
- Keep public copy centralized in `AppBrand` where reuse makes sense.
- Extend semantic design tokens rather than adding isolated styles.
- Do not restore the exact disputed mark or third-party logos, box art, card backs, or trade dress.

## Xcode And Release Boundaries

- Prefer Make/xcodebuild for deterministic local and CI work.
- Use Xcode UI for previews, visual inspection, debugger/Organizer data, signing-account diagnostics, and physical-device work.
- Apple's external-agent MCP bridge is optional and requires Xcode 26.3+. Check `xcrun --find mcpbridge` before suggesting or configuring it.
- On the maintainer Mac, verify App Store Connect access with `make asc-auth`; release scripts load the local Keychain credentials automatically without exposing values.
- Archive, export, validate, upload, attach, submit, and release are separate consequential operations. Never collapse them into “deploy.”
- Never commit Apple credentials or release artifacts.
