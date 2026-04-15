extends Node2D
# Floating damage number — spawned at hit position, floats up and fades out.

var _value   : int   = 0
var _elapsed : float = 0.0
const DURATION := 0.9
const RISE     := 60.0   # pixels per second upward

func setup(dmg: int, pos: Vector2, is_crit: bool = false) -> void:
	_value    = dmg
	position  = pos
	var lbl   := $Label
	lbl.text  = ("-%d!" % dmg) if not is_crit else ("-%d CRIT!" % dmg)
	lbl.modulate = Color(1, 0.3, 0.3) if not is_crit else Color(1, 0.9, 0.1)
	if is_crit:
		lbl.theme_override_font_sizes["font_size"] = 20

func _process(delta: float) -> void:
	_elapsed  += delta
	position.y -= RISE * delta
	modulate.a  = 1.0 - (_elapsed / DURATION)
	if _elapsed >= DURATION:
		queue_free()
