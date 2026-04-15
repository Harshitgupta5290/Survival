extends Area2D
# ─────────────────────────────────────────────
#  ITEM BOX  –  pickup for Health / Ammo / Grenade
#  Bobs up & down, glows on player proximity
# ─────────────────────────────────────────────

enum ItemType { HEALTH, AMMO, GRENADE }

var item_type    : ItemType = ItemType.HEALTH
var bob_time     : float    = 0.0
var origin_y     : float    = 0.0

@onready var sprite : Sprite2D = $Sprite2D
@onready var label  : Label    = $Label   # optional "+25" pop text

const BOB_SPEED  := 2.0
const BOB_AMOUNT := 4.0

func _ready() -> void:
	origin_y = position.y
	collision_layer = Constants.LAYER_PICKUP
	collision_mask  = Constants.LAYER_PLAYER
	connect("body_entered", _on_body_entered)
	add_to_group("items")

func setup(type: ItemType, pos: Vector2) -> void:
	item_type       = type
	global_position = pos
	var tex_map := {
		ItemType.HEALTH  : "res://assets/img/icons/health_box.png",
		ItemType.AMMO    : "res://assets/img/icons/ammo_box.png",
		ItemType.GRENADE : "res://assets/img/icons/grenade_box.png"
	}
	sprite.texture = load(tex_map[type])

func _physics_process(delta: float) -> void:
	bob_time      += delta * BOB_SPEED
	position.y     = origin_y + sin(bob_time) * BOB_AMOUNT

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_apply_effect(body)
	AudioManager.play_sfx("pickup")
	queue_free()

func _apply_effect(player: Node) -> void:
	match item_type:
		ItemType.HEALTH:
			if player.has_method("heal"):
				player.heal(Constants.PICKUP_HEALTH_AMOUNT)
		ItemType.AMMO:
			if player.has_method("add_ammo"):
				player.add_ammo(Constants.PICKUP_AMMO_AMOUNT)
		ItemType.GRENADE:
			if player.has_method("add_grenades"):
				player.add_grenades(Constants.PICKUP_GRENADE_AMOUNT)
