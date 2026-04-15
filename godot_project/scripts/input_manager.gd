extends Node
# ─────────────────────────────────────────────
#  INPUT MANAGER  –  Autoload singleton
#  Merges keyboard, gamepad AND virtual touch
#  controls into one unified query API.
#
#  Other scripts call:
#    InputManager.is_moving_left()
#    InputManager.is_moving_right()
#    InputManager.is_jumping()
#    InputManager.is_shooting()
#    InputManager.is_throwing_grenade()
# ─────────────────────────────────────────────

# Virtual inputs set by mobile_controls.gd
var _virt_left       : bool = false
var _virt_right      : bool = false
var _virt_jump       : bool = false
var _virt_shoot      : bool = false
var _virt_grenade    : bool = false
var _virt_pause      : bool = false

# Track just-pressed for one-frame actions
var _prev_jump       : bool = false
var _jump_just_pressed : bool = false
var _prev_grenade    : bool = false
var _grenade_just_pressed : bool = false

func _process(_delta: float) -> void:
	# Detect rising edges for jump and grenade (one-shot actions)
	var jump_now     := is_jumping_held()
	_jump_just_pressed  = jump_now and not _prev_jump
	_prev_jump = jump_now

	var gren_now     := is_grenade_held()
	_grenade_just_pressed = gren_now and not _prev_grenade
	_prev_grenade = gren_now

# ── Public API ───────────────────────────────

func is_moving_left() -> bool:
	return Input.is_action_pressed("move_left") or _virt_left

func is_moving_right() -> bool:
	return Input.is_action_pressed("move_right") or _virt_right

func is_jumping() -> bool:
	return _jump_just_pressed

func is_jumping_held() -> bool:
	return Input.is_action_just_pressed("jump") or (_virt_jump and not _prev_jump)

func is_shooting() -> bool:
	return Input.is_action_pressed("shoot") or _virt_shoot

func is_grenade_held() -> bool:
	return Input.is_action_pressed("throw_grenade") or _virt_grenade

func is_throwing_grenade() -> bool:
	return _grenade_just_pressed

func is_pausing() -> bool:
	return Input.is_action_just_pressed("pause") or _virt_pause

# ── Virtual button setters (called by mobile_controls.gd) ──

func set_virtual_left(pressed: bool)    -> void: _virt_left    = pressed
func set_virtual_right(pressed: bool)   -> void: _virt_right   = pressed
func set_virtual_jump(pressed: bool)    -> void: _virt_jump    = pressed
func set_virtual_shoot(pressed: bool)   -> void: _virt_shoot   = pressed
func set_virtual_grenade(pressed: bool) -> void: _virt_grenade = pressed
func set_virtual_pause(pressed: bool)   -> void: _virt_pause   = pressed

func release_all_virtual() -> void:
	_virt_left = _virt_right = _virt_jump = false
	_virt_shoot = _virt_grenade = _virt_pause = false
