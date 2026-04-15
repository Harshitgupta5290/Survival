extends CanvasLayer
# ─────────────────────────────────────────────
#  HUD  –  all in-game UI overlays
#  • Health bar with animated drain
#  • Ammo / Grenade counts
#  • Score + Combo multiplier
#  • XP bar
#  • Level / wave indicator
#  • Achievement popup queue
#  • Death screen
# ─────────────────────────────────────────────

@onready var health_bar      : ProgressBar = $Margin/VBox/TopRow/HealthBar
@onready var health_label    : Label       = $Margin/VBox/TopRow/HealthLabel
@onready var ammo_label      : Label       = $Margin/VBox/TopRow/AmmoLabel
@onready var grenade_label   : Label       = $Margin/VBox/TopRow/GrenadeLabel
@onready var score_label     : Label       = $Margin/VBox/TopRow/ScoreLabel
@onready var combo_label     : Label       = $Margin/VBox/TopRow/ComboLabel
@onready var xp_bar          : ProgressBar = $Margin/VBox/XPRow/XPBar
@onready var xp_label        : Label       = $Margin/VBox/XPRow/XPLabel
@onready var level_label     : Label       = $Margin/VBox/XPRow/LevelLabel
@onready var achievement_popup: PanelContainer = $AchievementPopup
@onready var achievement_text : Label      = $AchievementPopup/Label
@onready var death_screen    : Control     = $DeathScreen
@onready var death_score_label: Label      = $DeathScreen/VBox/ScoreLabel
@onready var death_hi_label  : Label       = $DeathScreen/VBox/HiLabel
@onready var restart_btn     : Button      = $DeathScreen/VBox/RestartBtn
@onready var menu_btn        : Button      = $DeathScreen/VBox/MenuBtn

# Animated health drain
var _target_health_ratio : float = 1.0
var _current_ratio       : float = 1.0

# Weapon label (created dynamically)
var weapon_label : Label = null

# Boss bar (created dynamically at bottom of screen)
var boss_bar_container : Control      = null
var boss_bar           : ProgressBar  = null
var boss_name_label    : Label        = null

# Achievement queue
var _achievement_queue   : Array = []
var _showing_achievement : bool  = false

# ─────────────────────────────────────────────

func _ready() -> void:
	achievement_popup.visible = false
	death_screen.visible      = false

	# Weapon label — added dynamically to TopRow
	weapon_label = Label.new()
	weapon_label.text = "[ Pistol ]"
	weapon_label.modulate = Color(0.4, 1.0, 0.4)
	$Margin/VBox/TopRow.add_child(weapon_label)

	# Wire WeaponManager unlock popup
	WeaponManager.weapon_unlocked.connect(_on_weapon_unlocked)

	# Wire GameManager signals
	GameManager.score_changed.connect(on_score_changed)
	GameManager.combo_changed.connect(on_combo_changed)
	GameManager.xp_changed.connect(on_xp_changed)
	GameManager.achievement_unlocked.connect(_queue_achievement)

	# Wire buttons
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_menu)

	on_score_changed(0)
	on_combo_changed(0)

func _process(delta: float) -> void:
	# Smooth health bar drain
	_current_ratio = move_toward(_current_ratio, _target_health_ratio, delta * 0.8)
	health_bar.value = _current_ratio * 100.0

# ── Signal handlers ───────────────────────────

func on_health_changed(hp: int, max_hp: int) -> void:
	_target_health_ratio = float(hp) / float(max_hp)
	health_label.text    = "%d / %d" % [hp, max_hp]
	# Color flash: red when low
	if _target_health_ratio < 0.3:
		health_bar.modulate = Color(1, 0.3, 0.3)
	elif _target_health_ratio < 0.6:
		health_bar.modulate = Color(1, 0.8, 0.2)
	else:
		health_bar.modulate = Color(0.2, 0.9, 0.2)

func on_ammo_changed(ammo: int) -> void:
	ammo_label.text = "AMMO  %d" % ammo
	if ammo == 0:
		ammo_label.modulate = Color(1, 0.3, 0.3)
	else:
		ammo_label.modulate = Color(1, 1, 1)

func on_grenade_changed(count: int) -> void:
	grenade_label.text = "GRENADES  %d" % count

func on_weapon_changed(weapon_name: String) -> void:
	if weapon_label:
		weapon_label.text = "[ %s ]" % weapon_name

func _on_weapon_unlocked(weapon_id: int, name: String) -> void:
	_queue_achievement("New Weapon!", "%s unlocked — press E to switch" % name)

# ── Boss health bar ───────────────────────────

func show_boss_bar(boss_name: String, max_hp: int) -> void:
	if boss_bar_container == null:
		boss_bar_container = Control.new()
		boss_bar_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		boss_bar_container.offset_top    = -60
		boss_bar_container.offset_bottom = 0

		boss_name_label = Label.new()
		boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_name_label.modulate = Color(1, 0.3, 0.3)
		boss_name_label.add_theme_font_size_override("font_size", 16)
		boss_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		boss_name_label.offset_top    = 4
		boss_name_label.offset_bottom = 28

		boss_bar = ProgressBar.new()
		boss_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		boss_bar.offset_left   = 60
		boss_bar.offset_right  = -60
		boss_bar.offset_top    = -26
		boss_bar.offset_bottom = -6
		boss_bar.modulate = Color(1, 0.2, 0.2)

		boss_bar_container.add_child(boss_name_label)
		boss_bar_container.add_child(boss_bar)
		add_child(boss_bar_container)

	boss_name_label.text  = boss_name
	boss_bar.max_value    = max_hp
	boss_bar.value        = max_hp
	boss_bar_container.visible = true

func on_boss_health_changed(hp: int, max_hp: int) -> void:
	if boss_bar:
		boss_bar.value = hp

func hide_boss_bar() -> void:
	if boss_bar_container:
		boss_bar_container.visible = false

func on_score_changed(score: int) -> void:
	score_label.text = "SCORE  %d" % score

func on_combo_changed(combo: int) -> void:
	if combo <= 1:
		combo_label.visible = false
	else:
		combo_label.visible = true
		combo_label.text    = "x%d COMBO!" % combo
		# Scale pop effect
		var tween := create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)

func on_xp_changed(xp: int, plevel: int) -> void:
	xp_bar.max_value = GameManager.xp_to_next_level
	xp_bar.value     = xp
	xp_label.text    = "XP %d / %d" % [xp, GameManager.xp_to_next_level]
	level_label.text  = "LVL %d" % plevel

# ── Achievement popup ─────────────────────────

func _queue_achievement(name: String, desc: String) -> void:
	_achievement_queue.append({"name": name, "desc": desc})
	if not _showing_achievement:
		_show_next_achievement()

func _show_next_achievement() -> void:
	if _achievement_queue.is_empty():
		_showing_achievement = false
		return
	_showing_achievement = true
	var data : Dictionary = _achievement_queue.pop_front()
	achievement_text.text    = "ACHIEVEMENT!\n%s\n%s" % [data["name"], data["desc"]]
	achievement_popup.visible = true

	var tween := create_tween()
	tween.tween_property(achievement_popup, "modulate:a", 1.0, 0.3)
	tween.tween_interval(3.0)
	tween.tween_property(achievement_popup, "modulate:a", 0.0, 0.4)
	await tween.finished
	achievement_popup.visible = false
	_show_next_achievement()

# ── Death screen ──────────────────────────────

func show_death_screen(score: int, hi_score: int) -> void:
	death_screen.visible   = true
	death_score_label.text = "SCORE: %d" % score
	death_hi_label.text    = "BEST: %d" % hi_score
	# Auto-submit to leaderboard if score qualifies
	if score > 0 and Leaderboard.ENABLED:
		Leaderboard.submit_score("HNT", score)   # default name; add name input later

func _on_restart() -> void:
	death_screen.visible = false
	get_tree().current_scene.restart_game()

func _on_menu() -> void:
	get_tree().current_scene.go_to_menu()
