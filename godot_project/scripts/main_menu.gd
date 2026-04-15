extends Control
# ─────────────────────────────────────────────
#  MAIN MENU
# ─────────────────────────────────────────────

@onready var btn_tutorial     : Button  = $Center/BtnTutorial
@onready var btn_play         : Button  = $Center/BtnPlay
@onready var btn_endless      : Button  = $Center/BtnEndless
@onready var btn_daily        : Button  = $Center/BtnDaily
@onready var btn_leaderboard  : Button  = $Center/BtnLeaderboard
@onready var btn_achievements : Button  = $Center/BtnAchievements
@onready var btn_settings     : Button  = $Center/BtnSettings
@onready var btn_quit         : Button  = $Center/BtnQuit
@onready var hi_score_label   : Label   = $Center/HiScore
@onready var version_label    : Label   = $VersionLabel
@onready var daily_label      : Label   = $Center/DailyLabel

@onready var settings_panel      : Control = $SettingsPanel
@onready var achievements_panel  : Control = $AchievementsPanel
@onready var leaderboard_panel   : Control = $LeaderboardPanel

var _http : HTTPRequest = null

# ─────────────────────────────────────────────

func _ready() -> void:
	hi_score_label.text = "BEST: %d" % GameManager.high_score
	version_label.text  = "v1.1  —  Survival: Hunter Chronicles"
	daily_label.text    = "Daily Kills: %d" % GameManager.daily_kills

	btn_tutorial.pressed.connect(_on_tutorial)
	btn_play.pressed.connect(_on_play)
	btn_endless.pressed.connect(_on_endless)
	btn_daily.pressed.connect(_on_daily_challenge)
	btn_leaderboard.pressed.connect(_on_leaderboard)
	btn_achievements.pressed.connect(_on_achievements)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)

	leaderboard_panel.get_node("VBox/BtnClose").pressed.connect(
		func(): leaderboard_panel.visible = false)

	settings_panel.visible     = false
	achievements_panel.visible = false
	leaderboard_panel.visible  = false

	AudioManager.play_music("res://assets/audio/music2.mp3")
	_animate_title()

func _animate_title() -> void:
	var title := $Center/Title
	if not is_instance_valid(title):
		return
	var tween := create_tween().set_loops()
	tween.tween_property(title, "scale", Vector2(1.05, 1.05), 0.8)
	tween.tween_property(title, "scale", Vector2(1.0,  1.0),  0.8)

# ── Navigation ────────────────────────────────

func _on_tutorial() -> void:
	GameManager.reset_session()
	WeaponManager.reset()
	var game := get_tree().get_root().get_node_or_null("Game")
	# Load game scene then set is_tutorial before _ready fires
	# We pass it via GameManager flag
	GameManager.start_tutorial = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_play() -> void:
	GameManager.reset_session()
	WeaponManager.reset()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_endless() -> void:
	GameManager.reset_session()
	WeaponManager.reset()
	GameManager.is_endless = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_daily_challenge() -> void:
	GameManager.reset_session()
	WeaponManager.reset()
	GameManager.is_daily_challenge = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")

# ── Achievements ──────────────────────────────

func _on_achievements() -> void:
	achievements_panel.visible = not achievements_panel.visible
	if achievements_panel.visible:
		_populate_achievements()

func _populate_achievements() -> void:
	var list := achievements_panel.get_node_or_null("List")
	if list == null:
		return
	for child in list.get_children():
		child.queue_free()
	if GameManager.achievements.is_empty():
		var lbl := Label.new()
		lbl.text = "No achievements yet — keep playing!"
		list.add_child(lbl)
		return
	for aname in GameManager.achievements.keys():
		var lbl := Label.new()
		lbl.text = "✓ %s — %s" % [aname, GameManager.achievements[aname]["desc"]]
		list.add_child(lbl)

# ── Leaderboard ───────────────────────────────

func _on_leaderboard() -> void:
	leaderboard_panel.visible = true
	_fetch_leaderboard()

func _fetch_leaderboard() -> void:
	var status_lbl : Label = leaderboard_panel.get_node("VBox/Status")
	status_lbl.text = "Loading..."

	# Clear old entries
	var list := leaderboard_panel.get_node("VBox/List")
	for c in list.get_children():
		c.queue_free()

	if _http == null:
		_http = HTTPRequest.new()
		add_child(_http)

	# Disconnect previous signal if any
	if _http.request_completed.is_connected(_on_leaderboard_data):
		_http.request_completed.disconnect(_on_leaderboard_data)
	_http.request_completed.connect(_on_leaderboard_data, CONNECT_ONE_SHOT)

	var url := Leaderboard.FIREBASE_URL + "?orderBy=%22score%22&limitToLast=10"
	var err  := _http.request(url)
	if err != OK:
		status_lbl.text = "Connection failed."

func _on_leaderboard_data(_res: int, code: int, _hdrs: PackedStringArray, body: PackedByteArray) -> void:
	var status_lbl : Label = leaderboard_panel.get_node("VBox/Status")
	var list       : Node  = leaderboard_panel.get_node("VBox/List")

	if code != 200:
		status_lbl.text = "Could not load scores (code %d)" % code
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null or typeof(data) != TYPE_DICTIONARY:
		status_lbl.text = "No scores yet. Be the first!"
		return

	# Firebase returns dict keyed by push ID; sort by score desc
	var entries : Array = data.values()
	entries.sort_custom(func(a, b): return a.get("score", 0) > b.get("score", 0))

	status_lbl.text = ""
	var rank := 1
	for entry in entries:
		var lbl := Label.new()
		lbl.text = "#%d  %s  —  %d" % [rank, entry.get("name", "???"), entry.get("score", 0)]
		if rank == 1:
			lbl.modulate = Color(1, 0.84, 0)
		list.add_child(lbl)
		rank += 1

# ── Settings ──────────────────────────────────

func _on_settings() -> void:
	settings_panel.visible = not settings_panel.visible

func _on_quit() -> void:
	get_tree().quit()
