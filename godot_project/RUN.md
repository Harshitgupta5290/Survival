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
| Pause | Escape |

On mobile / touchscreen — on-screen buttons appear automatically.

---

## Game Modes

| Mode | What it is |
|---|---|
| **Play Story** | 2 hand-crafted levels with CSV tile maps |
| **Endless Mode** | AI-generated infinite waves, gets harder each round |
| **Daily Challenge** | Same worldwide seed each day — unique modifiers |

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

## Tweaking the Game

All game values (speed, gravity, damage, scoring) are in one file:

```
scripts/constants.gd
```

Change a value, save, and press F5 — no rebuild needed.
