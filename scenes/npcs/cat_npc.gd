class_name CatNPC
extends NPCBase
## Friendly cat NPC. Wanders, approaches the player, and can be talked to.

@export var dialogue_id: String = ""
@export var is_quest_giver: bool = false

func _init() -> void:
	creature_type = "cat"
	can_speak = false  # Cats speak naturally, no ability needed
	wander_speed = 1.5
	approach_speed = 2.0
	detection_range = 6.0

func _on_player_detected(distance: float) -> void:
	if current_state == State.IDLE or current_state == State.WANDER:
		if distance < detection_range:
			_change_state(State.APPROACH)
			DebugLog.log("NPC:%s" % npc_id, "cat approaching player (dist=%.1f)" % distance)
