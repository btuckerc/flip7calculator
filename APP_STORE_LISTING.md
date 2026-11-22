# App Store Listing — Flipping Seven Calculator

Use this document as the human-readable source of truth for the `1.4 (12)` App Store Connect update. The matching machine-readable metadata lives in [AppStoreAssets/1.4/metadata-en-US.json](AppStoreAssets/1.4/metadata-en-US.json) and [AppStoreAssets/1.4/metadata-es-MX.json](AppStoreAssets/1.4/metadata-es-MX.json).

For the decision record and trademark/App Review guardrails, also read:

- [APP264401-I path forward](docs/APP264401-I-path-forward.md)
- [APP264401-I discovery and listing strategy](docs/APP264401-I-discovery-and-listing-strategy.md)

## App Information

| Field | Submission value |
|---|---|
| App name (25/30) | `Flipping Seven Calculator` |
| Subtitle `en-US` (26/30) | `Flip-Card Game Scorekeeper` |
| Subtitle `es-MX` (28/30) | `Marcador de juegos de cartas` |
| Bundle ID | `com.tcraig.flip7calculator.ios` |
| SKU | `flip7calculator` |
| Version | `1.4` |
| Build | `12` |
| Primary category | `Utilities` |
| Secondary category | `Games` → `Card`, `Board` |
| Age rating | `4+`, with the App Store Connect questionnaire verified for this release |
| Copyright | `2026 Tucker Craig` |

Keep the existing bundle ID and app record. Internal target/module names are intentionally unchanged.

## Promotional Text

159/170 characters:

> Score a full table in seconds. Tap cards, auto-add 7-card bonuses, and track who banked, froze, or busted. Offline on iPhone and iPad, with no ads or accounts.

## Keywords

100/100 characters:

```text
scoreboard,counter,tracker,score,keeper,tally,point,7,sheet,pad,bust,luck,party,board,tabletop,night
```

Do not repeat words already present in the app name, subtitle, or category. Never place `flip` and `7` adjacent anywhere, and never add the disputed mark, publisher name, competing app names, or spelling variations intended to reproduce them.

### Spanish (`es-MX`) Localization

Indexed in both the US and Mexico storefronts for Spanish-speaking players:

- Subtitle (28/30): `Marcador de juegos de cartas`
- Keywords (99/100): `puntos,anotador,contador,puntaje,ronda,suerte,fiesta,familia,mesa,tablero,baraja,jugada,hoja,rapido`

## Description

Flipping Seven Calculator is a fast, offline scorekeeper for push-your-luck card games on iPhone and iPad.

Spend game night playing cards instead of doing mental math:

- Tap number cards and modifiers as hands unfold
- See at a glance who is still drawing, banked, frozen, or busted
- Automatically total 7-card bonuses, x2 multipliers, special numbers, and negative modifiers
- Switch between two scoring modes with custom deck profiles
- Turn on optional Brutal rules for negative rounds and redirected 7-card bonuses
- Undo, redo, or type a manual round score whenever house rules come up
- Play on iPad with a full-table layout (side-by-side in landscape) or on iPhone with a compact board
- Check post-game score charts, highlights, player stats, and round-by-round history
- Pick up an interrupted game right where you left off

Everything stays on your device. No accounts, no ads, no subscriptions, and no internet connection needed.

Independent scorekeeping utility. Not affiliated with or endorsed by any game publisher.

## What's New in 1.4

Version 1.4 makes scoring faster, easier to read, and smoother to use:

- Faster startup with a shorter opening animation you can tap to skip, plus snappier taps throughout the app
- Higher-contrast number and modifier keys, clearer Bank, Bust, and Freeze states, and refreshed light and dark themes
- Redesigned iPad table layout with large player tiles in portrait and a side-by-side board and keypad in landscape
- Improved VoiceOver labels on modifier controls and dialogs, better Dynamic Type scaling, and full Reduce Motion support
- Updated post-game score charts and a sharper app icon

## URLs

| Field | URL | Status before submission |
|---|---|---|
| Privacy policy | `https://btuckerc.dev/privacy/flipping-seven-calculator` | Verified HTTP 200 live on 2026-11-22 |
| Support | `https://btuckerc.dev/contact` | Verified HTTP 200 live on 2026-11-22 |
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

The version `1.4` screenshots are composed on macOS from deterministic real app captures (fictional names: Miles, Ned, MJ, and Peter, using the shipped Neon player palette) with `-releaseMarketingPreview` so Debug-only preview controls are never depicted.

### iPhone 6.9-inch (`1320 x 2868`)

1. `01-live-scoring.png` — Score every flip fast
2. `02-states-and-bonus.png` — 7-card bonus, auto-added
3. `03-stats-charts.png` — Stats after every game
4. `04-game-over.png` — Final standings

### iPad 13-inch (`2064 x 2752`)

1. `01-live-split.png` — Built for the whole table
2. `02-states-and-bonus.png` — 7-card bonus, auto-added
3. `03-stats-charts.png` — Stats after every game
4. `04-game-over.png` — Final standings

### Header & Search Results Creative Assets (iOS 27 / iPadOS 27)

Text-free opaque RGB PNGs shared across `en-US` and `es-MX`, rendered via [render-appstore-creative.py](scripts/render-appstore-creative.py) using the same dark icon card geometry and twilight palette:

- **Product Page Header** (`3840 x 1646`, 21:9): `AppStoreAssets/1.4/Creative/header-3840x1646.png` (`PRODUCT_PAGE_HEADER_ASSET`)
- **Search Results Asset** (`3840 x 2560`, 3:2): `AppStoreAssets/1.4/Creative/search-3840x2560.png` (`APP_STORE_SEARCH_RESULTS_ASSET`)

Source asset documentation lives in [AppStoreAssets/1.4/README.md](AppStoreAssets/1.4/README.md).

## App Icon

Version `1.4 (12)` updates the two-card-and-7 icon using 4× supersampled rendering in [icon/generate_icon_variants.py](icon/generate_icon_variants.py): a clean two-card silhouette with a bold `7`, stronger contrast at home-screen and settings icon sizes for both Light and Dark variants, and a high-contrast grayscale Tinted variant. All three files are opaque `1024x1024` PNGs:

- `AppIcon-1024.png`
- `AppIcon-1024-dark.png`
- `AppIcon-1024-tinted.png`

## Search and Measurement

- Title (`Flipping Seven Calculator`), subtitle (`Flip-Card Game Scorekeeper`), and keywords (`scoreboard,counter,tracker,score,keeper,tally,point,7,sheet,pad,bust,luck,party,board,tabletop,night`) have zero token duplication and never place `flip` and `7` adjacent.
- `es-MX` adds genuine Spanish search coverage for US and Mexico storefronts without keyword stuffing.
- The first three iPhone screenshots lead with live scoring, 7-card bonus + player states, and post-game charts, and omit the setup screen so no expansion mode name or rules-like line appears on public marketing media.
- Query live App Store Connect state before any upload, build attachment, or submission; never infer live status from this file.
