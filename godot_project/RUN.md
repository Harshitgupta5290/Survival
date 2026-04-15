# Running the Game — Quick Start

---

## 1. Install Godot 4

- Download **Godot 4.2 (stable)** from [godotengine.org/download](https://godotengine.org/download)
- Pick the **Standard** version (not .NET/Mono)
- No installer needed — just extract and run the executable

---

## 2. Open the Project

1. Launch Godot
2. Click **Import**
3. Browse to this folder and select **`project.godot`**
4. Click **Import & Edit**

The editor opens automatically.

---

## 3. Run the Game

Press **F5** (or click the ▶ Play button in the top-right corner).

The game starts at the **Main Menu**.

---

## Controls

| Action | Key |
|---|---|
| Move Left | A |
| Move Right | D |
| Jump | W |
| Shoot | Space |
| Throw Grenade | Q |
| Switch Weapon | E |
| Pause | Escape |

On mobile / touchscreen — on-screen buttons appear automatically.

---

## Game Modes

| Mode | What it is |
|---|---|
| **Tutorial** | Guided intro — learn movement, shooting, grenades, combos |
| **Play Story** | 7 hand-crafted levels ending with a 3-phase boss fight |
| **Endless Mode** | AI-generated infinite waves, gets harder each round |
| **Daily Challenge** | Same worldwide seed each day — unique modifiers |

---

## Weapons

Weapons unlock automatically as you level up via XP:

| Weapon | Unlocks | Style |
|---|---|---|
| Pistol | From the start | Fast, reliable, 20 ammo |
| Shotgun | Player level 3 | 5 pellets per shot, close-range devastation |
| Sniper | Player level 6 | One-shot power (90 dmg), long reload |

Press **E** to cycle between unlocked weapons.

---

## Boss Fight (Level 7)

The Commander has 3 phases triggered by remaining HP:

| Phase | HP % | Behaviour |
|---|---|---|
| 1 | 100–60% | Charges + burst shoots |
| 2 | 60–25% | Adds grenade spam, moves faster, orange tint |
| 3 | < 25% | Enrage — rapid fire, spawns minions every 8s, red glow |

---

## If Something Goes Wrong

**Only one scenario requires action:** if you move or rename the `godot_project/` folder, Godot may lose its resource paths.

Fix: close Godot, reopen it, and re-import `project.godot` from its new location.

Everything else — assets, autoloads, audio, levels — is already in place and verified.

---

## Enabling AI Taunts (optional)

1. Get a free API key from [build.nvidia.com](https://build.nvidia.com)
2. Open `scripts/ai_director.gd`
3. Edit these two lines:

```gdscript
const AI_API_KEY := "nvapi-your-key-here"
const AI_ENABLED := true
```

4. Press F5 — the villain now speaks live AI-generated lines during gameplay

Without a key the game works fine — it falls back to built-in dialogue.

---

## Enabling the Online Leaderboard (optional)

1. Create a free project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Realtime Database** (Start in test mode)
3. Copy the database URL (looks like `https://your-project-default-rtdb.firebaseio.com`)
4. Open `scripts/leaderboard.gd` and edit:

```gdscript
const FIREBASE_URL := "https://your-project-default-rtdb.firebaseio.com/leaderboard.json"
const ENABLED      := true
```

5. Scores are auto-submitted from the death screen and viewable from the main menu.

---

## Tweaking the Game

All game values (speed, gravity, damage, scoring, weapon stats) are in one file:

```
scripts/constants.gd
```

Change a value, save, and press F5 — no rebuild needed.
