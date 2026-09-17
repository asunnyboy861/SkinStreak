# Pricing Configuration

## Monetization Model: Subscription (IAP) + One-Time BYO Buyout

Freemium with auto-renewable subscriptions (monthly/yearly under a 7-day full-feature trial) plus a single non-consumable lifetime buyout reserved for the Bring-Your-Own-Key mode. Free tier keeps the product's growth hooks (conflict detection, barcode, check-ins) permanently free and never paywalled.

## Subscription Group
- **Group Name**: SkinStreak Pro
- **Reference Name**: SkinStreak Pro
- **Products in group**: SkinStreak Pro Monthly, SkinStreak Pro Annual

## Subscription Tiers (Auto-Renewable)

### 1. Monthly Subscription
- **Reference Name**: SkinStreak Pro Monthly
- **Product ID**: `com.zzoutuo.SkinStreak.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $3.99 USD per month
- **Display Name**: `SkinStreak Pro Monthly` (22 chars, ≤35 ✅)
- **Description**: `Unlimited deep scans, AI scheduling, weekly reports` (52 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: SkinStreak Pro
- **Restore Purchases**: ✅ Required

### 2. Yearly Subscription (Main Tier)
- **Reference Name**: SkinStreak Pro Annual
- **Product ID**: `com.zzoutuo.SkinStreak.pro.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $19.99 USD per year (58% savings vs monthly)
- **Display Name**: `SkinStreak Pro Annual` (21 chars, ≤35 ✅)
- **Description**: `Unlimited deep scans, AI scheduling, weekly reports` (52 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: SkinStreak Pro (same group as monthly)
- **Restore Purchases**: ✅ Required
- **Differentiation Note**: Yearly is the promoted main tier — same features as Monthly at less than half the annualized cost, positioned as the transparent alternative to weekly-subscription competitors.

## One-Time Purchases (Non-Consumable)

### 1. SkinStreak Forever (BYO)
- **Reference Name**: SkinStreak Forever BYO
- **Product ID**: `com.zzoutuo.SkinStreak.forever.byo`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $39.99 USD (one-time)
- **Display Name**: `SkinStreak Forever` (18 chars, ≤35 ✅)
- **Description**: `All Pro features forever, use your own GLM API key` (51 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Differentiation Note**: Forever requires the user's own GLM API key (stored in Keychain; AI calls ride the user's channel, so the one-time price has no perpetual server cost). Subscriptions include the developer-subsidized AI channel with no key setup. Purchase flow surfaces key setup immediately after buying.

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - Unlimited ingredient conflict detection (local 200+ rule engine) — never paywalled
  - Unlimited barcode scanning + OBF ingredient lookups
  - Unlimited evening check-ins + streaks (with Streak Freeze)
  - Manual routine scheduling + progress photos (local)
  - 2 deep AI scans per week (rolling reset, full GLM quality — limited count, never limited quality)
- **Conversion hooks**:
  - Sunday aligned-photo reminder leads into the weekly Proof report (want more → Pro)
  - Soft paywall shown only when deep-scan quota is exhausted — closable, no countdown, free features unaffected
  - 7-day full-feature trial offered at quota exhaustion and in Settings

## Pro Features Unlocked (All Paid Tiers)

| Feature | Free | Pro (All Paid Tiers) |
|---------|:----:|:--------------------:|
| Ingredient conflict detection | ✅ Unlimited | ✅ Unlimited |
| Barcode scan + ingredient lookup | ✅ Unlimited | ✅ Unlimited |
| Evening check-ins + streaks | ✅ Unlimited | ✅ Unlimited |
| Deep AI scans | 2/week | ✅ Unlimited |
| AI smart scheduling (conflict avoidance + skin cycling calendar) | Manual only | ✅ Automatic |
| Weekly Proof report + trend attribution | ❌ | ✅ |
| Aligned photo comparison export/share | ❌ | ✅ |
| iCloud sync (CloudKit) | ❌ | ✅ (capability pending manual container setup — see capabilities.md) |
| Widgets | ❌ | ✅ (widget target added in code phase — see capabilities.md) |
| BYO GLM key (own channel, unlimited AI) | ✅ Available | ✅ Available |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial on the Annual subscription (auto-converts to paid; expires back to Free tier with free features never disabled; local notification 24h before trial end)
- **Available for**: SkinStreak Pro Annual

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page + one-tap Manage Subscription entry pinned at top of Settings
- [x] Pricing clearly stated in PaywallView (all three tiers, no obscured pricing)
- [x] Free trial terms included (7-day, auto-fallback to Free, 24h pre-expiry notice)
- [x] Restore purchases functionality implemented
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options (no competitor price comparisons in paywall)
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] BYO Key model: subscription value = app features (deep scans, scheduling, reports), never "unlock AI generations" for key owners; no free-generation counting (`freeGenerationsUsed` / `maxFreeGenerations` forbidden dead code)
