extends Node2D
# ─────────────────────────────────────────────
#  GAME  –  master scene controller
#
#  Responsibilities:
#    • Load / unload levels
#    • Spawn player, enemies, items
#    • Drive world scrolling and camera
#    • Wire signals between subsystems
#    • Handle pause, death, level complete
# ─────────────────────────────────────────────

# ── Node references ──────────────────────────
@onready var world            : Node2D   = $World
@onready var entities         : Node2D   = $Entities
@onready var projectiles      : Node2D   = $Projectiles
@onready var effects          : Node2D   = $Effects
@onready var items_node       : Node2D   = $Items
@onready var camera           : Camera2D = $Camera2D
@onready var hud              : Node     = $HUD
@onready var mobile_controls  : Node     = $MobileControls
@onready var death_overlay    : ColorRect = $DeathOverlay
@onready var level_banner     : Label     = $LevelBanner
@onready var pause_menu       : Node      = $PauseMenu

# ── State ────────────────────────────────────
var player_node   : Node2D = null
var current_level : int    = 1
var paused        : bool   = false
var game_over     : bool   = false
var level_ending  : bool   = false

# Scroll
var scroll_offset : float  = 0.0
var level_max_x   : float  = 6000.0
const SCROLL_THRESH : int  = Constants.SCROLL_THRESH

# Preloaded scenes
var player_scene   : PackedScene = preload("res://scenes/player.tscn")
var enemy_scene    : PackedScene = preload("res://scenes/enemy.tscn")
var item_box_scene : PackedScene = preload("res://scenes/item_box.tscn")
var exit_scene     : PackedScene = preload("res://scenes/exit_zone.tscn")

# ─────────────────────────────────────────────

func _ready() -> void:
	death_overlay.visible = false
	pause_menu.visible    = false
	GameManager.reset_session()
	_start_level(current_level)

func _start_level(level_num: int) -> void:
	level_ending = false
	_clear_entities()

	var spawn_data : Dictionary = world.load_level(level_num)
	world.level_length_set.connect(_on_level_length_set, CONNECT_ONE_SHOT)

	# Spawn player
	player_node = player_scene.instantiate()
	player_node.position = spawn_data.get("player_pos", Vector2(100, 300))
	player_node.add_to_group("player")
	entities.add_child(player_node)

	# Wire player signals → HUD
	player_node.health_changed.connect(hud.on_health_changed)
	player_node.ammo_changed.connect(hud.on_ammo_changed)
	player_node.grenade_changed.connect(hud.on_grenade_changed)
	player_node.player_died.connect(_on_player_died)
	player_node.level_complete.connect(_on_level_complete)

	# Initial HUD values
	hud.on_health_changed(player_node.health, player_node.max_health)
	hud.on_ammo_changed(player_node.ammo)
	hud.on_grenade_changed(player_node.grenades)

	# Spawn enemies
	for epos in spawn_data.get("enemies", []):
		_spawn_enemy(epos)

	# Spawn items
	for item_data in spawn_data.get("items", []):
		_spawn_item(item_data["type"], item_data["pos"])

	# Spawn exit
	var exit_pos : Vector2 = spawn_data.get("exit_pos", Vector2.ZERO)
	if exit_pos != Vector2.ZERO:
		var exit : Node2D = exit_scene.instantiate()
		exit.position = exit_pos
		exit.body_entered.connect(_on_exit_entered)
		items_node.add_child(exit)

	# Camera setup
	camera.limit_right  = int(level_max_x)
	camera.limit_bottom = Constants.SCREEN_HEIGHT
	scroll_offset = 0.0

	# Banner
	_show_level_banner("LEVEL %d" % level_num)

	# Music
	AudioManager.play_music("res://assets/audio/music2.mp3")

# ── Physics ───────────────────────────────────

func _physics_process(delta: float) -> void:
	if paused or game_over:
		return

	# Pause input
	if InputManager.is_pausing():
		_toggle_pause()
		return

	if player_node == null or not is_instance_valid(player_node):
		return

	_update_scroll()

func _update_scroll() -> void:
	if player_node == null:
		return
	var px := player_node.global_position.x

	var scroll_dx : float = 0.0

	# Right scroll
	if px > Constants.SCREEN_WIDTH - SCROLL_THRESH and scroll_offset < level_max_x - Constants.SCREEN_WIDTH:
		scroll_dx = player_node.velocity.x * get_physics_process_delta_time()

	# Left scroll
	if px < SCROLL_THRESH and scroll_offset > 0:
		scroll_dx = player_node.velocity.x * get_physics_process_delta_time()

	if scroll_dx == 0.0:
		return

	scroll_offset -= scroll_dx
	scroll_offset  = clampf(scroll_offset, 0.0, level_max_x - Constants.SCREEN_WIDTH)

	# Move everything except the player
	world.scroll(scroll_dx)
	for e in get_tree().get_nodes_in_group("enemy"):
		e.position.x += scroll_dx
	for p in get_tree().get_nodes_in_group("projectile"):
		p.position.x += scroll_dx
	for exp in get_tree().get_nodes_in_group("explosions"):
		exp.position.x += scroll_dx
	for item in get_tree().get_nodes_in_group("items"):
		item.position.x += scroll_dx

# ── Spawning ─────────────────────────────────

func _spawn_enemy(pos: Vector2) -> void:
	var e : Node2D = enemy_scene.instantiate()
	e.position = pos
	e.player_ref = player_node
	e.add_to_group("enemy")
	entities.add_child(e)
	e.enemy_died.connect(_on_enemy_died)

func _spawn_item(type_str: String, pos: Vector2) -> void:
	var ib : Node2D = item_box_scene.instantiate()
	items_node.add_child(ib)
	var type_map := {"health": 0, "ammo": 1, "grenade": 2}
	ib.setup(type_map.get(type_str, 0), pos)

func _clear_entities() -> void:
	for child in entities.get_children():
		child.queue_free()
	for child in projectiles.get_children():
		child.queue_free()
	for child in effects.get_children():
		child.queue_free()
	for child in items_node.get_children():
		child.queue_free()
	player_node = null

# ── Callbacks ────────────────────────────────

func _on_level_length_set(px: float) -> void:
	level_max_x        = px
	camera.limit_right = int(px)

func _on_player_died() -> void:
	game_over = true
	AudioManager.stop_music()
	await get_tree().create_timer(1.5).timeout
	death_overlay.visible = true
	hud.show_death_screen(GameManager.score, GameManager.high_score)

func _on_level_complete() -> void:
	if level_ending:
		return
	level_ending = true
	GameManager.complete_level()
	AudioManager.stop_music()
	_show_level_banner("LEVEL COMPLETE!")

	await get_tree().create_timer(2.0).timeout

	current_level += 1
	if current_level > Constants.MAX_LEVELS:
		_show_game_win()
	else:
		_start_level(current_level)

func _on_enemy_died(_pos: Vector2) -> void:
	pass   # GameManager already updated via add_kill()

func _on_exit_entered(body: Node) -> void:
	if body.is_in_group("player") and not level_ending:
		if player_node and player_node.has_method("on_reach_exit"):
			player_node.on_reach_exit()

# ── Pause ─────────────────────────────────────

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	pause_menu.visible = paused
	if paused:
		AudioManager.stop_music()
	else:
		AudioManager.play_music("res://assets/audio/music2.mp3")

func resume_game() -> void:
	_toggle_pause()

func restart_game() -> void:
	game_over = false
	death_overlay.visible = false
	current_level = 1
	GameManager.reset_session()
	_start_level(current_level)

func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ── UI helpers ────────────────────────────────

func _show_level_banner(text: String) -> void:
	level_banner.text    = text
	level_banner.visible = true
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(level_banner):
		level_banner.visible = false

func _show_game_win() -> void:
	_show_level_banner("YOU WIN! Thanks for playing!")
	await get_tree().create_timer(3.0).timeout
	go_to_menu()

# ── Screen shake ──────────────────────────────
func _shake_camera(intensity: float = 6.0, duration: float = 0.3) -> void:
	var original := camera.offset
	var end_time := Time.get_ticks_msec() + duration * 1000.0
	while Time.get_ticks_msec() < end_time:
		camera.offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		await get_tree().process_frame
	camera.offset = original
