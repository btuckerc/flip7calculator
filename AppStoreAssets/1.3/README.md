# App Store Assets - Version 1.3

These screenshots were captured from the version 1.3 (build 9) debug build using deterministic, real app state. The fictional roster is Peter, Ned, Mary, and Gwen.

## Upload Order

### iPhone 6.9-inch

1. `01-setup.png`
2. `02-live-entry.png`
3. `03-player-states.png`
4. `04-game-over.png`
5. `05-stats-highlights.png`
6. `06-stats-charts.png`
7. `07-round-history.png`

All iPhone images are 1320 x 2868 PNG files.

### iPad 13-inch

1. `01-setup.png`
2. `02-live-entry.png`
3. `03-player-states.png`
4. `04-game-over.png`
5. `05-stats.png`

All iPad images are 2064 x 2752 PNG files.

## Capture Harness

Debug builds accept `-appStoreCapture` with one of these values:

- `setup`
- `live`
- `game-over`
- `stats`

The capture harness is excluded from Release builds. It creates real `Game`, `GameRound`, and `RoundResult` values so the score engine, player states, history, and charts render through production views.

## App Preview

The proof-of-concept App Preview is intentionally not included in version 1.3. A later recording should show continuous, realistic play with minimal idle time before it is added to the listing.
