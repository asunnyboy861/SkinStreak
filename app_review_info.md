# App Review Information — SkinStreak

## App Summary
SkinStreak ("Skincare that proves it works") is a skincare routine and progress tracker. Users log products, get ingredient-conflict warnings, follow a skin-cycling night plan, check in daily for streaks, and take weekly aligned selfies with on-device measurements (redness / texture / spots) tracked against their own baseline only. There are no beauty scores.

## Does the app work without any API key or account?
**Yes.** The app is fully functional immediately after download:

- Onboarding, product cabinet, manual product entry, and the conflict engine (68 built-in rules bundled in the app) require no key, no account, no network.
- Daily coach notes run through a three-step degradation chain: Apple Intelligence (on-device, iOS 26+) → template coach. If neither AI path is available, the deterministic template coach still produces the note. The app never dead-ends.
- Deep scans (2 per week free) follow the same chain: the user's own optional API key → Apple Intelligence → deterministic template report. Every path produces a full deep report.
- The optional GLM API key is **bring-your-own** and stored only in the iOS Keychain on the user's device. Reviewers do not need any key — leaving Settings → "Your own AI key" empty exercises the on-device and template paths, which are the default experience.

## Reviewer Notes
- **Simulator:** the camera is unavailable in the simulator; on a real device the guided selfie capture works normally (front camera, alignment ellipse, light-quality guard). Barcode scanning also requires a device camera; **Manual entry** in Cabinet → + covers the same flow without a camera.
- **Purchases:** three IAP products — Pro Yearly $19.99 with 7-day free trial, Pro Monthly $3.99, Forever BYO one-time $39.99 — are configured in the included `SkinStreak.storekit` for sandbox/testing. Free tier keeps conflict checks, streaks, check-ins and photos forever; Pro unlocks unlimited deep scans, the Weekly Proof report, and share cards.
- **Photo uploads:** only a deep scan can upload a photo, and only after an explicit "Upload this one photo?" confirmation each time, using the user's own API key. Apple Intelligence deep scans never leave the device.
- **Contact Support** posts name/email/subject/message to the developer's feedback endpoint; it is used solely to reply to the user.
- The app shows a fixed disclaimer ("General wellness info, not medical advice.") on measurement and AI screens.

## Data
All user data (products, photos, reports, streaks) is stored locally in SwiftData. No developer server receives user content. Policy pages: https://asunnyboy861.github.io/SkinStreak/privacy.html and https://asunnyboy861.github.io/SkinStreak/terms.html
