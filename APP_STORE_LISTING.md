# App Store Listing — Flipping Seven Calculator

Use this document as the human-readable source of truth for the `1.4 (12)` App Store Connect update. The matching machine-readable metadata is in [AppStoreAssets/1.4/metadata-en-US.json](AppStoreAssets/1.4/metadata-en-US.json).

For the decision record and trademark/App Review guardrails, also read:

- [APP264401-I path forward](docs/APP264401-I-path-forward.md)
- [APP264401-I discovery and listing strategy](docs/APP264401-I-discovery-and-listing-strategy.md)

## App Information

| Field | Submission value |
|---|---|
| App name (25/30) | `Flipping Seven Calculator` |
| Subtitle (29/30) | `Offline Card Game Scorekeeper` |
| Bundle ID | `com.tcraig.flip7calculator.ios` |
| SKU | `flip7calculator` |
| Version | `1.4` |
| Build | `12` |
| Primary category | `Utilities` |
| Secondary category | `Games` → `Card` |
| Age rating | `4+`, with the App Store Connect questionnaire verified for this release |
| Copyright | `2026 Tucker Craig` |

Keep the existing bundle ID and app record. Internal target/module names are intentionally unchanged.

## Promotional Text

135/170 characters:

> Tap cards, track 7-card bonuses, and tally rounds fast on iPhone and iPad. Works completely offline with no ads, accounts, or tracking.

## Keywords

97/100 characters:

```text
scoreboard,tally,tracker,points,luck,bust,party,tabletop,night,stats,undo,counter,score,pad,sheet
```

Do not repeat words already present in the app name, subtitle, or category. Do not add the exact disputed mark, publisher name, competing app names, or spelling variations intended to reproduce them.

## Description

Flipping Seven Calculator is a simple, fast, offline scorekeeper for push-your-luck card games on iPhone and iPad.

Keep the table moving without doing mental math:

- Tap number cards and modifiers as hands are played
- See who is active, banked, frozen, or busted right on the board
- Automatically apply 7-card bonuses, multipliers, special numbers, and negative modifiers
- Switch between two scoring modes with separate custom deck profiles
- Turn on optional Brutal rules for negative rounds and redirected 7-card bonuses
- Undo, redo, or enter a manual round score whenever house rules come up
- Use the full-table layout on iPad (side-by-side in landscape) or the compact board on iPhone
- Review post-game charts, highlights, player stats, and round history
- Pick up an interrupted game right where you left off

Everything stays on your device. No accounts, no ads, no subscriptions, and no internet connection required.

Independent scorekeeping utility. Not affiliated with or endorsed by any game publisher.

## What's New in 1.4

Version 1.4 focuses on speed, readability, and polish:

- Faster startup with a shorter, tap-to-skip opening animation and more responsive taps throughout
- Cleaner layout with higher-contrast number and modifier buttons, distinct Bank, Bust, and Freeze colors, and updated light and dark themes
- New iPad table layout with big player tiles in portrait and side-by-side board and keypad in landscape
- Better VoiceOver support on modifier controls and dialogs, improved Dynamic Type sizing, and full Reduce Motion support
- Updated score charts and a refreshed app icon

## URLs

| Field | URL | Status before submission |
|---|---|---|
| Privacy policy | `https://btuckerc.dev/privacy/flipping-seven-calculator` | Verified deployed production route and policy bundle on 2026-07-29 |
| Support | `https://btuckerc.dev/contact` | Verified HTTP 200 with rendered contact content on 2026-07-28 |
| Marketing | Optional | Leave blank unless a product-specific page is published |

Do not submit with a blank fallback route or the old Lucky Ledger privacy page merely because either returns HTTP 200. The rendered policy and submitted URL must agree with the new product name.

## App Review Notes

Private reviewer notes may identify the previous app title because they are operational correspondence rather than public discovery metadata.

```text
This is version 1.4 (build 12) of the existing Flipping Seven Calculator app record.

The app is an offline scorekeeping utility. Launch the app, add 2 to 8 player names, choose Classic or Vengeance scoring, and tap card values and modifiers to track rounds, 7-card bonuses, player states, busts, and totals. No login, purchase, network connection, or special hardware is required.

The exact FLIP 7 mark, publisher name, third-party logos, box artwork, card-back artwork, and rules content are not displayed in the app or public metadata. The refined two-card app icon, seven-card launch motion, and navy/cream/gold artwork in this build were created specifically for this app. An in-app statement identifies the product as an independent scorekeeping utility that is not affiliated with or endorsed by any game publisher.

Reference for the related correspondence: APP264401-I.
```

## Content Rights

- The app does not contain or access third-party content.
- All app UI, card illustrations, icon assets, screenshots, and animations are original or properly licensed.
- Generic scorekeeping mechanics, numbers, cards, and card-flip motion are used without third-party logos or product artwork.

## Screenshots

The version `1.4` screenshots are composed on macOS from deterministic real app captures (fictional names: Peter, Ned, Mary, and Gwen) using `-releaseMarketingPreview` so Debug-only preview controls are never depicted.

### iPhone 6.9-inch (`1320 x 2868`)

1. `01-live-scoring.png` — Fast round scoring
2. `02-states-and-bonus.png` — Clear player states
3. `03-stats-charts.png` — Full game stats
4. `04-quick-setup.png` — Quick game setup
5. `05-game-over.png` — Final standings

### iPad 13-inch (`2064 x 2752`)

1. `01-live-split.png` — Made for the whole table
2. `02-states-and-bonus.png` — Clear player states
3. `03-stats-charts.png` — Full game stats
4. `04-game-over.png` — Final standings

Source asset documentation lives in [AppStoreAssets/1.4/README.md](AppStoreAssets/1.4/README.md).

## App Icon

Version `1.4 (12)` updates the two-card-and-7 icon using 4× supersampled rendering in [icon/generate_icon_variants.py](icon/generate_icon_variants.py): a clean two-card silhouette with a bold `7`, stronger contrast at home-screen and settings icon sizes for both Light and Dark variants, and a high-contrast grayscale Tinted variant. All three files are opaque `1024x1024` PNGs:

- `AppIcon-1024.png`
- `AppIcon-1024-dark.png`
- `AppIcon-1024-tinted.png`

## Search and Measurement

- Title (`Flipping Seven Calculator`), subtitle (`Offline Card Game Scorekeeper`), and keywords (`scoreboard,tally,tracker,points,luck,bust,party,tabletop,night,stats,undo,counter,score,pad,sheet`) have zero token duplication.
- The first three iPhone screenshots lead with live scoring, player states + 7-card bonus, and post-game charts.
- Query live App Store Connect state before any upload, build attachment, or submission; never infer live status from this file.
