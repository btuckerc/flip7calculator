# App Store Listing — Flip 7 Calculator

Use this document to prepare your App Store Connect submission. Fill in the blanks and copy/paste into App Store Connect.

---

## App Identity

| Field | Value |
|-------|-------|
| **App Name** (30 chars max) | `Flip 7 Calculator` |
| **Subtitle** (30 chars max) | `Score tracker for card game` |
| **Bundle ID** | `com.tcraig.flip7calculator.ios` |
| **SKU** | `flip7calculator` |
| **Primary Language** | English (U.S.) |

---

## Category

| Field | Recommendation |
|-------|----------------|
| **Primary Category** | Utilities |
| **Secondary Category** | Games → Card |

> Tip: "Utilities" often has less competition than "Games" and fits a score-tracker app well.

---

## Keywords (100 characters max, comma-separated)

```
flip 7,card game,score tracker,score keeper,card score,game calculator,flip seven,board game scorer
```

*(98 characters — adjust as needed)*

---

## Description

### Short Promotional Text (170 chars max, can be updated without review)

```
Track scores for Flip 7 card games quickly and accurately. Supports multiple players, undo, and automatic bonus calculation.
```

### Full Description (4000 chars max)

```
Flip 7 Calculator is the ultimate companion for tracking scores during your Flip 7 card game sessions.

FEATURES
• Multi-player support — add as many players as you need
• Quick card entry — tap to log each card drawn
• Automatic scoring — calculates bonuses (×2 multipliers, +5/+10 modifiers, Flip 7 bonus) instantly
• Round-by-round history — review past rounds at a glance
• Undo support — made a mistake? Roll it back
• Customizable themes — light, dark, or system preference
• Haptic feedback — satisfying taps as you play
• Offline-first — no internet required, your data stays on your device

HOW IT WORKS
1. Add player names before you start.
2. As cards are drawn, tap the corresponding number or modifier.
3. When a player busts or stops, end their turn.
4. View cumulative scores and crown the winner!

PRIVACY
This app collects no personal data. All game data is stored locally on your device and is never uploaded anywhere.

---
Flip 7 Calculator is an unofficial companion app and is not affiliated with or endorsed by the creators of Flip 7.
```

---

## What's New (Release Notes)

Use for each new version submitted.

### Version 1.0

```
Initial release — track Flip 7 scores with ease!
```

---

## Privacy Policy

Apple requires a privacy policy URL even for apps that collect no data.

**Option A — Host your own**
Create a simple page (GitHub Pages, Notion, personal site) with the following text:

> **Privacy Policy for Flip 7 Calculator**
>
> Last updated: [DATE]
>
> Flip 7 Calculator does not collect, store, or share any personal information. All data (player names, scores, settings) is stored locally on your device using standard iOS storage and is never transmitted to any server.
>
> This app does not use analytics, advertising, or third-party tracking services.
>
> If you have questions, contact: [YOUR EMAIL]

**Option B — Use a free generator**
Sites like termly.io or freeprivacypolicy.com can generate a compliant policy.

| Field | Your Value |
|-------|------------|
| **Privacy Policy URL** | `https://___________` |

---

## Support Information

| Field | Your Value |
|-------|------------|
| **Support URL** | `https://___________` (can be GitHub Issues, personal site, etc.) |
| **Marketing URL** (optional) | |
| **Contact Email** | `___________@_____` |

---

## App Review Information

| Field | Value |
|-------|-------|
| **Demo Account Required?** | No |
| **Notes for Reviewer** | This is a simple score-tracking utility for the Flip 7 card game. Launch the app, add player names, and tap cards to track scores. No login or network access required. |

---

## Age Rating Questionnaire

Answer **No** to all content questions (violence, gambling, etc.) unless you've added something beyond basic score tracking.

| Content Type | Answer |
|--------------|--------|
| Cartoon or Fantasy Violence | No |
| Realistic Violence | No |
| Gambling | No |
| Contests | No |
| Alcohol, Tobacco, Drugs | No |
| Sexual Content | No |
| Profanity | No |
| Horror/Fear | No |
| Medical/Treatment Info | No |
| Mature/Suggestive Themes | No |
| Simulated Gambling | No |
| Unrestricted Web Access | No |

**Expected Rating:** 4+ (suitable for all ages)

---

## App Privacy (App Store Connect Data Collection)

When asked "Does this app collect any user data?", select:

**☑ No, we do not collect data from this app**

This sets the App Privacy label to "Data Not Collected".

---

## Screenshots Checklist

App Store Connect requires screenshots for each device class you support. Since `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad), you need both.

### iPhone (required sizes — provide at least one)

| Size | Device Examples | Resolution |
|------|-----------------|------------|
| 6.7" | iPhone 15 Pro Max, 14 Pro Max | 1290 × 2796 |
| 6.5" | iPhone 14 Plus, 11 Pro Max | 1284 × 2778 |
| 5.5" | iPhone 8 Plus, 7 Plus | 1242 × 2208 |

### iPad (required if supporting iPad)

| Size | Device Examples | Resolution |
|------|-----------------|------------|
| 12.9" (6th gen) | iPad Pro 12.9" | 2048 × 2732 |
| 12.9" (2nd gen) | iPad Pro 12.9" (older) | 2048 × 2732 |

### Screenshot Suggestions

1. **Game Setup** — show the player entry screen with a few names
2. **Active Round** — mid-game with cards selected and scores visible
3. **Score Summary** — end-of-round or multi-round leaderboard
4. **Settings** — show theme options
5. **Flip 7 Bonus** — highlight the 7-card bonus indicator

> Tip: Use Xcode Simulator or a real device to capture. Consider adding device frames via tools like Screenshots.pro or Rotato.

---

## App Icon Checklist

Your asset catalog already includes:
- [x] `AppIcon-1024.png` (standard)
- [x] `AppIcon-1024-dark.png` (dark mode variant)
- [x] `AppIcon-1024-tinted.png` (tinted variant)

Ensure:
- [ ] No alpha channel / transparency
- [ ] No rounded corners (iOS applies them automatically)
- [ ] sRGB color space recommended

---

## Pre-Submission Checklist

- [ ] Bundle ID matches App Store Connect app record
- [ ] Version number (`MARKETING_VERSION`) is correct (currently `1.0`)
- [ ] Build number (`CURRENT_PROJECT_VERSION`) increments with each upload
- [ ] Archive built with **Release** configuration
- [ ] Tested on real device (not just Simulator)
- [ ] Privacy Policy URL is live and accessible
- [ ] Support URL is live and accessible
- [ ] All required screenshots uploaded
- [ ] App Review notes filled in
- [ ] Export compliance answered (set to NO in build settings)

---

## Notes

- **Trademark disclaimer**: The in-app UI and App Store description include a note that this app is unofficial and not affiliated with the Flip 7 game creators. Adjust wording if you obtain explicit permission.
- **Localization**: Currently English only. Add more languages in Xcode's String Catalogs if desired.

---

*Document generated for flip7calculator — good luck with your submission!*



