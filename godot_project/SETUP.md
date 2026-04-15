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

### Hand-crafted levels
- Copy `assets/levels/level1_data.csv` to `level3_data.csv`, etc.
- Edit the CSV in any spreadsheet app (LibreOffice Calc works great)
- Update `Constants.MAX_LEVELS` in `scripts/constants.gd`

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
| Story mode (2 levels) | `world.gd` + CSV files | Done |
| Endless mode | `level_generator.gd` | Done |
| AI Director (intensity waves) | `ai_director.gd` | Done |
| Daily Challenge | `daily_challenge.gd` | Done |
| Adaptive difficulty | `game_manager.gd` | Done |
| Score + Combo system | `game_manager.gd` | Done |
| XP + Levelling | `game_manager.gd` | Done |
| Achievements | `game_manager.gd` | Done |
| Save/Load progress | `game_manager.gd` | Done |
| Mobile touch controls | `mobile_controls.gd` | Done |
| Enemy AI state machine | `enemy.gd` | Done |
| Coyote time + jump buffer | `player.gd` | Done |
| Invincibility frames | `player.gd` | Done |
| Grenade rescue mechanic | `ai_director.gd` | Done |
| Audio manager + volume | `audio_manager.gd` | Done |
| Parallax background | `world.gd` | Done |
| Screen shake | `game.gd` | Done |

---

## Recommended Next Features (Phase 2)

- [ ] Online leaderboard (use Godot's HTTP request + a free Firebase Realtime DB)
- [ ] 5 more hand-crafted levels
- [ ] Boss character (large enemy with 3-phase attack pattern)
- [ ] Character unlock screen (use `GameManager.unlocked_skins`)
- [ ] Weapon upgrades (spend XP on faster bullets, bigger explosion)
- [ ] Claude AI integration (ask claude.ai API for dynamic taunts / story text)
- [ ] Seasonal events (Halloween skin pack, Christmas level)
- [ ] Social sharing button (screenshot + score to clipboard)

---

## Claude AI Integration (Optional but Powerful)

Add real AI-generated content by calling the Anthropic API:

```gdscript
# In ai_director.gd or a dedicated script
func get_ai_taunt(player_kills: int, health: int) -> void:
    var http := HTTPRequest.new()
    add_child(http)
    
    var body := JSON.stringify({
        "model": "claude-haiku-4-5-20251001",
        "max_tokens": 60,
        "messages": [{
            "role": "user",
            "content": "Generate a short villain taunt for a shooter game. Player has %d kills and %d%% health. Max 10 words." % [player_kills, health]
        }]
    })
    
    http.request(
        "https://api.anthropic.com/v1/messages",
        ["x-api-key: YOUR_API_KEY", "anthropic-version: 2023-06-01",
         "content-type: application/json"],
        HTTPClient.METHOD_POST,
        body
    )
    http.request_completed.connect(_on_taunt_received)

func _on_taunt_received(_result, _code, _headers, body: PackedByteArray) -> void:
    var data = JSON.parse_string(body.get_string_from_utf8())
    var taunt = data["content"][0]["text"]
    # Display taunt on screen
```

This gives every player unique, AI-generated dialogue. Get your API key at https://console.anthropic.com

---

## Project Structure Quick Reference

```
godot_project/
├── project.godot          ← Open this in Godot
├── assets/
│   ├── audio/             ← jump.wav, shot.wav, grenade.wav, music2.mp3
│   ├── img/               ← all sprite sheets
│   └── levels/            ← level1_data.csv, level2_data.csv
├── scenes/
│   ├── main_menu.tscn     ← entry point
│   ├── game.tscn          ← gameplay scene
│   ├── player.tscn
│   ├── enemy.tscn
│   ├── bullet.tscn
│   ├── grenade.tscn
│   ├── explosion.tscn
│   ├── item_box.tscn
│   └── exit_zone.tscn
└── scripts/
    ├── constants.gd        ← tweak all game values here
    ├── game_manager.gd     ← score, XP, save/load [Autoload]
    ├── audio_manager.gd    ← music/SFX [Autoload]
    ├── input_manager.gd    ← keyboard + touch [Autoload]
    ├── player.gd
    ├── enemy.gd            ← 5-state AI machine
    ├── ai_director.gd      ← Left4Dead-style intensity system
    ├── level_generator.gd  ← procedural endless levels
    ├── daily_challenge.gd  ← daily modifiers
    ├── world.gd            ← CSV tile loader
    ├── game.gd             ← master controller
    ├── hud.gd
    ├── mobile_controls.gd
    ├── main_menu.gd
    └── pause_menu.gd
```
