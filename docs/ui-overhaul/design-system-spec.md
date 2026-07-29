# Design System Spec (v2 Readiness)

## Direction
- Theme direction: **Playful Table**
- Goal: bold game-night energy with high legibility and tactile controls.

## Theme bridge
- Persisted key: `visualThemeVersion`
- Supported values:
  - `legacy`: current visual system
  - `v2`: new tokenized system
- Runtime enum: `VisualTheme` in `DesignTokens.swift`

## Token interfaces
- `DesignColor.Role`
  - `surfacePrimary`, `surfaceSecondary`
  - `textPrimary`, `textSecondary`
  - `brandPrimary`, `brandSecondary`
  - `stateSuccess`, `stateWarning`, `stateDanger`
  - `playerHighlight`
- `DesignTypography.Style`
  - `display`, `title`, `body`, `label`, `mono`
- `DesignSpacing`
  - `xxs`, `xs`, `sm`, `md`, `lg`, `xl`
- `DesignRadius`
  - `sm`, `md`, `lg`, `pill`
- `DesignMotion.Preset`
  - `fast`, `normal`, `emphasis`

## Semantic styles
- Buttons:
  - `PrimaryButtonStyle`
  - `SecondaryButtonStyle`
  - `GhostButtonStyle`
- Surfaces:
  - `CardSurfaceStyle`
- Badges:
  - `PillBadgeStyle` with tones `neutral`, `info`, `success`, `warning`, `danger`

## Migration rules
- New/updated UI should consume semantic styles and token roles.
- Raw accent constants (for example `.blue`) should be replaced in touched screens.
- Gameplay/scoring models must remain unchanged.
- Use `legacy` as default for safe rollout; opt into `v2` through settings.

## Core implementation mapping (current pass)
- App-level theme injection: `ContentView`
- Theme selection control: `SettingsView`
- Initial token adoption:
  - `GameSetupView`
  - `GameView`
- Foundation files:
  - `flip7calculator/Utilities/DesignTokens.swift`
  - `flip7calculator/Utilities/DesignStyles.swift`
