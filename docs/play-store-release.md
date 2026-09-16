# Google Play release verification

## Code changes

- API 36 and NDK 28 configuration retained from the current checkout.
- Release builds use the upload key only; missing signing credentials fail validation.
- Removed unused Firebase Analytics and explicitly excluded broad media/storage and advertising-ID permissions from manifest merging.
- Production network configuration requires HTTPS; local HTTP and user certificate exceptions exist only in debug resources.
- Native authentication tokens migrate out of SharedPreferences into secure storage. Android backup is disabled to avoid backing up private app data.
- Reporting failures remain visible and retryable; success is shown only after backend acceptance. No unverified moderation turnaround promise.
- Fixed both account-deletion URLs, third-party privacy disclosures, and location disclosure.
- Repaired mojibake in regional-language ARB files and regenerated localizations.

## Required before publishing

1. Supply `android/key.properties` using the template and the existing Play upload key. Do not generate a replacement for an existing app without following Play's upload-key reset process. Paths in `storeFile` are relative to `android/app`.
2. Use Java 17 for this project's Gradle version. Build a fresh release AAB; the old bundle does not represent these fixes. Confirm the version code is unused in Play Console.
3. Inspect the final merged manifest and App Bundle Explorer: API 36, intended permissions, upload certificate, and 16 KB compatibility. Test on a 16 KB emulator/device.
4. Verify `/api/reports` accepts authenticated reports, delivers them to moderators, and supports effective provider blocking. Client-side listing hiding is not a substitute for backend moderation.
5. Verify account deletion removes associated profile/listing/image data and revokes sessions according to the published retention policy. Do not claim deletion compliance based on an HTTP success response alone.
6. Use `https://agrifarms.in/delete-account` in Play Console; verify that it supports a request without installing the app. Synchronize the hosted privacy policy with the app disclosures.
7. Supply reusable, isolated reviewer accounts for both Farmer and Owner in Play Console App access. Configure review access securely on the backend; do not add a universal OTP bypass to the app.
8. Complete Data safety from actual app/backend/SDK behavior, including personal details, location, photos, booking data, notifications, translation, and geocoding. Check advertising-ID declarations against the rebuilt artifact.
9. Confirm store screenshots/features, target audience and content rating match the app. Test booking, uploading, denied permissions, reporting, logout, deletion, and all languages on Android.

## Scope

No backend or Play Console configuration is present here. The client cannot prove server-side deletion, moderation, retention, reviewer access, or production data security. Existing privacy-policy retention promises must be checked against the backend.

## Verification performed

- `flutter test --no-pub`: 4 tests passed (native token migration/cleanup, failed and accepted reports, unauthenticated privacy access).
- `flutter analyze --no-pub`: no errors; 510 warning/information diagnostics remain across the project.
- Java 17 Gradle debug and release manifest generation: passed. Release manifest inspected: target API 36, backup disabled, network security resource configured, no broad media/storage or advertising-ID permissions.
- `:app:validateReleaseCredentials`: failed with the intended missing `android/key.properties` message, confirming the guard. For release manifest inspection only, this task was excluded; no signed release artifact was produced.
- `git diff --check`: passed.
