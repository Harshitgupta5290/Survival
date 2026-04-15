extends Node
# ─────────────────────────────────────────────
#  CONSTANTS  –  single source of truth for every
#  magic number in Survival: Hunter Chronicles
# ─────────────────────────────────────────────

# ── Screen ──────────────────────────────────
const SCREEN_WIDTH   : int   = 800
const SCREEN_HEIGHT  : int   = 640

# ── World / Tiles ────────────────────────────
const ROWS           : int   = 16
const COLS           : int   = 150
const TILE_SIZE      : int   = 40        # SCREEN_HEIGHT / ROWS
const TILE_TYPES     : int   = 21
const MAX_LEVELS     : int   = 7
const TUTORIAL_LEVEL : String = "tutorial"
const SCROLL_THRESH  : int   = 200

# ── Physics ──────────────────────────────────
const GRAVITY        : float = 980.0
const JUMP_VELOCITY  : float = -550.0
const MAX_FALL_SPEED : float = 900.0

# ── Player ───────────────────────────────────
const PLAYER_SPEED        : float = 250.0
const PLAYER_HEALTH       : int   = 100
const PLAYER_AMMO         : int   = 20
const PLAYER_GRENADES     : int   = 5
const SHOOT_COOLDOWN      : float = 0.25  # seconds
const INVINCIBLE_DURATION : float = 0.5   # seconds after hit

# ── Bullets ──────────────────────────────────
const BULLET_SPEED        : float = 800.0
const BULLET_DAMAGE_ENEMY : int   = 25
const BULLET_DAMAGE_PLAYER: int   = 5

# ── Grenades ─────────────────────────────────
const GRENADE_SPEED    : float = 350.0
const GRENADE_TIMER    : float = 2.2     # seconds before explosion
const GRENADE_DAMAGE   : int   = 50
const GRENADE_RADIUS   : int   = 2       # tiles

# ── Enemies ──────────────────────────────────
const ENEMY_BASE_SPEED        : float = 120.0
const ENEMY_HEALTH            : int   = 100
const ENEMY_AMMO              : int   = 20
const ENEMY_VISION_RANGE      : float = 350.0
const ENEMY_SHOOT_COOLDOWN    : float = 1.4
const ENEMY_PATROL_DISTANCE   : int   = 3    # tiles
const ENEMY_IDLE_CHANCE       : int   = 200  # 1-in-N chance per frame
const ENEMY_GRENADE_CHANCE    : int   = 400  # 1-in-N per frame when chasing

# ── Tile categories ──────────────────────────
const TILE_OBSTACLE_MIN : int = 0
const TILE_OBSTACLE_MAX : int = 8
const TILE_WATER_MIN    : int = 9
const TILE_WATER_MAX    : int = 10
const TILE_DECO_MIN     : int = 11
const TILE_DECO_MAX     : int = 14
const TILE_PLAYER       : int = 15
const TILE_ENEMY        : int = 16
const TILE_AMMO         : int = 17
const TILE_GRENADE      : int = 18
const TILE_HEALTH       : int = 19
const TILE_EXIT         : int = 20

# ── Pickup values ────────────────────────────
const PICKUP_HEALTH_AMOUNT  : int = 25
const PICKUP_AMMO_AMOUNT    : int = 15
const PICKUP_GRENADE_AMOUNT : int = 3

# ── Scoring ──────────────────────────────────
const SCORE_PER_KILL         : int = 100
const SCORE_LEVEL_COMPLETE   : int = 500
const SCORE_NO_DAMAGE_BONUS  : int = 300
const COMBO_WINDOW           : float = 3.0  # seconds
const COMBO_BONUS_PER_STREAK : float = 0.1  # +10% per kill in combo

# ── XP / Progression ────────────────────────
const XP_PER_KILL            : int = 50
const XP_PER_LEVEL_COMPLETE  : int = 200
const XP_BASE_TO_NEXT_LEVEL  : int = 500
const XP_LEVEL_SCALE         : float = 1.5

# ── Adaptive Difficulty ──────────────────────
const DIFF_EASY_KILL_RATE   : float = 5.0
const DIFF_HARD_KILL_RATE   : float = 15.0
const DIFF_MIN              : float = 0.5
const DIFF_MAX              : float = 2.0
const DIFF_STEP             : float = 0.05

# ── Layers ───────────────────────────────────
const LAYER_WORLD   : int = 1   # bit 0
const LAYER_PLAYER  : int = 2   # bit 1
const LAYER_ENEMY   : int = 4   # bit 2
const LAYER_PICKUP  : int = 8   # bit 3
const LAYER_BULLET  : int = 16  # bit 4

# ── Weapons ──────────────────────────────────
const WEAPON_PISTOL_COOLDOWN   : float = 0.25
const WEAPON_PISTOL_DAMAGE     : int   = 25
const WEAPON_PISTOL_AMMO       : int   = 20
const WEAPON_SHOTGUN_COOLDOWN  : float = 0.7
const WEAPON_SHOTGUN_DAMAGE    : int   = 15   # per pellet (5 pellets)
const WEAPON_SHOTGUN_PELLETS   : int   = 5
const WEAPON_SHOTGUN_SPREAD    : float = 0.25 # radians
const WEAPON_SHOTGUN_AMMO      : int   = 8
const WEAPON_SNIPER_COOLDOWN   : float = 1.2
const WEAPON_SNIPER_DAMAGE     : int   = 90
const WEAPON_SNIPER_AMMO       : int   = 5
const WEAPON_SNIPER_SPEED      : float = 1600.0
const WEAPON_UNLOCK_SHOTGUN_LV : int   = 3    # player level required
const WEAPON_UNLOCK_SNIPER_LV  : int   = 6

# ── Colors ───────────────────────────────────
const COLOR_BG        := Color(0.565, 0.788, 0.471)   # (144,201,120)
const COLOR_HEALTH_BG := Color(0, 0, 0)
const COLOR_HEALTH_FG := Color(0, 1, 0)
const COLOR_HEALTH_EM := Color(1, 0, 0)
const COLOR_WHITE     := Color(1, 1, 1)
const COLOR_GOLD      := Color(1, 0.84, 0)
const COLOR_PINK      := Color(0.922, 0.255, 0.212)
