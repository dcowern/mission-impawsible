# autoloads/game_state.gd
extends Node

const MAGIC_DISCIPLINES := ["fire", "ice", "woodland", "dragon_taming", "creature_speak"]

var tuna_coins: int = 2:  # Player starts with 2 per lore
	set(value):
		var old := tuna_coins
		tuna_coins = max(0, value)
		if old != tuna_coins:
			DebugLog.log_state_change("GameState", "tuna_coins", old, tuna_coins)
			SignalBus.tuna_coins_changed.emit(old, tuna_coins)
			_sync_to_world_dict()

# ability_name -> level (0 = locked, 1+ = unlocked levels)
var ability_levels: Dictionary = {}
var quest_flags: Dictionary = {}  # quest_id -> state string
var gem_found: bool = false
var _loading_from_save: bool = false

func _ready() -> void:
	for discipline in MAGIC_DISCIPLINES:
		ability_levels[discipline] = 0
	DebugLog.log("GameState", "initialized: tuna_coins=%d, disciplines=%s" % [tuna_coins, MAGIC_DISCIPLINES])

func unlock_ability(discipline: String) -> bool:
	if discipline not in MAGIC_DISCIPLINES:
		DebugLog.log_error("GameState", "invalid discipline: %s" % discipline)
		return false
	if tuna_coins <= 0:
		DebugLog.log("GameState", "cannot unlock %s — no tuna coins" % discipline)
		return false
	var current_level: int = ability_levels[discipline]
	tuna_coins -= 1
	ability_levels[discipline] = current_level + 1
	DebugLog.log("GameState", "unlocked %s to level %d (spent 1 tuna coin, remaining: %d)" % [discipline, current_level + 1, tuna_coins])
	SignalBus.ability_unlocked.emit(discipline, current_level + 1)
	_sync_to_world_dict()
	return true

func get_ability_level(discipline: String) -> int:
	return ability_levels.get(discipline, 0)

func add_tuna_coins(amount: int) -> void:
	DebugLog.log("GameState", "adding %d tuna coins" % amount)
	tuna_coins += amount

func reset() -> void:
	tuna_coins = 2
	for discipline in MAGIC_DISCIPLINES:
		ability_levels[discipline] = 0
	quest_flags.clear()
	gem_found = false
	DebugLog.log("GameState", "reset to initial state")

# --- COGITO Save/Load Integration ---
# Syncs GameState to COGITO's world_dictionary on every state change,
# so data is always ready when COGITO triggers a save.

func _sync_to_world_dict() -> void:
	if _loading_from_save:
		return
	if not is_instance_valid(CogitoSceneManager):
		return
	CogitoSceneManager._current_world_dict["mi_tuna_coins"] = tuna_coins
	CogitoSceneManager._current_world_dict["mi_ability_levels"] = ability_levels.duplicate()
	CogitoSceneManager._current_world_dict["mi_quest_flags"] = quest_flags.duplicate()
	CogitoSceneManager._current_world_dict["mi_gem_found"] = gem_found

func write_to_save() -> void:
	if not is_instance_valid(CogitoSceneManager):
		return
	CogitoSceneManager._current_world_dict["mi_tuna_coins"] = tuna_coins
	CogitoSceneManager._current_world_dict["mi_ability_levels"] = ability_levels.duplicate()
	CogitoSceneManager._current_world_dict["mi_quest_flags"] = quest_flags.duplicate()
	CogitoSceneManager._current_world_dict["mi_gem_found"] = gem_found
	DebugLog.log("GameState", "wrote to COGITO world_dict: coins=%d, abilities=%s" % [tuna_coins, ability_levels])

func read_from_save() -> void:
	if not is_instance_valid(CogitoSceneManager):
		return
	_loading_from_save = true
	var wd: Dictionary = CogitoSceneManager._current_world_dict
	if wd.has("mi_tuna_coins"):
		tuna_coins = wd["mi_tuna_coins"]
	if wd.has("mi_ability_levels"):
		ability_levels = wd["mi_ability_levels"]
	if wd.has("mi_quest_flags"):
		quest_flags = wd["mi_quest_flags"]
	if wd.has("mi_gem_found"):
		gem_found = wd["mi_gem_found"]
	_loading_from_save = false
	_sync_to_world_dict()
	DebugLog.log("GameState", "read from COGITO world_dict: coins=%d, abilities=%s" % [tuna_coins, ability_levels])
