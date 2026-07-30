# Agent Playbook

This guide turns a feature request, bug report, design note, or release request into the smallest safe workflow for Flipping Seven Calculator. It is written for both collaborators and coding agents.

## Request Shape

A useful request can be short. Include whatever is known:

- **Goal:** what should be easier, clearer, or newly possible
- **Observed:** what happens now, including screenshots or reproduction steps
- **Desired:** what success looks like
- **Constraints:** wording, visual direction, compatibility, timing, or legal boundaries
- **Release intent:** local prototype, merge-ready change, TestFlight, or App Store

Missing detail is not an excuse to stop. Agents should inspect the app and code, make reversible assumptions when consequences are small, and ask only when options have materially different product or release outcomes.

## Classify Before Editing

| Task | Read first | First verification | Completion gate |
|---|---|---|---|
| Scoring or card rule | `ARCHITECTURE.md`, `vengeance-support.md` | Relevant `ScoreEngineTests` or `VengeanceModeTests` | Legacy decoding, undo/redo, stats/history, full unit target |
| Persistence or model | `ARCHITECTURE.md` | New isolated-decoding test | Old payload decoding, active-game resume, undo/redo |
| Gameplay flow | Product and experience skill references | Closest view-model test | Targeted UI flow, unit target, compact layout |
| Visual polish | Experience rubric and design-system docs | `make launch` | iPhone/iPad, light/dark, Dynamic Type, VoiceOver, reduced motion |
| Animation | Motion spec and experience rubric | Reduced-motion path | No state jump, no clipping, stable frame pacing, UI smoke test |
| Icon or screenshots | Legal path-forward and release runbook | Source asset inspection | All variants/sizes, small-scale legibility, listing accuracy |
| App Store or TestFlight | `RELEASE_RUNBOOK.md` | Query live ASC state | Explicitly approved archive/upload/submit boundary |
| Build or CI failure | Engineering skill reference | `make doctor` | Root cause fixed, narrow rerun, relevant CI-equivalent command |
| Branding or discovery | All `APP264401-I` strategy docs | Search public strings and metadata | App, icon, screenshots, metadata, help, privacy, correspondence audit |

## Standard Workflow

1. **Preserve state.** Run `git status --short`, inspect relevant diffs, and distinguish prior work from the requested change.
2. **Reproduce or trace.** Observe the UI when relevant. For logic, trace the model-to-view-model-to-view path and identify persistence or history consequences.
3. **Define invariants.** State what must not regress: score math, existing saves, current-round cards, undo/redo, tap count, layout, or public wording.
4. **Research uncertain facts.** Prefer primary rules, Apple documentation, official tool documentation, and the implementation itself. Record sources for rule or release decisions.
5. **Implement narrowly.** Keep pure rules in `ScoreEngine`, mutations in `GameViewModel`, persisted shape in models, and styling in tokens/components.
6. **Run the smallest feedback loop.** One test or suite first, then the affected target. Do not run UI tests repeatedly for pure logic work.
7. **Inspect real UI when visual behavior changed.** Build and launch the app instead of treating compilation as visual validation.
8. **Escalate verification by risk.** Use the matrix below; do not claim checks that were not performed.
9. **Update durable context.** Change architecture, rule, release, capture, or legal docs when the decision will matter to the next agent.
10. **Close clearly.** Summarize outcome, tests, unverified risks, and whether anything was uploaded or submitted.

## Verification Matrix

| Change risk | During iteration | Before handoff |
|---|---|---|
| Documentation only | Link/path and command review | Markdown/reference audit |
| Pure scoring/stat helper | One suite/test | `make test-unit` |
| Model or persistence | New + legacy decode tests | `make test-unit` |
| View-model mutation | Focused suite | Unit target plus relevant UI flow |
| Isolated SwiftUI polish | Build/launch and focused UI check | Compact iPhone + iPad where layout changes |
| Shared component/theme | Build/launch | Relevant UI target, light/dark, accessibility checks |
| App entry, navigation, or game lifecycle | Focused unit/UI tests | `make test` |
| Release candidate | Targeted checks while iterating | `make verify`, physical device, release preflight |

Use `make test-summary RESULT=...` before rerunning a failed test. Use `make list-tests` to discover suites, then prefer `Target/Suite` filters; Xcode 26.0's displayed Swift Testing method names are not reliable `-only-testing` inputs. Use `make test-repeat` only to investigate suspected nondeterminism. The wrappers fail when a filter matches zero tests instead of accepting Xcode's false-green exit status.

## Feature Change Checklist

- Identify the user-visible outcome and whether it adds taps during live scoring.
- Map every affected layer using `ARCHITECTURE.md`.
- Decide whether the feature changes persisted data or only presentation.
- Add compatibility defaults before relying on a new Codable field.
- Keep scoring arithmetic pure and testable.
- Ensure mutations participate in undo/redo before assigning the new game value.
- Verify history and stats if completed-round meaning changes.
- Update help text and accessibility labels when controls or terminology change.
- Add deterministic capture state only when App Store media must show the feature.

## Bug Fix Checklist

- Preserve the evidence: screenshot, video, exact state, device, orientation, appearance, and content size when available.
- Find the earliest layer where actual state diverges from expected state.
- Add a regression test at that layer when behavior is deterministic.
- Avoid masking state defects with animation delays or view-only conditionals.
- For transient UI defects, check identity, insertion/removal transitions, swipe state, focus, and asynchronous callbacks.
- For customer crashes, use a complete symbolicated Apple crash report and retain the matching archive.

## UI Review Checklist

- Common actions remain visible and tap-efficient.
- Score, player state, selected player, and round progress are glanceable.
- No control or text clips on compact height or with larger content sizes.
- iPad uses space intentionally instead of merely stretching the phone view.
- VoiceOver labels explain gameplay meaning and control state.
- Reduce Motion removes or substitutes spatial motion without hiding feedback.
- Colors, spacing, type, radii, and shadows come from semantic tokens where possible.
- Animations have stable identity and do not reveal intermediate delete/swipe/edit states.
- Screenshots are inspected, not inferred from source coordinates.

## Release Boundary

Agents may build, test, archive, export, validate, upload, attach, submit, and release only as distinct steps. The user's request must clearly include the consequential step being taken.

- `make release-preflight` does not contact App Review or upload a binary.
- `make upload` uploads an IPA but does not attach it to a version or submit it.
- Removing an in-review submission can reset review progress; query current state and explain that consequence first.
- Metadata and screenshots can have status-dependent edit restrictions.
- Every Apple Legal email for this matter must include `APP264401-I` in the subject and copy the required parties.

## Keep Context Current

Update the relevant durable source instead of adding a contradictory note elsewhere:

- Product identity and legal guardrails: `docs/APP264401-I-path-forward.md`
- Architecture and persistence: `docs/ARCHITECTURE.md`
- Vengeance rules and implementation: `docs/vengeance-support.md`
- Release mechanics and status querying: `docs/RELEASE_RUNBOOK.md`
- Submitted listing values and historical status: `APP_STORE_LISTING.md`
- Screenshot capture/order: `AppStoreAssets/<version>/README.md`
- Agent workflow: this playbook and the repo skill

Time-sensitive status belongs in a dated release record, not in root instructions.
