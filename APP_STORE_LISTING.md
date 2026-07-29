# App Store Listing — Flipping Seven Calculator

Use this document as the human-readable source of truth for the `1.3 (9)` App Store Connect update. The matching machine-readable metadata is in [AppStoreAssets/1.3/metadata-en-US.json](AppStoreAssets/1.3/metadata-en-US.json).

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
| Age rating | `4+`, with the App Store Connect questionnaire verified for this release |
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
| Privacy policy | `https://btuckerc.dev/privacy/flipping-seven-calculator` | Verified deployed production route and policy bundle on 2026-07-29 |
| Support | `https://btuckerc.dev/contact` | Verified HTTP 200 with rendered contact content on 2026-07-28 |
| Marketing | Optional | Leave blank unless a product-specific page is published |

Do not submit with a blank fallback route or the old Lucky Ledger privacy page merely because either returns HTTP 200. The rendered policy and submitted URL must agree with the new product name.

### Privacy Route Verification

The production site now registers `/privacy/flipping-seven-calculator` and deploys a dedicated `FlippingSevenPrivacy` bundle. The rendered policy identifies Flipping Seven Calculator, states that the app collects no personal data, and sets the exact route as its canonical URL. The initial HTML document retains the portfolio shell title because the site is a client-rendered SPA; the route-specific title and policy are applied by the page bundle.

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

## Screenshots

The submitted screenshots were captured from deterministic real app state with the fictional names Peter, Ned, Mary, and Gwen. They contain no third-party game packaging, card artwork, or added marketing overlays.

The final iPhone order is:

1. Setup and original seven-card presentation
2. Live score entry
3. Distinct active, frozen, banked, and busted player states
4. Game-over result
5. Statistical highlights
6. Score charts
7. Round history

Required device coverage:

- Seven 1320 x 2868 screenshots in the 6.9-inch iPhone set
- Five 2064 x 2752 screenshots in the 13-inch iPad set

The source images and deterministic capture instructions are in [AppStoreAssets/1.3/README.md](AppStoreAssets/1.3/README.md).

## App Preview

An app preview is optional and is intentionally deferred from the 1.3 release. Do not upload the current proof-of-concept recording. When a polished play-through is produced later, keep it under 30 seconds:

1. Deal/flip brand animation
2. Add players
3. Enter a round
4. Undo a mistake
5. Review stats

## Submission Status

Version `1.3 (9)` was submitted to App Review on 2026-07-29 at 04:47:22 UTC. App Store Connect accepted the submission without validation errors and reported `WAITING_FOR_REVIEW`. The release type is `AFTER_APPROVAL`, so the update should publish automatically after Apple approves it.

The App Preview is not part of this submission. It can be added later as a metadata update after a shorter, continuous recording of realistic play is ready.

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
- [x] New privacy policy published and verified at the submitted URL
- [x] Support URL and contact route verified
- [x] App Store Connect name, subtitle, keywords, description, categories, and review notes updated
- [x] Every localization audited or removed
- [x] Seven iPhone and five iPad screenshots uploaded and processed
- [x] Content-rights declaration and inherited `4+` age rating verified
- [x] Debug, unit, UI, and Release validation passed for the release candidate source
- [ ] Physical-device launch, icon, Dynamic Type, VoiceOver, light/dark, and reduced-motion checks completed
- [x] Distribution-signed build uploaded, processed, and attached successfully
- [x] Version submitted to App Review with automatic release after approval
- [x] App Preview intentionally deferred from version `1.3`
- [ ] `APP264401-I` status email sent to Apple with the claimant copied

## Submission Order

1. Publish and verify the privacy policy.
2. Capture final screenshots from the release build.
3. Complete final automated and physical-device checks.
4. Archive and upload `1.3 (9)`.
5. Replace all App Store Connect metadata and localizations.
6. Submit for review with the private reviewer note above.
7. Send the transparent `APP264401-I` status update and preserve a PDF/screenshot record of submitted materials.
