class_name CreatureNPC
extends NPCBase
## Speakable creature NPC (bird, fish, mouse). Only interactable when
## player has Creature Speak ability active.

@export var dialogue_id: String = ""
@export var knowledge_type: String = ""  # "far_sight", "underground", "water"

func _init() -> void:
	can_speak = true
	wander_speed = 1.0
	detection_range = 5.0
	wander_radius = 6.0

func _on_player_detected(distance: float) -> void:
	# Small creatures flee from the player
	if current_state == State.IDLE or current_state == State.WANDER:
		if distance < 3.0:
			_change_state(State.FLEE)
			DebugLog.log("NPC:%s" % npc_id, "%s fleeing from player (dist=%.1f)" % [creature_type, distance])

func _create_placeholder_model() -> void:
	# Smaller placeholder for creatures
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "PH_Model"
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_placeholder_color()
	sphere.material = mat
	mesh_inst.mesh = sphere
	mesh_inst.position.y = 0.2
	add_child(mesh_inst)

	var label := Label3D.new()
	label.text = "%s\n[%s]" % [npc_id, creature_type.to_upper()]
	label.position.y = 0.5
	label.font_size = 24
	label.modulate = Color.WHITE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

	DebugLog.log("NPC:%s" % npc_id, "using PH_ %s placeholder" % creature_type)

func _setup_collision() -> void:
	if get_node_or_null("CollisionShape3D"):
		return
	var shape := SphereShape3D.new()
	shape.radius = 0.2
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = shape
	col.position.y = 0.2
	add_child(col)
	collision_layer = 4  # Layer 3: NPCs
	collision_mask = 1   # Collide with World
