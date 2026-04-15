extends CanvasLayer
# ─────────────────────────────────────────────
#  MOBILE CONTROLS
#  Virtual D-pad (left/right) + Jump + Shoot + Grenade + Pause
#  Works on phone AND tablet – hidden on desktop
# ─────────────────────────────────────────────

@onready var btn_left    : Button = $Buttons/BtnLeft
@onready var btn_right   : Button = $Buttons/BtnRight
@onready var btn_jump    : Button = $Buttons/BtnJump
@onready var btn_shoot   : Button = $Buttons/BtnShoot
@onready var btn_grenade : Button = $Buttons/BtnGrenade
@onready var btn_pause   : Button = $Buttons/BtnPause

func _ready() -> void:
	# Only show on touch devices
	var is_touch := DisplayServer.is_touchscreen_available()
	visible = is_touch

	# Left / Right — held buttons
	_wire_held(btn_left,    func(p): InputManager.set_virtual_left(p))
	_wire_held(btn_right,   func(p): InputManager.set_virtual_right(p))
	_wire_held(btn_shoot,   func(p): InputManager.set_virtual_shoot(p))

	# Jump / Grenade — press-once buttons
	btn_jump.button_down.connect(func(): InputManager.set_virtual_jump(true))
	btn_jump.button_up.connect(func():   InputManager.set_virtual_jump(false))

	btn_grenade.button_down.connect(func(): InputManager.set_virtual_grenade(true))
	btn_grenade.button_up.connect(func():   InputManager.set_virtual_grenade(false))

	btn_pause.pressed.connect(func(): InputManager.set_virtual_pause(true))

func _wire_held(btn: Button, callback: Callable) -> void:
	btn.button_down.connect(func(): callback.call(true))
	btn.button_up.connect(func():   callback.call(false))

func _exit_tree() -> void:
	InputManager.release_all_virtual()
