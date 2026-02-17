class_name QuestManager
extends Node
## Manages quest state, progression, and integration with GameState.

const MAIN_QUEST_STAGES := {
	"not_started": "Main quest not started",
	"awakening": "Talk to the Elder Cat",
	"first_steps": "Find the scroll in the northern ruins",
	"five_trials": "Complete the five elemental trials",
	"gem_location": "Travel to the gem's resting place",
	"restoration": "Find the gem",
	"complete": "The gem has been found!",
}

const SIDE_QUESTS := {
	"fetch_barrel": {
		"name": "The Missing Barrel",
		"description": "A villager lost a barrel. Find it in the plains.",
		"stages": ["not_started", "active", "found_barrel", "complete"],
	},
	"creature_secret": {
		"name": "Creature Secrets",
		"description": "A bird knows where hidden tuna coins are.",
		"stages": ["not_started", "active", "found_coins", "complete"],
	},
	"tame_dragon": {
		"name": "The Lonely Dragon",
		"description": "Tame a dragon in the foothills.",
		"stages": ["not_started", "active", "tamed", "complete"],
	},
}

func _ready() -> void:
	DebugLog.log("QuestManager", "initialized: main_quest=%s, side_quests=%d" % [
		get_main_quest_stage(), SIDE_QUESTS.size()])

func get_main_quest_stage() -> String:
	return GameState.quest_flags.get("main_quest", "not_started")

func set_main_quest_stage(stage: String) -> void:
	if stage not in MAIN_QUEST_STAGES:
		DebugLog.log_error("QuestManager", "invalid main quest stage: %s" % stage)
		return
	var old: String = get_main_quest_stage()
	GameState.quest_flags["main_quest"] = stage
	DebugLog.log_state_change("QuestManager", "main_quest", old, stage)
	if old == "not_started":
		SignalBus.quest_started.emit("main_quest")
	if stage == "complete":
		GameState.gem_found = true
		SignalBus.quest_completed.emit("main_quest")

func advance_main_quest() -> void:
	var current: String = get_main_quest_stage()
	var stages: Array = MAIN_QUEST_STAGES.keys()
	var idx: int = stages.find(current)
	if idx >= 0 and idx < stages.size() - 1:
		set_main_quest_stage(stages[idx + 1])
	else:
		DebugLog.log("QuestManager", "main quest already at final stage: %s" % current)

func get_side_quest_stage(quest_id: String) -> String:
	return GameState.quest_flags.get(quest_id, "not_started")

func set_side_quest_stage(quest_id: String, stage: String) -> void:
	if quest_id not in SIDE_QUESTS:
		DebugLog.log_error("QuestManager", "unknown side quest: %s" % quest_id)
		return
	var quest_data: Dictionary = SIDE_QUESTS[quest_id]
	if stage not in quest_data["stages"]:
		DebugLog.log_error("QuestManager", "invalid stage %s for quest %s" % [stage, quest_id])
		return
	var old: String = get_side_quest_stage(quest_id)
	GameState.quest_flags[quest_id] = stage
	DebugLog.log_state_change("QuestManager", quest_id, old, stage)
	if old == "not_started" and stage != "not_started":
		SignalBus.quest_started.emit(quest_id)
	if stage == "complete":
		SignalBus.quest_completed.emit(quest_id)

func get_active_quests() -> Array[String]:
	var active: Array[String] = []
	for quest_id in GameState.quest_flags:
		var stage: String = GameState.quest_flags[quest_id]
		if stage != "not_started" and stage != "complete":
			active.append(quest_id)
	return active

func is_quest_complete(quest_id: String) -> bool:
	return GameState.quest_flags.get(quest_id, "not_started") == "complete"
