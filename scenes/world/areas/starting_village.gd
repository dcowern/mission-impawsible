extends Node3D
## Starting Village — the player's spawn area in the Central Plains.
## Contains medieval buildings, props, and vegetation for the initial hub.

func _ready() -> void:
	DebugLog.log("StartingVillage", "loaded at %s" % global_position)
	_log_children()

func _log_children() -> void:
	var count := 0
	for child in get_children():
		count += 1
	DebugLog.log("StartingVillage", "%d objects placed" % count)
