# APP264401-I — Lucky Ledger Rebrand Todo

This is the working checklist for the trademark-driven rebrand and stabilization pass.

## Local product work

- [x] Replace trademarked title treatment with generic in-app branding
- [x] Replace the launch/splash experience with new generic visuals
- [x] Replace game-specific help/rules content with a neutral scoring guide
- [x] Rebrand settings/footer/version references
- [x] Update score/stat terminology to use `7-card bonus` and `Hold`
- [x] Add compatibility-safe migration for renamed deck action-card keys
- [x] Retune player palettes so palette validation passes safely
- [x] Update Xcode display name to `Lucky Ledger`
- [x] Rewrite App Store metadata draft for the rebrand
- [x] Rewrite privacy policy for the rebrand
- [x] Replace icon assets and verify light/dark/tinted variants
- [x] Strengthen generic product cues around flips, `7-card bonus`, holds, and busts
- [x] Rework the icon so the die, flipping card, and `7` read at home-screen size
- [ ] Capture new iPhone/iPad screenshots with only generic branding

## Build and quality

- [x] Investigate failing tests instead of papering over them
- [x] Fix the undo/redo test drift around `x2` deck configuration
- [x] Fix palette validation regressions
- [x] Run full test suite with stable simulator settings
- [x] Run a clean `Release` build
- [x] Move local build caches outside the repo to avoid `Documents/.build` Release failures
- [x] Smoke-test on simulator with `make launch`
- [ ] Verify the new icon on a physical iPhone home screen
- [ ] Smoke-test on a physical device

## App Store / legal operations

- [ ] Update App Store Connect app name, subtitle, keywords, description, and screenshots
- [ ] Update the privacy policy URL if the final hosted path differs
- [ ] Confirm the app is removed from sale temporarily if more time is needed
- [x] Draft a claimant/Apple status email with `APP264401-I` in the subject line
- [ ] Send Apple and USAopoly a short status update after the rebrand build is submitted

Future correspondence subject line:
`APP264401-I — Lucky Ledger Rebrand Update`

- [ ] Keep Apple copied on claimant communications
- [ ] Avoid any request for continued trademark use unless written permission is offered
- [ ] Preserve documentation of the shipped changes in case Apple asks for proof

## Recommended submission order

1. Finish asset replacement and screenshot capture.
2. Verify icon readability on an actual home screen before final screenshot capture.
3. Run tests and a release archive.
4. Upload the rebranded build.
5. Send the status email with `APP264401-I` in the subject line and copy the claimant.
6. If review stalls, follow up with before/after screenshots and the updated metadata.

## Notes

- Keep the bundle identifier unchanged unless Apple specifically requires a new app record.
- The historical analysis doc at `docs/APP264401-I-path-forward.md` intentionally keeps legacy references because it documents the dispute and research record.
