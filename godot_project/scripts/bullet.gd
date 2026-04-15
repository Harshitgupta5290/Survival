extends Area2D
# ─────────────────────────────────────────────
#  BULLET
# ─────────────────────────────────────────────

var direction   : int   = 1
var angle_rad   : float = 0.0   # spread offset in radians (shotgun)
var owner_type  : String = "player"
var speed       : float = Constants.BULLET_SPEED
var damage      : int   = Constants.BULLET_DAMAGE_ENEMY
var lifetime    : float = 1.2

@onready var sprite : Sprite2D = $Sprite2D

func _ready() -> void:
	var tex := load("res://assets/img/icons/bullet.png") as Texture2D
	if tex:
		sprite.texture = tex
	collision_layer = Constants.LAYER_BULLET
	if owner_type == "player":
		collision_mask = Constants.LAYER_ENEMY | Constants.LAYER_WORLD
	else:
		collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_WORLD
	connect("body_entered", _on_body_entered)
	connect("area_entered", _on_area_entered)

func set_direction(dir: int, angle_offset: float = 0.0) -> void:
	direction = dir
	angle_rad = angle_offset
	scale.x   = float(dir)
	rotation  = angle_offset * dir

func set_owner_type(t: String) -> void:
	owner_type = t
	# Recalculate mask after owner is set
	if owner_type == "player":
		collision_mask = Constants.LAYER_ENEMY | Constants.LAYER_WORLD
	else:
		collision_mask = Constants.LAYER_PLAYER | Constants.LAYER_WORLD

func set_damage(d: int) -> void:
	damage = d

func set_speed(s: float) -> void:
	speed = s

func _physics_process(delta: float) -> void:
	var vel := Vector2(direction * speed, tan(angle_rad) * speed)
	position += vel * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("world_tile"):
		queue_free()
		return
	if owner_type == "player" and body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif owner_type == "enemy" and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(Constants.BULLET_DAMAGE_PLAYER)
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()
