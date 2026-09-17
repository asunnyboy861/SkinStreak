# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | SkinStreak |
| **Git URL** | git@github.com:asunnyboy861/SkinStreak.git |
| **Repo URL** | https://github.com/asunnyboy861/SkinStreak |
| **Visibility** | Public |
| **Default Branch** | main |
| **Initial Commit** | 6ba418d — "SkinStreak v1.0 — conflict engine, streaks, proof loop, StoreKit 2" |
| **Primary Language** | Swift (SwiftUI + SwiftData, iOS 17.0+) |
| **GitHub Pages** | ✅ Active (deploying from `/docs` on `main` via branch-based Pages build) |

## Build & Test Results (PHASE 6)

| Check | Result |
|-------|--------|
| iPhone build (iPhone 16, iOS 26.4.1 sim, Debug) | ✅ BUILD SUCCEEDED |
| iPhone run test (install + launch `com.zzoutuo.SkinStreak`) | ✅ Launched, process stayed alive, onboarding rendered |
| iPad build (iPad Pro 13-inch (M5), Debug) | ✅ BUILD SUCCEEDED (build-only) |
| Simulator cleanup | ✅ `after_test` erase of iPhone 16 (C77A1FB3-01CA-4997-A077-95CFB85AEDBB); iPad was never booted |
| Secret-leak scan (staged content + tracked files) | ✅ Clean |

## Policy Pages (Deployed from Main Repository /docs — PHASE 7 ✅ 2026-09-17)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/SkinStreak/ | ✅ Active |
| Support | https://asunnyboy861.github.io/SkinStreak/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/SkinStreak/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/SkinStreak/terms.html | ✅ Active |

> Deployed via branch-based Pages build (`/docs` on `main`). No Actions workflow committed — `actions/deploy-pages@v4` requires Pages `build_type: workflow` and would fail on every push under branch mode.
> Landing page download button uses `href="#"` placeholder (APP_STORE_ID comment in `docs/index.html`) until the app is live on App Store Connect.

## Repository Structure

```
SkinStreak/
├── SkinStreak/                    # iOS App Source Code
│   ├── SkinStreak.xcodeproj/      # Xcode Project
│   ├── SkinStreak/                # Swift Source (36 files)
│   │   ├── Models/                # SwiftData models (Product, CheckIn, StreakState, ...)
│   │   ├── Services/              # ConflictEngine, AIRouter, GLMClient, StreakEngine, ...
│   │   ├── Views/                 # Cabinet, Scan, Tonight, Proof, Paywall, Settings, ...
│   │   ├── Support/               # Theme
│   │   └── Resources/             # conflict_rules.json
│   ├── SkinStreak.storekit        # StoreKit 2 test configuration (IAP products)
│   ├── SkinStreakTests/
│   └── SkinStreakUITests/
├── us.md                          # Translated operation guide (product spec)
├── price.md                       # Pricing / IAP strategy
├── capabilities.md                # Capabilities config status
├── icon.md                        # App icon generation record
├── app_review_info.md             # App Review information
├── nowgit.md                      # This file
├── docs/                          # ✅ Policy pages + landing (live via GitHub Pages)
└── .gitignore
```

## Excluded from Repo (.gitignore)

| File | Reason |
|------|--------|
| `.env` | Secrets (GitHub token) |
| `keytext*.md` | Confidential ASO strategy |
| `COMPETITOR_REPORT.md` | Confidential competitor analysis |
| `TR-*.MD` | Original Chinese source guide |
| `GLMSecret.txt`, `Secrets.plist`, `*.p8`, `*.pem`, `*.mobileprovision` | Secrets / signing material |
| `xcuserdata/`, `DerivedData/`, `.DS_Store` | Build noise |

## Pending Items

| Item | Status | Unblocked By |
|------|--------|--------------|
| Policy pages live URLs (GitHub Pages) | ✅ Active — deployed 2026-09-17 (branch `/docs` mode) | PHASE 7 complete |
| CloudKit container `iCloud.com.zzoutuo.SkinStreak` | ⏳ Pending | Manual Xcode setup (capabilities.md) |
| IAP products in App Store Connect (`skinstreak.pro.yearly` / `skinstreak.pro.monthly` / `skinstreak.forever.byo`) | ⏳ Pending | PHASE 8.5 App Store metadata / manual ASC setup |
| App Group `group.com.zzoutuo.SkinStreak` (widgets) | ⏳ Pending | Widget target phase |
