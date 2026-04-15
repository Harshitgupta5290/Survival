extends Node
# ─────────────────────────────────────────────────────────────────────────────
#  DAILY CHALLENGE SYSTEM
#
#  Every day a new seeded challenge is generated. Same seed worldwide so
#  every player fights the same level — leaderboard-fair.
#
#  Challenge modifiers (one random set per day):
#    SPEED_RUN        – Must finish in under X seconds
#    NO_GRENADES      – Grenades disabled, enemies drop more
#    HEADSHOT_ONLY    – Bullets do 1 damage unless enemy is killed in 1 shot
#    SURVIVAL         – Survive N waves with no exit, infinite enemies
#    BOSS_RUSH        – Every wave spawns a boss
#    LOW_AMMO         – Start with only 5 bullets, find more in level
#    MIRROR           – Level is horizontally flipped
#    BLOOD_MOON       – All enemies have 2× health, player drops 1 grenade on kill
# ─────────────────────────────────────────────────────────────────────────────
class_name DailyChallenge

enum Modifier {
	SPEED_RUN,
	NO_GRENADES,
	SURVIVAL,
	BOSS_RUSH,
	LOW_AMMO,
	MIRROR,
	BLOOD_MOON,
	DOUBLE_SCORE
}

# Applied modifiers this session
var active_modifiers : Array[Modifier] = []
var time_limit       : float = 120.0   # for SPEED_RUN
var elapsed_time     : float = 0.0
var wave_target      : int   = 10      # for SURVIVAL

# Signals
signal time_warning(seconds_left: float)
signal challenge_failed(reason: String)
signal challenge_complete(score: int)

# ─────────────────────────────────────────────────────────────────────────────

static func get_today_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return d["year"] * 10000 + d["month"] * 100 + d["day"]

static func get_today_modifiers() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = get_today_seed()

	var all_mods := [
		Modifier.SPEED_RUN, Modifier.NO_GRENADES, Modifier.SURVIVAL,
		Modifier.BOSS_RUSH, Modifier.LOW_AMMO, Modifier.MIRROR,
		Modifier.BLOOD_MOON, Modifier.DOUBLE_SCORE
	]
	# Pick 1 or 2 modifiers
	all_mods.shuffle()
	var count := rng.randi_range(1, 2)
	return all_mods.slice(0, count)

static func modifier_name(m: Modifier) -> String:
	var names := {
		Modifier.SPEED_RUN   : "Speed Run",
		Modifier.NO_GRENADES : "No Grenades",
		Modifier.SURVIVAL    : "Survival",
		Modifier.BOSS_RUSH   : "Boss Rush",
		Modifier.LOW_AMMO    : "Low Ammo",
		Modifier.MIRROR      : "Mirror World",
		Modifier.BLOOD_MOON  : "Blood Moon",
		Modifier.DOUBLE_SCORE: "Double Score"
	}
	return names.get(m, "Unknown")

static func modifier_desc(m: Modifier) -> String:
	var descs := {
		Modifier.SPEED_RUN   : "Finish in under 2 minutes!",
		Modifier.NO_GRENADES : "Grenades unavailable. Aim carefully.",
		Modifier.SURVIVAL    : "Survive 10 waves — no exit.",
		Modifier.BOSS_RUSH   : "Every wave has a boss.",
		Modifier.LOW_AMMO    : "Start with 5 bullets. Find more.",
		Modifier.MIRROR      : "The level is flipped. Stay sharp.",
		Modifier.BLOOD_MOON  : "Enemies have 2× health. Kill for grenades.",
		Modifier.DOUBLE_SCORE: "All points doubled!"
	}
	return descs.get(m, "")

# ─────────────────────────────────────────────────────────────────────────────
# Apply modifiers to game state after player spawns

func apply_to_player(player: Node) -> void:
	for m in active_modifiers:
		match m:
			Modifier.NO_GRENADES:
				player.grenades = 0
			Modifier.LOW_AMMO:
				player.ammo = 5
			Modifier.BLOOD_MOON:
				player.grenades += 2  # death-drop compensation

func apply_to_enemy(enemy: Node) -> void:
	for m in active_modifiers:
		match m:
			Modifier.BLOOD_MOON:
				enemy.health     *= 2
				enemy.max_health *= 2
			Modifier.BOSS_RUSH:
				enemy.health     = int(enemy.health * 1.5)
				enemy.max_health = int(enemy.max_health * 1.5)

func apply_score_modifier(base_score: int) -> int:
	if active_modifiers.has(Modifier.DOUBLE_SCORE):
		return base_score * 2
	return base_score

# ─────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not active_modifiers.has(Modifier.SPEED_RUN):
		return
	elapsed_time += delta
	var left := time_limit - elapsed_time
	if left <= 30.0 and int(left) % 10 == 0:
		emit_signal("time_warning", left)
	if elapsed_time >= time_limit:
		emit_signal("challenge_failed", "Time's up!")
