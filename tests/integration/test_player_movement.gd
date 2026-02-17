extends GutTest
## Integration test: verifies player movement via simulated input and NPC
## interaction in a lightweight test scene with a physics floor.

var _sender: GutInputSender


func before_each() -> void:
	GameState.reset()
	_sender = GutInputSender.new(Input)
	_sender.set_auto_flush_input(true)


func after_each() -> void:
	if _sender:
		_sender.release_all()
		_sender.clear()


## Build a minimal scene with a flat floor for physics testing.
func _build_test_scene() -> Node3D:
	var root := Node3D.new()
	root.name = "TestScene"

	# Floor: StaticBody3D with BoxShape3D (20x1x20m), top surface at Y=0
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.position = Vector3(0, -0.5, 0)
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(20.0, 1.0, 20.0)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	root.add_child(floor_body)

	# Basic lighting
	var light := DirectionalLight3D.new()
	light.name = "TestLight"
	root.add_child(light)

	return root


func test_player_moves_forward() -> void:
	var scene := _build_test_scene()
	add_child_autoqfree(scene)

	var player: CatPlayer = preload("res://scenes/player/cat_player.tscn").instantiate()
	scene.add_child(player)
	player.global_position = Vector3(0, 2, 0)

	# Wait for player to fall and land on floor
	await wait_physics_frames(60)

	var start_pos := player.global_position
	print("[DEBUG] test_player_moves_forward: start_pos=%s" % start_pos)

	# Send forward input — COGITO reads Input.get_vector("left","right","forward","back")
	_sender.action_down("forward")
	await wait_physics_frames(30)
	_sender.action_up("forward")
	await wait_physics_frames(5)

	var end_pos := player.global_position
	print("[DEBUG] test_player_moves_forward: end_pos=%s delta_z=%.3f" % [end_pos, end_pos.z - start_pos.z])

	# COGITO uses -Z as forward, so Z should decrease
	assert_lt(end_pos.z, start_pos.z - 0.1, "Player should have moved forward (negative Z)")
	assert_gt(end_pos.y, -1.0, "Player should not have fallen through floor")


func test_player_does_not_move_without_input() -> void:
	var scene := _build_test_scene()
	add_child_autoqfree(scene)

	var player: CatPlayer = preload("res://scenes/player/cat_player.tscn").instantiate()
	scene.add_child(player)
	player.global_position = Vector3(0, 2, 0)

	# Wait for player to fall and settle on floor
	await wait_physics_frames(60)

	var start_pos := player.global_position
	print("[DEBUG] test_player_no_input: start_pos=%s" % start_pos)

	# Wait with no input at all
	await wait_physics_frames(30)

	var end_pos := player.global_position
	print("[DEBUG] test_player_no_input: end_pos=%s" % end_pos)

	# XZ should not have changed without input
	assert_almost_eq(end_pos.x, start_pos.x, 0.1, "X should not change without input")
	assert_almost_eq(end_pos.z, start_pos.z, 0.1, "Z should not change without input")


func test_npc_interaction_changes_state() -> void:
	var scene := _build_test_scene()
	add_child_autoqfree(scene)

	var npc := CatNPC.new()
	npc.npc_id = "test_elder"
	scene.add_child(npc)
	npc.global_position = Vector3(2, 2, 0)

	await wait_physics_frames(5)
	print("[DEBUG] test_npc_interact: state_before=%s" % NPCBase.State.keys()[npc.current_state])

	npc.interact()

	print("[DEBUG] test_npc_interact: state_after=%s" % NPCBase.State.keys()[npc.current_state])
	assert_eq(npc.current_state, NPCBase.State.INTERACT, "NPC should be in INTERACT state after interact()")


func test_npc_detects_nearby_player() -> void:
	var scene := _build_test_scene()
	add_child_autoqfree(scene)

	var player: CatPlayer = preload("res://scenes/player/cat_player.tscn").instantiate()
	scene.add_child(player)
	player.global_position = Vector3(0, 2, 0)

	# Place NPC within detection_range (CatNPC default = 6.0)
	var npc := CatNPC.new()
	npc.npc_id = "test_detector"
	scene.add_child(npc)
	npc.global_position = Vector3(3, 2, 0)

	print("[DEBUG] test_npc_detect: player_pos=%s npc_pos=%s detection_range=%.1f" % [
		player.global_position, npc.global_position, npc.detection_range])

	# Wait for NPC to find player via "Player" group and check proximity
	# Frame 1: _find_player() → found, idle_timer=0 → WANDER
	# Frame 2: _process_wander() → _check_player_proximity() → APPROACH
	await wait_physics_frames(15)

	print("[DEBUG] test_npc_detect: npc_state=%s" % NPCBase.State.keys()[npc.current_state])
	assert_eq(npc.current_state, NPCBase.State.APPROACH, "CatNPC should approach nearby player")
