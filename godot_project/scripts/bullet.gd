extends Area2D
# ─────────────────────────────────────────────
#  BULLET
# ─────────────────────────────────────────────

var direction   : int   = 1       # 1 = right, -1 = left
var owner_type  : String = "player"  # "player" | "enemy"
var speed       : float = Constants.BULLET_SPEED
var lifetime    : float = 1.2     # auto-destroy after N seconds

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

func set_direction(dir: int) -> void:
	direction = dir
	scale.x   = float(dir)   # flip sprite automatically

func set_owner_type(t: String) -> void:
	owner_type = t

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	lifetime   -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("world_tile"):
		queue_free()
		return
	if owner_type == "player" and body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(Constants.BULLET_DAMAGE_ENEMY)
		queue_free()
	elif owner_type == "enemy" and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(Constants.BULLET_DAMAGE_PLAYER)
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()
