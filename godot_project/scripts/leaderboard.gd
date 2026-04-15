extends Node
# ─────────────────────────────────────────────────────────────────────────────
#  LEADERBOARD  –  Autoload
#  Connects to Firebase Realtime Database (free tier).
#
#  SETUP (one-time, 5 minutes):
#    1. Go to console.firebase.google.com → Create project
#    2. Build → Realtime Database → Create database (start in test mode)
#    3. Copy the database URL (looks like: https://your-app-default-rtdb.firebaseio.com)
#    4. Paste it into FIREBASE_URL below
#
#  The database stores entries at /leaderboard/<push_id>:
#    { "name": "AAA", "score": 9999, "date": "2026-04-15" }
#
#  After testing, lock down rules in Firebase Console:
#    { "rules": { "leaderboard": { ".read": true,
#        "$entry": { ".write": "!data.exists()" } } } }
# ─────────────────────────────────────────────────────────────────────────────

const FIREBASE_URL := "https://YOUR-PROJECT-default-rtdb.firebaseio.com/leaderboard.json"
const ENABLED      := false   # set true after you add your Firebase URL

signal score_submitted(success: bool)
signal scores_fetched(entries: Array)

var _http_post : HTTPRequest = null
var _http_get  : HTTPRequest = null

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_http_post = HTTPRequest.new()
	_http_get  = HTTPRequest.new()
	add_child(_http_post)
	add_child(_http_get)

# ── Submit a score ────────────────────────────────────────────────────────────

func submit_score(player_name: String, score: int) -> void:
	if not ENABLED or FIREBASE_URL.contains("YOUR-PROJECT"):
		emit_signal("score_submitted", false)
		return

	var body := JSON.stringify({
		"name"  : player_name.to_upper().left(12),
		"score" : score,
		"date"  : Time.get_date_string_from_system()
	})
	var headers := ["Content-Type: application/json"]

	if _http_post.request_completed.is_connected(_on_post_done):
		_http_post.request_completed.disconnect(_on_post_done)
	_http_post.request_completed.connect(_on_post_done, CONNECT_ONE_SHOT)
	_http_post.request(FIREBASE_URL, headers, HTTPClient.METHOD_POST, body)

func _on_post_done(_res: int, code: int, _hdrs: PackedStringArray, _body: PackedByteArray) -> void:
	emit_signal("score_submitted", code == 200)

# ── Fetch top scores ──────────────────────────────────────────────────────────

func fetch_top10() -> void:
	if not ENABLED or FIREBASE_URL.contains("YOUR-PROJECT"):
		emit_signal("scores_fetched", [])
		return

	var url := FIREBASE_URL.replace(".json", "") + \
		       ".json?orderBy=%22score%22&limitToLast=10"

	if _http_get.request_completed.is_connected(_on_get_done):
		_http_get.request_completed.disconnect(_on_get_done)
	_http_get.request_completed.connect(_on_get_done, CONNECT_ONE_SHOT)
	_http_get.request(url)

func _on_get_done(_res: int, code: int, _hdrs: PackedStringArray, body: PackedByteArray) -> void:
	if code != 200:
		emit_signal("scores_fetched", [])
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null or typeof(data) != TYPE_DICTIONARY:
		emit_signal("scores_fetched", [])
		return
	var entries : Array = data.values()
	entries.sort_custom(func(a, b): return a.get("score", 0) > b.get("score", 0))
	emit_signal("scores_fetched", entries.slice(0, 10))
