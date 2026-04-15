extends CharacterBody2D
# ─────────────────────────────────────────────────────────────────────────────
#  BOSS ENEMY  –  The Commander
#
#  3 Phases based on remaining health %:
#    Phase 1 (100–60 HP%): Ground assault — charges + shoots bursts
#    Phase 2  (60–25 HP%): Adds grenade spam + becomes faster
#    Phase 3   (<25 HP%): Enrage — burst fire, spawns minions every 8s,
#                          double speed, red glow
#
#  Visual: enemy sprite at 1.8× scale, color-tinted per phase
#  HP: 500  (displayed in a dedicated health bar via signal)
# ─────────────────────────────────────────────────────────────────────────────
class_name Boss

signal boss_died(position: Vector2)
signal boss_hit(amount: int, position: Vector2)
signal boss_health_changed(hp: int, max_hp: int)
signal spawn_minion(position: Vector2)

enum Phase { ONE, TWO, THREE }

# ── Stats ────────────────────────────────────
const MAX_HP          := 500
const PHASE2_THRESH   := 0.60
const PHASE3_THRESH   := 0.25

var hp         : int   = MAX_HP
var phase      : Phase = Phase.ONE
var alive      : bool  = true
var player_ref : Node2D = null
var facing_right : bool = true

# Per-phase speed table
const SPEEDS := {Phase.ONE: 130.0, Phase.TWO: 170.0, Phase.THREE: 220.0}

# ── Timers ───────────────────────────────────
var shoot_timer   : float = 0.0
var charge_timer  : float = 0.0
var grenade_timer : float = 0.0
var minion_timer  : float = 0.0
var burst_count   : int   = 0

# ── Charging state ───────────────────────────
var is_charging   : bool  = false
var charge_vel    : float = 0.0

# ── Nodes ─────────────────────────────────────
@onready var sprite    : AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape : CollisionShape2D = $CollisionShape2D

var bullet_scene  : PackedScene = preload("res://scenes/bullet.tscn")
var grenade_scene : PackedScene = preload("res://scenes/grenade.tscn")

# ─────────────────────────────────────────────

func _ready() -> void:
	_build_animations()
	sprite.play("Idle")
	sprite.scale = Vector2(1.8, 1.8)          # visually bigger
	collision_layer = Constants.LAYER_ENEMY
	collision_mask  = Constants.LAYER_WORLD | Constants.LAYER_PLAYER
	add_to_group("enemy")
	add_to_group("boss")
	emit_signal("boss_health_changed", hp, MAX_HP)

func _build_animations() -> void:
	# Reuse enemy sprite — boss just runs at a bigger scale
	var frames := SpriteFrames.new()
	var anims  := ["Idle", "Run", "Jump", "Death"]
	var speeds := [8.0,    10.0,  6.0,   5.0]
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
		player_ref = get_tree().get_first_node_in_group("player")
		if player_ref == null:
			return

	_update_phase()
	_tick_timers(delta)
	_apply_gravity(delta)
	_run_behaviour(delta)
	move_and_slide()
	_update_animation()

func _update_phase() -> void:
	var ratio : float = float(hp) / float(MAX_HP)
	var new_phase := Phase.ONE
	if ratio <= PHASE3_THRESH:
		new_phase = Phase.THREE
	elif ratio <= PHASE2_THRESH:
		new_phase = Phase.TWO

	if new_phase != phase:
		phase = new_phase
		_on_phase_change()

func _on_phase_change() -> void:
	match phase:
		Phase.TWO:
			sprite.modulate = Color(1.0, 0.6, 0.2)   # orange tint
		Phase.THREE:
			sprite.modulate = Color(1.2, 0.2, 0.2)   # red glow (HDR-like)
			# Brief invincibility flash to signal phase change
			for _i in 6:
				sprite.visible = false
				await get_tree().create_timer(0.1).timeout
				sprite.visible = true
				await get_tree().create_timer(0.1).timeout

func _tick_timers(delta: float) -> void:
	if shoot_timer   > 0.0: shoot_timer   -= delta
	if charge_timer  > 0.0: charge_timer  -= delta
	if grenade_timer > 0.0: grenade_timer -= delta
	if minion_timer  > 0.0: minion_timer  -= delta

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += Constants.GRAVITY * delta
		velocity.y  = min(velocity.y, Constants.MAX_FALL_SPEED)
	else:
		velocity.y = 0.0

func _run_behaviour(delta: float) -> void:
	var spd   : float = SPEEDS[phase]
	var dir   : int   = _dir_to_player()

	# ── Phase 1: charge then shoot ──────────────
	if is_charging:
		velocity.x  = charge_vel
		charge_timer -= delta
		if charge_timer <= 0.0:
			is_charging = false
	else:
		# Walk toward player
		velocity.x = dir * spd * 0.4

		# Charge every 4s
		if charge_timer <= 0.0:
			is_charging  = true
			charge_vel   = dir * spd * 2.5
			charge_timer = 0.6

		# Shoot burst
		if shoot_timer <= 0.0:
			var shots : int = 1 if phase == Phase.ONE else (2 if phase == Phase.TWO else 3)
			for _s in shots:
				_shoot()
				await get_tree().create_timer(0.12).timeout
			shoot_timer = 1.4 if phase == Phase.ONE else (1.0 if phase == Phase.TWO else 0.7)

	# ── Phase 2+: grenade lobs ──────────────────
	if phase != Phase.ONE and grenade_timer <= 0.0:
		_throw_grenade()
		grenade_timer = 3.5 if phase == Phase.TWO else 2.0

	# ── Phase 3: spawn minions ──────────────────
	if phase == Phase.THREE and minion_timer <= 0.0:
		var spawn_pos := global_position + Vector2(randf_range(-200, 200), -10)
		emit_signal("spawn_minion", spawn_pos)
		minion_timer = 8.0

	_face(dir)

# ── Combat ───────────────────────────────────

func _shoot() -> void:
	if not alive:
		return
	var bullet : Node2D = bullet_scene.instantiate()
	bullet.global_position = global_position + Vector2((40 if facing_right else -40), -20)
	bullet.set_direction(1 if facing_right else -1)
	bullet.set_owner_type("enemy")
	bullet.set_damage(12)
	get_tree().current_scene.get_node("Projectiles").add_child(bullet)
	AudioManager.play_sfx("shoot")

func _throw_grenade() -> void:
	var g : Node2D = grenade_scene.instantiate()
	g.global_position = global_position + Vector2(_dir_to_player() * 50, -30)
	g.set_direction(_dir_to_player())
	get_tree().current_scene.get_node("Projectiles").add_child(g)
	AudioManager.play_sfx("grenade")

func take_damage(amount: int) -> void:
	if not alive:
		return
	hp -= amount
	hp  = max(hp, 0)
	emit_signal("boss_hit", amount, global_position)
	emit_signal("boss_health_changed", hp, MAX_HP)

	# Hit flash
	sprite.modulate.v = 2.0
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(self):
		# Restore phase tint
		match phase:
			Phase.ONE:   sprite.modulate = Color(1, 1, 1)
			Phase.TWO:   sprite.modulate = Color(1.0, 0.6, 0.2)
			Phase.THREE: sprite.modulate = Color(1.2, 0.2, 0.2)

	if hp <= 0:
		_die()

func _die() -> void:
	alive = false
	velocity = Vector2.ZERO
	col_shape.set_deferred("disabled", true)
	sprite.play("Death")
	AudioManager.play_sfx("death")
	GameManager.add_kill()
	GameManager.add_kill()   # boss worth double
	GameManager.add_kill()   # and triple
	emit_signal("boss_died", global_position)
	await sprite.animation_finished
	queue_free()

# ── Animation ────────────────────────────────

func _update_animation() -> void:
	if not is_on_floor():
		sprite.play("Jump")
	elif abs(velocity.x) > 10.0:
		sprite.play("Run")
	else:
		sprite.play("Idle")

func _face(dir: int) -> void:
	if dir > 0:
		facing_right  = true
		sprite.flip_h = false
	elif dir < 0:
		facing_right  = false
		sprite.flip_h = true

func _dir_to_player() -> int:
	if player_ref == null or not is_instance_valid(player_ref):
		return 1
	return int(sign(player_ref.global_position.x - global_position.x))
