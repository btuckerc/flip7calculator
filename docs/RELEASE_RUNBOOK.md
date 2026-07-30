# Release Runbook

This runbook separates local verification, signing, binary upload, TestFlight, App Store metadata, App Review, and public release. These are not interchangeable states.

## Safety Rules

- Query live App Store Connect state before taking action. Do not trust a dated README or prior conversation.
- Do not remove or replace a submission already waiting for or in review without explaining the review-queue consequence and receiving explicit approval.
- Never commit API credentials, `.p8` files, certificates, profiles, JWTs, `.xcarchive` bundles, or exported IPAs.
- Keep the matching archive and dSYM for every uploaded build so customer crashes can be symbolicated.
- Build numbers are unique per uploaded version. Confirm the current highest build before incrementing.
- `AppStoreAssets/release-state.json` records the last known uploaded build as a local lower bound. It is not a substitute for the live query.
- Every correspondence about the trademark matter must include `APP264401-I` in the subject and copy the other required party.

## Credentials

On the maintainer Mac, credentials are stored outside the repository in the login Keychain. `make doctor`, `make asc-auth`, and `scripts/release.sh` load them automatically without printing their values. The operational `.p8` file lives under `~/.appstoreconnect/private_keys/` with owner-only permissions; an encrypted Keychain copy allows the loader to restore that file if it is accidentally removed.

Verify the complete local setup before release work:

```bash
make asc-auth
```

For a command that reads `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_PATH` directly, use the secure wrapper:

```bash
scripts/with-asc-credentials.sh \
  uv run --with pyjwt --with cryptography \
  python scripts/app-store-connect-api.py GET '/v1/apps?filter[bundleId]=com.tcraig.flip7calculator.ios'
```

Explicit environment variables still override Keychain values, which supports ephemeral CI secret injection:

```bash
export ASC_KEY_ID="..."
export ASC_ISSUER_ID="..."
export ASC_KEY_PATH="/absolute/path/to/AuthKey_....p8"
```

Keep the key outside the repository with restrictive file permissions. Never copy its values into documentation, task prompts, shell startup files, committed environment files, or Codex configuration. Simulator builds and tests do not require credentials. Secure local storage is machine-specific; a different Mac or hosted agent needs separately provisioned secrets.

For an authenticated API read:

```bash
scripts/with-asc-credentials.sh \
  uv run --with pyjwt --with cryptography \
  python scripts/app-store-connect-api.py GET '/v1/apps?filter[bundleId]=com.tcraig.flip7calculator.ios'
```

Use API reads to discover IDs and state. Use `--data-file` for write payloads so consequential JSON can be reviewed before execution.

## Release Gates

1. **Scope:** confirm the exact commit/diff intended to ship and whether an active review submission exists.
2. **Versioning:** confirm `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, bundle ID, display name, category, and supported devices.
3. **Automated verification:** run `make verify`.
4. **Manual verification:** launch on a physical iPhone and, when layout changed, iPad. Check core game flow, icon, light/dark, largest practical Dynamic Type, VoiceOver, and Reduce Motion.
5. **Public surfaces:** audit app copy, help, privacy/support URLs, icon variants, metadata, screenshots, reviewer notes, and legal constraints.
6. **Asset validation:** run `make release-assets` to check metadata limits, app-icon properties, screenshot dimensions, and source-name consistency.
7. **Release preflight:** run `make release-preflight`. It refuses a dirty worktree by default.

`ALLOW_DIRTY_RELEASE=YES` is an emergency override, not a normal workflow. Use it only when the user explicitly accepts that the uploaded binary is not tied to a clean commit.

The scripts also refuse a build number that is not newer than the recorded upload for the same marketing version. `ALLOW_EXISTING_BUILD=YES` is only for reproducing an old archive and must never be used to upload, because App Store Connect will not accept the duplicate build.

## Archive, Export, Validate, Upload

```bash
make archive
make export
make validate-upload
make upload
```

Artifacts default to versioned paths under `~/Library/Developer/Xcode/Archives/FlippingSevenCalculator/` and use `scripts/ExportOptions-AppStore.plist`. Ordinary `make clean` does not remove them. Preserve each uploaded archive and dSYM even after its exported IPA is no longer needed.

- `archive` creates a signed `.xcarchive` for generic iOS.
- `export` creates the App Store IPA.
- `validate-upload` asks App Store Connect to validate the IPA.
- `upload` transfers the binary. It does **not** attach the build to a version, submit it for review, or release it.

After upload, wait for processing and confirm the build reports a valid/eligible state before changing the version record.

## TestFlight Path

1. Upload and wait for processing.
2. Confirm export compliance and required beta metadata.
3. Add the build to an internal group for immediate team testing, or submit it for Beta App Review before external testing when required.
4. Record tester feedback against the exact build number.
5. Do not assume a TestFlight build is attached to the App Store version.

## App Store Path

1. Query the app, version, build, localization, screenshot-set, and submission records.
2. Verify the listing source in `APP_STORE_LISTING.md` and machine-readable values under `AppStoreAssets/<version>/` agree.
3. Verify privacy policy and support routes by rendered content, not HTTP status alone.
4. Attach the processed build to the intended version.
5. Recheck age rating, content rights, export compliance, privacy answers, review contact, review notes, and release method.
6. Upload or confirm screenshots for every required device family and active localization.
7. Add the version for review, inspect the draft submission, then submit it as a separate explicit action.
8. Confirm the returned submission and item states.
9. Record timestamp, version/build, release method, and status in the release record.
10. Update `AppStoreAssets/release-state.json` after a successful upload.
11. Send any required Apple Legal update with `APP264401-I` in the subject.

## Screenshots And Preview Media

- Capture deterministic real app state using the Debug-only fixture documented in `AppStoreAssets/<version>/README.md`.
- Use fictional names and original app artwork only.
- Verify exact pixel dimensions and upload order.
- Inspect the first three iPhone screenshots at search-result size; they carry the acquisition story when no App Preview is present.
- Do not upload a proof-of-concept video with dead space. App Previews must meet Apple's current duration, device, codec, and content rules at upload time.
- A listing-media update may be restricted while a version is waiting for review; query status before promising an in-place edit.

## Status Vocabulary

- **Archived:** a local signed archive exists.
- **Uploaded:** Apple received the binary.
- **Processed:** the build appears in App Store Connect.
- **Attached:** the processed build is selected for an app version.
- **Submitted:** a submission was sent to App Review.
- **Approved:** App Review accepted the version.
- **Released:** the version is publicly available in the intended storefronts.

Always report the exact achieved state. “Deployed” is too ambiguous for release communication.

## Failure Recovery

- Build/test failure: inspect the retained `.xcresult` with `make test-summary RESULT=...` or open it in Xcode.
- Signing failure: verify team, certificate, profile, key role, bundle ID, and Xcode account independently; do not rewrite project signing blindly.
- Upload rejection: preserve the complete delivery log and fix the reported binary/metadata issue before incrementing again.
- Processing delay: wait and query; do not repeatedly upload the same build number.
- App Review issue: preserve Apple's message, identify the exact guideline or metadata field, respond factually, and avoid changing unrelated surfaces.
- Customer crash: retrieve the complete Apple report, use the matching archive/dSYM, symbolicate it, and reproduce against the released build.

## Source Of Truth

- Release mechanics: this document
- Submitted listing values and status history: `APP_STORE_LISTING.md`
- Versioned screenshots and metadata: `AppStoreAssets/<version>/`
- Last known uploaded build lower bound: `AppStoreAssets/release-state.json`
- Product/legal constraints: `docs/APP264401-I-path-forward.md`
- Private credentials: secure local storage only, never this repository
