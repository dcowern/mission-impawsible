class_name NPCBase
extends CharacterBody3D
## Base class for all NPCs. Provides AI state machine, model loading,
## interaction, and debug logging.

enum State { IDLE, WANDER, APPROACH, FLEE, INTERACT, TAMED }

@export var npc_id: String = ""
@export var creature_type: String = "cat"  # cat, dragon, bird, fish, mouse
@export var can_speak: bool = false
@export var model_scene: PackedScene = null
@export var wander_radius: float = 10.0
@export var wander_speed: float = 2.0
@export var detection_range: float = 8.0
@export var approach_speed: float = 3.0

var tamed: bool = false
var current_state: State = State.IDLE
var _model_instance: Node3D = null
var _wander_target: Vector3 = Vector3.ZERO
var _wander_timer: float = 0.0
var _idle_timer: float = 0.0
var _spawn_position: Vector3 = Vector3.ZERO
var _player_ref: Node3D = null
var _gravity: float = 9.8

func _ready() -> void:
	_spawn_position = global_position
	_load_model()
	_setup_collision()
	add_to_group("NPCs")
	_change_state(State.IDLE)
	DebugLog.log("NPC:%s" % npc_id, "spawned: type=%s pos=%s" % [creature_type, global_position])

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta

	_find_player()

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.APPROACH:
			_process_approach(delta)
		State.FLEE:
			_process_flee(delta)
		State.INTERACT:
			_process_interact(delta)
		State.TAMED:
			_process_tamed(delta)

	move_and_slide()

func _change_state(new_state: State) -> void:
	if new_state == current_state:
		return
	var old_name: String = State.keys()[current_state]
	var new_name: String = State.keys()[new_state]
	current_state = new_state
	DebugLog.log_state_change("NPC:%s" % npc_id, "ai_state", old_name, new_name)
	_on_state_entered(new_state)

func _on_state_entered(state: State) -> void:
	match state:
		State.IDLE:
			_idle_timer = randf_range(2.0, 5.0)
			velocity.x = 0
			velocity.z = 0
		State.WANDER:
			_pick_wander_target()
		State.APPROACH:
			pass
		State.FLEE:
			pass
		State.TAMED:
			DebugLog.log("NPC:%s" % npc_id, "tamed!")

# --- State processors ---

func _process_idle(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer <= 0:
		_change_state(State.WANDER)
		return
	_check_player_proximity()

func _process_wander(delta: float) -> void:
	var to_target: Vector3 = _wander_target - global_position
	to_target.y = 0
	if to_target.length() < 1.0:
		_change_state(State.IDLE)
		return
	var dir: Vector3 = to_target.normalized()
	velocity.x = dir.x * wander_speed
	velocity.z = dir.z * wander_speed
	_face_direction(dir)
	_check_player_proximity()

func _process_approach(delta: float) -> void:
	if not _player_ref or not is_instance_valid(_player_ref):
		_change_state(State.IDLE)
		return
	var to_player: Vector3 = _player_ref.global_position - global_position
	to_player.y = 0
	var dist: float = to_player.length()
	if dist > detection_range * 1.5:
		_change_state(State.IDLE)
		return
	if dist < 2.0:
		velocity.x = 0
		velocity.z = 0
		return
	var dir: Vector3 = to_player.normalized()
	velocity.x = dir.x * approach_speed
	velocity.z = dir.z * approach_speed
	_face_direction(dir)

func _process_flee(delta: float) -> void:
	if not _player_ref or not is_instance_valid(_player_ref):
		_change_state(State.IDLE)
		return
	var away: Vector3 = global_position - _player_ref.global_position
	away.y = 0
	if away.length() > detection_range * 2.0:
		_change_state(State.IDLE)
		return
	var dir: Vector3 = away.normalized()
	velocity.x = dir.x * approach_speed * 1.5
	velocity.z = dir.z * approach_speed * 1.5
	_face_direction(dir)

func _process_interact(_delta: float) -> void:
	velocity.x = 0
	velocity.z = 0

func _process_tamed(delta: float) -> void:
	# Follow the player at a distance
	if not _player_ref or not is_instance_valid(_player_ref):
		velocity.x = 0
		velocity.z = 0
		return
	var to_player: Vector3 = _player_ref.global_position - global_position
	to_player.y = 0
	if to_player.length() > 4.0:
		var dir: Vector3 = to_player.normalized()
		velocity.x = dir.x * wander_speed
		velocity.z = dir.z * wander_speed
		_face_direction(dir)
	else:
		velocity.x = 0
		velocity.z = 0

# --- Helpers ---

func _check_player_proximity() -> void:
	if not _player_ref or not is_instance_valid(_player_ref):
		return
	var dist: float = global_position.distance_to(_player_ref.global_position)
	if dist < detection_range:
		_on_player_detected(dist)

## Override in subclasses to customize player reaction
func _on_player_detected(distance: float) -> void:
	DebugLog.log("NPC:%s" % npc_id, "player detected at distance %.1f" % distance)

func _pick_wander_target() -> void:
	var angle: float = randf() * TAU
	var dist: float = randf_range(2.0, wander_radius)
	_wander_target = _spawn_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _face_direction(dir: Vector3) -> void:
	if dir.length_squared() > 0.001:
		var target_angle: float = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 0.1)

func _find_player() -> void:
	if _player_ref and is_instance_valid(_player_ref):
		return
	var players := get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player_ref = players[0]
	else:
		# Try finding by name
		var root := get_tree().current_scene
		if root:
			_player_ref = root.get_node_or_null("CatPlayer")

func _load_model() -> void:
	if model_scene:
		_model_instance = model_scene.instantiate()
		add_child(_model_instance)
		DebugLog.log("NPC:%s" % npc_id, "loaded model: %s" % model_scene.resource_path)
	else:
		_create_placeholder_model()

func _create_placeholder_model() -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "PH_Model"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_placeholder_color()
	capsule.material = mat
	mesh_inst.mesh = capsule
	mesh_inst.position.y = 0.5
	add_child(mesh_inst)

	# Label
	var label := Label3D.new()
	label.text = "%s\n[%s]" % [npc_id, creature_type]
	label.position.y = 1.3
	label.font_size = 32
	label.modulate = Color.WHITE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

	DebugLog.log("NPC:%s" % npc_id, "using PH_ placeholder model (%s)" % creature_type)

func _get_placeholder_color() -> Color:
	match creature_type:
		"cat": return Color(1.0, 0.0, 1.0)  # Magenta
		"dragon": return Color(1.0, 0.5, 0.0)  # Orange
		"bird": return Color(0.5, 0.8, 1.0)  # Sky blue
		"fish": return Color(0.0, 0.5, 1.0)  # Blue
		"mouse": return Color(0.6, 0.4, 0.2)  # Brown
		_: return Color(1.0, 0.0, 1.0)  # Magenta default

func _setup_collision() -> void:
	if get_node_or_null("CollisionShape3D"):
		return  # Already has collision
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.0
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = shape
	col.position.y = 0.5
	add_child(col)
	collision_layer = 4  # Layer 3: NPCs
	collision_mask = 1   # Collide with World

## Called by Dragon Taming ability to tame this NPC
func apply_taming() -> void:
	if creature_type != "dragon":
		DebugLog.log("NPC:%s" % npc_id, "cannot tame — not a dragon")
		return
	tamed = true
	_change_state(State.TAMED)

## Called when player interacts with this NPC
func interact() -> void:
	DebugLog.log("NPC:%s" % npc_id, "interaction triggered")
	_change_state(State.INTERACT)

## Save NPC state to a dictionary
func save_state() -> Dictionary:
	return {
		"npc_id": npc_id,
		"position": var_to_str(global_position),
		"tamed": tamed,
		"state": State.keys()[current_state],
	}

## Restore NPC state from a dictionary
func load_state(data: Dictionary) -> void:
	if data.has("position"):
		global_position = str_to_var(data["position"])
	if data.has("tamed"):
		tamed = data["tamed"]
		if tamed:
			_change_state(State.TAMED)
	DebugLog.log("NPC:%s" % npc_id, "state loaded: tamed=%s" % tamed)
