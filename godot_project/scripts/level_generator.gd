extends Node
# ─────────────────────────────────────────────────────────────────────────────
#  PROCEDURAL LEVEL GENERATOR  –  AI-driven infinite level creation
#
#  How it works:
#    1.  The AIDirector picks a "challenge profile" for this level
#        based on player performance, current wave, and playtime.
#    2.  Rooms are assembled from pre-designed "chunks" (mini-segments)
#        stitched together end-to-end.
#    3.  Enemy count, type distribution, and item density are calculated
#        from the difficulty curve.
#    4.  The resulting 2-D integer grid is written to a temp CSV and
#        returned so that world.gd can load it identically to hand-crafted levels.
#
#  Chunk types:
#    FLAT          – simple ground run
#    PLATFORM      – floating platforms, gaps
#    FORTRESS      – barricades and cover objects
#    SNIPER_NEST   – elevated enemies with long sight-lines
#    BUNKER        – dense enemies, limited pickups
#    REWARD_ROOM   – lots of pickups, few enemies
# ─────────────────────────────────────────────────────────────────────────────
class_name LevelGenerator

const ROWS  := Constants.ROWS   # 16
const COLS  := Constants.COLS   # 150
const TS    := Constants.TILE_SIZE

# ── Chunk catalog ─────────────────────────────────────────────────────────────
#  Each chunk is a Dictionary:
#    "width"   → number of columns
#    "pattern" → Array of (row, col, tile_id) triples
enum ChunkType { FLAT, PLATFORM, FORTRESS, SNIPER_NEST, BUNKER, REWARD_ROOM }

# ── Public interface ──────────────────────────────────────────────────────────

static func generate(wave: int, profile: Dictionary) -> Array:
	"""
	Returns a 2-D Array[Array[int]] grid (ROWS x dynamic_cols).
	profile keys:
	  enemy_density   : float  0.0 – 1.0
	  item_density    : float  0.0 – 1.0
	  platform_ratio  : float  0.0 – 1.0  (how aerial the level is)
	  fortress_ratio  : float  0.0 – 1.0
	  sniper_ratio    : float  0.0 – 1.0
	  has_boss        : bool
	"""
	var rng := RandomNumberGenerator.new()
	rng.seed = wave * 7919 + hash(profile.get("seed_salt", 1))

	var grid := _empty_grid(ROWS, COLS)

	# 1. Always start with a flat spawn room (20 tiles wide)
	_write_flat_room(grid, 0, 20, rng, false, false)
	var cursor := 20

	# 2. Stitch chunks based on profile ratios
	var chunk_budget := COLS - 40   # leave 20 for end room
	while cursor < COLS - 20:
		var ctype := _pick_chunk(profile, rng)
		var width := rng.randi_range(18, 28)
		width = min(width, COLS - 20 - cursor)
		if width < 10:
			break
		_write_chunk(grid, cursor, width, ctype, wave, profile, rng)
		cursor += width

	# 3. End room with exit
	_write_end_room(grid, cursor, COLS - cursor, rng)

	# 4. Place player spawn at tile 15
	grid[ROWS - 3][2] = Constants.TILE_PLAYER

	return grid

# ── Grid helpers ──────────────────────────────────────────────────────────────

static func _empty_grid(rows: int, cols: int) -> Array:
	var g : Array = []
	for _r in rows:
		var row : Array = []
		for _c in cols:
			row.append(-1)
		g.append(row)
	return g

static func set_tile(grid: Array, row: int, col: int, id: int) -> void:
	if row >= 0 and row < grid.size() and col >= 0 and col < grid[0].size():
		grid[row][col] = id

# ── Flat room ─────────────────────────────────────────────────────────────────
static func _write_flat_room(grid: Array, start_col: int, width: int,
		rng: RandomNumberGenerator, place_enemies: bool, place_items: bool) -> void:
	# Ground row (row 14, 15)
	for c in range(start_col, start_col + width):
		set_tile(grid, ROWS - 2, c, 0)  # ground tile
		set_tile(grid, ROWS - 1, c, 0)

	if place_enemies and width > 8:
		var mid := start_col + width / 2
		set_tile(grid, ROWS - 3, mid, Constants.TILE_ENEMY)

	if place_items:
		set_tile(grid, ROWS - 3, start_col + 3, Constants.TILE_HEALTH)

# ── Chunk dispatcher ──────────────────────────────────────────────────────────
static func _pick_chunk(profile: Dictionary, rng: RandomNumberGenerator) -> ChunkType:
	var roll := rng.randf()
	var pf   := profile.get("platform_ratio", 0.3)
	var ff   := profile.get("fortress_ratio", 0.2)
	var sf   := profile.get("sniper_ratio", 0.2)
	var rf   := profile.get("item_density", 0.15)

	if roll < rf:
		return ChunkType.REWARD_ROOM
	roll -= rf
	if roll < pf:
		return ChunkType.PLATFORM
	roll -= pf
	if roll < ff:
		return ChunkType.FORTRESS
	roll -= ff
	if roll < sf:
		return ChunkType.SNIPER_NEST
	return ChunkType.FLAT

static func _write_chunk(grid: Array, start: int, width: int, ctype: ChunkType,
		wave: int, profile: Dictionary, rng: RandomNumberGenerator) -> void:
	match ctype:
		ChunkType.FLAT:
			_chunk_flat(grid, start, width, wave, profile, rng)
		ChunkType.PLATFORM:
			_chunk_platform(grid, start, width, wave, profile, rng)
		ChunkType.FORTRESS:
			_chunk_fortress(grid, start, width, wave, profile, rng)
		ChunkType.SNIPER_NEST:
			_chunk_sniper(grid, start, width, wave, profile, rng)
		ChunkType.BUNKER:
			_chunk_bunker(grid, start, width, wave, profile, rng)
		ChunkType.REWARD_ROOM:
			_chunk_reward(grid, start, width, rng)

# ── Chunk implementations ─────────────────────────────────────────────────────

static func _chunk_flat(grid: Array, s: int, w: int, wave: int,
		profile: Dictionary, rng: RandomNumberGenerator) -> void:
	for c in range(s, s + w):
		set_tile(grid, ROWS - 2, c, 0)
		set_tile(grid, ROWS - 1, c, 0)
	# Gap in middle
	if w > 12:
		var gap_start := s + rng.randi_range(4, w - 8)
		var gap_size  := rng.randi_range(2, 4)
		for c in range(gap_start, gap_start + gap_size):
			set_tile(grid, ROWS - 2, c, -1)
			set_tile(grid, ROWS - 1, c, -1)
			# Water in gap
			set_tile(grid, ROWS - 1, c, Constants.TILE_WATER_MIN)
	# Enemies
	var enemy_count := int(profile.get("enemy_density", 0.3) * w * 0.2) + 1
	enemy_count = min(enemy_count, 4)
	for _e in enemy_count:
		var ec := s + rng.randi_range(2, w - 3)
		set_tile(grid, ROWS - 3, ec, Constants.TILE_ENEMY)

static func _chunk_platform(grid: Array, s: int, w: int, wave: int,
		profile: Dictionary, rng: RandomNumberGenerator) -> void:
	# Ground with gaps
	for c in range(s, s + w):
		if rng.randf() > 0.25:
			set_tile(grid, ROWS - 2, c, 0)
			set_tile(grid, ROWS - 1, c, 0)
	# Floating platforms
	var num_platforms := rng.randi_range(2, 5)
	for _p in num_platforms:
		var pr := rng.randi_range(ROWS - 8, ROWS - 4)
		var pc := s + rng.randi_range(1, w - 5)
		var pl := rng.randi_range(3, 6)
		for c in range(pc, min(pc + pl, s + w)):
			set_tile(grid, pr, c, 0)
		# Enemy on platform
		if rng.randf() < profile.get("enemy_density", 0.3):
			set_tile(grid, pr - 1, pc + pl / 2, Constants.TILE_ENEMY)

static func _chunk_fortress(grid: Array, s: int, w: int, _wave: int,
		profile: Dictionary, rng: RandomNumberGenerator) -> void:
	# Ground
	for c in range(s, s + w):
		set_tile(grid, ROWS - 2, c, 0)
		set_tile(grid, ROWS - 1, c, 0)
	# Walls (cover objects)
	var wall_positions := [s + 3, s + w - 5, s + w / 2]
	for wp in wall_positions:
		for r in range(ROWS - 4, ROWS - 2):
			set_tile(grid, r, wp, 1)
			set_tile(grid, r, wp + 1, 1)
	# Dense enemies behind cover
	var enemy_count := int(profile.get("enemy_density", 0.5) * 5) + 2
	for _e in enemy_count:
		var ec := s + rng.randi_range(2, w - 3)
		set_tile(grid, ROWS - 3, ec, Constants.TILE_ENEMY)
	# Ammo pickup reward
	set_tile(grid, ROWS - 3, s + w / 2, Constants.TILE_AMMO)

static func _chunk_sniper(grid: Array, s: int, w: int, _wave: int,
		profile: Dictionary, rng: RandomNumberGenerator) -> void:
	# Ground
	for c in range(s, s + w):
		set_tile(grid, ROWS - 2, c, 0)
		set_tile(grid, ROWS - 1, c, 0)
	# High platform for snipers
	var platform_row := rng.randi_range(ROWS - 10, ROWS - 7)
	for c in range(s + 2, s + w - 2):
		set_tile(grid, platform_row, c, 0)
	# Enemies on high ground (2)
	set_tile(grid, platform_row - 1, s + 4,     Constants.TILE_ENEMY)
	set_tile(grid, platform_row - 1, s + w - 5, Constants.TILE_ENEMY)
	# Ladder / steps to reach high ground
	for r in range(platform_row, ROWS - 2):
		set_tile(grid, r, s + 2, 0)

static func _chunk_bunker(grid: Array, s: int, w: int, _wave: int,
		profile: Dictionary, rng: RandomNumberGenerator) -> void:
	_chunk_fortress(grid, s, w, _wave, profile, rng)
	# Extra enemies
	for _e in 3:
		var ec := s + rng.randi_range(1, w - 2)
		set_tile(grid, ROWS - 3, ec, Constants.TILE_ENEMY)

static func _chunk_reward(grid: Array, s: int, w: int,
		rng: RandomNumberGenerator) -> void:
	for c in range(s, s + w):
		set_tile(grid, ROWS - 2, c, 0)
		set_tile(grid, ROWS - 1, c, 0)
	# Cluster of pickups
	var types := [Constants.TILE_HEALTH, Constants.TILE_AMMO,
				  Constants.TILE_GRENADE, Constants.TILE_HEALTH]
	for i in types.size():
		set_tile(grid, ROWS - 3, s + 2 + i * 3, types[i])
	# Decorations
	for c in range(s, s + w, 4):
		set_tile(grid, ROWS - 3, c, Constants.TILE_DECO_MIN)

static func _write_end_room(grid: Array, start: int, width: int,
		rng: RandomNumberGenerator) -> void:
	for c in range(start, start + width):
		set_tile(grid, ROWS - 2, c, 0)
		set_tile(grid, ROWS - 1, c, 0)
	# Exit tile near the end
	set_tile(grid, ROWS - 3, start + width - 3, Constants.TILE_EXIT)
	# A couple of guards
	set_tile(grid, ROWS - 3, start + 2, Constants.TILE_ENEMY)
	set_tile(grid, ROWS - 3, start + 5, Constants.TILE_ENEMY)

# ── Grid → CSV string ─────────────────────────────────────────────────────────
static func grid_to_csv(grid: Array) -> String:
	var lines : Array[String] = []
	for row in grid:
		lines.append(",".join(row.map(func(v): return str(v))))
	return "\n".join(lines)

# ── Save to tmp file for world.gd ─────────────────────────────────────────────
static func save_temp_level(grid: Array) -> String:
	var path := "user://temp_level.csv"
	var f    := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(grid_to_csv(grid))
	return path
