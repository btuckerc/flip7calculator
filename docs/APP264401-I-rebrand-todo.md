# APP264401-I — Flipping Seven Calculator Release Checklist

This is the working checklist for the approved `1.3 (9)` rebrand. It records completed repository work separately from App Store Connect, hosting, and physical-device operations.

## Repository and Product

- [x] Preserve the complete Lucky Ledger baseline in git (`8a47e54`)
- [x] Create the `codex/flipping-seven-rebrand` release branch
- [x] Centralize the new public name in `AppBrand`
- [x] Update the Xcode display name to `Flipping Seven Calculator`
- [x] Bump the app to version `1.3`, build `9`
- [x] Replace the in-app `LL` hero with an original seven-card mark
- [x] Restore a seven-card deal-and-flip launch sequence
- [x] Keep the app icon assets unchanged at the owner's direction
- [x] Preserve reduced-motion parity for launch and title animation
- [x] Keep scorekeeping copy generic: `7-card bonus`, hold, bust, modifier, round
- [x] Keep internal bundle, module, target, and migration identifiers where changing them would add release risk
- [x] Display the independent/non-affiliation statement in the app help/about surface
- [x] Complete the remaining live-game design-token and hard-coded color cleanup
- [x] Audit visible strings and accessibility labels for stale branding

## Original-Art Guardrails

- [x] Do not restore the former layered `FLIP 7`-style wordmark
- [x] Do not restore colors or typography copied from third-party box art
- [x] Do not restore third-party card-back patterns, modifier artwork, logos, publisher names, or rules text
- [x] Use original blue, cream, gold, and copper artwork consistent with the approved app icon
- [x] Use generic numbered cards, card flipping, dice, calculator, and scorekeeping motifs only
- [x] Spell out `FLIPPING SEVEN` in the in-app wordmark rather than using `Flipping7`

## Build and Quality

- [x] Confirm the new title/splash implementation compiles in Debug
- [x] Run `git diff --check`
- [x] Run the complete test scheme: 136 passed, 0 failed, 0 skipped
- [x] Run the complete UI test target: 3 methods / 4 executions passed, 0 failed, 0 skipped
- [x] Run a clean Release simulator build
- [x] Smoke-test a clean simulator install and launch
- [x] Check iPhone compact layout in dark appearance
- [x] Check iPad regular-width layout in dark appearance
- [x] Check clean-install light appearance on iPhone and iPad
- [x] Check the rebranded setup surface at the maximum accessibility content size
- [x] Keep decorative wordmark/card fonts fixed-size while exposing one complete accessibility label
- [x] Audit VoiceOver names and control semantics in the touched branding surfaces
- [ ] Run the complete app flow with VoiceOver enabled
- [x] Implement static parity for iOS Reduce Motion and the in-app Reduce Animations setting
- [ ] Exercise both reduced-motion settings on a physical device
- [ ] Verify the unchanged icon on a physical iPhone home screen
- [ ] Smoke-test on a physical iPhone or iPad

## App Store Materials

- [x] Rewrite the App Store listing source for `Flipping Seven Calculator`
- [x] Rewrite the privacy policy source
- [x] Update the private App Review notes
- [x] Update the transparent Apple/claimant status-email draft
- [x] Publish the privacy policy at `https://btuckerc.dev/privacy/flipping-seven-calculator`
- [x] Verify privacy and support URLs return correct production content
- [x] Capture and upload seven 6.9-inch iPhone screenshots
- [x] Capture and upload five 13-inch iPad screenshots
- [x] Capture stable iPhone and iPad simulator images for visual QA; these are not the production screenshot set
- [x] Confirm the project currently ships no localized metadata or `.lproj` resources that could retain stale branding
- [x] Update name, subtitle, keywords, description, promotional text, and What's New
- [x] Set primary category to `Utilities` and secondary to `Games → Card`
- [x] Verify the content-rights declaration and inherited `4+` age rating
- [x] Confirm no exact disputed mark appears in proposed public metadata or shipped UI copy

## Submission and Correspondence

- [x] Archive and upload `1.3 (9)`
- [x] Confirm App Store Connect finishes processing the build
- [x] Attach final build and screenshots to the new version
- [x] Submit the update for review on 2026-07-29
- [ ] Send the status email with `APP264401-I` in the subject
- [ ] Copy Molly Wohlin/USAopoly on correspondence to Apple
- [x] Ensure the status-email draft does not state or imply that USAopoly approved the new name
- [x] Preserve the submitted metadata and dated screenshot sources in the repository
- [ ] Preserve the sent correspondence in the case record
- [ ] Record any Apple or claimant response verbatim before deciding on another name or metadata change

## Remaining External Operations

- Wait for Apple to review version `1.3`; it is configured to release automatically after approval.
- Complete the physical-device icon, VoiceOver, reduced-motion, and layout checks.
- Send the status email in the existing Apple Legal thread with `APP264401-I` in the subject and Molly Wohlin copied.
- Preserve any Apple or claimant response before changing the name or listing again.
- Replace the temporary Admin API key with a least-privilege App Manager key after release operations are complete.

## Local Release Credential Audit — 2026-07-29

- Bundle ID: `com.tcraig.flip7calculator.ios`
- Confirmed Apple team: `7F3KV9WTNW`
- Project-level and target-level development team settings are aligned
- Apple-managed distribution signing successfully exported the release IPA for team `7F3KV9WTNW`
- The exported app is signed by `Apple Distribution: Briggs Craig (7F3KV9WTNW)`
- An App Store Connect API key is stored outside the repository with owner-only filesystem permissions
- Build `9` was uploaded, processed as `VALID`, attached to version `1.3`, and submitted
- The release key currently has the broader Admin role and should be rotated to App Manager after release operations

Do not commit the private key, key ID, issuer ID, JWTs, profiles, or other release credentials. Keep release secrets outside the repository and use the narrowest App Store Connect role that supports the required operation.
