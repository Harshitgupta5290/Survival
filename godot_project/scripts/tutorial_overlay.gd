extends CanvasLayer
# ─────────────────────────────────────────────────────────────────────────────
#  TUTORIAL OVERLAY
#  Shows contextual control hints as the player moves through the tutorial level.
#  Each hint triggers once when the player crosses an X threshold.
#  Fades in → hold → fade out automatically.
# ─────────────────────────────────────────────────────────────────────────────

var player_ref : Node2D = null
var _shown     : Array[bool] = []   # which hints have been shown

# Each hint: [trigger_x_px, title, body]
const HINTS := [
	[80,   "MOVE",    "Press  A ◀  and  D ▶  to walk"],
	[320,  "JUMP",    "Press  W  to jump\nJump again before landing for a double-tap!"],
	[560,  "SHOOT",   "Press  SPACE  to shoot\nWatch your ammo count!"],
	[900,  "GRENADE", "Press  Q  to throw a grenade\nGreat for groups of enemies!"],
	[1600, "ITEMS",   "Collect boxes to restore Health, Ammo and Grenades"],
	[2400, "COMBO",   "Kill enemies quickly to build a COMBO multiplier!"],
	[2800, "EXIT",    "Reach the EXIT door to complete the level!\nGood luck, Hunter."],
]

@onready var panel   : PanelContainer = $Panel
@onready var title_l : Label           = $Panel/VBox/Title
@onready var body_l  : Label           = $Panel/VBox/Body

var _queue    : Array = []
var _busy     : bool  = false

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	panel.visible = false
	_shown.resize(HINTS.size())
	_shown.fill(false)

func set_player(p: Node2D) -> void:
	player_ref = p

func _process(_delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		return

	var px : float = player_ref.global_position.x

	for i in HINTS.size():
		if not _shown[i] and px >= HINTS[i][0]:
			_shown[i] = true
			_queue.append({"title": HINTS[i][1], "body": HINTS[i][2]})

	if not _busy and not _queue.is_empty():
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var data : Dictionary = _queue.pop_front()
	title_l.text = data["title"]
	body_l.text  = data["body"]
	panel.modulate.a = 0.0
	panel.visible    = true

	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.0)
	tw.tween_property(panel, "modulate:a", 0.0, 0.4)
	await tw.finished
	panel.visible = false
	_show_next()
