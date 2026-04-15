extends Control
# ─────────────────────────────────────────────
#  MAIN MENU
#  • Play, Daily Challenge, Endless Mode,
#    Leaderboard, Settings, Achievements
# ─────────────────────────────────────────────

@onready var btn_play         : Button = $Center/VBox/BtnPlay
@onready var btn_endless      : Button = $Center/VBox/BtnEndless
@onready var btn_daily        : Button = $Center/VBox/BtnDaily
@onready var btn_achievements : Button = $Center/VBox/BtnAchievements
@onready var btn_settings     : Button = $Center/VBox/BtnSettings
@onready var btn_quit         : Button = $Center/VBox/BtnQuit
@onready var hi_score_label   : Label  = $Center/HiScore
@onready var version_label    : Label  = $VersionLabel
@onready var daily_label      : Label  = $Center/DailyLabel

@onready var settings_panel   : Control = $SettingsPanel
@onready var achievements_panel: Control = $AchievementsPanel

func _ready() -> void:
	hi_score_label.text  = "BEST: %d" % GameManager.high_score
	version_label.text   = "v1.0  —  Survival: Hunter Chronicles"
	daily_label.text     = "Daily Kills: %d" % GameManager.daily_kills

	btn_play.pressed.connect(_on_play)
	btn_endless.pressed.connect(_on_endless)
	btn_daily.pressed.connect(_on_daily_challenge)
	btn_achievements.pressed.connect(_on_achievements)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)

	settings_panel.visible    = false
	achievements_panel.visible = false

	AudioManager.play_music("res://assets/audio/music2.mp3")
	_animate_title()

func _animate_title() -> void:
	var title := $Center/Title
	if not is_instance_valid(title):
		return
	var tween := create_tween().set_loops()
	tween.tween_property(title, "scale", Vector2(1.05, 1.05), 0.8)
	tween.tween_property(title, "scale", Vector2(1.0,  1.0),  0.8)

func _on_play() -> void:
	GameManager.reset_session()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_endless() -> void:
	GameManager.reset_session()
	GameManager.is_endless = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_daily_challenge() -> void:
	GameManager.reset_session()
	GameManager.is_daily_challenge = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_achievements() -> void:
	achievements_panel.visible = not achievements_panel.visible
	_populate_achievements()

func _populate_achievements() -> void:
	var list := achievements_panel.get_node_or_null("List")
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()
	for aname in GameManager.achievements.keys():
		var lbl := Label.new()
		lbl.text = "✓ %s — %s" % [aname, GameManager.achievements[aname]["desc"]]
		list.add_child(lbl)

func _on_settings() -> void:
	settings_panel.visible = not settings_panel.visible

func _on_quit() -> void:
	get_tree().quit()
