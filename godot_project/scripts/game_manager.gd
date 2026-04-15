extends Node
# ─────────────────────────────────────────────
#  GAME MANAGER  –  Autoload singleton
#  Handles: score, XP, progression, save/load,
#           adaptive difficulty, achievements
# ─────────────────────────────────────────────

# ── Signals ──────────────────────────────────
signal score_changed(new_score: int)
signal combo_changed(combo: int)
signal xp_changed(xp: int, player_level: int)
signal level_changed(new_level: int)
signal achievement_unlocked(name: String, description: String)
signal high_score_beaten(score: int)

# ── Session state (reset each play) ──────────
var score              : int   = 0
var current_level      : int   = 1
var kills_this_session : int   = 0
var combo              : int   = 0
var combo_timer        : float = 0.0
var level_start_health : int   = 100
var took_damage_this_level : bool = false

# ── Persistent state (saved) ─────────────────
var high_score         : int   = 0
var total_xp           : int   = 0
var player_level       : int   = 1
var xp_to_next_level   : int   = Constants.XP_BASE_TO_NEXT_LEVEL
var unlocked_skins     : Array = ["player"]
var achievements       : Dictionary = {}
var daily_kills        : int   = 0
var last_play_date     : String = ""

# ── Adaptive difficulty ───────────────────────
var difficulty_multiplier : float = 1.0

# ─────────────────────────────────────────────

func _ready() -> void:
	_load_save()
	_check_daily_reset()

func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
			emit_signal("combo_changed", 0)

# ── Scoring ──────────────────────────────────

func add_kill() -> void:
	kills_this_session += 1
	daily_kills += 1
	combo += 1
	combo_timer = Constants.COMBO_WINDOW

	var bonus_mult : float = 1.0 + combo * Constants.COMBO_BONUS_PER_STREAK
	var points     : int   = int(Constants.SCORE_PER_KILL * bonus_mult * difficulty_multiplier)
	_add_raw_score(points)
	add_xp(Constants.XP_PER_KILL)
	emit_signal("combo_changed", combo)
	_update_difficulty()
	_check_kill_achievements()

func complete_level() -> void:
	var bonus : int = Constants.SCORE_LEVEL_COMPLETE
	if not took_damage_this_level:
		bonus += Constants.SCORE_NO_DAMAGE_BONUS
	_add_raw_score(bonus)
	add_xp(Constants.XP_PER_LEVEL_COMPLETE)
	current_level += 1
	took_damage_this_level = false
	emit_signal("level_changed", current_level)
	_save()

func register_player_hit() -> void:
	took_damage_this_level = true

func _add_raw_score(points: int) -> void:
	score += points
	if score > high_score:
		high_score = score
		emit_signal("high_score_beaten", score)
	emit_signal("score_changed", score)

# ── XP / Levelling ───────────────────────────

func add_xp(amount: int) -> void:
	total_xp += amount
	while total_xp >= xp_to_next_level:
		total_xp -= xp_to_next_level
		player_level += 1
		xp_to_next_level = int(xp_to_next_level * Constants.XP_LEVEL_SCALE)
		_on_player_level_up()
	emit_signal("xp_changed", total_xp, player_level)

func _on_player_level_up() -> void:
	_unlock_achievement("Level Up!", "Reached hunter level %d" % player_level)

# ── Adaptive Difficulty ───────────────────────

func _update_difficulty() -> void:
	var kill_rate : float = float(kills_this_session) / max(1.0, float(current_level))
	if kill_rate > Constants.DIFF_HARD_KILL_RATE:
		difficulty_multiplier = min(Constants.DIFF_MAX,
			difficulty_multiplier + Constants.DIFF_STEP)
	elif kill_rate < Constants.DIFF_EASY_KILL_RATE:
		difficulty_multiplier = max(Constants.DIFF_MIN,
			difficulty_multiplier - Constants.DIFF_STEP)

func get_enemy_speed_mult() -> float:
	return clampf(difficulty_multiplier, 0.7, 1.5)

func get_enemy_shoot_cooldown_mult() -> float:
	# harder = faster shooting = smaller cooldown
	return clampf(2.0 - difficulty_multiplier, 0.6, 1.8)

func get_enemy_vision_mult() -> float:
	return clampf(difficulty_multiplier, 0.8, 1.4)

# ── Achievements ─────────────────────────────

func _check_kill_achievements() -> void:
	var milestones := {10: "First Blood", 50: "Killing Spree",
					   100: "Century Hunter", 500: "Unstoppable"}
	for kills in milestones.keys():
		if kills_this_session == kills:
			_unlock_achievement(milestones[kills],
				"Eliminated %d enemies" % kills)

func _unlock_achievement(aname: String, desc: String) -> void:
	if achievements.has(aname):
		return
	achievements[aname] = {"desc": desc, "date": Time.get_date_string_from_system()}
	emit_signal("achievement_unlocked", aname, desc)
	_save()

# ── Session reset ────────────────────────────

func reset_session() -> void:
	score = 0
	current_level = 1
	kills_this_session = 0
	combo = 0
	combo_timer = 0.0
	difficulty_multiplier = 1.0
	took_damage_this_level = false
	emit_signal("score_changed", 0)
	emit_signal("combo_changed", 0)
	emit_signal("level_changed", 1)

# ── Save / Load ──────────────────────────────

const SAVE_PATH := "user://save.json"

func _save() -> void:
	var data := {
		"high_score"       : high_score,
		"total_xp"         : total_xp,
		"player_level"     : player_level,
		"xp_to_next_level" : xp_to_next_level,
		"unlocked_skins"   : unlocked_skins,
		"achievements"     : achievements,
		"daily_kills"      : daily_kills,
		"last_play_date"   : last_play_date
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	high_score       = data.get("high_score", 0)
	total_xp         = data.get("total_xp", 0)
	player_level     = data.get("player_level", 1)
	xp_to_next_level = data.get("xp_to_next_level", Constants.XP_BASE_TO_NEXT_LEVEL)
	unlocked_skins   = data.get("unlocked_skins", ["player"])
	achievements     = data.get("achievements", {})
	daily_kills      = data.get("daily_kills", 0)
	last_play_date   = data.get("last_play_date", "")

func _check_daily_reset() -> void:
	var today := Time.get_date_string_from_system()
	if today != last_play_date:
		daily_kills    = 0
		last_play_date = today
		_save()
