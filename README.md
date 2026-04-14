# Survival - A Hunter

A 2D side-scrolling shooter game built with Python and Pygame. Fight through enemy-filled levels, collect power-ups, and survive the hunt.

## Gameplay

- Navigate through tile-based levels with scrolling backgrounds
- Shoot enemies and throw grenades to clear your path
- Collect health packs, ammo boxes, and grenade crates
- Reach the exit to advance to the next level
- Avoid water hazards and falling off the map

## Controls

| Key | Action |
|-----|--------|
| `A` | Move Left |
| `D` | Move Right |
| `W` | Jump |
| `Space` | Shoot |
| `Q` | Throw Grenade |
| `Escape` | Quit |

## Features

- Animated player and enemy sprites (Idle, Run, Jump, Death)
- Enemy AI with vision-based detection and patrol behavior
- Grenade physics with explosion radius damage
- Parallax scrolling background (sky, mountains, pine trees)
- Health bar, ammo counter, and grenade counter HUD
- Screen fade transitions between levels and on death
- Restart on death with level reload
- 2 playable levels loaded from CSV tile maps

## Prerequisites

- Python 3.x
- Pygame

```bash
pip install pygame
```

## Running the Game

```bash
python Survival.py
```

## Project Structure

```
Survival/
├── Survival.py          # Main game loop and all game classes
├── button.py            # Button UI component
├── d.py                 # Level editor / tile map designer
├── level1_data.csv      # Level 1 tile map data
├── level2_data.csv      # Level 2 tile map data
├── audio/               # Sound effects (jump, shot, grenade)
└── img/                 # Game assets
    ├── Background/      # Parallax background layers
    ├── player/          # Player animation frames
    ├── enemy/           # Enemy animation frames
    ├── Tile/            # 21 tile types for level building
    ├── icons/           # Bullet, grenade, item box sprites
    └── explosion/       # Explosion animation frames
```

## Game Classes

| Class | Description |
|-------|-------------|
| `Soldier` | Player and enemy character with movement, AI, shooting, and animation |
| `World` | Parses CSV tile data and builds the level |
| `Bullet` | Projectile with collision detection |
| `Grenade` | Physics-based grenade with explosion and area damage |
| `Explosion` | Frame-based explosion animation |
| `ItemBox` | Collectible health, ammo, and grenade pickups |
| `HealthBar` | HUD health display |
| `ScreenFade` | Transition effects for level start and death |

## License

See [LICENSE](LICENSE) for details.
