# Engineering Workflow

## Default Tool Path

Use the Makefile instead of raw `xcodebuild`. The wrapper resolves an installed simulator, disables simulator signing, keeps DerivedData outside the repo, retains `.xcresult` diagnostics, disables parallel test workers by default for determinism, and uses `xcbeautify` when installed.

Start with:

```bash
make doctor
make help
```

## Feedback Ladder

| Intent | Command |
|---|---|
| Discover test suites | `make list-tests` |
| One suite or method | `make test-one TEST=flip7calculatorTests/ScoreEngineTests` |
| All unit tests | `make test-unit` |
| Suspected flaky suite | `make test-repeat TEST=flip7calculatorTests/ScoreEngineTests ITERATIONS=20` |
| UI tests only | `make ui-test` |
| Full unit + UI plan | `make test` |
| Release simulator confidence | `make verify` |
| Read failed result without rerunning | `make test-summary RESULT=/path/to/result.xcresult` |
| Open diagnostics in Xcode | `make open-results RESULT=/path/to/result.xcresult` |
| Incremental build timing | `make build-timed` |

Apple recommends a similar progression: one relevant test while developing, the affected target before integration, and a complete plan at the broader delivery gate. Do not use full UI coverage as the inner loop for pure arithmetic.

Use `make list-tests` to discover suite names, then prefer `Target/Suite` filters. On the installed Xcode 26.0, displayed Swift Testing method names include `()` but those names are not reliable `-only-testing` inputs; suite filters are stable. XCTest method filters may still be used after verification. The wrapper inspects the resulting `.xcresult` and fails if a filter matched zero tests, because `xcodebuild` itself can return success in that situation.

Optional overrides:

```bash
make test-unit SIMULATOR_NAME="iPhone SE (3rd generation)"
make ui-test SIMULATOR_NAME="iPad mini (A17 Pro)" SIMULATOR_OS=18.5
make test-unit SIMULATOR_NAME=auto
make test PARALLEL_TESTING=YES
```

Parallel workers can be faster for a large stable suite but add simulator clones and can expose shared-state assumptions. Keep the default `NO` unless measuring proves a benefit.

## Result Bundles

Results live under `~/Library/Caches/FlippingSevenCalculator/Results/`. Each new invocation removes only the bundle for that command. Preserve a failing bundle until the failure has been understood.

Use `xcresulttool` through `make test-summary` for counts and failure text. Open the bundle in Xcode when screenshots, attachments, activity logs, or per-test timing matter.

## Simulator And UI Work

- `make destinations`: list available runtimes/devices.
- `make boot-sim`: boot and wait for the configured simulator.
- `make launch`: build, install, and launch with the same resolved UDID.
- `make xcode`: open the project for previews/debugging.
- Use accessibility identifiers and semantic waits in UI tests; fixed sleeps are a last resort.
- Validate density-sensitive changes on a compact-height iPhone and an iPad. Test all supported roster sizes when rows/columns/scrolling change.
- The simulator is not a substitute for the physical-device release gate, icon appearance, haptics, VoiceOver operation, or real performance.

## Xcode Connection Options

### Recommended Today: Headless Commands

Make/xcodebuild is the reliable agent interface because it works unattended, matches CI, and creates shareable logs/results. Use Xcode or Computer Use only where GUI state adds information.

### Native Xcode MCP: Xcode 26.3+

Apple added external-agent access in Xcode 26.3. Before setup:

1. Confirm `xcodebuild -version` is 26.3 or newer.
2. Confirm `xcrun --find mcpbridge` succeeds.
3. In Xcode Intelligence settings, enable **Allow external agents to use Xcode tools**.
4. Open this project in Xcode before prompting the external agent.
5. Add the server with `codex mcp add xcode -- xcrun mcpbridge`, or add the equivalent `mcp_servers.xcode` entry through the user's managed Codex configuration.
6. Verify with `codex mcp list`.

This user's Codex configuration is managed through chezmoi, so use the shared `codex-config` workflow rather than hand-editing `~/.codex/config.toml`. Do not check a project MCP entry into this repo while supported machines still lack `mcpbridge`; a missing server would slow or degrade every session.

Use Xcode MCP for open-project context, previews, issue/debugger state, and Xcode-specific tools. Keep Make commands as the verification source of truth so results remain reproducible without an open GUI.

## CI

`.github/workflows/ios-ci.yml` uses GitHub's GA `macos-26` hosted runner:

- Pull requests run setup checks and the unit target.
- Pushes to `main` and manual runs add UI tests and a Release simulator build.
- Failed jobs upload `.xcresult` bundles for seven days.
- CI intentionally does not receive signing or App Store credentials.

Do not cache DerivedData by default. This project has no package-resolution bottleneck, while stale Xcode intermediates can be larger and less reliable than a clean hosted build.

## Build Diagnostics

- Start with `make doctor`, not broad signing changes.
- If raw `xcodebuild` is unavoidable for simulator work, preserve `CODE_SIGNING_ALLOWED=NO` and `CODE_SIGNING_REQUIRED=NO`.
- Use `make build-timed` before optimizing compile time; optimize measured work rather than file size alone.
- Use `make clean` only when stale build products are plausible. It removes this repo's external cache and results, so preserve needed `.xcresult` bundles first.
- For customer crashes, use Apple's complete symbolicated report and the matching distributed archive/dSYM.

## High-Value Tests

- `ScoreEngineTests`: Classic arithmetic and hand behavior
- `VengeanceModeTests`: deck composition, Vengeance arithmetic, compatibility, mode switching, persistence, undo/redo, history
- `GameViewModelUndoTests`: mutation snapshot behavior
- `GameStatsTests`: completed-round derivation and charts
- `PlayerPaletteTests`: reserved-color and contrast invariants
- UI tests: app launch, setup mode copy/layout, live mode switching, and 4–8 player Vengeance layouts

## Release Operations

Use `docs/RELEASE_RUNBOOK.md`. The Make targets are deliberately staged:

```bash
make release-preflight
make archive
make export
make validate-upload
make upload
```

An upload does not attach a build or submit it for review.
