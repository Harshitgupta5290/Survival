extends Node
# ─────────────────────────────────────────────────────────────────────────────
#  WEAPON MANAGER  –  Autoload
#  Tracks which weapons are unlocked and the player's currently equipped weapon.
#
#  Weapons:
#    0 = Pistol   (always available, unlimited ammo reserves)
#    1 = Shotgun  (unlocked at player level 3, fires 5 pellets per shot)
#    2 = Sniper   (unlocked at player level 6, high damage, slow fire rate)
#
#  Unlocking is checked whenever GameManager emits level_changed.
#  Player switches weapons with the E key (cycle) or number keys 1/2/3.
# ─────────────────────────────────────────────────────────────────────────────

signal weapon_unlocked(weapon_id: int, name: String)

enum Weapon { PISTOL = 0, SHOTGUN = 1, SNIPER = 2 }

const WEAPON_NAMES := ["Pistol", "Shotgun", "Sniper"]
const WEAPON_ICONS := ["🔫", "💥", "🎯"]   # used for HUD text fallback

var current_weapon   : int   = Weapon.PISTOL
var unlocked_weapons : Array[bool] = [true, false, false]

# Weapon stats pulled from Constants at init time
var stats := {
	Weapon.PISTOL:  {
		"cooldown" : Constants.WEAPON_PISTOL_COOLDOWN,
		"damage"   : Constants.WEAPON_PISTOL_DAMAGE,
		"ammo"     : Constants.WEAPON_PISTOL_AMMO,
		"pellets"  : 1,
		"spread"   : 0.0,
		"speed"    : Constants.BULLET_SPEED,
	},
	Weapon.SHOTGUN: {
		"cooldown" : Constants.WEAPON_SHOTGUN_COOLDOWN,
		"damage"   : Constants.WEAPON_SHOTGUN_DAMAGE,
		"ammo"     : Constants.WEAPON_SHOTGUN_AMMO,
		"pellets"  : Constants.WEAPON_SHOTGUN_PELLETS,
		"spread"   : Constants.WEAPON_SHOTGUN_SPREAD,
		"speed"    : Constants.BULLET_SPEED,
	},
	Weapon.SNIPER:  {
		"cooldown" : Constants.WEAPON_SNIPER_COOLDOWN,
		"damage"   : Constants.WEAPON_SNIPER_DAMAGE,
		"ammo"     : Constants.WEAPON_SNIPER_AMMO,
		"pellets"  : 1,
		"spread"   : 0.0,
		"speed"    : Constants.WEAPON_SNIPER_SPEED,
	},
}

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	GameManager.level_changed.connect(_on_player_level_changed)

func _on_player_level_changed(new_level: int) -> void:
	if not unlocked_weapons[Weapon.SHOTGUN] and new_level >= Constants.WEAPON_UNLOCK_SHOTGUN_LV:
		unlocked_weapons[Weapon.SHOTGUN] = true
		emit_signal("weapon_unlocked", Weapon.SHOTGUN, "Shotgun")
		GameManager._unlock_achievement("Armed & Dangerous", "Unlocked the Shotgun")

	if not unlocked_weapons[Weapon.SNIPER] and new_level >= Constants.WEAPON_UNLOCK_SNIPER_LV:
		unlocked_weapons[Weapon.SNIPER] = true
		emit_signal("weapon_unlocked", Weapon.SNIPER, "Sniper Rifle")
		GameManager._unlock_achievement("One Shot, One Kill", "Unlocked the Sniper Rifle")

func cycle_weapon() -> int:
	var start := current_weapon
	var next  := (current_weapon + 1) % 3
	while next != start:
		if unlocked_weapons[next]:
			current_weapon = next
			return current_weapon
		next = (next + 1) % 3
	return current_weapon

func select_weapon(id: int) -> bool:
	if id < 0 or id >= 3 or not unlocked_weapons[id]:
		return false
	current_weapon = id
	return true

func get_stats() -> Dictionary:
	return stats[current_weapon]

func get_name() -> String:
	return WEAPON_NAMES[current_weapon]

func reset() -> void:
	current_weapon = Weapon.PISTOL
