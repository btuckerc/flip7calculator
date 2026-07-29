# App Store Listing — Flipping Seven Calculator

Use this document as the source of truth for the `1.3 (9)` App Store Connect update.

For the decision record and trademark/App Review guardrails, also read:

- [APP264401-I path forward](docs/APP264401-I-path-forward.md)
- [APP264401-I discovery and listing strategy](docs/APP264401-I-discovery-and-listing-strategy.md)

## App Information

| Field | Submission value |
|---|---|
| App name (25/30) | `Flipping Seven Calculator` |
| Subtitle (26/30) | `Fast Flip-Card Scorekeeper` |
| Bundle ID | `com.tcraig.flip7calculator.ios` |
| SKU | `flip7calculator` |
| Version | `1.3` |
| Build | `9` |
| Primary category | `Utilities` |
| Secondary category | `Games` → `Card` |
| Age rating target | `4+`, subject to the completed App Store Connect questionnaire |
| Copyright | `2026 Tucker Craig` |

Keep the existing bundle ID and app record. Internal target/module names are intentionally unchanged.

## Promotional Text

144/170 characters:

> Track flips, 7-card bonuses, holds, busts, modifiers, and totals in seconds. Built for fast tables, easy corrections, and complete offline play.

## Keywords

96/100 characters:

```text
scorekeeper,card game,round tracker,score calculator,push your luck,bust,hold,offline,party game
```

Do not repeat words already present in the app name, subtitle, or category. Do not add the exact disputed mark, publisher name, competing app names, or spelling variations intended to reproduce them.

## Description

Flipping Seven Calculator is a fast, offline scorekeeper for flip-card and push-your-luck table games.

Keep every round moving:

- Add players and begin scoring in seconds
- Enter card values and modifiers with quick, readable controls
- Track 7-card bonuses, holds, busts, and running totals
- Undo and redo mistakes without rebuilding a round
- Adjust scores manually when house rules call for it
- Review round history, charts, and post-game statistics
- Customize deck profiles and target scores
- Continue an interrupted game from local on-device state

Designed for a shared phone or tablet at the table, the app keeps common actions visible and minimizes interruptions while people play.

No account is required. There are no ads, subscriptions, analytics SDKs, or network-dependent features. Game state and settings remain on your device.

Independent scorekeeping utility. Not affiliated with or endorsed by any game publisher.

## What's New in 1.3

Flipping Seven Calculator introduces a complete new identity and an original seven-card opening sequence. This release also includes clearer scorekeeping language, a refined blue-and-gold interface, accessibility improvements, and reliability fixes across score entry, history, and stats.

## URLs

| Field | URL | Status before submission |
|---|---|---|
| Privacy policy | `https://btuckerc.dev/privacy/flipping-seven-calculator` | **Blocked:** HTTP 200 currently renders an empty main area with the generic portfolio title. Publish [PRIVACY_POLICY.md](PRIVACY_POLICY.md), then verify the rendered title and policy text. |
| Support | `https://btuckerc.dev/contact` | Verified HTTP 200 with rendered contact content on 2026-07-28 |
| Marketing | Optional | Leave blank unless a product-specific page is published |

Do not submit with a blank fallback route or the old Lucky Ledger privacy page merely because either returns HTTP 200. The rendered policy and submitted URL must agree with the new product name.

## App Review Notes

Private reviewer notes may identify the previous app title because they are operational correspondence rather than public discovery metadata.

```text
This is version 1.3 (build 9) of the existing app record. The customer-facing app name has changed from Flip 7 Calculator to Flipping Seven Calculator.

The app is an offline scorekeeping utility. Launch the app, add player names, and use the visible card values and modifiers to track rounds, 7-card bonuses, holds, busts, and totals. No login, purchase, network connection, or special hardware is required.

The exact FLIP 7 mark, publisher name, third-party logos, box artwork, card-back artwork, and rules content are not displayed in the app or public metadata. The seven-card deal-and-flip animation and blue/cream/gold artwork in this build were created specifically for this app. An in-app statement identifies the product as an independent scorekeeping utility that is not affiliated with or endorsed by any game publisher.

Reference for the related correspondence: APP264401-I.
```

## Content Rights

Answer the App Store Connect content-rights question based on the submitted build:

- The app does not contain or access third-party content.
- All app UI, card illustrations, icon assets, screenshots, and animations must be original or properly licensed.
- Generic scorekeeping mechanics, numbers, cards, dice, and card-flip motion are used without third-party logos or product artwork.

## Screenshot Plan

Capture screenshots from the final `1.3 (9)` build only. Show real app UI, fictional player names, and no third-party game packaging or cards.

1. **Score a round in seconds** — Setup screen with three or four players and the full Flipping Seven Calculator wordmark.
2. **Track every flip** — Live score entry with card values and modifiers visible.
3. **See holds and busts clearly** — Active round with distinct player states and readable totals.
4. **Fix mistakes instantly** — Undo/redo and manual score adjustment in context.
5. **Review every round** — History and post-game stats/charts.
6. **Make it your table** — Target score, deck profile, theme, and accessibility options.

Required device coverage:

- Current 6.9-inch iPhone screenshot set
- Current 13-inch iPad screenshot set
- Additional sizes only if App Store Connect does not accept scaling from these source sets

Screenshot overlays should use short generic phrases. Do not use the exact disputed mark, a publisher name, “official,” “authorized,” or comparison claims.

## App Preview

An app preview is optional. Do not delay the compliance update for one. If produced later, keep it under 30 seconds:

1. Deal/flip brand animation
2. Add players
3. Enter a round
4. Undo a mistake
5. Review stats

## App Icon

The owner-approved light, dark, and tinted icon files remain unchanged for this release:

- `AppIcon-1024.png`
- `AppIcon-1024-dark.png`
- `AppIcon-1024-tinted.png`

Do not rerun the generator or modify the icon during this rebrand. Before upload, verify all three variants at home-screen size and confirm that App Store Connect displays the same production icon.

## Localization

For `1.3`, update every existing App Store localization. Do not leave an old localized title, subtitle, description, screenshot, promotional text, or What's New field attached to the app version.

If a localization cannot be accurately refreshed before submission, remove that localization from the new version rather than publishing mixed branding.

## Search and Measurement

- Search indexing uses the app name, subtitle, keywords, and categories, but placement is not guaranteed.
- The title and subtitle intentionally contain `Flipping`, `Seven`, and `Flip-Card`; do not duplicate them in the keyword field.
- After release, record ranking for generic searches such as `flip card scorekeeper`, `seven card calculator`, `round scorekeeper`, and `push your luck scorekeeper`.
- Use App Analytics to compare product-page views, conversion, retention, and crash-free sessions before revising metadata again.
- If running Apple Ads, begin with generic category terms and Search Match. Keep any third-party trademark campaign outside this release plan.

## Pre-Submission Checklist

- [x] Display name updated to `Flipping Seven Calculator`
- [x] Version/build updated to `1.3 (9)`
- [x] Original title and seven-card launch presentation implemented
- [x] Approved icon files left unchanged
- [x] Privacy policy source updated
- [ ] New privacy policy published and verified at the submitted URL
- [x] Support URL and contact route verified
- [ ] App Store Connect name, subtitle, keywords, description, categories, and review notes updated
- [ ] Every localization audited or removed
- [ ] New iPhone and iPad screenshots uploaded
- [ ] Content-rights and age-rating questionnaires completed accurately
- [x] Debug, unit, UI, and Release validation passed for the release candidate source
- [ ] Physical-device launch, icon, Dynamic Type, VoiceOver, light/dark, and reduced-motion checks completed
- [ ] Build uploaded and processed successfully
- [ ] `APP264401-I` status email sent to Apple with the claimant copied

## Submission Order

1. Publish and verify the privacy policy.
2. Capture final screenshots from the release build.
3. Complete final automated and physical-device checks.
4. Archive and upload `1.3 (9)`.
5. Replace all App Store Connect metadata and localizations.
6. Submit for review with the private reviewer note above.
7. Send the transparent `APP264401-I` status update and preserve a PDF/screenshot record of submitted materials.
