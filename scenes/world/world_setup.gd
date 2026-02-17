extends Node3D
## World scene initialization script.
## Handles first-time terrain import and ongoing debug logging.

@onready var terrain: Terrain3D = $Terrain3D

var _terrain_initialized := false

func _ready() -> void:
	DebugLog.log("World", "scene loading...")
	_setup_terrain()
	_setup_save_load()
	if _terrain_initialized:
		_snap_objects_to_terrain.call_deferred()

func _setup_terrain() -> void:
	if not terrain:
		DebugLog.log_error("World", "Terrain3D node not found")
		return

	# Check if terrain data exists
	if terrain.data and terrain.data.get_region_count() > 0:
		DebugLog.log("World", "terrain data loaded: %d regions" % terrain.data.get_region_count())
		var hr: Vector2 = terrain.data.get_height_range()
		DebugLog.log("World", "terrain height range: min=%.1f max=%.1f" % [hr.x, hr.y])
		_terrain_initialized = true
	else:
		DebugLog.log("World", "no terrain data found — import heightmap via editor or run tools/generate_terrain.gd")
		DebugLog.log("World", "terrain will render as flat until data is imported")

func _setup_save_load() -> void:
	var player := get_node_or_null("CatPlayer")
	if player and player.has_signal("player_state_loaded"):
		player.player_state_loaded.connect(_on_player_state_loaded)
		DebugLog.log("World", "connected to player_state_loaded signal for save/load")

func _snap_objects_to_terrain() -> void:
	## Reposition player, NPCs, village, shrine, and coins onto the terrain surface.
	var nodes_to_snap: Array[String] = [
		"CatPlayer", "StartingVillage", "AbilityShrine",
		"ElderCat", "VillageCat1", "VillageCat2",
		"Dragon1", "Dragon2",
		"Bird1", "Mouse1", "Fish1",
	]
	# Also snap all tuna coins
	for child in get_children():
		if child.name.begins_with("TunaCoin"):
			nodes_to_snap.append(child.name)
		# Snap scattered trees and bushes too
		if child.name.begins_with("ScatteredTree") or child.name.begins_with("Bush"):
			nodes_to_snap.append(child.name)

	for node_name in nodes_to_snap:
		var node := get_node_or_null(node_name) as Node3D
		if not node:
			continue
		var pos: Vector3 = node.global_position
		var terrain_h: float = terrain.data.get_height(pos)
		if is_nan(terrain_h):
			DebugLog.log("World", "snap: %s — no terrain at (%.0f, %.0f), skipping" % [node_name, pos.x, pos.z])
			continue
		var offset: float = 2.0 if node_name == "CatPlayer" else 0.5
		node.global_position.y = terrain_h + offset
		DebugLog.log("World", "snap: %s → Y=%.1f (terrain=%.1f)" % [node_name, node.global_position.y, terrain_h])

func _on_player_state_loaded() -> void:
	DebugLog.log("World", "player state loaded — restoring GameState from COGITO world_dict")
	GameState.read_from_save()

func _physics_process(_delta: float) -> void:
	if not _terrain_initialized or not terrain or not terrain.data:
		return

	# Log player position relative to terrain periodically
	var player := get_node_or_null("CatPlayer")
	if player:
		var pos: Vector3 = player.global_position
		var terrain_h: float = terrain.data.get_height(pos)
		if not is_nan(terrain_h) and pos.y < terrain_h - 5.0:
			DebugLog.log_error("World", "player below terrain! pos.y=%.1f terrain_h=%.1f" % [pos.y, terrain_h])
