extends RigidBody2D
# ─────────────────────────────────────────────
#  GRENADE  –  physics-based, bounces off walls
# ─────────────────────────────────────────────

var direction    : int   = 1
var fuse_time    : float = Constants.GRENADE_TIMER
var exploded     : bool  = false

var explosion_scene : PackedScene = preload("res://scenes/explosion.tscn")

@onready var sprite : Sprite2D = $Sprite2D
@onready var timer  : Timer    = $FuseTimer

func _ready() -> void:
	var tex := load("res://assets/img/icons/grenade.png") as Texture2D
	if tex:
		sprite.texture = tex

	# Launch impulse
	linear_velocity = Vector2(direction * Constants.GRENADE_SPEED, -350.0)
	gravity_scale   = 2.0
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.4

	timer.wait_time = fuse_time
	timer.one_shot  = true
	timer.timeout.connect(_explode)
	timer.start()

func set_direction(dir: int) -> void:
	direction = dir

func _physics_process(_delta: float) -> void:
	# Rotate visually as it flies
	sprite.rotation += 0.15 * direction

func _explode() -> void:
	if exploded:
		return
	exploded = true
	AudioManager.play_sfx("grenade")

	# Spawn explosion visual
	var exp : Node2D = explosion_scene.instantiate()
	exp.global_position = global_position
	get_tree().current_scene.get_node("Effects").add_child(exp)

	# Damage in radius
	var radius := Constants.GRENADE_RADIUS * Constants.TILE_SIZE
	_damage_in_radius("player",  radius, Constants.GRENADE_DAMAGE)
	_damage_in_radius("enemy",   radius, Constants.GRENADE_DAMAGE)

	queue_free()

func _damage_in_radius(group: String, radius: float, dmg: int) -> void:
	for body in get_tree().get_nodes_in_group(group):
		if not is_instance_valid(body):
			continue
		if global_position.distance_to(body.global_position) <= radius:
			if body.has_method("take_damage"):
				body.take_damage(dmg)
