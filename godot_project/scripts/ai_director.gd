extends Node
# ─────────────────────────────────────────────────────────────────────────────
#  AI DIRECTOR  –  the brain behind the endless mode and dynamic difficulty
#
#  Inspired by Left 4 Dead's AI Director — it watches the player at all times
#  and continuously adjusts the game's intensity to keep them in the
#  "FLOW ZONE" — challenging but never impossible.
#
#  It controls:
#    • Enemy spawn rate and squad size
#    • Elite / boss spawn thresholds
#    • Pickup drop rates
#    • Level generation profile for endless mode
#    • Taunts and narrative moments (AI-generated via NVIDIA NIM)
#    • "Rescue" events when the player is critically close to death
#
#  AI TAUNT BACKEND:
#    Uses NVIDIA NIM free API (build.nvidia.com) — OpenAI-compatible format.
#    To switch to Claude or OpenAI later, change AI_BASE_URL + AI_API_KEY only.
#    Fallback to hardcoded lines when API is unavailable / rate-limited.
#
#  Usage:
#    Call tick(delta) from game.gd every frame.
#    Call on_player_hit(), on_kill(), on_level_start() from appropriate places.
# ─────────────────────────────────────────────────────────────────────────────
class_name AIDirector
extends Node

# ── NVIDIA NIM API config ─────────────────────────────────────────────────────
#  Get your free key at: https://build.nvidia.com  (sign in → API Key)
#  Free tier: 1000 credits/month. Switch endpoints here to move to Claude later.
const AI_BASE_URL  := "https://integrate.api.nvidia.com/v1/chat/completions"
const AI_MODEL     := "meta/llama-3.1-8b-instruct"   # fast + free on NVIDIA NIM
const AI_API_KEY   := "YOUR_NVIDIA_API_KEY_HERE"      # paste your key here
const AI_ENABLED   := false    # set true once you have a key

var _http_node     : HTTPRequest = null
var _ai_busy       : bool        = false   # one request at a time

# ── Intensity model ───────────────────────────────────────────────────────────
#  Intensity is a float 0.0 – 1.0 representing how stressed the player is.
#  The director tracks a "build-up" phase, a "peak" phase, and a "rest" phase.
enum Phase { BUILD_UP, PEAK, RELAX, BOSS }

var phase               : Phase = Phase.BUILD_UP
var intensity           : float = 0.0   # 0 = calm, 1 = maximum chaos
var phase_timer         : float = 0.0

# Phase durations (seconds)
const BUILD_UP_DURATION  := 45.0
const PEAK_DURATION      := 20.0
const RELAX_DURATION     := 15.0

# ── Player stress indicators ──────────────────────────────────────────────────
var player_health_ratio  : float = 1.0   # updated each frame
var recent_deaths        : int   = 0
var kills_last_10s       : int   = 0
var kill_window_timer    : float = 0.0
var ammo_critically_low  : bool  = false

# ── Wave state ────────────────────────────────────────────────────────────────
var wave                 : int   = 1
var boss_spawned         : bool  = false
var last_spawn_time      : float = 0.0
var spawn_cooldown       : float = 5.0

# ── Enemy pool reference (game.gd fills this) ─────────────────────────────────
var enemy_group_ref      : Node  = null   # Node2D holding enemies
var player_ref           : Node  = null

# ── Signals ───────────────────────────────────────────────────────────────────
signal spawn_enemies(count: int, squad_type: String, near_pos: Vector2)
signal spawn_boss(pos: Vector2)
signal drop_pickup(item_type: String, pos: Vector2)
signal show_taunt(message: String)
signal wave_complete(wave: int)

# ─────────────────────────────────────────────────────────────────────────────

func start(wave_num: int, player: Node, enemy_parent: Node) -> void:
	wave            = wave_num
	player_ref      = player
	enemy_group_ref = enemy_parent
	phase           = Phase.BUILD_UP
	phase_timer     = 0.0
	intensity       = 0.0
	boss_spawned    = false

func tick(delta: float) -> void:
	if player_ref == null:
		return

	_update_player_metrics(delta)
	_update_phase(delta)
	_update_intensity(delta)
	_check_spawns(delta)
	_check_rescue()

# ── Metrics ───────────────────────────────────────────────────────────────────

func _update_player_metrics(delta: float) -> void:
	if player_ref.has_method("get") and player_ref.get("max_health"):
		player_health_ratio = float(player_ref.health) / float(player_ref.max_health)
	ammo_critically_low = player_ref.get("ammo") <= 3

	kill_window_timer += delta
	if kill_window_timer >= 10.0:
		kill_window_timer = 0.0
		kills_last_10s    = 0

# ── Phase transitions ─────────────────────────────────────────────────────────

func _update_phase(delta: float) -> void:
	phase_timer += delta

	match phase:
		Phase.BUILD_UP:
			if phase_timer >= BUILD_UP_DURATION:
				_enter_phase(Phase.PEAK)

		Phase.PEAK:
			if phase_timer >= PEAK_DURATION:
				# Boss every 3 waves
				if wave % 3 == 0 and not boss_spawned:
					_enter_phase(Phase.BOSS)
				else:
					_enter_phase(Phase.RELAX)

		Phase.RELAX:
			if phase_timer >= RELAX_DURATION:
				wave += 1
				boss_spawned = false
				emit_signal("wave_complete", wave)
				_enter_phase(Phase.BUILD_UP)

		Phase.BOSS:
			if boss_spawned:
				# Check if boss is dead by counting enemies
				var enemy_count := get_tree().get_nodes_in_group("enemy").size()
				if enemy_count == 0:
					_enter_phase(Phase.RELAX)

func _enter_phase(new_phase: Phase) -> void:
	phase       = new_phase
	phase_timer = 0.0

	match new_phase:
		Phase.BUILD_UP:
			_request_ai_taunt("wave_start")
		Phase.PEAK:
			_request_ai_taunt("peak")
		Phase.RELAX:
			# Drop a care package when player is struggling
			if player_health_ratio < 0.5 and player_ref != null:
				emit_signal("drop_pickup", "health", player_ref.global_position + Vector2(100, -50))
			if ammo_critically_low and player_ref != null:
				emit_signal("drop_pickup", "ammo", player_ref.global_position + Vector2(150, -50))
		Phase.BOSS:
			_request_ai_taunt("boss")
			if player_ref != null:
				emit_signal("spawn_boss", player_ref.global_position + Vector2(300, 0))
			boss_spawned = true

# ── Intensity curve ───────────────────────────────────────────────────────────

func _update_intensity(delta: float) -> void:
	var target : float
	match phase:
		Phase.BUILD_UP: target = phase_timer / BUILD_UP_DURATION
		Phase.PEAK:     target = 1.0
		Phase.RELAX:    target = 0.2
		Phase.BOSS:     target = 1.0

	# Scale by difficulty multiplier
	target *= GameManager.difficulty_multiplier

	# Player in danger → ramp intensity faster
	if player_health_ratio < 0.3:
		target = min(target + 0.3, 1.0)

	intensity = move_toward(intensity, target, delta * 0.15)

# ── Spawn logic ───────────────────────────────────────────────────────────────

func _check_spawns(delta: float) -> void:
	last_spawn_time += delta
	spawn_cooldown   = lerp(8.0, 2.0, intensity)   # faster spawns when intense

	if last_spawn_time < spawn_cooldown:
		return

	var living_enemies := get_tree().get_nodes_in_group("enemy").size()
	var max_enemies    := int(lerp(3.0, 12.0, intensity))

	if living_enemies >= max_enemies:
		return

	last_spawn_time = 0.0

	# Pick spawn position: off-screen right or left of player
	var spawn_pos := _pick_spawn_pos()
	var squad     := _pick_squad_type()
	var count     := _pick_squad_size()

	emit_signal("spawn_enemies", count, squad, spawn_pos)

func _pick_spawn_pos() -> Vector2:
	if player_ref == null:
		return Vector2(400, 300)
	var side := 1 if randf() > 0.5 else -1
	return player_ref.global_position + Vector2(side * (Constants.SCREEN_WIDTH * 0.7), -30)

func _pick_squad_size() -> int:
	match phase:
		Phase.BUILD_UP: return randi_range(1, 2)
		Phase.PEAK:     return randi_range(2, 4)
		Phase.BOSS:     return randi_range(1, 3)
		_:              return 1

func _pick_squad_type() -> String:
	var roll := randf()
	if wave >= 5 and roll < 0.2:
		return "elite"    # faster, more health
	if wave >= 3 and roll < 0.4:
		return "grenadier"
	return "grunt"

# ── Rescue system ────────────────────────────────────────────────────────────
# When the player is at critical health and surrounded, we secretly remove
# one enemy or drop a health pack — the player should feel lucky, not cheated.

func _check_rescue() -> void:
	if player_health_ratio > 0.15:
		return
	var enemies := get_tree().get_nodes_in_group("enemy")
	if enemies.size() < 3:
		return
	# Remove the closest enemy silently
	enemies.sort_custom(func(a, b):
		return a.global_position.distance_to(player_ref.global_position) < \
			   b.global_position.distance_to(player_ref.global_position))
	if is_instance_valid(enemies[0]):
		enemies[0].queue_free()
	# Drop health nearby
	emit_signal("drop_pickup", "health", player_ref.global_position + Vector2(80, -40))

# ── Narrative taunts ──────────────────────────────────────────────────────────

func on_kill() -> void:
	kills_last_10s += 1
	if kills_last_10s == 5:
		_request_ai_taunt("killing_spree")

func on_player_hit() -> void:
	if player_health_ratio < 0.3:
		_request_ai_taunt("low_health")

# ── AI taunt via NVIDIA NIM ───────────────────────────────────────────────────
#  Builds a context-aware prompt, sends it to the free NVIDIA API.
#  Falls back to hand-written lines instantly if AI is off or busy.

func _request_ai_taunt(context: String) -> void:
	if not AI_ENABLED or _ai_busy or AI_API_KEY == "YOUR_NVIDIA_API_KEY_HERE":
		# Fallback immediately — no delay for the player
		emit_signal("show_taunt", _fallback_taunt(context))
		return

	_ai_busy = true

	# Lazy-create the HTTPRequest node
	if _http_node == null:
		_http_node = HTTPRequest.new()
		add_child(_http_node)
		_http_node.request_completed.connect(_on_ai_response.bind(context))

	var kills  := GameManager.kills_this_session
	var health := int(player_health_ratio * 100)
	var hp_str := "%d%%" % health

	var prompt_map := {
		"killing_spree": "You are a villain in a 2D shooter game. The player just got a 5-kill streak with %d total kills. Generate ONE short villain taunt. Max 8 words. No quotes." % kills,
		"low_health":    "You are a villain in a 2D shooter game. The player is at %s health and struggling. Generate ONE short mocking taunt. Max 8 words. No quotes." % hp_str,
		"wave_start":    "You are a villain. Wave %d is starting in a 2D shooter. Generate ONE dramatic threat. Max 8 words. No quotes." % wave,
		"peak":          "You are a villain sending all troops in a 2D shooter. Generate ONE battle cry. Max 8 words. No quotes.",
		"boss":          "You are a villain boss entering battle in a 2D shooter. Generate ONE intimidating entrance line. Max 8 words. No quotes.",
	}

	var user_prompt : String = prompt_map.get(context, "Generate a short villain taunt. Max 8 words.")

	var body := JSON.stringify({
		"model": AI_MODEL,
		"max_tokens": 30,
		"temperature": 0.9,
		"messages": [
			{"role": "system", "content": "You are a villain in an action game. Always reply with exactly one short taunt. No explanations."},
			{"role": "user",   "content": user_prompt}
		]
	})

	var headers := [
		"Authorization: Bearer " + AI_API_KEY,
		"Content-Type: application/json"
	]

	var err := _http_node.request(AI_BASE_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_ai_busy = false
		emit_signal("show_taunt", _fallback_taunt(context))

func _on_ai_response(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, context: String) -> void:
	_ai_busy = false

	if code != 200:
		emit_signal("show_taunt", _fallback_taunt(context))
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null or not data.has("choices"):
		emit_signal("show_taunt", _fallback_taunt(context))
		return

	var taunt : String = data["choices"][0]["message"]["content"].strip_edges()

	# Safety: cap length in case model returns more than asked
	if taunt.length() > 80:
		taunt = taunt.substr(0, 80) + "..."

	emit_signal("show_taunt", taunt)

# ── Fallback lines (used when AI is off or API fails) ─────────────────────────

func _fallback_taunt(context: String) -> String:
	match context:
		"killing_spree": return _killing_spree_taunt()
		"low_health":    return _low_health_taunt()
		"wave_start":    return _build_up_taunt()
		"peak":          return _peak_taunt()
		_:               return "Come on, hunter. Is that all you've got?"

func _build_up_taunt() -> String:
	var lines := [
		"They're coming...",
		"Wave %d begins." % wave,
		"Reload. They won't wait.",
		"Ears open, soldier.",
	]
	return lines[randi() % lines.size()]

func _peak_taunt() -> String:
	var lines := [
		"ALL UNITS — MOVE IN!",
		"OVERWHELM THE HUNTER!",
		"No mercy. No retreat.",
		"This is the end, hunter.",
	]
	return lines[randi() % lines.size()]

func _killing_spree_taunt() -> String:
	var lines := [
		"Impressive... but it won't last.",
		"5 kills! The hunter is dangerous.",
		"Keep going. We'll break you.",
	]
	return lines[randi() % lines.size()]

func _low_health_taunt() -> String:
	var lines := [
		"You're bleeding out...",
		"Find a health pack — FAST.",
		"Hang in there!",
	]
	return lines[randi() % lines.size()]

# ── Profile for level generator ───────────────────────────────────────────────
func get_level_profile() -> Dictionary:
	return {
		"enemy_density"  : clampf(0.2 + wave * 0.05, 0.2, 0.9),
		"item_density"   : clampf(0.3 - wave * 0.02, 0.05, 0.35),
		"platform_ratio" : clampf(0.2 + wave * 0.03, 0.1, 0.6),
		"fortress_ratio" : clampf(0.1 + wave * 0.04, 0.0, 0.5),
		"sniper_ratio"   : clampf(0.0 + wave * 0.03, 0.0, 0.4),
		"has_boss"       : wave % 3 == 0,
		"seed_salt"      : wave * 137 + GameManager.kills_this_session
	}
