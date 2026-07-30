# App Store Assets - Version 1.3

These screenshots were captured from the version 1.3 (build 9) debug build using deterministic, real app state. The fictional roster is Peter, Ned, Mary, and Gwen. Build 10 changed the home-screen icon, and build 11 adds optional game modes while retaining the represented Classic surfaces. The submitted screenshots remain accurate Classic gameplay examples.

## Upload Order

### iPhone 6.9-inch

1. `01-setup.png`
2. `02-live-entry.png`
3. `05-stats-highlights.png`
4. `04-game-over.png`
5. `06-stats-charts.png`

All iPhone images are 1320 x 2868 PNG files.

### iPad 13-inch

1. `01-setup.png`
2. `02-live-entry.png`
3. `05-stats.png`
4. `04-game-over.png`

All iPad images are 2064 x 2752 PNG files.

The `03-player-states.png` source files are retained as capture records but are not submitted. The live-entry images already show banked, active, frozen, and busted states with substantially better use of the frame. The iPhone `07-round-history.png` source is also retained but excluded because scrolled content visibly bleeds into its translucent status area.

## Capture Harness

Debug builds accept `-appStoreCapture` with one of these values:

- `setup`
- `live`
- `game-over`
- `stats`

The capture harness is excluded from Release builds. It creates real `Game`, `GameRound`, and `RoundResult` values so the score engine, player states, history, and charts render through production views.

## App Preview

The proof-of-concept App Preview is intentionally not included in version 1.3. A later recording should show continuous, realistic play with minimal idle time before it is added to the listing. An App Preview can improve acquisition presentation, but it cannot force an installed app's compact search result to display media.
