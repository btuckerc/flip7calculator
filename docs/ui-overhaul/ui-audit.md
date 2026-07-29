# UI Audit (Before State)

## Product surfaces in scope
- Launch/loading: `OpeningSplashView`
- Setup: `GameSetupView`
- Active round: `GameView`, `SelectedPlayerPanel`, `PlayerGrid`, chips and action controls
- End of game: `GameOverOverlay`, `GameOverStatsView`
- Rules/tutorial: `RulesView` (+ subpages)
- Settings/options: `SettingsView`
- Management: `PlayerManagementView`, `DeckManagementView`

## Reusable UI components
- Inputs/editors: `PlayersEditorCard`, `FocusableTextField`, `TargetScoreEditorSheet`, `ManualScoreEditorSheet`
- Game controls: `NumberChipGrid`, `ModifierGrid`, `QuickCardPicker`, `OptionChips`
- Overlays/banners: `ConfirmationOverlay`, `InlineBustBanner`, `GameOverOverlay`
- Charts: `ScoreCharts` (`CumulativeScoreChart`, `RoundScoreBarChart`, `ScoreSparkline`)
- Branding: `AppTitleView`, `BrandMarkView`

## Existing style architecture
- App theme: `AppTheme` enum in `SettingsView`
- Player color palettes: `PlayerPalette` + `ReservedColors`
- Fragmented accent usage with hardcoded `.blue` in several views/components
- Fonts currently bundled: `Nunito-Black`, `Nunito-Bold`

## Existing visual assets
- `Assets.xcassets/AppIcon.appiconset`: standard, dark, tinted 1024 icon variants
- No centralized token file before overhaul
- No semantic button/surface style layer before overhaul

## Risk inventory for overhaul
- Visual consistency drift from screen-level hardcoded colors
- Motion consistency drift due ad hoc animation curves/durations
- iPhone/iPad layout parity must be preserved across all redesigned screens
- Accessibility must keep reduced-motion parity, especially around launch/loading
