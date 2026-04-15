extends Node
# ─────────────────────────────────────────────
#  AUDIO MANAGER  –  Autoload singleton
#  Centralized music + SFX with volume control
# ─────────────────────────────────────────────

var music_player  : AudioStreamPlayer
var sfx_pool      : Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

var music_volume  : float = 0.3   # 0.0 – 1.0
var sfx_volume    : float = 0.8
var music_enabled : bool  = true
var sfx_enabled   : bool  = true

# Cache loaded streams to avoid re-loading
var _stream_cache : Dictionary = {}

# ─────────────────────────────────────────────

func _ready() -> void:
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)

	# SFX pool (prevents cutoff on rapid fire)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)

	_load_prefs()

# ── Music ─────────────────────────────────────

func play_music(path: String, loop: bool = true) -> void:
	if not music_enabled:
		return
	var stream := _get_stream(path)
	if not stream:
		return
	if stream is AudioStreamMP3:
		stream.loop = loop
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume)
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)
	_save_prefs()

func toggle_music(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled:
		music_player.stop()
	_save_prefs()

# ── SFX ───────────────────────────────────────

func play_sfx(name: String) -> void:
	if not sfx_enabled:
		return
	var path := _sfx_path(name)
	var stream := _get_stream(path)
	if not stream:
		return
	# Find a free player in the pool
	for p in sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = linear_to_db(sfx_volume)
			p.play()
			return
	# All busy – use the first one anyway
	sfx_pool[0].stream = stream
	sfx_pool[0].volume_db = linear_to_db(sfx_volume)
	sfx_pool[0].play()

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)
	_save_prefs()

func toggle_sfx(enabled: bool) -> void:
	sfx_enabled = enabled
	_save_prefs()

# ── Helpers ───────────────────────────────────

func _sfx_path(name: String) -> String:
	var map := {
		"jump"     : "res://assets/audio/jump.wav",
		"shoot"    : "res://assets/audio/shot.wav",
		"grenade"  : "res://assets/audio/grenade.wav",
		"pickup"   : "res://assets/audio/jump.wav",   # reuse until dedicated sfx added
		"death"    : "res://assets/audio/grenade.wav",
		"level_up" : "res://assets/audio/jump.wav",
	}
	return map.get(name, "")

func _get_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var stream : AudioStream = load(path)
	_stream_cache[path] = stream
	return stream

# ── Prefs ─────────────────────────────────────

const PREFS_PATH := "user://audio_prefs.json"

func _save_prefs() -> void:
	var f := FileAccess.open(PREFS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"music_vol"     : music_volume,
			"sfx_vol"       : sfx_volume,
			"music_enabled" : music_enabled,
			"sfx_enabled"   : sfx_enabled
		}))

func _load_prefs() -> void:
	if not FileAccess.file_exists(PREFS_PATH):
		return
	var f := FileAccess.open(PREFS_PATH, FileAccess.READ)
	if not f:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	music_volume  = d.get("music_vol", 0.3)
	sfx_volume    = d.get("sfx_vol", 0.8)
	music_enabled = d.get("music_enabled", true)
	sfx_enabled   = d.get("sfx_enabled", true)
