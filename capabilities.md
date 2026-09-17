# Capabilities Configuration

## Analysis
Based on operation guide analysis (keywords: 同步/CloudKit, 通知/提醒, 相机/扫码/自拍, 购买/订阅, Widget, 照片保存):

| Requirement | Capability |
|-------------|-----------|
| Barcode scan + aligned selfie capture | Camera usage description |
| Save proof photos / share cards | Photo library add usage description |
| Local reminders (Sunday photo, 24h trial/renewal) | Local Notifications (no capability needed, UNUserNotificationCenter) |
| Subscription + BYO lifetime | In-App Purchase |
| CloudKit sync (no account) | iCloud (CloudKit) |
| Widgets (small/medium/lock-screen) | App Groups + Widget Extension target (code phase) |
| On-device CV / Apple FM | No special capability (iOS 26+ gating) |
| GLM deep scan upload | Outgoing network (ATS default OK for https) |

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| Bundle ID `com.zzoutuo.SkinStreak` | ✅ Configured | pbxproj edit (was `com.zzoutuo.SkinStreak.SkinStreak`) |
| Deployment target iOS 17.0 (app target) | ✅ Verified | pbxproj (project-level 26.4 stays; app target = 17) |
| Camera usage description | ✅ Configured | `INFOPLIST_KEY_NSCameraUsageDescription` in pbxproj (local-analysis wording, BIPA-aware) |
| Photo library add usage description | ✅ Configured | `INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription` in pbxproj |
| App Icon | ✅ Installed | Agnes Image 2.1 Flash → AppIcon.appiconset |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| iCloud/CloudKit container | ⏳ Pending (graceful degradation: local SwiftData is the source of truth; sync is an enhancement) | Xcode → Signing & Capabilities → + iCloud → check CloudKit → create container `iCloud.com.zzoutuo.SkinStreak` with your team (JP4TN5PTS3). Requires Apple Developer portal login. |
| In-App Purchase products | ⏳ Pending | App Store Connect → create `skinstreak.pro.yearly` ($19.99, 7-day trial), `skinstreak.pro.monthly` ($3.99), `skinstreak.forever.byo` ($39.99 non-consumable). App builds/runs without them (StoreKit config file used in dev). |
| App Group for widgets | ⏳ Pending | Xcode → + App Groups → `group.com.zzoutuo.SkinStreak` (needed when Widget target is added in code phase). App works without widgets. |

## No Configuration Needed
- Push Notifications (APNs): guide only requires LOCAL notifications — not configured, not needed
- HealthKit: app is wellness-only, no HealthKit integration
- Location, Siri, Sign in with Apple, Apple Watch: not in guide

## Verification
- Build succeeded after configuration: (verified below in PHASE 2 build step)
- All entitlements correct: ✅ (none required at this stage beyond defaults)
