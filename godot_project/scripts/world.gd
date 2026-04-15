extends Node2D
# ─────────────────────────────────────────────
#  WORLD  –  loads CSV tile data and builds the level
#
#  Tile index legend (from original game):
#    0-8   → solid obstacles
#    9-10  → water (instant kill)
#    11-14 → decoration (no collision)
#    15    → player spawn
#    16    → enemy spawn
#    17    → ammo box
#    18    → grenade box
#    19    → health box
#    20    → exit door
# ─────────────────────────────────────────────

signal player_spawned(player_node: Node2D)
signal level_length_set(pixels: float)

const TILE_SIZE := Constants.TILE_SIZE
const ROWS      := Constants.ROWS
const TILE_TYPES := Constants.TILE_TYPES

var obstacle_rects   : Array[Rect2] = []   # for custom collision
var tile_sprites     : Array[Sprite2D] = []
var level_length_px  : float = 0.0

# Preloaded tile textures
var tile_textures    : Array[Texture2D] = []

# Preloaded scene references
var player_scene     : PackedScene = preload("res://scenes/player.tscn")
var enemy_scene      : PackedScene = preload("res://scenes/enemy.tscn")
var item_box_scene   : PackedScene = preload("res://scenes/item_box.tscn")
var exit_scene       : PackedScene = preload("res://scenes/exit_zone.tscn")

# Background layers for parallax
var bg_layers        : Array[Sprite2D] = []
var bg_scroll_factors: Array[float]   = [0.5, 0.6, 0.7, 0.8]

# ─────────────────────────────────────────────

func _ready() -> void:
	_load_tile_textures()
	_build_background()

func _load_tile_textures() -> void:
	tile_textures.clear()
	for i in TILE_TYPES:
		var path := "res://assets/img/tile/%d.png" % i
		if ResourceLoader.exists(path):
			tile_textures.append(load(path) as Texture2D)
		else:
			tile_textures.append(null)

func _build_background() -> void:
	var bg_files := [
		"res://assets/img/background/sky_cloud.png",
		"res://assets/img/background/mountain.png",
		"res://assets/img/background/pine1.png",
		"res://assets/img/background/pine2.png"
	]
	var bg_y_offsets := [0.0, 80.0, 160.0, 200.0]

	for i in bg_files.size():
		var path := bg_files[i]
		if not ResourceLoader.exists(path):
			continue
		var tex : Texture2D = load(path)
		# Tile 5 copies for seamless scroll
		for copy in range(5):
			var s := Sprite2D.new()
			s.texture   = tex
			s.centered  = false
			s.position  = Vector2(copy * tex.get_width(), bg_y_offsets[i])
			s.z_index   = -10 + i
			add_child(s)
			bg_layers.append(s)

# ── Level loading ────────────────────────────

func load_level(level_index: int) -> Dictionary:
	# Clear old tiles
	_clear()

	var path := "res://assets/levels/level%d_data.csv" % level_index
	if not FileAccess.file_exists(path):
		push_error("Level file not found: " + path)
		return {}

	var grid : Array = _read_csv(path)
	return _build_level(grid)

func _read_csv(path: String) -> Array:
	var file   := FileAccess.open(path, FileAccess.READ)
	var result : Array = []
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var row : Array = []
		for cell in line.split(","):
			row.append(int(cell.strip_edges()))
		result.append(row)
	return result

func _build_level(grid: Array) -> Dictionary:
	var spawn_data := {
		"player_pos"  : Vector2.ZERO,
		"enemies"     : [],
		"items"       : [],
		"exit_pos"    : Vector2.ZERO
	}

	var cols := grid[0].size() if grid.size() > 0 else 0
	level_length_px = cols * TILE_SIZE
	emit_signal("level_length_set", level_length_px)

	for row_i in grid.size():
		for col_i in grid[row_i].size():
			var tile_id : int = grid[row_i][col_i]
			if tile_id < 0:
				continue

			var world_pos := Vector2(col_i * TILE_SIZE, row_i * TILE_SIZE)

			if tile_id <= Constants.TILE_OBSTACLE_MAX:
				_place_tile(tile_id, world_pos, true)

			elif tile_id <= Constants.TILE_WATER_MAX:
				_place_tile(tile_id, world_pos, false, "water")

			elif tile_id <= Constants.TILE_DECO_MAX:
				_place_tile(tile_id, world_pos, false, "decoration")

			elif tile_id == Constants.TILE_PLAYER:
				spawn_data["player_pos"] = world_pos

			elif tile_id == Constants.TILE_ENEMY:
				spawn_data["enemies"].append(world_pos)

			elif tile_id == Constants.TILE_AMMO:
				spawn_data["items"].append({"type": "ammo", "pos": world_pos})

			elif tile_id == Constants.TILE_GRENADE:
				spawn_data["items"].append({"type": "grenade", "pos": world_pos})

			elif tile_id == Constants.TILE_HEALTH:
				spawn_data["items"].append({"type": "health", "pos": world_pos})

			elif tile_id == Constants.TILE_EXIT:
				spawn_data["exit_pos"] = world_pos
				_place_tile(tile_id, world_pos, false, "exit")

	return spawn_data

func _place_tile(id: int, pos: Vector2, solid: bool, group: String = "") -> void:
	var tex := tile_textures[id] if id < tile_textures.size() else null
	if tex == null:
		return

	var s := Sprite2D.new()
	s.texture  = tex
	s.centered = false
	s.position = pos
	add_child(s)
	tile_sprites.append(s)

	if solid:
		var body := StaticBody2D.new()
		body.position = pos
		body.add_to_group("world_tile")
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape  = shape
		col.position = Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
		body.add_child(col)
		add_child(body)
		obstacle_rects.append(Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)))

	if group != "":
		s.add_to_group(group)

# ── Scroll ────────────────────────────────────

func scroll(dx: float) -> void:
	# Shift all tiles and bodies
	for child in get_children():
		if child is Sprite2D or child is StaticBody2D:
			child.position.x += dx

	# Parallax background
	for i in bg_layers.size():
		var factor_index := i / 5   # each background image uses 5 copies
		if factor_index < bg_scroll_factors.size():
			bg_layers[i].position.x += dx * bg_scroll_factors[factor_index]

# ── Cleanup ───────────────────────────────────

func _clear() -> void:
	obstacle_rects.clear()
	tile_sprites.clear()
	for child in get_children():
		if child is Sprite2D or child is StaticBody2D:
			child.queue_free()
