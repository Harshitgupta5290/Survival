# Survival: Hunter Chronicles — Complete Setup & Publishing Guide

---

## STEP 1: Install Godot 4

1. Go to https://godotengine.org/download
2. Download **Godot 4.2** (stable) — pick your OS
3. Also download the **Export Templates** (same page, bottom section)
4. Open Godot → Editor → Manage Export Templates → Install from file

---

## STEP 2: Open the Project

1. Launch Godot
2. Click **Import**
3. Navigate to `godot_project/project.godot`
4. Click **Open** → the project loads automatically

---

## STEP 3: First Run

Press **F5** (or the Play button). The game should start at the main menu.

### If you see errors about missing images:
- All images are in `assets/img/` — they use the original game's art
- The code loads them at runtime, so no manual assignment needed

---

## STEP 4: Adding More Levels

### Hand-crafted levels (7 already included)
- Levels 1–7 are in `assets/levels/` as CSV files
- The tutorial has its own `tutorial_data.csv`
- To add more: create `level8_data.csv`, etc., and bump `Constants.MAX_LEVELS` in `scripts/constants.gd`
- Edit CSVs in any spreadsheet app (LibreOffice Calc works great)

### Endless / AI-generated levels (already built in)
- Select **ENDLESS MODE** from main menu
- The `LevelGenerator` + `AIDirector` scripts create infinite waves automatically
- Each wave is harder and more varied than the last

---

## STEP 5: Export to Web (for Poki / itch.io)

1. In Godot: **Project → Export**
2. Add preset: **Web**
3. Set output file to `export/web/index.html`
4. Enable **Export PCK/ZIP** → uncheck
5. Click **Export Project**

### Upload to itch.io (free, takes 5 minutes)
- Create account at https://itch.io
- Upload the `export/web/` folder as a ZIP
- Set "Kind of project" = HTML
- Publish → share your link

### Apply to Poki
- Go to https://developers.poki.com
- Submit your HTML5 build
- Poki reviews within 2–4 weeks

---

## STEP 6: Export to Android (Google Play)

### Requirements
- Android Studio installed
- Java JDK 17+
- Android SDK

### Steps in Godot
1. **Project → Export → Add → Android**
2. Fill in:
   - Package name: `com.yourstudio.survivalhunter`
   - Version name / code
   - Keystore (create with `keytool` — Google it)
3. Click **Export Project** → generates `.aab` file

### Upload to Google Play
1. Go to https://play.google.com/console
2. Create developer account ($25 one-time fee)
3. Create new app → upload your `.aab`
4. Fill in store listing (title, description, screenshots)
5. Submit for review (~3 days)

---

## STEP 7: Export to iOS (Apple App Store)

### Requirements (non-negotiable by Apple)
- **Mac computer** running macOS 12+
- **Xcode 15+** installed
- **Apple Developer account** ($99/year at https://developer.apple.com)

### Steps
1. In Godot: **Project → Export → Add → iOS**
2. Fill in Bundle ID, team ID (from Apple Developer account)
3. Click **Export Project** → generates Xcode project
4. Open in Xcode → set signing → **Product → Archive**
5. Upload via **Xcode Organizer → Distribute App**

---

## What's Already Built In

| Feature | File | Status |
|---|---|---|
| Tutorial with overlay hints | `tutorial_overlay.gd` + CSV | Done |
| Story mode (7 levels) | `world.gd` + CSV files | Done |
| Boss enemy — 3-phase | `boss.gd` | Done |
| Weapon system (Pistol/Shotgun/Sniper) | `weapon_manager.gd` | Done |
| Online leaderboard (Firebase) | `leaderboard.gd` | Done (needs URL) |
| Screen juice — hit-stop, damage numbers | `game.gd` | Done |
| Screen flash on player hit | `game.gd` | Done |
| Endless mode | `level_generator.gd` | Done |
| AI Director (intensity waves) | `ai_director.gd` | Done |
| NVIDIA AI villain taunts | `ai_director.gd` | Done (needs key) |
| Daily Challenge | `daily_challenge.gd` | Done |
| Adaptive difficulty | `game_manager.gd` | Done |
| Score + Combo system | `game_manager.gd` | Done |
| XP + Levelling | `game_manager.gd` | Done |
| Achievements | `game_manager.gd` | Done |
| Save/Load progress | `game_manager.gd` | Done |
| Mobile touch controls | `mobile_controls.gd` | Done |
| Enemy AI state machine (6 states) | `enemy.gd` | Done |
| Coyote time + jump buffer | `player.gd` | Done |
| Invincibility frames | `player.gd` | Done |
| Audio manager + volume | `audio_manager.gd` | Done |
| Parallax background | `world.gd` | Done |
| Screen shake | `game.gd` | Done |

---

## Optional Activation Steps

These features are coded and ready — they just need credentials:

### NVIDIA AI Taunts
1. Get a free key at [build.nvidia.com](https://build.nvidia.com)
2. Open `scripts/ai_director.gd`, set:
   ```gdscript
   const AI_API_KEY := "nvapi-your-key-here"
   const AI_ENABLED := true
   ```

### Online Leaderboard
1. Create a free Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Realtime Database** → copy the URL
3. Open `scripts/leaderboard.gd`, set:
   ```gdscript
   const FIREBASE_URL := "https://your-project-default-rtdb.firebaseio.com/leaderboard.json"
   const ENABLED      := true
   ```

---

## Recommended Next Features (Phase 3)

- [ ] Character unlock screen (use `GameManager.unlocked_skins`)
- [ ] Weapon upgrades (spend XP on faster bullets, bigger explosion)
- [ ] Seasonal events (Halloween skin pack, Christmas level)
- [ ] Social sharing button (screenshot + score to clipboard)
- [ ] Controller / gamepad support

---

## Switching to Claude AI Taunts

The villain taunt system uses NVIDIA NIM by default (free tier). To switch to Claude instead:

```gdscript
# In ai_director.gd — replace the HTTP request block with:
var body := JSON.stringify({
    "model": "claude-haiku-4-5-20251001",
    "max_tokens": 60,
    "messages": [{"role": "user", "content": "...taunt prompt..."}]
})
http.request(
    "https://api.anthropic.com/v1/messages",
    ["x-api-key: YOUR_CLAUDE_KEY", "anthropic-version: 2023-06-01",
     "content-type: application/json"],
    HTTPClient.METHOD_POST, body
)
```

Get a Claude API key at [console.anthropic.com](https://console.anthropic.com)

---

## Project Structure Quick Reference

```
godot_project/
├── project.godot              ← Open this in Godot
├── assets/
│   ├── audio/                 ← jump.wav, shot.wav, grenade.wav, music2.mp3
│   ├── img/                   ← all sprite sheets
│   └── levels/
│       ├── tutorial_data.csv
│       ├── level1_data.csv
│       ├── level2_data.csv
│       ├── level3_data.csv
│       ├── level4_data.csv
│       ├── level5_data.csv
│       ├── level6_data.csv
│       └── level7_data.csv
├── scenes/
│   ├── main_menu.tscn         ← entry point
│   ├── game.tscn              ← gameplay scene
│   ├── player.tscn
│   ├── enemy.tscn
│   ├── boss.tscn              ← 3-phase boss
│   ├── bullet.tscn
│   ├── grenade.tscn
│   ├── explosion.tscn
│   ├── item_box.tscn
│   ├── exit_zone.tscn
│   ├── damage_number.tscn     ← floating kill/damage labels
│   └── tutorial_overlay.tscn
└── scripts/
    ├── constants.gd            ← tweak all game values here
    ├── game_manager.gd         ← score, XP, save/load [Autoload]
    ├── audio_manager.gd        ← music/SFX [Autoload]
    ├── input_manager.gd        ← keyboard + touch [Autoload]
    ├── weapon_manager.gd       ← weapon stats + unlocks [Autoload]
    ├── leaderboard.gd          ← Firebase REST [Autoload]
    ├── player.gd
    ├── enemy.gd                ← 6-state AI machine
    ├── boss.gd                 ← 3-phase boss AI
    ├── ai_director.gd          ← Left4Dead-style intensity + AI taunts
    ├── level_generator.gd      ← procedural endless levels
    ├── daily_challenge.gd      ← daily modifiers
    ├── world.gd                ← CSV tile loader
    ├── game.gd                 ← master controller
    ├── hud.gd
    ├── tutorial_overlay.gd
    ├── mobile_controls.gd
    ├── main_menu.gd
    └── pause_menu.gd
```
