# SkinStreak — Configuration Reference

Generated: 2026-09-17 (PHASE 8.5 launch checklist)

**Default-to-working guarantee**: SkinStreak is fully functional the moment it is downloaded, with zero manual configuration. Conflict detection (68 bundled rules), barcode scanning, check-ins, streaks, photos, and local reminders all work out of the box. AI deep scans degrade gracefully through a three-step chain — your own optional GLM key → Apple Intelligence (on-device, iOS 26+) → deterministic template report — so the app never dead-ends. Everything in the manual section below is an **enhancement** (sync, real purchases, subsidized AI), never a requirement for basic use.

---

## ⚠️ Manual Configuration Required (read this first — enhancements only)

### 1. iCloud CloudKit Container — cross-device sync

| | |
|---|---|
| **Unlocks** | Automatic background sync of non-biometric records (products, check-ins, streaks, reports) to iCloud. Sync is a Pro feature. Photos stay on-device by default. |
| **Without it** | Local SwiftData is the single source of truth. The app runs normally; data simply stays on one device. |
| **Current state** | Graceful degradation already coded. Local storage is the default; nothing breaks unconfigured. |

**Prerequisite**: a **paid** Apple Developer Program membership (see item 5). Team `JP4TN5PTS3` is already set in the project.

**Steps (Xcode — one time, ~2 minutes)**:
1. Sign in to Xcode with the Apple ID for team `JP4TN5PTS3`: Xcode → **Settings…** → **Accounts**.
2. Open `SkinStreak/SkinStreak.xcodeproj` in Xcode.
3. In the Project navigator, select the project → select the **SkinStreak** app target → **Signing & Capabilities** tab.
4. Confirm **Team** = `JP4TN5PTS3` and **Automatically manage signing** is checked.
5. Click **+ Capability**, then double-click **iCloud**.
6. In the iCloud section, check **CloudKit**, then under **Containers** click **+** → **Specify container name…** → enter `iCloud.com.zzoutuo.SkinStreak` → **OK**. Xcode registers the container with the Developer portal automatically.
7. If Xcode cannot register it, do it on the web: https://developer.apple.com → **Certificates, Identifiers & Profiles** → **Identifiers** → select `com.zzoutuo.SkinStreak` → enable **iCloud** (with **CloudKit**) → **Configure** → create container `iCloud.com.zzoutuo.SkinStreak` → assign it to the App ID.
8. ⚠️ Rebuild and run on a device to verify (see Verification below).

### 2. In-App Purchase Products — App Store Connect

| | |
|---|---|
| **Unlocks** | Real purchases: Pro Yearly, Pro Monthly, and Forever BYO. |
| **Without it** | Users stay on the fully-featured Free tier (conflict engine, barcode, check-ins, photos — never paywalled) plus 2 deep scans/week. In development, purchases work via the committed `SkinStreak.storekit` file — no ASC needed to build/run/test. |

**Steps (App Store Connect)**:
1. Sign in at https://appstoreconnect.apple.com → **My Apps** → **SkinStreak** → **Monetization** → **Subscriptions**.
2. Click **+** to create a subscription group named `SkinStreak Pro`.
3. Inside the group, click **+** to create the annual product:
   - Reference Name: `SkinStreak Pro Annual`
   - Product ID: `com.zzoutuo.SkinStreak.pro.yearly`
   - Subscription duration: **1 Year**, price **$19.99**
   - Localization (English US): Display Name `SkinStreak Pro Annual`; Description `Unlimited deep scans, AI scheduling, weekly reports`
   - **Offer**: introductory offer → **Free Trial**, **7 days**
4. Create the monthly product in the same group:
   - Reference Name: `SkinStreak Pro Monthly`
   - Product ID: `com.zzoutuo.SkinStreak.pro.monthly`
   - Duration **1 Month**, price **$3.99**, same Display Name / Description pattern as above
5. For the one-time buyout: **Monetization** → **In-App Purchases** → **+ Create** → Type **Non-Consumable**:
   - Reference Name: `SkinStreak Forever BYO`
   - Product ID: `com.zzoutuo.SkinStreak.forever.byo`
   - Price **$39.99**
   - Localization: Display Name `SkinStreak Forever`; Description `All Pro features forever, use your own GLM API key`
6. Products enter **Waiting for Review** and go live when the first app version is submitted. All three Product IDs already match the StoreKit 2 code and `SkinStreak.storekit` (committed to the repo).
7. A **Restore Purchases** button already exists in Settings — use it to verify the flow after setup.

### 3. Developer-Subsidized GLM Channel — built-in AI deep scans

| | |
|---|---|
| **Unlocks** | Deep AI scans that work for Pro subscribers with **no key setup at all** (you subsidize the GLM-5.3-Flash usage via your own key held server-side). |
| **Without it** | Deep scans still work via the degradation chain: user's own GLM key (entered in **Settings → AI key**, stored in the iOS Keychain) → Apple FoundationModels (on-device, iOS 26+) → deterministic template report. BYO mode needs **zero developer setup**. |

**Current state in code**: `SkinStreak/SkinStreak/Services/GLMClient.swift` calls `https://api.z.ai/api/paas/v4/chat/completions` directly with the user's Keychain key (BYO path — works today). There is no server proxy yet.

**Steps**:
1. Obtain a GLM API key from https://z.ai (do **not** embed it in the app bundle — keys in an IPA can be extracted).
2. Deploy a small server-side proxy (e.g., a Cloudflare Worker) that accepts the app's chat-completions requests, injects `Authorization: Bearer <your GLM key>` server-side, and forwards to `https://api.z.ai/api/paas/v4/chat/completions` (OpenAI-compatible; must pass through `json_object` mode and image payloads for deep scans).
3. Point the app's built-in subsidized path at your proxy URL (update `GLMClient.endpoint` or ship a bundled config), keeping the BYO path on the user's own key.
4. Rebuild and verify a deep scan completes with no user-entered key.

### 4. App Group — `group.com.zzoutuo.SkinStreak` (widgets, later)

| | |
|---|---|
| **Unlocks** | Home-screen / lock-screen widgets (flame + tonight count, tonight cards) once a Widget Extension target is added in a future code phase. |
| **Without it** | No widgets — the app itself is 100% functional. |

**Steps**: when the widget target is added — Xcode → select **both** the app target and the widget target → **Signing & Capabilities** → **+ Capability** → **App Groups** → **+** → enter `group.com.zzoutuo.SkinStreak`. Xcode registers it with the portal automatically. ⚠️ Rebuild afterward.

### 5. Apple Developer Program Membership (paid) — prerequisite for items 1 and 2

CloudKit container registration (item 1) and In-App Purchase products (item 2) require a **paid** Apple Developer Program membership; free accounts cannot create containers or IAPs. Team `JP4TN5PTS3` is already configured in the project — once enrolled, no further action is needed for this item itself.

---

## ✅ Auto-Configured (already done — no action needed)

| Item | Detail | Status |
|------|--------|:------:|
| Bundle ID | `com.zzoutuo.SkinStreak` (fixed from doubled `SkinStreak.SkinStreak` via pbxproj) | ✅ |
| Deployment target | iOS 17.0 on the app target (iOS 26-only APIs availability-gated with graceful fallback) | ✅ |
| Camera usage description | `NSCameraUsageDescription` via `INFOPLIST_KEY_NSCameraUsageDescription` — plain-language, BIPA-aware, "analyzed only on this device" | ✅ |
| Photo library add usage description | `NSPhotoLibraryAddUsageDescription` via pbxproj | ✅ |
| App icon | Generated with Agnes Image 2.1 Flash → installed in `AppIcon.appiconset` | ✅ |
| Conflict rule engine | 68 deterministic rules bundled in `Resources/conflict_rules.json` — free forever, zero network | ✅ |
| StoreKit test config | `SkinStreak.storekit` committed with all 3 products for local/sandbox testing without ASC | ✅ |
| Local notifications | UNUserNotificationCenter (no capability required) — Sunday photo reminder, 24h pre-trial-end, 24h pre-renewal | ✅ |
| Outgoing networking | ATS defaults OK for HTTPS (`api.z.ai`, Open Food Facts lookups); no exceptions needed | ✅ |
| Repo hygiene | `.gitignore` protects `.env`, `keytext*.md`, `COMPETITOR_REPORT.md`, secrets/signing material | ✅ |
| Policy pages | Live at https://asunnyboy861.github.io/SkinStreak/ — support.html / privacy.html / terms.html all verified HTTP 200 (branch-based Pages from `/docs`) | ✅ |
| GitHub repo | Pushed to https://github.com/asunnyboy861/SkinStreak (`main`) | ✅ |

## Not Needed (verified against the product spec)

- **Push Notifications (APNs)** — all reminders are LOCAL notifications; APNs not configured, not needed
- **HealthKit** — wellness-only app, no HealthKit integration
- **Location / Siri / Sign in with Apple / Apple Watch / Background Modes** — not in the spec
- **WeatherKit** — no weather features
- **App Group (today)** — only becomes relevant with the future widget target (manual item 4)

## Verification

**Already verified (PHASE 6)**: iPhone 16 (iOS 26.4.1 simulator, Debug) BUILD SUCCEEDED; install + launch test passed (onboarding rendered, process alive); iPad Pro 13-inch (M5) build-only succeeded; secret-leak scan of staged content and tracked files clean.

**Checklist after each manual item**:
1. **CloudKit**: run on a real device → no CloudKit entitlement error at launch; install on a second device signed into the same iCloud account and confirm data appears.
2. **IAP**: in Xcode, scheme → **Run** → **Options** → StoreKit Configuration = `SkinStreak.storekit` → complete a sandbox purchase + **Restore Purchases** in Settings. After ASC setup, verify products load with the config option off (TestFlight/sandbox).
3. **GLM proxy**: with no user key entered, run a deep scan → full report produced through the subsidized path; confirm the degradation chain still works by removing the proxy.
4. **App Group**: after adding the widget target, widgets appear in the gallery and update after check-ins.
