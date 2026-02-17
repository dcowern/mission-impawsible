class_name DragonNPC
extends NPCBase
## Dragon NPC. Patrols territory, aggressive when player approaches.
## Can be tamed via Dragon Taming ability.

@export var aggro_range: float = 15.0
@export var patrol_points: Array[Vector3] = []

var _patrol_index: int = 0

func _init() -> void:
	creature_type = "dragon"
	can_speak = false
	wander_speed = 3.0
	approach_speed = 5.0
	detection_range = 15.0
	wander_radius = 20.0

func _on_player_detected(distance: float) -> void:
	if tamed:
		return  # Tamed dragons don't aggro
	if current_state == State.IDLE or current_state == State.WANDER:
		if distance < aggro_range:
			_change_state(State.APPROACH)
			DebugLog.log("NPC:%s" % npc_id, "dragon aggro! chasing player (dist=%.1f)" % distance)

func _process_approach(delta: float) -> void:
	if tamed:
		_change_state(State.TAMED)
		return
	# Aggressive approach — faster and doesn't stop at 2m
	if not _player_ref or not is_instance_valid(_player_ref):
		_change_state(State.IDLE)
		return
	var to_player: Vector3 = _player_ref.global_position - global_position
	to_player.y = 0
	var dist: float = to_player.length()
	if dist > detection_range * 2.0:
		DebugLog.log("NPC:%s" % npc_id, "dragon lost interest (dist=%.1f)" % dist)
		_change_state(State.IDLE)
		return
	if dist < 1.5:
		# Close enough to "attack" — log it
		DebugLog.log("NPC:%s" % npc_id, "dragon attack range! (dist=%.1f)" % dist)
		velocity.x = 0
		velocity.z = 0
		return
	var dir: Vector3 = to_player.normalized()
	velocity.x = dir.x * approach_speed
	velocity.z = dir.z * approach_speed
	_face_direction(dir)

func _create_placeholder_model() -> void:
	# Larger placeholder for dragons
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "PH_Model"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.6
	capsule.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.0)  # Orange for dragons
	capsule.material = mat
	mesh_inst.mesh = capsule
	mesh_inst.position.y = 1.0
	add_child(mesh_inst)

	var label := Label3D.new()
	label.text = "%s\n[DRAGON]" % npc_id
	label.position.y = 2.5
	label.font_size = 32
	label.modulate = Color.WHITE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

	DebugLog.log("NPC:%s" % npc_id, "using PH_ dragon placeholder (orange capsule)")

func _setup_collision() -> void:
	if get_node_or_null("CollisionShape3D"):
		return
	var shape := CapsuleShape3D.new()
	shape.radius = 0.6
	shape.height = 2.0
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = shape
	col.position.y = 1.0
	add_child(col)
	collision_layer = 4  # Layer 3: NPCs
	collision_mask = 1   # Collide with World
