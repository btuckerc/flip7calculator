# App Store Listing — Flipping Seven Calculator

Use this document as the human-readable source of truth for the `1.3 (11)` App Store Connect update. The matching machine-readable metadata is in [AppStoreAssets/1.3/metadata-en-US.json](AppStoreAssets/1.3/metadata-en-US.json).

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
| Build | `11` |
| Primary category | `Utilities` |
| Secondary category | `Games` → `Card` |
| Age rating | `4+`, with the App Store Connect questionnaire verified for this release |
| Copyright | `2026 Tucker Craig` |

Keep the existing bundle ID and app record. Internal target/module names are intentionally unchanged.

## Promotional Text

137/170 characters:

> Track flips, 7-card bonuses, busts, modifiers, and totals in seconds. Built for fast tables, easy corrections, and complete offline play.

## Keywords

96/100 characters:

```text
scorekeeper,card game,round tracker,score calculator,push your luck,bust,stats,offline,party game
```

Do not repeat words already present in the app name, subtitle, or category. Do not add the exact disputed mark, publisher name, competing app names, or spelling variations intended to reproduce them.

## Description

Flipping Seven Calculator is a fast, offline scorekeeper for flip-card and push-your-luck table games.

Keep every round moving:

- Add players and begin scoring in seconds
- Enter card values and modifiers with quick, readable controls
- Choose Classic or Vengeance scoring with separate deck profiles
- Track 7-card bonuses, player states, busts, and running totals
- Record special numbers plus positive, negative, multiply, and divide modifiers
- Undo and redo mistakes without rebuilding a round
- Adjust scores manually when house rules call for it
- Review round history, charts, and post-game statistics
- Customize deck profiles and target scores
- Continue an interrupted game from local on-device state

Designed for a shared phone or tablet at the table, the app keeps common actions visible and minimizes interruptions while people play.

No account is required. There are no ads, subscriptions, analytics SDKs, or network-dependent features. Game state and settings remain on your device.

Independent scorekeeping utility. Not affiliated with or endorsed by any game publisher.

## What's New in 1.3

Version 1.3 adds complete support for Classic and Vengeance play with separate deck profiles, special number cards, negative modifiers, optional Brutal scoring, mode-aware history, and expanded stats. It also introduces the Flipping Seven Calculator identity, original card-and-7 icon and opening animation, a refined blue-and-gold interface, accessibility improvements, and reliability fixes.

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
This is version 1.3 (build 11) of the existing app record. The customer-facing app name has changed from Flip 7 Calculator to Flipping Seven Calculator.

The app is an offline scorekeeping utility. Launch the app, add player names, choose Classic or Vengeance, and use the visible card values and modifiers to track rounds, 7-card bonuses, player states, busts, and totals. Vengeance mode adds special numbers, negative modifiers, separate deck customization, and an optional Brutal toggle that is off by default. No login, purchase, network connection, or special hardware is required.

The exact FLIP 7 mark, publisher name, third-party logos, box artwork, card-back artwork, and rules content are not displayed in the app or public metadata. The two-card app icon, seven-card deal-and-flip animation, and blue/cream/gold artwork in this build were created specifically for this app. An in-app statement identifies the product as an independent scorekeeping utility that is not affiliated with or endorsed by any game publisher.

Reference for the related correspondence: APP264401-I.
```

## Content Rights

Answer the App Store Connect content-rights question based on the submitted build:

- The app does not contain or access third-party content.
- All app UI, card illustrations, icon assets, screenshots, and animations must be original or properly licensed.
- Generic scorekeeping mechanics, numbers, cards, dice, and card-flip motion are used without third-party logos or product artwork.

## Screenshots

The submitted screenshots were captured from deterministic real app state with the fictional names Peter, Ned, Mary, and Gwen. They contain no third-party game packaging, card artwork, or added marketing overlays.

The final iPhone order leads with the three strongest search-result images:

1. Setup, original seven-card presentation, and product name
2. Live score entry
3. Statistical highlights
4. Game-over result
5. Score charts

The final iPad order is setup, live score entry, statistics, then game over.

The separate player-states captures are intentionally excluded from the submitted gallery. They repeat information already visible in the live-entry images and leave excessive unused space. The dedicated round-history capture is also excluded because scrolled chart content bleeds through its translucent status area; the stronger stats capture already communicates history and analysis value.

Required device coverage:

- Five 1320 x 2868 screenshots in the 6.9-inch iPhone set
- Four 2064 x 2752 screenshots in the 13-inch iPad set

The source images and deterministic capture instructions are in [AppStoreAssets/1.3/README.md](AppStoreAssets/1.3/README.md).

### Search-Result Media Audit

The live `1.2` version already has five complete iPhone and five complete iPad screenshots in App Store Connect, and Apple serves those files on the public product page. The missing media in the supplied iPhone search screenshot is therefore not an upload failure. That result shows `Open`; iOS has used a compact search row for installed or previously downloaded apps since iOS 15, while acquisition results showing `Get` can receive the screenshot or preview shelf.

Apple says up to three screenshots or app previews may appear depending on platform and orientation. When no App Preview exists, the first one to three screenshots are the search assets. No metadata field or additional image can force the expanded shelf for an installed-app result. Validate the acquisition presentation after approval from a device/account where the app has not been downloaded, or after removing the app when the storefront still treats it as a new acquisition.

The supplied competitor examples show two forms of the same system: three portrait screenshots for portrait-first apps and one wide screenshot for a landscape-first app. The wide treatment is not a separate entitlement or banner upload. This app's real scorekeeping UI is portrait-first on iPhone, so the honest competitive treatment is three strong portrait images rather than a fabricated landscape frame.

Sources:

- [Apple App Store search](https://developer.apple.com/app-store/search/)
- [Apple product-page guidance](https://developer.apple.com/app-store/product-page/)
- [Apple screenshot and App Preview upload guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/)
- [Reported iOS 15 installed-app search change](https://www.macrumors.com/2021/06/09/ios-15-app-store-search-results/)

Apple announced Product Page Headers, additional search-result creative, and a centralized Asset Library at WWDC26, with availability described as coming in fall 2026. Those are closer to a true custom banner than the current screenshot shelf, but they are not yet available to configure for this release. Revisit the listing when Apple enables them in App Store Connect.

- [Apple App Store What's New](https://developer.apple.com/app-store/whats-new/)
- [WWDC26: What's new in App Store Connect](https://developer.apple.com/videos/play/wwdc2026/205/)

## App Preview

An App Preview is optional and is intentionally deferred from the 1.3 release. It would precede screenshots and can autoplay in search, but it would not force an installed-app result to expand. Do not upload the current proof-of-concept recording. When a polished play-through is produced later, keep it between Apple's 15- and 30-second limits:

1. Deal/flip brand animation
2. Add players
3. Enter a round
4. Undo a mistake
5. Review stats

## Submission Snapshot

Version `1.3 (11)` was submitted to App Review on 2026-07-29 at 13:47:36 UTC. App Store Connect accepted the submission without validation errors and reported `WAITING_FOR_REVIEW`. The release type is `AFTER_APPROVAL`, so the update should publish automatically after Apple approves it.

The earlier build `9` submission was canceled before review and its item was removed. Build `11` is the only active submission and includes the finalized icon plus Classic and Vengeance support.

This is a dated snapshot, not a live status API. Query App Store Connect before acting. The local worktree has received post-submission changes, including mid-game mode switching and agent/release tooling, while the project build number remains `11`; those changes must use a new build number and a fresh release verification if uploaded.

The App Preview is not part of this submission. It can be added later as a metadata update after a shorter, continuous recording of realistic play is ready.

## App Icon

Build 10 replaces the former Lucky Ledger-derived icon with original, high-contrast artwork: two offset cards, a dominant `7`, and the app's blue, cream, gold, and copper palette. The design omits the old `LL`, pencil, dice, partial wordmark, publisher artwork, and third-party card styling.

- `AppIcon-1024.png`
- `AppIcon-1024-dark.png`
- `AppIcon-1024-tinted.png`

The icon generator is [icon/generate_icon_variants.py](icon/generate_icon_variants.py). Regenerate all three variants together, then inspect them at 1024px and home-screen size. The submitted build 11 assets were checked at both scales, including the rounded top-right card corner that previously exposed a drawing artifact.

## Localization

For `1.3`, update every existing App Store localization. Do not leave an old localized title, subtitle, description, screenshot, promotional text, or What's New field attached to the app version.

If a localization cannot be accurately refreshed before submission, remove that localization from the new version rather than publishing mixed branding.

## Search and Measurement

- Search indexing uses the app name, subtitle, keywords, and categories, but placement is not guaranteed.
- The title and subtitle intentionally contain `Flipping`, `Seven`, and `Flip-Card`; do not duplicate them in the keyword field.
- After release, record ranking for generic searches such as `flip card scorekeeper`, `seven card calculator`, `round scorekeeper`, and `push your luck scorekeeper`.
- Use App Analytics to compare product-page views, conversion, retention, and crash-free sessions before revising metadata again.
- Verify the search shelf from a device/account where the app has not been downloaded; an `Open` result is not a valid acquisition-media test.
- Once traffic is sufficient, run a Product Page Optimization test on the first three screenshots or an alternate icon rather than changing multiple conversion variables without measurement.
- Add an App Preview only when a continuous 15–30 second play-through communicates setup, live scoring, correction, and stats without dead time.
- If running Apple Ads, begin with generic category terms and Search Match. Keep any third-party trademark campaign outside this release plan.

## Pre-Submission Checklist

- [x] Display name updated to `Flipping Seven Calculator`
- [x] Version/build updated to `1.3 (11)`
- [x] Original title and seven-card launch presentation implemented
- [x] Original light, dark, and tinted icon variants generated and visually checked
- [x] Privacy policy source updated
- [x] New privacy policy published and verified at the submitted URL
- [x] Support URL and contact route verified
- [x] App Store Connect name, subtitle, keywords, description, categories, and review notes updated
- [x] Every localization audited or removed
- [x] Five iPhone and four iPad screenshots selected from the complete processed source set
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
4. Archive and upload `1.3 (11)`.
5. Replace all App Store Connect metadata and localizations.
6. Submit for review with the private reviewer note above.
7. Send the transparent `APP264401-I` status update and preserve a PDF/screenshot record of submitted materials.
