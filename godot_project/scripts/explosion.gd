extends Node2D
# ─────────────────────────────────────────────
#  EXPLOSION  –  plays animated sprite then dies
# ─────────────────────────────────────────────

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	_build_animation()
	sprite.play("explode")
	sprite.animation_finished.connect(queue_free)
	# Screen shake via Camera (optional, handled by game.gd listening to this node)
	add_to_group("explosions")

func _build_animation() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("explode")
	frames.set_animation_speed("explode", 14.0)
	frames.set_animation_loop("explode", false)

	for i in range(1, 6):
		var path := "res://assets/img/explosion/exp%d.png" % i
		if ResourceLoader.exists(path):
			frames.add_frame("explode", load(path))

	sprite.sprite_frames = frames
	sprite.scale = Vector2(1.5, 1.5)
