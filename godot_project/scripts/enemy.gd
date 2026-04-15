extends CharacterBody2D
# ─────────────────────────────────────────────
#  ENEMY  –  Advanced AI with a full state machine
#
#  States:
#    PATROL   → walk back & forth
#    ALERT    → player spotted, move toward
#    ATTACK   → in range, shoot
#    TAKE_COVER → health low, strafe away
#    FLEE     → critical health, run
#    DEAD     → play death animation then queue_free
#
#  Adaptive difficulty via GameManager multipliers
# ─────────────────────────────────────────────
class_name Enemy

signal enemy_died(position: Vector2)

# ── AI States ────────────────────────────────
enum State { PATROL, ALERT, ATTACK, TAKE_COVER, FLEE, DEAD }

var state           : State = State.PATROL
var player_ref      : Node2D = null   # set by game.gd after spawn

# ── Stats (scaled by difficulty) ─────────────
var health         : int   = Constants.ENEMY_HEALTH
var max_health     : int   = Constants.ENEMY_HEALTH
var ammo           : int   = Constants.ENEMY_AMMO
var speed          : float = Constants.ENEMY_BASE_SPEED
var vision_range   : float = Constants.ENEMY_VISION_RANGE
var shoot_cooldown : float = Constants.ENEMY_SHOOT_COOLDOWN

var alive          : bool  = true
var facing_right   : bool  = true

# ── Patrol ───────────────────────────────────
var patrol_origin  : Vector2
var patrol_dir     : int   = 1       # 1 = right, -1 = left
var patrol_dist    : float = 0.0
const PATROL_MAX   : float = Constants.ENEMY_PATROL_DISTANCE * Constants.TILE_SIZE

# ── Timers ───────────────────────────────────
var shoot_timer     : float = 0.0
var idle_timer      : float = 0.0     # random idle pause
var cover_timer     : float = 0.0
var alert_timer     : float = 0.0     # how long to stay alert
var grenade_timer   : float = 0.0

# ── Nodes ─────────────────────────────────────
@onready var sprite    : AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape : CollisionShape2D = $CollisionShape2D

var bullet_scene  : PackedScene = preload("res://scenes/bullet.tscn")
var grenade_scene : PackedScene = preload("res://scenes/grenade.tscn")

# ─────────────────────────────────────────────

func _ready() -> void:
	patrol_origin = global_position
	_build_animations()
	sprite.play("Idle")
	collision_layer = Constants.LAYER_ENEMY
	collision_mask  = Constants.LAYER_WORLD | Constants.LAYER_PLAYER

	# Apply adaptive difficulty
	speed         *= GameManager.get_enemy_speed_mult()
	shoot_cooldown *= GameManager.get_enemy_shoot_cooldown_mult()
	vision_range   *= GameManager.get_enemy_vision_mult()

func _build_animations() -> void:
	var frames := SpriteFrames.new()
	var anims  := ["Idle", "Run", "Jump", "Death"]
	var speeds := [8.0,    10.0,  6.0,   6.0]

	for i in anims.size():
		var aname := anims[i]
		frames.add_animation(aname)
		frames.set_animation_speed(aname, speeds[i])
		frames.set_animation_loop(aname, aname != "Death")
		var dir := "res://assets/img/enemy/%s/" % aname
		var j   := 0
		while ResourceLoader.exists(dir + "%d.png" % j):
			frames.add_frame(aname, load(dir + "%d.png" % j))
			j += 1

	sprite.sprite_frames = frames

# ── Main loop ────────────────────────────────

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if player_ref == null:
		_find_player()

	_tick_timers(delta)
	_run_state_machine(delta)
	_apply_gravity(delta)
	move_and_slide()
	_update_animation()

func _tick_timers(delta: float) -> void:
	if shoot_timer     > 0.0: shoot_timer     -= delta
	if idle_timer      > 0.0: idle_timer      -= delta
	if cover_timer     > 0.0: cover_timer     -= delta
	if alert_timer     > 0.0: alert_timer     -= delta
	if grenade_timer   > 0.0: grenade_timer   -= delta

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += Constants.GRAVITY * delta
		velocity.y  = min(velocity.y, Constants.MAX_FALL_SPEED)
	else:
		velocity.y = 0.0

# ── State Machine ─────────────────────────────

func _run_state_machine(delta: float) -> void:
	var dist := _dist_to_player()

	match state:
		State.PATROL:   _do_patrol(dist)
		State.ALERT:    _do_alert(dist)
		State.ATTACK:   _do_attack(dist)
		State.TAKE_COVER: _do_take_cover()
		State.FLEE:     _do_flee()
		State.DEAD:     pass

func _do_patrol(dist: float) -> void:
	if idle_timer > 0.0:
		velocity.x = 0.0
		return

	# Random idle pause
	if randi() % Constants.ENEMY_IDLE_CHANCE == 0:
		idle_timer = randf_range(0.5, 1.5)
		return

	# Walk
	velocity.x = patrol_dir * speed
	patrol_dist += abs(velocity.x) * get_physics_process_delta_time()

	if patrol_dist >= PATROL_MAX:
		patrol_dir  *= -1
		patrol_dist  = 0.0

	_face_direction(patrol_dir)

	# Transition check
	if dist <= vision_range:
		_set_state(State.ALERT)

func _do_alert(dist: float) -> void:
	alert_timer = 3.0
	var dir := _dir_to_player()
	velocity.x = dir * speed * 1.2   # move slightly faster when alerted
	_face_direction(dir)

	# Occasional grenade throw while chasing
	if grenade_timer <= 0.0 and randi() % Constants.ENEMY_GRENADE_CHANCE == 0:
		_throw_grenade()
		grenade_timer = randf_range(4.0, 8.0)

	if dist <= Constants.ENEMY_VISION_RANGE * 0.5:
		_set_state(State.ATTACK)
	elif dist > vision_range * 1.5:
		_set_state(State.PATROL)

func _do_attack(dist: float) -> void:
	# Strafe slightly to be less of a sitting duck
	velocity.x = _dir_to_player() * speed * 0.3

	# Shoot
	if shoot_timer <= 0.0 and ammo > 0:
		_shoot()
		shoot_timer = shoot_cooldown

	# Health-based transitions
	if float(health) / float(max_health) < 0.3:
		_set_state(State.TAKE_COVER)
	elif dist > Constants.ENEMY_VISION_RANGE * 0.6:
		_set_state(State.ALERT)

func _do_take_cover() -> void:
	# Strafe away from player and wait before re-engaging
	velocity.x = -_dir_to_player() * speed * 0.8
	cover_timer -= get_physics_process_delta_time()

	if float(health) / float(max_health) < 0.15:
		_set_state(State.FLEE)
	elif cover_timer <= 0.0:
		_set_state(State.ATTACK)

func _do_flee() -> void:
	velocity.x = -_dir_to_player() * speed * 1.5
	_face_direction(int(sign(velocity.x)))

func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	match state:
		State.TAKE_COVER: cover_timer = randf_range(1.5, 3.0)
		State.PATROL:     patrol_dist = 0.0

# ── Combat ───────────────────────────────────

func _shoot() -> void:
	if not alive or ammo <= 0:
		return
	ammo -= 1
	AudioManager.play_sfx("shoot")

	var bullet : Node2D = bullet_scene.instantiate()
	bullet.global_position = global_position + Vector2((30 if facing_right else -30), -10)
	bullet.set_direction(1 if facing_right else -1)
	bullet.set_owner_type("enemy")
	get_tree().current_scene.get_node("Projectiles").add_child(bullet)

func _throw_grenade() -> void:
	var g : Node2D = grenade_scene.instantiate()
	g.global_position = global_position + Vector2(_dir_to_player() * 40, -20)
	g.set_direction(_dir_to_player())
	get_tree().current_scene.get_node("Projectiles").add_child(g)
	AudioManager.play_sfx("grenade")

func take_damage(amount: int) -> void:
	if not alive:
		return
	health -= amount
	# Flash red
	sprite.modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		sprite.modulate = Color(1, 1, 1)

	if health <= 0:
		health = 0
		_die()

func _die() -> void:
	alive      = false
	state      = State.DEAD
	velocity   = Vector2.ZERO
	col_shape.set_deferred("disabled", true)
	sprite.play("Death")
	AudioManager.play_sfx("death")
	GameManager.add_kill()
	emit_signal("enemy_died", global_position)
	await sprite.animation_finished
	queue_free()

# ── Animation ────────────────────────────────

func _update_animation() -> void:
	if state == State.DEAD:
		return
	if not is_on_floor():
		sprite.play("Jump")
	elif abs(velocity.x) > 10.0:
		sprite.play("Run")
	else:
		sprite.play("Idle")

func _face_direction(dir: int) -> void:
	if dir > 0:
		facing_right  = true
		sprite.flip_h = false
	elif dir < 0:
		facing_right  = false
		sprite.flip_h = true

# ── Helpers ───────────────────────────────────

func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")

func _dist_to_player() -> float:
	if player_ref == null or not is_instance_valid(player_ref):
		return INF
	return global_position.distance_to(player_ref.global_position)

func _dir_to_player() -> int:
	if player_ref == null:
		return patrol_dir
	return int(sign(player_ref.global_position.x - global_position.x))
