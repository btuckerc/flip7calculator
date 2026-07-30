# Flipping Seven Calculator Repo Instructions

This repository contains `Flipping Seven Calculator`, an offline SwiftUI scorekeeper for iPhone and iPad. Public product names and internal identifiers intentionally differ: the Xcode project, target, module, bundle ID, and App Store record still use `flip7calculator`.

## Start Here

Before substantial work:

1. Run `git status --short` and preserve every pre-existing change.
2. Read `README.md`.
3. Load `.agents/skills/table-tally-ios/SKILL.md` if project skills are available.
4. Use `docs/AGENT_PLAYBOOK.md` to classify the task and load only its required references.
5. Run `make doctor` before diagnosing build, simulator, signing, or release failures.

Read `docs/APP264401-I-path-forward.md` before changing branding, screenshots, help/rules copy, App Store metadata, icons, or other public product surfaces.

## Non-Negotiables

- Treat dirty-worktree changes as intentional unless the user explicitly asks to discard them. Never reset, checkout, or overwrite unrelated work.
- Preserve fast, low-friction live score entry. Extra taps, hidden state, and slower round flow require a clear product benefit.
- Keep the app offline-first. Do not introduce accounts, analytics, network dependencies, or cloud persistence by assumption.
- Route reusable public copy through `flip7calculator/Utilities/AppBrand.swift` where practical.
- Extend `DesignTokens.swift` and `DesignStyles.swift`; do not add avoidable one-off colors, typography, spacing, shadows, or card treatments.
- Preserve backward-compatible decoding when adding or renaming persisted fields. Existing games, rosters, settings, and deck profiles are user data.
- Do not reintroduce the exact disputed `FLIP 7` mark, publisher logos, box art, card backs, or trade dress on public surfaces.
- Never commit `.p8` keys, key IDs, issuer IDs, JWTs, certificates, provisioning profiles, or exported archives.

## Choose The Smallest Correct Loop

- Pure logic or model work: `make test-one TEST=Target/Suite[/test]`, then `make test-unit`.
- SwiftUI/component work: targeted unit test, `make launch`, and the relevant UI test. Check compact iPhone and iPad when layout can change.
- Persistence or rules changes: unit tests for new behavior plus legacy decoding and undo/redo coverage.
- Broad integration changes: `make test`.
- Release candidate: `make verify`, physical-device/accessibility checks, then `make release-preflight`.
- Flaky test diagnosis: run `make list-tests`, then repeat the narrowest verified suite with `make test-repeat TEST=Target/Suite ITERATIONS=20`.

Prefer Make targets over raw `xcodebuild`. They resolve a simulator, disable simulator signing, store build products outside the repo, preserve result bundles, and use `xcbeautify` when available.

## Task Routing

- Product intent or UX: `docs/AGENT_PLAYBOOK.md` and `references/product.md` / `references/experience-rubric.md` in the repo skill.
- Architecture, state, persistence, or change impact: `docs/ARCHITECTURE.md`.
- Classic/Vengeance rules: `docs/vengeance-support.md` plus primary rule sources before changing behavior.
- Build, tests, simulator, CI, or Xcode: `references/engineering.md` in the repo skill.
- App Store, TestFlight, signing, screenshots, or submission: `docs/RELEASE_RUNBOOK.md` and the `app-store-connect-ops` skill when available.
- On the maintainer Mac, run `make asc-auth` before App Store Connect work. Release scripts load credentials from Keychain; never request that values be pasted into a task or commit them.
- Branding, discovery, or legal correspondence: the `APP264401-I` documents. Any correspondence subject must include `APP264401-I` and copy the required parties.

## Completion Standard

- Reproduce or understand the existing behavior before editing.
- Test at the narrowest level during iteration, then escalate according to risk.
- For touched UI, assess iPhone/iPad layout, Dynamic Type, VoiceOver semantics, contrast, light/dark appearance, and reduced-motion parity.
- Update tests and durable docs when behavior, persistence, rules, release workflow, or product decisions change.
- Report what changed, exact verification performed, and any unverified physical-device or App Store state. Never imply an upload or submission occurred unless it was confirmed by App Store Connect.
