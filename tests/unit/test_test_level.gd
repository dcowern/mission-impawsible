extends GutTest

## Tests for the test level scene structure.

var _level_scene: PackedScene
var _level: Node

func before_all():
	_level_scene = load("res://scenes/test/test_level.tscn")
	assert_not_null(_level_scene, "test_level.tscn should load successfully")

func before_each():
	_level = _level_scene.instantiate()
	add_child(_level)

func after_each():
	if _level and is_instance_valid(_level):
		_level.queue_free()
		_level = null

func test_level_loads():
	assert_not_null(_level, "Test level should instantiate")

func test_has_ground():
	var ground := _level.get_node_or_null("Ground")
	assert_not_null(ground, "Test level should have Ground node")
	assert_true(ground is StaticBody3D, "Ground should be a StaticBody3D")

func test_has_player():
	var player := _level.get_node_or_null("CatPlayer")
	assert_not_null(player, "Test level should have CatPlayer node")
	assert_true(player is CatPlayer, "Player should be CatPlayer class")

func test_has_directional_light():
	var light := _level.get_node_or_null("DirectionalLight3D")
	assert_not_null(light, "Test level should have DirectionalLight3D")

func test_has_world_environment():
	var env := _level.get_node_or_null("WorldEnvironment")
	assert_not_null(env, "Test level should have WorldEnvironment")

func test_has_obstacles():
	var obstacles := _level.get_node_or_null("Obstacles")
	assert_not_null(obstacles, "Test level should have Obstacles container")
	if obstacles:
		assert_gt(obstacles.get_child_count(), 0, "Obstacles should have children")

func test_has_ramp():
	var ramp := _level.get_node_or_null("Ramp")
	assert_not_null(ramp, "Test level should have Ramp")

func test_has_door():
	var door := _level.get_node_or_null("Doorway/Door")
	assert_not_null(door, "Test level should have Doorway/Door")

func test_has_readable_note():
	var note := _level.get_node_or_null("ReadableNote")
	assert_not_null(note, "Test level should have ReadableNote")

func test_has_carryable_item():
	var item := _level.get_node_or_null("CarryableItem")
	assert_not_null(item, "Test level should have CarryableItem")

func test_has_spawn_point():
	var spawn := _level.get_node_or_null("SpawnPoint")
	assert_not_null(spawn, "Test level should have SpawnPoint marker")
