# SkinStreak - iOS Development Guide

> Source: TR-20260916-AI护肤（SkinStreak）操作指南.MD (researched 2026-09-16 via pain-point-hunter: App Store review corpus, r/SkincareAddiction, FTC/BMJ/Australian Psychological Society regulatory & academic evidence, Mordor Intelligence market data)
> Target: US market, women 18-34. Category: Health & Fitness (NOT Medical).

## Executive Summary

**SkinStreak** ("Skincare that proves it works") is an honest skincare coach iOS app combining **deterministic ingredient conflict detection + scheduled routine check-ins (streaks) + an evidence loop** (aligned before/after photos with attribution). It replicates and beats GlowUp (~$800K/yr, TikTok-driven) by converting that category's top complaint sources — vague advice, no execution loop, beauty-score anxiety, subscription traps — into four differentiators:

1. **Conflict Engine** (free forever): local deterministic 200+ rule engine flags clashes like Retinol × BPO in 0.1s. Nobody else gives this away.
2. **Streak check-ins + aligned proof photos**: Duolingo-style streaks with Streak Freeze (never shames).
3. **Zero beauty scores**: only relative-to-baseline trend % ("Progress, not ratings"). Fitzpatrick I-VI calibrated.
4. **Transparent pricing**: $19.99/yr vs competitors' ~$260/yr effective; 7-day full trial that falls back to Free (never silent rebill).

**Architecture philosophy**: "CV computes numbers, AI only interprets." All skin metrics come from an on-device deterministic CV pipeline; conflict verdicts come from a local rule engine (never the LLM); AI (Apple FM on-device + GLM-5.3-Flash cloud) only writes explanations. Free features are never paywalled.

**Key variables**: APP_NAME=`SkinStreak`, BUNDLE_ID=`com.zzoutuo.SkinStreak`, MIN_IOS=`17.0` (iOS 26-only APIs must be availability-gated with graceful fallback), GITHUB_USER=`asunnyboy861`, CONTACT_EMAIL=`iocompile67692@gmail.com`.

## Competitive Analysis

| App | Strengths | Weaknesses | Our Advantage |
|-----|-----------|------------|---------------|
| GlowUp (AI Skin Scanner, Eric Zeng) | TikTok growth machine, AI scan + routine | Advice ends at suggestion (no tracking loop), everything behind paywall, $4.99/wk ≈ $260/yr | Free conflict engine + streak closure loop + 1/13 price |
| Umax / LooksMax AI family | Viral "scoring" hooks | 26+ apps named by Australian Psychological Society for selling appearance anxiety; scores feel random ("same photo, different score"), repurchase-to-rescore | Zero scores; deterministic reproducible CV metrics; trends only |
| SkinVision / Skin360 (Neutrogena) | Medical-adjacent mole scanning | BMJ: mole-app accuracy rated "poor"; Skin360 paid $4.7M BIPA settlement over face data | Wellness-only positioning, no diagnosis, local-first biometric data, one-tap delete |
| INCIDecoder | Ingredient lookup authority (~#37,967 global rank proves demand) | No conflict detection, no routine tracking | Conflict detection (blue-ocean: `ingredients/conflict/checker` keywords unowned) |
| HadaBuddy | 150+ conflict rules | Rules behind $3.99/mo paywall, small DB, no analysis | 200+ rules free, integrated with scheduling avoidance |
| Luvly / Olive | Subscription monetization | No in-app cancel (£38→£78 rebill), trial charges without warning (FTC dark-pattern enforcement era) | In-app Manage Subscription, 24h pre-renewal notice, trial auto-falls back to Free |

## Apple Design Guidelines Compliance

- **Liquid Glass / system materials**: use `.glassEffect()` (iOS 26+) on conflict alert and schedule cards; fall back to `.ultraThinMaterial` below iOS 26.
- **Accessibility**: VoiceOver labels everywhere; conflict alerts use icon+text dual encoding (never color-only); Dynamic Type fully supported; trend numbers use monospacedDigit.
- **Haptics**: `.sensoryFeedback(.success, ...)` on check-in completion and LightGuard pass.
- **Privacy**: camera permission requested in context with plain-language explanation ("analyzed only on this device").
- **Health & Fitness category, not Medical**: fixed disclaimer "General wellness info, not medical advice." No mole/lesion diagnosis anywhere.
- **Dark-first**: app is used at night; default follows system with dim glass cards.

## ⚠️ App Store Compliance — AI Features

### Dual AI backend with mandatory degradation chain
- **L0 daily**: Apple FoundationModels (on-device, `@Generable` guided generation) — free, $0. Requires iOS 26+; on iOS < 26 fall back to template copy.
- **L2 deep weekly**: GLM-5.3-Flash via `https://api.z.ai/api/paas/v4/chat/completions` (OpenAI-compatible, vision + `json_object` mode). Developer-subsidized key ships via server proxy; user BYO key stored in Keychain only.
- **Degradation is mandatory**: GLM fail → Apple FM → template copy. The UI must NEVER dead-end.
- AI NEVER invents numbers: prompts explicitly forbid restating/altering CV metrics; every AI string is labeled "AI insight" in UI; metrics labeled "measured".

### BYO Key tier (SkinStreak Forever $39.99 non-consumable)
- Purchase requires/enables user-entered GLM key (Keychain). AI calls then ride the user's own channel.
- **No free-generation counting logic anywhere** (`freeGenerationsUsed`/`maxFreeGenerations` are forbidden dead code). Free tier quota applies ONLY to deep scans (2/week), enforced by `QuotaManager`, and never gates conflict engine/barcode/check-in/photos.
- Create `app_review_info.md` with reviewer demo-key instructions.
- Paywall must contain: Privacy Policy link, Terms of Use (EULA) link, title/length/price for each tier, auto-renewal disclosure.

## ⚠️ App Store Compliance — Subscriptions

- StoreKit 2: `skinstreak.pro.yearly` ($19.99, 7-day free trial, intro offer), `skinstreak.pro.monthly` ($3.99), `skinstreak.forever.byo` ($39.99 non-consumable).
- 7-day trial expiry → automatic fallback to Free tier (free features never disabled); local notification 24h before trial end and before renewal; Manage Subscription entry pinned at top of Settings.
- Paywall "three nevers": no countdown timers, no obscured pricing, no review-begging.

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Onboarding (4 screens) | 1. Launch first time → 2. Screen 1 value prop ("Skincare that proves it works." + transparent pricing) → 3. Screen 2 pick skin type (oily/dry/combination/sensitive) & goal → 4. Screen 3 pick Fitzpatrick I-VI card → 5. Screen 4 scan one existing product → 6. Enter Tonight page | Skin type, goal, Fitzpatrick grade, first barcode | Store profile; camera permission requested with local-analysis explanation | Personalized thresholds set; first conflict alert OR green confirmation within 30s | SwiftData `UserProfile` | ≤90s to first conflict alert/first check-in; no paywall in onboarding |
| 2 | Barcode scan → ingredients | Tap Scan button → VisionKit CodeScanner → barcode → 0.3s ingredient list from OBF cache/network | Barcode string | OBF API fetch + local cache; `IngredientParser` normalizes INCI → IDs → actives | Ingredient list with actives highlighted; "Add to Cabinet" button | SwiftData `Product`; OBF cache on disk | Cached result <0.5s; network fallback works; manual name-entry fallback path exists |
| 3 | Ingredient conflict engine (FREE forever) | Adding a product auto-runs `ConflictEngine.check(product, cabinet)` | Product actives | Local JSON rules (200+), deterministic, 0.1s; supports "a\|b" family syntax | Conflict findings: rule ID, severity (high/medium/low), mechanism, evidence grade A-D, source, resolution | SwiftData `ConflictLog` | Deterministic (same input → same output); <0.1s for 50 products; ZERO paywall code in this path |
| 4 | Conflict alert card | On conflict: half-sheet glass card shows ingredient-vs-ingredient visual + mechanism + evidence badge + source + 2 buttons: "Separate them" (recommended) / "Use anyway" | User choice | "Separate" → `scheduleAvoidance` moves product to opposite session/night; "Use anyway" → dismiss with log | Resolution applied to schedule | `RoutineSlot` update | User always has choice; no panic red; icon+text dual encoding |
| 5 | Tonight scheduling engine | Tonight page shows today's schedule card stream (AM/PM/skin-cycling night) | Cabinet + profile + conflict logs | `TonightEngine`: conflict avoidance + Skin Cycling template (exfoliation→retinoid→recovery→recovery, Dr. Whitney Bowe) + user goals | Tonight cards: product name + ingredient badges + "already separated" tag when avoidance applied | SwiftData `RoutineSlot` | Conflicts auto-avoided; skin cycling rotates correctly; empty state = big Scan button |
| 6 | Check-in flow + Streak | Open app at night → swipe each Tonight card to complete → all done → streak flame +1 with ring-charge animation + haptic | Swipe gestures per product | `StreakEngine.settle`: continued if yesterday checked; else consume Streak Freeze (2/month) to restore; else restart with kind copy | Streak count, flame UI, completion state | SwiftData `CheckIn` | Whole flow <10s for 3 products; break-day copy = "Day 1 — every glow-up starts here." (never red/shaming) |
| 7 | Streak Freeze | On missed day, next check-in auto-consumes 1 freeze card | FreezeWallet state | Monthly reset to 2 cards | Restored streak + "freeze used" toast | SwiftData `StreakState` | Max 2/month; restoration not reset-to-zero |
| 8 | Guided aligned selfie (LightGuard) | Proof tab → weekly reminder (Sunday local notification) → camera preview with ellipse alignment frame + last-photo ghost overlay at 30% opacity → LightGuard histogram QC (brightness within ±15% of baseline) → capture | Camera frames | Real-time brightness histogram/shadow check; status: tooDark / harsh / ok | Captured aligned photo + quality score | SwiftData `ProgressPhoto` (image Data + alignment landmarks, local-only) | Bad-light captures blocked with "one more try" copy; quality <threshold never saved |
| 9 | On-device CV metrics pipeline | After capture: face-parsing CoreML (BiSeNet 19-class) segments zones → redness pixel ratio, texture variance, spot count; thresholds per Fitzpatrick grade | Aligned image | Deterministic CV (CoreML + Vision), reproducible | `SkinMetrics` (rednessPct, textureVar, spotCount) tagged "measured" | SwiftData `SkinReport` metrics fields (ONLY CV writes these) | Same-lighting re-shot variance <±10%; Fitzpatrick IV-VI includes PIH-focused parameters |
| 10 | AI Router dual engine | Daily scan → L0 Apple FM note (iOS 26+, else template); Deep weekly scan (quota) → L2 GLM-5.3-Flash vision → merge qualitative only | CV metrics + (deep: image) | L0: `SkinCoachNote` @Generable; L2: `DeepSkinReport` JSON (observations zone/finding/evidenceGrade/source, one routineAdjustment validated by ConflictEngine before scheduling) | Coach note ("AI insight" label), deep report, fixed disclaimer | `SkinReport.coachNote` (AI-only field), `deepUsedGLM` flag | GLM fail → FM → template, never dead-end; AI output never changes metrics |
| 11 | Deep scan quota (2/week free) | Before deep scan: check rolling weekly quota; 2 dots under shutter show remaining | Usage timestamps | `QuotaManager` rolling 7-day window; free=2, Pro=unlimited | Allow/deny; deny → soft paywall sheet (7-day trial + both prices, closable, no countdown) | UserDefaults/SwiftData quota record | Quota never gates conflict engine/barcode/check-ins/photos; paywall dismissible without dark patterns |
| 12 | Proof weekly report | Weekly: aligned photo pair → trend % vs user's own baseline (redness/texture/spots with arrows) + attribution line ("redness down 18% — right around when you swapped that BPO combo") + evidence grades | SkinReport history + ProgressPhotos | Compute relative deltas; match timeline to conflict-log/schedule changes for attribution | Week report card; before/after slider on timeline | SwiftData `SkinReport` + `ProgressPhoto` | Trends only vs own baseline (never absolute score); exportable |
| 13 | Share/export proof card | Tap share on week report → IG Stories-size card with "proven by SkinStreak" watermark → UIActivityViewController | Report data + photos | Render share card image | Shared/exported card | none (temp file) | Card renders correctly in dark mode; watermark present |
| 14 | Paywall + StoreKit 2 (trial/monthly/yearly/BYO lifetime) | Soft paywall or Settings → plans: 7-day free full trial; Pro Yearly $19.99 (main); Pro Monthly $3.99; Forever BYO $39.99 one-time (requires own GLM key) | Purchase intents | StoreKit 2 `Transaction` listener + `Product.products(for:)`; trial expiry auto-falls to Free | Entitlement state; Pro features unlocked | StoreKit 2 + `EntitlementManager` | Sandbox purchase flow completes; cancel path = Settings top "Manage Subscription"; 24h pre-renewal local notification |
| 15 | Settings | Open Settings: subscription status + Manage at top; GLM BYO key input (Keychain note: "Key stays on your phone"); skin type / Fitzpatrick edit; "Delete all my data" red entry; Data Sources attribution (OBF/AAD/INCI dataset) | Various edits | Update profile; keychain write; cascade delete all SwiftData + photos | Confirmation states | All stores | One-tap full data deletion works; ODbL attribution visible |
| 16 | Privacy confirm before upload | Deep scan with image: explicit per-shot confirm dialog ("upload this one photo?") before GLM call | User consent | Gate network call | Proceed/abort | none | Default is L0 local; upload only after explicit confirm |
| 17 | CloudKit sync | Automatic background sync of non-biometric records | SwiftData changes | CloudKit private DB, E2E encrypted; photos stay local by default | Multi-device consistency | CloudKit | No account required; photo upload opt-in |
| 18 | Widgets | Widget gallery: small (flame + tonight count), medium (tonight 3 cards), lock-screen accessoryCircular (flame) | Shared app group data | WidgetKit timeline from tonight schedule + streak | Live widgets | App Group UserDefaults | Widgets reflect today's schedule; update after check-ins |
| 19 | Local notifications | Sunday weekly photo reminder; 24h-before trial end; 24h-before renewal | Schedule state | UNUserNotificationCenter scheduling | Timely reminders | none (system) | Never silent rebill; reminders match stated policy |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 2.1 | Barcode | Manual entry fallback | No result → manual product name search via OBF + local INCI dictionary | Tap "Enter manually" |
| 2.2 | Barcode | Active highlighting | INCI list highlights recognized actives with badges | View only |
| 4.1 | Conflict card | Schedule avoidance preview | Shows where product will move (AM/PM/opposite night) | Tap "Separate them" |
| 5.1 | Tonight | "Already separated" tag | Transparent algorithm display when avoidance applied | View only |
| 8.1 | LightGuard | Banner states | tooDark → "Find brighter light — move toward a window"; harsh → "Too much shadow — face the light, not away" | Auto |
| 9.1 | CV pipeline | Deep-skin PIH check | Fitzpatrick IV-VI prompts explicitly check post-inflammatory hyperpigmentation | Auto |
| 11.1 | Quota | Dots indicator | 2 dots under shutter showing weekly deep-scan remaining | View only |
| 14.1 | Paywall | BYO lifetime gating | Forever purchase surfaces key-setup flow immediately after | Purchase flow |
| 15.1 | Settings | BIPA-aware deletion | "Delete all my data" deletes biometric data + all records, no identity linkage ever existed | Tap → confirm |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Scan → Conflict check | Barcode scan (2) | Conflict engine (3) | Product + actives | On add-to-cabinet |
| Conflict → Schedule | Conflict card (4) | Tonight engine (5) | SlotMove resolution | "Separate them" tap |
| Cabinet → Tonight | Product added (2) | Tonight engine (5) | Product list | Cabinet change |
| Check-in → Streak | Check-in (6) | Streak (6/7) | CheckIn date | Every full/complete swipe |
| Photo → CV → Report | Selfie (8) | CV metrics (9) → AI (10) → Proof (12) | Aligned image → metrics → report | Capture saved |
| Quota → Paywall | Quota exhausted (11) | Paywall (14) | Deny event | Deep scan with 0 remaining |
| Purchase → Quota/AI | Paywall (14) | Quota (11) / AI router (10) | Entitlement | Transaction confirmed |
| Profile → CV thresholds | Onboarding (1) / Settings (15) | CV pipeline (9) | Fitzpatrick grade | Profile change |
| Conflict log → Proof attribution | Conflict engine (3) | Proof report (12) | Timeline events | Week report build |

**VERIFICATION**: 19 primary features vs guide sections (§2 flowcharts, §3 paths, §5 code specs, §8.2 screens) — ✅ MATCH (all guide-described features covered).

## Technical Architecture

- **Language**: Swift 5.9+, SwiftUI-first
- **Data**: SwiftData (local single source of truth) + CloudKit private DB sync (no account required)
- **CV-L0**: face-parsing CoreML (BiSeNet 19-class, from yakhyo/face-parsing ONNX → coremltools) + Vision framework; deterministic metric computation; Fitzpatrick-calibrated thresholds
- **AI-L0 copy**: FoundationModels `@Generable` (iOS 26+, availability-gated)
- **AI-L2**: GLM-5.3-Flash via api.z.ai OpenAI-compatible endpoint (vision + json_object), model ID hot-updatable; developer key behind server proxy, BYO key in Keychain
- **Barcode**: VisionKit CodeScanner (twostraws/CodeScanner pattern) + Open Beauty Facts API + local INCI dictionary fallback
- **Payments**: StoreKit 2 (pure; StoreHelper patterns), RevenueCat optional but NOT required
- **Min iOS**: 17.0 — all iOS 26 APIs (FoundationModels, `.glassEffect`, Liquid Glass) MUST be wrapped in `if #available(iOS 26.0, *)` with material/template fallbacks

## Module Structure

```
SkinStreak/
├── SkinStreakApp.swift            // App entry, SwiftData container, notifications setup
├── Views/
│   ├── Onboarding/                // 4-screen flow
│   ├── Tonight/                   // Home: schedule cards, streak flame, scan button
│   ├── Scan/                      // Barcode scanner, result page, manual entry
│   ├── Conflict/                  // Alert card, resolution buttons
│   ├── Capture/                   // GuidedCaptureView, LightGuard banners
│   ├── Proof/                     // Timeline, before/after slider, week report, share card
│   ├── Paywall/                   // Plans, trial, BYO lifetime, legal links
│   └── Settings/                  // Subscription, BYO key, profile, delete all, attributions
├── Models/                        // Product, RoutineSlot, CheckIn, SkinReport, ProgressPhoto, ConflictLog, UserProfile, StreakState
├── Services/
│   ├── ConflictEngine.swift       // 200+ JSON rules, deterministic
│   ├── IngredientParser.swift     // INCI normalization
│   ├── OBFApiClient.swift         // Open Beauty Facts + cache
│   ├── LightGuard.swift           // histogram QC
│   ├── CVPipeline.swift           // CoreML segmentation + metrics
│   ├── AIRouter.swift             // L0/L2 dual engine + degradation chain
│   ├── GLMClient.swift            // api.z.ai client (BYO + proxy)
│   ├── QuotaManager.swift         // 2/week rolling deep-scan quota
│   ├── StreakEngine.swift         // streak settle + FreezeWallet
│   ├── TonightEngine.swift        // schedule + skin cycling + avoidance
│   ├── EntitlementManager.swift   // StoreKit 2
│   └── NotificationScheduler.swift
├── Resources/
│   └── conflict_rules.json        // 200+ rules with evidence grades & sources
└── Widgets/                       // small/medium/lock-screen
```

## ⚠️ Data Flow Diagram (MANDATORY)

```
Feature: Barcode Scan → Conflict Verdict
User Input (camera barcode)
  → ScanViewModel → OBFApiClient (cache first, 0.3s) → IngredientParser (INCI→IDs→actives)
  → ConflictEngine.check(product, cabinet) [deterministic JSON rules, 0.1s]
  → ConflictFindings → UI: green confirmation card OR red-less alert half-sheet
  → Persistence: SwiftData Product + ConflictLog
  → Cross-feature: findings → TonightEngine (avoidance) → Tonight cards

Feature: Check-in → Streak
User Input (swipe card complete)
  → TonightViewModel → CheckIn record → StreakEngine.settle(history)
  → continued | frozenRestored(FreezeWallet.consume) | restarted(1, kind copy)
  → Persistence: SwiftData CheckIn + StreakState → UI: flame +1 ring animation + haptic

Feature: Selfie → Proof
User Input (aligned capture, LightGuard QC passed)
  → CaptureViewModel → CVPipeline (CoreML 19-class + Fitzpatrick thresholds)
  → SkinMetrics (deterministic, "measured") → AIRouter
      ├ daily → Apple FM @Generable SkinCoachNote (iOS 26+) | template fallback
      └ deep → QuotaManager check → confirm dialog → GLMClient → DeepSkinReport JSON
        → ConflictEngine validates routineAdjustment before scheduling
  → Persistence: SwiftData SkinReport (CV fields vs coachNote strictly separated, deepUsedGLM flag)
  → ProofViewModel: weekly delta vs own baseline + attribution from ConflictLog timeline → share card

Feature: Purchase
User Input (plan tap) → PaywallViewModel → StoreKit 2 purchase
  → EntitlementManager updates → QuotaManager unlimited / AI router Pro paths
  → trial expiry → auto fallback Free (local notification 24h before)
```

## Implementation Flow

1. Data models (SwiftData) + app entry + profile/onboarding
2. OBF client + barcode scan + IngredientParser
3. ConflictEngine + conflict_rules.json (first 80, then 200+) + alert UI
4. TonightEngine + Skin Cycling template + check-in + StreakEngine/FreezeWallet
5. LightGuard + GuidedCaptureView + CVPipeline (CoreML) + SkinReport
6. AIRouter + GLMClient + QuotaManager + degradation chain
7. StoreKit 2 paywall + EntitlementManager + notifications
8. Proof timeline + share card + Settings + delete-all + attributions
9. Widgets + CloudKit sync + accessibility pass

## UI/UX Design Specifications

- **Palette (anti-anxiety)**: primary Sage `#7C9A83`; warm sand background; conflict coral `#E5695E` (never pure red); streak flame amber. "Clinical calm" — never purple/pink anxiety gradients.
- **Typography**: SF Pro; trend numbers `.largeTitle` + monospacedDigit.
- **Layout**: one screen = one task (Tonight / Cabinet / Proof); all primary actions in bottom 2/3 thumb zone.
- **Materials**: glass cards (`.glassEffect()` iOS 26+, `.ultraThinMaterial` fallback); dark-mode first.
- **Copy (Proof voice)**: empty state "Add your first product — conflict check takes 0.3 seconds."; conflict "Heads up — these two cancel each other out. Want me to separate them?"; break "Day 1 — every glow-up starts here."; low light "The light's a bit off — one more try so your progress is real."; fixed disclaimer "General wellness info, not medical advice."

## Code Generation Rules

1. Conflict verdicts ONLY from local rule engine; discard any LLM conflict judgment (AI explains, never decides).
2. CV-metric fields and AI-copy fields strictly separated; UI labels "measured" vs "AI insight".
3. Every AI path must degrade: GLM → Apple FM → template. Never dead-end.
4. All photo intake passes LightGuard; sub-threshold captures never persist.
5. Evidence grade A/B/C/D is a hard field — no source, no display.
6. **Zero beauty scores**: no 1-10 beauty score concept anywhere in codebase; only relative-to-baseline trends.
7. **Free features never gated**: no paywall checks in ConflictEngine/OBF/check-in/photo paths.
8. Privacy: explicit confirm before any image upload; keys in Keychain; "Delete all my data" required.
9. StoreKit trial must fall back to Free with 24h notice; no silent rebilling.
10. GLM model ID must be hot-updatable (validate api.z.ai image_url + json_object before launch; on failure switch model ID only, architecture unchanged).
11. iOS 26-only APIs availability-gated with functional iOS 17 fallbacks.
12. Version strings always read from `Bundle.main.infoDictionary` — never hardcode.

## Build & Deployment Checklist

- [ ] Bundle ID `com.zzoutuo.SkinStreak`; min iOS 17.0; Health & Fitness category
- [ ] Camera usage description (local-analysis wording); FaceID not required
- [ ] CloudKit + Push (remote notifications for sync) + Background Modes capabilities
- [ ] IAP products configured: yearly trial, monthly, BYO lifetime
- [ ] conflict_rules.json bundled + version/source annotated
- [ ] ODbL attribution in Settings (Open Beauty Facts)
- [ ] app_review_info.md with demo-key instructions
- [ ] Privacy labels: face data processed on-device, not linked to identity, deletable
- [ ] Illinois BIPA consent copy for face capture
- [ ] Zero-score audit: grep codebase for score concepts
- [ ] Free-path audit: no entitlement checks in free feature call graphs
