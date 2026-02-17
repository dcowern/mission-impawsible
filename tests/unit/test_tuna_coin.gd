extends GutTest
## Tests for the tuna coin pickup system.

var _coin_scene: PackedScene

func before_all():
	_coin_scene = load("res://scenes/interactables/tuna_coin_pickup.tscn")

func test_tuna_coin_scene_loads():
	assert_not_null(_coin_scene, "tuna_coin_pickup.tscn should load")

func test_tuna_coin_is_area3d():
	var coin := _coin_scene.instantiate()
	add_child(coin)
	assert_true(coin is Area3D, "TunaCoinPickup should be an Area3D")
	coin.queue_free()

func test_tuna_coin_has_mesh():
	var coin := _coin_scene.instantiate()
	add_child(coin)
	var mesh := coin.get_node_or_null("MeshInstance3D")
	assert_not_null(mesh, "TunaCoinPickup should have a MeshInstance3D")
	coin.queue_free()

func test_tuna_coin_has_collision():
	var coin := _coin_scene.instantiate()
	add_child(coin)
	var shape := coin.get_node_or_null("CollisionShape3D")
	assert_not_null(shape, "TunaCoinPickup should have a CollisionShape3D")
	coin.queue_free()

func test_tuna_coin_default_value():
	var coin := _coin_scene.instantiate()
	add_child(coin)
	assert_eq(coin.coin_value, 1, "Default coin value should be 1")
	coin.queue_free()

func test_tuna_coin_has_class_name():
	var coin := _coin_scene.instantiate()
	add_child(coin)
	assert_true(coin is TunaCoinPickup, "Should have TunaCoinPickup class_name")
	coin.queue_free()
