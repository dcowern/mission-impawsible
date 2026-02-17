extends Node
## Bridges Sky3D TimeOfDay signals to the game's SignalBus.
## Attach to a node in the world scene and set sky3d_path to the Sky3D node.

@export var sky3d_path: NodePath

var _sky3d: Node = null
var _was_day: bool = true

func _ready() -> void:
	if sky3d_path.is_empty():
		DebugLog.log_error("SkyBridge", "sky3d_path not set")
		return

	_sky3d = get_node_or_null(sky3d_path)
	if not _sky3d:
		DebugLog.log("SkyBridge", "Sky3D node not found at path: %s (GDExtension may not be loaded)" % sky3d_path)
		return

	if not _sky3d.has_method("get") or not ("tod" in _sky3d):
		DebugLog.log("SkyBridge", "Sky3D node exists but TimeOfDay property not available (placeholder)")
		return

	var tod = _sky3d.tod
	if tod and tod.has_signal("hour_changed"):
		tod.hour_changed.connect(_on_hour_changed)
		DebugLog.log("SkyBridge", "connected to TimeOfDay signals, current_time=%.1f" % tod.current_time)
	else:
		DebugLog.log("SkyBridge", "TimeOfDay not available — sky bridge inactive")

func _on_hour_changed(hour: float) -> void:
	DebugLog.log("SkyBridge", "hour changed: %.0f" % hour)

	# Determine day/night based on hour (6am-18pm = day)
	var is_day: bool = hour >= 6.0 and hour < 18.0
	if is_day != _was_day:
		_was_day = is_day
		var phase: String = "day" if is_day else "night"
		DebugLog.log("SkyBridge", "day/night transition: %s" % phase)
		SignalBus.day_night_changed.emit(is_day)

	# Log dawn/dusk transitions
	var hour_int := int(hour)
	if hour_int == 6:
		DebugLog.log("SkyBridge", "dawn")
	elif hour_int == 18:
		DebugLog.log("SkyBridge", "dusk")
