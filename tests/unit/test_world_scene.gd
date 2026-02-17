extends GutTest
## Tests for the world scene structure and Phase 2 content.
## NOTE: World scene uses GDExtension types (Sky3D, Terrain3D) that produce
## engine errors as placeholders in headless mode — these are expected.

var _world_scene: PackedScene
var _world: Node

func before_all():
	_world_scene = load("res://scenes/world/world.tscn")

func before_each():
	# Sky3D/Terrain3D produce expected engine errors in headless mode
	gut.p("Instantiating world scene (Sky3D/Terrain3D placeholder warnings expected)")
	_world = _world_scene.instantiate()
	add_child(_world)

func after_each():
	if _world and is_instance_valid(_world):
		_world.queue_free()
		_world = null

func test_world_scene_loads():
	assert_not_null(_world_scene, "world.tscn should load")

func test_world_scene_has_terrain():
	var terrain := _world.get_node_or_null("Terrain3D")
	assert_not_null(terrain, "World should have Terrain3D node")

func test_world_scene_has_sky():
	var sky := _world.get_node_or_null("Sky3D")
	assert_not_null(sky, "World should have Sky3D node")

func test_world_scene_has_ocean():
	var ocean := _world.get_node_or_null("Ocean")
	assert_not_null(ocean, "World should have Ocean node")

func test_world_scene_has_river():
	var river := _world.get_node_or_null("River")
	assert_not_null(river, "World should have River node")

func test_world_scene_has_forest_lake():
	var lake := _world.get_node_or_null("ForestLake")
	assert_not_null(lake, "World should have ForestLake node")

func test_world_scene_has_highland_lake():
	var lake := _world.get_node_or_null("HighlandLake")
	assert_not_null(lake, "World should have HighlandLake node")

func test_world_scene_has_starting_village():
	var village := _world.get_node_or_null("StartingVillage")
	assert_not_null(village, "World should have StartingVillage node")

func test_world_scene_has_ability_shrine():
	var shrine := _world.get_node_or_null("AbilityShrine")
	assert_not_null(shrine, "World should have AbilityShrine node")

func test_world_scene_has_tuna_coins():
	var coins := _world.get_node_or_null("TunaCoins")
	assert_not_null(coins, "World should have TunaCoins container")
	var coin_count := coins.get_child_count()
	assert_gte(coin_count, 5, "Should have at least 5 tuna coin pickups")

func test_world_scene_has_player():
	var player := _world.get_node_or_null("CatPlayer")
	assert_not_null(player, "World should have CatPlayer node")

func test_world_scene_has_sky_bridge():
	var bridge := _world.get_node_or_null("SkyBridge")
	assert_not_null(bridge, "World should have SkyBridge node")

func test_world_scene_has_scattered_trees():
	var trees := _world.get_node_or_null("ScatteredTrees")
	assert_not_null(trees, "World should have ScatteredTrees container")
	assert_gt(trees.get_child_count(), 0, "Should have scattered vegetation")
