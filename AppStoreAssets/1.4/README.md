# App Store Assets - Version 1.4

These marketing screenshots were composed on macOS (using SF Pro Rounded + Nunito Black) from live captures of the version 1.4 (build 12) debug fixtures with `-releaseMarketingPreview` on real iPhone 6.9-inch and iPad 13-inch simulators via `scripts/capture-appstore-raw.sh` and `scripts/render-appstore-screenshots.py`. The fictional roster is Peter, Ned, Mary, and Gwen.

## Upload Order

### iPhone 6.9-inch (`1320 x 2868`)

1. `01-live-scoring.png` — Live scoring board with active keycaps and round previews
2. `02-states-and-bonus.png` — Banked, frozen, busted states and 7-card bonus clarity
3. `03-stats-charts.png` — Post-game highlights and monotone score progression chart
4. `04-quick-setup.png` — Fast Release-parity roster setup with face-up 7-card mark
5. `05-game-over.png` — Centered game-over standings and one-tap rematch

### iPad 13-inch (`2064 x 2752`)

1. `01-live-split.png` — Full-table iPad score board and keypad layout
2. `02-states-and-bonus.png` — Clear player states and 7-card bonus on iPad
3. `03-stats-charts.png` — Post-game highlights, charts, and player stats
4. `04-game-over.png` — Centered game-over standings and rematch

## Notes

- Simulator mode remains gated behind `#if DEBUG` (`DealerAvailability.isPreviewEnabled`) and is excluded from App Store screenshots via `-releaseMarketingPreview` so every depicted feature is reachable in Release.
- All headlines, sublines, and marketing copy avoid third-party marks, publisher names, and sequel titles per `docs/APP264401-I-path-forward.md`.
