extends CharacterBody2D
# ─────────────────────────────────────────────
#  PLAYER
#  • Full movement with coyote-time & jump buffer
#  • Shoot / grenade with cooldowns
#  • Animated sprite loaded from files at runtime
#  • Hit-flash + invincibility frames
#  • Signals drive HUD updates (zero coupling)
# ─────────────────────────────────────────────
class_name Player

# ── Signals ──────────────────────────────────
signal health_changed(new_hp: int, max_hp: int)
signal ammo_changed(new_ammo: int)
signal grenade_changed(new_grenades: int)
signal player_died
signal level_complete

# ── State ────────────────────────────────────
enum Anim { IDLE, RUN, JUMP, DEATH }

var health        : int   = Constants.PLAYER_HEALTH
var max_health    : int   = Constants.PLAYER_HEALTH
var ammo          : int   = Constants.PLAYER_AMMO
var grenades      : int   = Constants.PLAYER_GRENADES
var alive         : bool  = true
var facing_right  : bool  = true

var shoot_timer       : float = 0.0
var invincible_timer  : float = 0.0
var coyote_timer      : float = 0.0   # allows jump briefly after walking off ledge
var jump_buffer_timer : float = 0.0   # queues jump when pressed just before landing
var grenade_on_cooldown : bool = false

const COYOTE_TIME    := 0.12
const JUMP_BUFFER    := 0.10
const FLASH_INTERVAL := 0.08

# ── Node refs ────────────────────────────────
@onready var sprite     : AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape  : CollisionShape2D = $CollisionShape2D
@onready var shoot_pos  : Marker2D         = $ShootPos
@onready var muzzle_fx  : GPUParticles2D   = $MuzzleFlash if has_node("MuzzleFlash") else null

# Preload scenes
var bullet_scene  : PackedScene = preload("res://scenes/bullet.tscn")
var grenade_scene : PackedScene = preload("res://scenes/grenade.tscn")

# ─────────────────────────────────────────────

func _ready() -> void:
	_build_animations()
	sprite.play("Idle")
	collision_layer = Constants.LAYER_PLAYER
	collision_mask  = Constants.LAYER_WORLD | Constants.LAYER_ENEMY

func _build_animations() -> void:
	var frames := SpriteFrames.new()
	var anims  := ["Idle", "Run", "Jump", "Death"]
	var speeds := [8.0,    10.0,  6.0,   6.0]

	for i in anims.size():
		var aname := anims[i]
		frames.add_animation(aname)
		frames.set_animation_speed(aname, speeds[i])
		frames.set_animation_loop(aname, aname != "Death")
		var dir := "res://assets/img/player/%s/" % aname
		var j   := 0
		while ResourceLoader.exists(dir + "%d.png" % j):
			frames.add_frame(aname, load(dir + "%d.png" % j))
			j += 1

	sprite.sprite_frames = frames

# ── Per-frame ────────────────────────────────

func _physics_process(delta: float) -> void:
	if not alive:
		return

	_handle_timers(delta)
	_handle_movement(delta)
	_handle_combat()
	_update_animation()

func _handle_timers(delta: float) -> void:
	if shoot_timer > 0.0:
		shoot_timer -= delta
	if invincible_timer > 0.0:
		invincible_timer -= delta
		# Flash effect
		sprite.modulate.a = 0.0 if int(invincible_timer / FLASH_INTERVAL) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta

func _handle_movement(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += Constants.GRAVITY * delta
		velocity.y  = min(velocity.y, Constants.MAX_FALL_SPEED)
		coyote_timer = max(0.0, coyote_timer - delta)
	else:
		coyote_timer = COYOTE_TIME
		velocity.y   = 0.0

	# Horizontal
	var dir := 0
	if InputManager.is_moving_left():
		dir         -= 1
		facing_right = false
		sprite.flip_h = true
	if InputManager.is_moving_right():
		dir         += 1
		facing_right = true
		sprite.flip_h = false

	velocity.x = dir * Constants.PLAYER_SPEED

	# Jump
	if InputManager.is_jumping():
		jump_buffer_timer = JUMP_BUFFER

	if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0):
		velocity.y        = Constants.JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer      = 0.0
		AudioManager.play_sfx("jump")

	move_and_slide()

	# Kill on water / fall
	if position.y > Constants.SCREEN_HEIGHT + 100:
		take_damage(max_health)

func _handle_combat() -> void:
	if InputManager.is_shooting() and shoot_timer <= 0.0 and ammo > 0:
		_shoot()
	if InputManager.is_throwing_grenade() and grenades > 0 and not grenade_on_cooldown:
		_throw_grenade()

func _update_animation() -> void:
	if not is_on_floor():
		sprite.play("Jump")
	elif abs(velocity.x) > 10.0:
		sprite.play("Run")
	else:
		sprite.play("Idle")

# ── Combat ───────────────────────────────────

func _shoot() -> void:
	shoot_timer = Constants.SHOOT_COOLDOWN
	ammo       -= 1
	emit_signal("ammo_changed", ammo)
	AudioManager.play_sfx("shoot")

	var bullet : Node2D = bullet_scene.instantiate()
	bullet.global_position = shoot_pos.global_position if shoot_pos else global_position
	bullet.set_direction(1 if facing_right else -1)
	bullet.set_owner_type("player")
	get_tree().current_scene.get_node("Projectiles").add_child(bullet)

func _throw_grenade() -> void:
	grenades -= 1
	grenade_on_cooldown = true
	emit_signal("grenade_changed", grenades)
	AudioManager.play_sfx("grenade")

	var g : Node2D = grenade_scene.instantiate()
	var offset := Vector2((50 if facing_right else -50), -20)
	g.global_position = global_position + offset
	g.set_direction(1 if facing_right else -1)
	get_tree().current_scene.get_node("Projectiles").add_child(g)

	# Simple cooldown using a timer
	await get_tree().create_timer(0.8).timeout
	grenade_on_cooldown = false

func take_damage(amount: int) -> void:
	if invincible_timer > 0.0 or not alive:
		return
	health         -= amount
	invincible_timer = Constants.INVINCIBLE_DURATION
	GameManager.register_player_hit()
	emit_signal("health_changed", health, max_health)

	if health <= 0:
		health = 0
		_die()

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	emit_signal("health_changed", health, max_health)

func add_ammo(amount: int) -> void:
	ammo += amount
	emit_signal("ammo_changed", ammo)

func add_grenades(amount: int) -> void:
	grenades += amount
	emit_signal("grenade_changed", grenades)

func _die() -> void:
	alive = false
	velocity = Vector2.ZERO
	col_shape.set_deferred("disabled", true)
	sprite.play("Death")
	AudioManager.play_sfx("death")
	await sprite.animation_finished
	emit_signal("player_died")

func on_reach_exit() -> void:
	emit_signal("level_complete")

# ── Scroll support ────────────────────────────
# Called by game.gd every frame to shift the world
func apply_scroll(dx: float) -> void:
	position.x += dx
