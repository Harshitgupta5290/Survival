# Survival: Hunter Chronicles — Full Roadmap to Millions

> Target: ₹1 Crore+ revenue within 18 months of mobile launch  
> Game: 2D side-scrolling action shooter (Godot 4.2)  
> Platforms: Android → iOS → Web → Steam

---

## Table of Contents

- [Phase 1 — Fix & Polish (Weeks 1–4)](#phase-1)
- [Phase 2 — Content Expansion (Weeks 5–10)](#phase-2)
- [Phase 3 — Monetization Integration (Weeks 9–12)](#phase-3)
- [Phase 4 — Platform Launch Strategy (Weeks 12–16)](#phase-4)
- [Phase 5 — Marketing & Community (Ongoing)](#phase-5)
- [Phase 6 — Scale & Revenue Optimization (Month 5+)](#phase-6)
- [GitHub Actions CI/CD Plan](#cicd)
- [Revenue Projections](#revenue)
- [Tools & Resources](#tools)

---

## Phase 1 — Fix & Polish {#phase-1}
### Weeks 1–4 | Goal: Make it feel like a real game

### Critical Bug Fixes
- [ ] Wire `ai_director.gd` into `game.gd` — Endless Mode is broken (never called)
- [ ] Connect Settings menu sliders to actual AudioManager functions
- [ ] Enable double jump (buffer system already coded, just disabled)
- [ ] Fix `critical_hit` parameter — it exists in damage_number.gd but is never passed
- [ ] Fix Endless Mode loop — AIDirector.tick() must be called from game loop
- [ ] Add error handling for missing level CSV files (silent fail in world.gd)

### Game Feel Upgrades (Highest ROI)
- [ ] Add **knockback** on player hit (velocity impulse away from damage source)
- [ ] Add **knockback** on enemy hit (enemies stagger when shot)
- [ ] Add **muzzle flash** particle (node exists in player.gd, wire it up)
- [ ] Add **bullet impact sparks** on wall hit
- [ ] Add **blood/hit particles** on enemy damage
- [ ] Increase screen shake intensity on boss hits (+30%)
- [ ] Add **death slow-motion** (time_scale 0.3 for 0.5s on player death)
- [ ] Add **level complete fanfare** animation before transition

### Audio Overhaul
- [ ] Add hit sound (enemy taking damage)
- [ ] Add player hurt sound
- [ ] Add death sound (player)
- [ ] Add boss phase transition sound
- [ ] Add combo sound (escalating pitch per combo level)
- [ ] Add UI button click sounds
- [ ] Add footstep sounds (player running)
- [ ] Add grenade bounce sound
- [ ] Add level complete music sting
- [ ] Add boss intro sound
- [ ] **Add boss-specific music track** (switches on boss spawn)
- [ ] Source from: freesound.org, pixabay.com/music, zapsplat.com (all free/CC)

### Visual Overhaul
- [ ] **Differentiate enemy visuals** — 3 distinct enemy sprites (Grunt/Elite/Grenadier)
- [ ] Add player character face/portrait in HUD corner
- [ ] Add health bar damage flash (white flash before drain)
- [ ] Add tile border/outline shader for depth
- [ ] Add animated background elements (birds, clouds moving)
- [ ] Add dust particles on player land
- [ ] Add climb/ledge grab animation placeholder
- [ ] Replace placeholder button sprites with polished UI kit
- [ ] Add game logo on main menu (stylized font + artwork)

---

## Phase 2 — Content Expansion {#phase-2}
### Weeks 5–10 | Goal: Give players reasons to keep playing

### New Gameplay Features
- [ ] **Skill Tree** — 3 trees (Speed/Power/Survival), 5 nodes each, unlocked with XP
- [ ] **Critical Hits** — 15% chance, 2x damage, distinct visual + sound
- [ ] **Headshot system** — upper hitbox = 1.5x damage
- [ ] **Dash/Dodge** mechanic (short iframe roll, 1s cooldown)
- [ ] **4th weapon: Rocket Launcher** — slow fire, huge AOE, rare ammo
- [ ] **Shield pickup** — temporary damage absorption
- [ ] **Rage Mode** — fill rage meter on kills, activate for 8s of 2x damage + speed

### New Content
- [ ] **3 additional campaign levels** (Levels 8–10) with new tile themes
  - Night city tileset
  - Underground bunker tileset
  - Rooftop/urban tileset
- [ ] **2 new boss types**
  - The Sniper (long-range, cover-based)
  - The Brute (tank, melee charge)
- [ ] **Character select screen** — 3 playable characters with different base stats
- [ ] **Story intro cutscene** — simple scrolling text + key art (5 panels)
- [ ] **Chapter end cutscene** — 3 panels showing story progression
- [ ] **New daily challenge modifiers** (add 4 more to existing 8)
  - SNIPER_ONLY, MELEE_ONLY, PACIFIST, TIME_ATTACK

### Progression Systems
- [ ] **Prestige system** — reset level for bonus multiplier + prestige badge
- [ ] **Weapon upgrade tree** — each weapon has 3 upgrade nodes (damage/fire rate/clip)
- [ ] **Challenge missions** — 3 rotating daily objectives (kill X with Y weapon, etc.)
- [ ] **Cosmetic unlocks** — player skins, bullet colors, explosion colors

---

## Phase 3 — Monetization Integration {#phase-3}
### Weeks 9–12 | Goal: Add all revenue streams without ruining experience

### AdMob Integration (Android — Primary Revenue)
- [ ] Create Google AdMob account at admob.google.com
- [ ] Install Godot AdMob plugin (godot-admob-android on GitHub)
- [ ] **Interstitial Ads** — show on game over screen (NOT during gameplay)
- [ ] **Rewarded Ads** — "Watch ad to revive once" button on death screen
- [ ] **Rewarded Ads** — "Watch ad for double score" button at level start
- [ ] **Banner Ads** — small bottom banner on main menu ONLY
- [ ] Set ad frequency cap: max 1 interstitial per 3 minutes (avoid player rage)
- [ ] Test with test ad unit IDs before going live
- [ ] **Expected CPM:** ₹30–80 for Indian traffic, ₹200–600 for US/EU traffic

### In-App Purchases (IAP) — Bigger Revenue
- [ ] Integrate Godot GodotGooglePlayBilling plugin
- [ ] **Consumables (repeat purchase):**
  - Coin packs: ₹49 (100 coins), ₹149 (350 coins), ₹399 (1000 coins)
  - Revive token pack: ₹29 (3 revives)
  - Grenade pack: ₹19 (10 grenades)
- [ ] **One-time purchases:**
  - Remove Ads: ₹199 permanent
  - Starter Pack (first 24h only): ₹99 for 500 coins + skin + no-ads 7 days
  - Character skin bundle: ₹149 per character
  - VIP Season Pass: ₹299/month (daily coins + exclusive challenges + badge)
- [ ] **Soft currency (coins) loop:**
  - Earn slowly in-game (10–30 coins per run)
  - Spend on: weapon upgrades, skins, continues
  - Hard cap free-to-earn at 200 coins/day to drive purchases

### Web Monetization (Secondary)
- [ ] Host HTML5 build on itch.io — pay-what-you-want (₹0 min, ₹99 suggested)
- [ ] Embed game on personal domain — place Google AdSense ads around game iframe
- [ ] Submit to Newgrounds, Kongregate, GameJolt for additional traffic
- [ ] Crazy Games / GameDistribution — revenue share programs for HTML5 games

---

## Phase 4 — Platform Launch Strategy {#phase-4}
### Weeks 12–16 | Goal: Hit stores with maximum impact

### Android Launch (Primary)
- [ ] Create Google Play Developer account ($25 one-time fee)
- [ ] Configure Godot Android export preset with correct package name
- [ ] Set `minSdkVersion 21`, `targetSdkVersion 33`
- [ ] Create signed keystore for release builds
- [ ] Write Play Store listing:
  - Title: "Survival: Hunter Chronicles - Action Shooter"
  - Short description (80 chars): "Fight enemy hordes in this thrilling 2D action shooter. Can you survive?"
  - Full description (4000 chars): Story + features + modes list
  - 8 screenshots (phone + tablet sizes)
  - Feature graphic (1024x500px)
  - Promo video (30–60 seconds of gameplay)
- [ ] Set up Closed Testing track (50 testers) before public launch
- [ ] Set up Open Testing track (500 testers) for 2-week beta
- [ ] Launch on Free tier with ads + IAP
- [ ] Target launch day: **get 50 ratings in first week** (ask friends/family/communities)

### iOS Launch (Month 4)
- [ ] Apple Developer Program ($99/year)
- [ ] Configure Godot iOS export
- [ ] Create App Store Connect listing (same content as Play Store)
- [ ] TestFlight beta — 100 testers for 2 weeks
- [ ] Submit for App Store review (7–10 day wait)

### Web Platforms (Parallel to Android)
- [ ] **itch.io** — Free + pay-what-you-want, HTML5 build
- [ ] **GameJolt** — Free hosting, trophy/achievement integration
- [ ] **Newgrounds** — Large existing audience for action games
- [ ] **Crazy Games** — Apply at developer.crazygames.com (revenue share)
- [ ] **itch.io page optimization:** proper tags (action, shooter, 2d, pixel, survival)

### Steam (Month 6)
- [ ] Steam Direct fee: $100 one-time
- [ ] Minimum requirements before Steam: 4+ hours of content, polished UI, controller support
- [ ] Set up Steam page 30 days before launch for wishlist building
- [ ] Price: $2.99 or $4.99 USD
- [ ] Run launch week discount (25% off)

---

## Phase 5 — Marketing & Community {#phase-5}
### Ongoing | Goal: Build audience before & after launch

### Pre-Launch (Start NOW — 8 weeks before launch)
- [ ] Create **TikTok account** — post 1 gameplay clip/day (15–30 seconds)
  - Show: combo chains, boss fights, close-call moments, satisfying kills
  - Hashtags: #indiegame #gamedev #godot #mobilegame #shooter
- [ ] Create **Instagram Reels** — same clips as TikTok (cross-post)
- [ ] Create **YouTube channel** — weekly devlog + trailer
  - Week 1: "I made a mobile game from scratch" (hook: zero to game)
  - Week 2: "Adding a 3-phase boss fight to my game"
  - Week 3: "Making my indie game feel like a AAA game"
  - Launch week: Official gameplay trailer (60 seconds)
- [ ] Post on **Reddit:**
  - r/indiegaming — showcase posts
  - r/godot — technical posts (how we built the AI Director)
  - r/AndroidGaming — launch announcement
  - r/gamedev — devlog posts
- [ ] Create **Discord server** — "Hunter Chronicles Community"
  - Channels: #announcements, #feedback, #bug-reports, #leaderboard-flex
- [ ] Post on **Twitter/X** daily dev update
- [ ] Submit to **TouchArcade forums** (pre-launch thread)
- [ ] Submit to **IndieDB** listing
- [ ] Contact **10 mobile game YouTubers** (under 100k subs — more likely to cover indie)

### Launch Week
- [ ] Post launch trailer everywhere same day
- [ ] Run "1000 downloads challenge" — post update at milestones
- [ ] Ask every Discord member to leave a Play Store review
- [ ] Submit to **Product Hunt** (Games category)
- [ ] Post on **Hacker News** Show HN thread
- [ ] Email 20 gaming journalists/bloggers with press kit
- [ ] Create press kit: screenshots, trailer, description, APK download link

### Post-Launch (Month 2+)
- [ ] Weekly content updates (new daily challenges, limited-time events)
- [ ] Monthly new character skin (creates anticipation cycle)
- [ ] Seasonal events: Diwali event (special skins), Christmas event
- [ ] Community tournaments: monthly high-score competition with Discord prizes
- [ ] Respond to EVERY Play Store review (Google rewards this with visibility)
- [ ] Feature fan art / screenshots from players on social media
- [ ] Run "Report a Bug, Get Coins" program via Discord

---

## Phase 6 — Scale & Revenue Optimization {#phase-6}
### Month 5+ | Goal: Maximize LTV per player

### Analytics Setup (Do Before Launch)
- [ ] Integrate Firebase Analytics (free, Godot plugin available)
- [ ] Track key events:
  - `session_start`, `level_start`, `level_complete`, `level_fail`
  - `enemy_killed`, `boss_killed`, `player_died`
  - `ad_watched`, `iap_initiated`, `iap_complete`
  - `daily_challenge_started`, `daily_challenge_complete`
- [ ] Set up Firebase Crashlytics for crash reporting
- [ ] Set up Google Play Console analytics (retention, churn, ARPU)
- [ ] Weekly review of D1/D7/D30 retention rates
  - Good D1 retention: 40%+, D7: 20%+, D30: 10%+

### ASO (App Store Optimization)
- [ ] Research keywords: "offline shooter game", "2D action game android", "survival shooter"
- [ ] A/B test store icon (Google Play allows this natively)
- [ ] A/B test screenshots (first screenshot is most important)
- [ ] Update description with top keywords (first 167 chars are indexed)
- [ ] Translate listing to Hindi, Spanish, Portuguese (3 highest mobile game markets)

### Revenue Optimization
- [ ] Analyze which IAP converts best — double down on those
- [ ] Add "Starter Pack" limited-time offer popup on Day 1 of install
- [ ] Add "Second Chance" rewarded ad on death (highest converting placement)
- [ ] Implement push notifications:
  - Daily: "Your daily challenge is ready!"
  - Weekly: "New weekly event started!"
  - Re-engagement (3 days inactive): "Your top score is at risk!"
- [ ] Add referral system: "Invite friend, both get 200 coins"
- [ ] Consider **subscription model** at Month 6: ₹99/month VIP pass

---

## GitHub Actions CI/CD Plan {#cicd}

> See `.github/workflows/` for full implementation  
> Three pipelines: PR Review → Staging → Production

### Pipeline Overview

```
Code Push (any branch)
    │
    ▼
[1] LINT & VALIDATE
    │ GDScript syntax check
    │ Export preset validation
    │
    ▼
[2] BUILD (HTML5)
    │ Godot headless export
    │ Artifact stored
    │
    ▼
[3] DEPLOY TO STAGING (GitHub Pages - dev branch)
    │ Live URL shared on PR comment
    │ QA testers play here
    │
    ▼
[4] COLLECT FEEDBACK (Manual gate)
    │ Google Form link in PR comment
    │ Minimum 3 tester responses required
    │
    ▼
[5] PRODUCTION DEPLOY (main branch only, manual approval)
    │ Deploy to itch.io / web host
    │ GitHub Release created with build artifact
    │ Discord webhook notification
```

### Files Created
- `.github/workflows/ci.yml` — Lint + Build on every push
- `.github/workflows/staging.yml` — Auto-deploy PRs to staging URL
- `.github/workflows/production.yml` — Manual-trigger production deploy

---

## Revenue Projections {#revenue}

> Conservative estimates based on similar indie mobile games

### Year 1 Projections

| Milestone | Downloads | Monthly Revenue | Cumulative |
|---|---|---|---|
| Launch (Month 1) | 1,000 | ₹3,000–8,000 | ₹5,000 |
| Month 3 | 10,000 | ₹15,000–40,000 | ₹70,000 |
| Month 6 | 50,000 | ₹60,000–150,000 | ₹4,00,000 |
| Month 12 | 2,00,000 | ₹2,00,000–5,00,000 | ₹20,00,000 |
| Month 18 | 5,00,000 | ₹5,00,000–12,00,000 | ₹75,00,000 |

### What Drives ₹1 Crore+
- 5 lakh (500k) active users
- 2% IAP conversion at ₹99 avg = ₹9,90,000/month
- Ad revenue at ₹5/DAU/month = ₹25,00,000/month
- **This is achievable — but requires serious marketing investment**

### Reality Check
- 90% of indie games make under ₹10,000 total
- Top 1% make crores
- The difference: **marketing budget + consistency + community**
- Recommend reinvesting first ₹50,000 earned into paid UA (user acquisition)

---

## Tools & Resources {#tools}

### Free Tools
| Tool | Purpose |
|---|---|
| Godot 4.2 | Game engine |
| GitHub Actions | CI/CD pipelines |
| GitHub Pages | Staging web host |
| Firebase (free tier) | Analytics, crash reports, leaderboard |
| itch.io | Web/desktop distribution |
| freesound.org | Free SFX |
| Google AdMob | Mobile ads |
| Canva | Store screenshots, social graphics |
| OBS Studio | Gameplay recording |
| DaVinci Resolve | Video trailer editing |
| Discord | Community hub |

### Paid (When Revenue Starts)
| Tool | Cost | Purpose |
|---|---|---|
| Google Play Developer | $25 one-time | Android publishing |
| Apple Developer | $99/year | iOS publishing |
| Steam Direct | $100 one-time | Steam publishing |
| Meta/TikTok Ads | ₹500/day budget | Paid user acquisition |
| Fiverr (artist) | ₹2,000–5,000 | Character sprites |

---

## Week-by-Week Sprint Plan

| Week | Focus | Deliverable |
|---|---|---|
| 1 | Fix all critical bugs (endless mode, settings, knockback) | Playable beta build |
| 2 | Audio overhaul (10 new SFX + boss music) | Full audio game |
| 3 | Visual polish (particles, enemy sprites, HUD portrait) | Polished build |
| 4 | Skill tree + double jump + dash | Feature complete v1.0 |
| 5 | GitHub Actions CI/CD setup | Auto-deploy pipeline |
| 6 | AdMob integration + test ads | Monetized build |
| 7 | IAP integration + coin economy | Full monetization |
| 8 | Android export + Play Store beta (50 testers) | Live on Play Store (closed) |
| 9 | Collect beta feedback + fix reported bugs | v1.0.1 patch |
| 10 | Marketing content creation (TikTok/YouTube) | 20+ social posts |
| 11 | itch.io + web platforms live | Multi-platform presence |
| 12 | Open beta (500 testers) | 500 real user reviews |
| 13 | Public Android launch | DAY 1 LAUNCH |
| 14–16 | Monitor analytics, fix issues, engage community | Stable v1.0 |
| Month 5 | iOS launch | Second platform |
| Month 6 | Steam launch | Third platform |

---

*Last updated: April 2026*  
*Game version target: v1.0 (Campaign + Endless + Daily Challenge)*
