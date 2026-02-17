extends GutTest

## Tests for CatPlayer scene and script configuration.
## Movement tests requiring physics are limited to what's feasible headlessly.

var _player_scene: PackedScene
var _player: Node

func before_all():
	_player_scene = load("res://scenes/player/cat_player.tscn")
	assert_not_null(_player_scene, "cat_player.tscn should load successfully")

func before_each():
	_player = _player_scene.instantiate()
	add_child(_player)

func after_each():
	if _player and is_instance_valid(_player):
		_player.queue_free()
		_player = null

# --- Scene structure tests ---

func test_player_is_cat_player_class():
	assert_true(_player is CatPlayer, "Instantiated node should be CatPlayer class")

func test_player_extends_character_body_3d():
	assert_true(_player is CharacterBody3D, "CatPlayer should be a CharacterBody3D")

# --- Cat proportion tests ---

func test_walking_speed():
	assert_eq(_player.WALKING_SPEED, 4.0, "Cat walk speed should be 4.0 m/s")

func test_sprinting_speed():
	assert_eq(_player.SPRINTING_SPEED, 8.0, "Cat sprint speed should be 8.0 m/s")

func test_crouching_speed():
	assert_eq(_player.CROUCHING_SPEED, 2.0, "Cat crouch speed should be 2.0 m/s")

func test_jump_velocity():
	assert_eq(_player.JUMP_VELOCITY, 5.5, "Cat jump velocity should be 5.5")

func test_fall_damage():
	assert_eq(_player.fall_damage, 3, "Cat fall damage should be 3 (0.3x of default 10)")

func test_fall_damage_threshold():
	assert_eq(_player.fall_damage_threshold, -7.0, "Fall damage threshold should be -7.0")

# --- Scene hierarchy tests ---

func test_has_standing_collision_shape():
	var shape := _player.get_node_or_null("StandingCollisionShape")
	assert_not_null(shape, "CatPlayer should have StandingCollisionShape")

func test_has_crouching_collision_shape():
	var shape := _player.get_node_or_null("CrouchingCollisionShape")
	assert_not_null(shape, "CatPlayer should have CrouchingCollisionShape")

func test_standing_capsule_dimensions():
	var shape_node := _player.get_node("StandingCollisionShape") as CollisionShape3D
	var capsule := shape_node.shape as CapsuleShape3D
	assert_almost_eq(capsule.radius, 0.2, 0.01, "Standing capsule radius should be 0.2")
	assert_almost_eq(capsule.height, 0.5, 0.01, "Standing capsule height should be 0.5")

func test_crouching_capsule_dimensions():
	var shape_node := _player.get_node("CrouchingCollisionShape") as CollisionShape3D
	var capsule := shape_node.shape as CapsuleShape3D
	assert_almost_eq(capsule.radius, 0.2, 0.01, "Crouching capsule radius should be 0.2")
	assert_almost_eq(capsule.height, 0.4, 0.01, "Crouching capsule height should be 0.4")

func test_neck_height():
	var neck := _player.get_node_or_null("Body/Neck")
	assert_not_null(neck, "Player should have Body/Neck node")
	if neck:
		assert_almost_eq(neck.transform.origin.y, 0.4, 0.01, "Neck Y should be 0.4m for cat eye level")
