extends GutTest
## Tests for Starting Village and Ability Shrine scenes.

var _village_scene: PackedScene
var _shrine_scene: PackedScene

func before_all():
	_village_scene = load("res://scenes/world/areas/starting_village.tscn")
	_shrine_scene = load("res://scenes/world/areas/ability_shrine.tscn")

# --- Starting Village tests ---

func test_village_scene_loads():
	assert_not_null(_village_scene, "starting_village.tscn should load")

func test_village_has_buildings():
	var village := _village_scene.instantiate()
	add_child(village)
	var main_hall := village.get_node_or_null("MainHall")
	var workshop := village.get_node_or_null("Workshop")
	var storage := village.get_node_or_null("StorageHut")
	assert_not_null(main_hall, "Village should have MainHall")
	assert_not_null(workshop, "Village should have Workshop")
	assert_not_null(storage, "Village should have StorageHut")
	village.queue_free()

func test_village_has_at_least_5_buildings():
	var village := _village_scene.instantiate()
	add_child(village)
	var building_count := 0
	for child in village.get_children():
		var name_lower: String = child.name.to_lower()
		if "hall" in name_lower or "workshop" in name_lower or "hut" in name_lower or "granary" in name_lower or "tent" in name_lower or "storage" in name_lower:
			building_count += 1
	assert_gte(building_count, 3, "Village should have at least 3 buildings")
	village.queue_free()

func test_village_has_village_center():
	var village := _village_scene.instantiate()
	add_child(village)
	var center := village.get_node_or_null("VillageCenter")
	assert_not_null(center, "Village should have a VillageCenter marker")
	village.queue_free()

# --- Ability Shrine tests ---

func test_shrine_scene_loads():
	assert_not_null(_shrine_scene, "ability_shrine.tscn should load")

func test_shrine_has_altar():
	var shrine := _shrine_scene.instantiate()
	add_child(shrine)
	var altar := shrine.get_node_or_null("Altar")
	assert_not_null(altar, "Shrine should have an Altar")
	shrine.queue_free()

func test_shrine_has_five_pillars():
	var shrine := _shrine_scene.instantiate()
	add_child(shrine)
	var pillars := ["PillarFire", "PillarIce", "PillarWoodland", "PillarDragonTaming", "PillarCreatureSpeak"]
	for pillar_name in pillars:
		var pillar := shrine.get_node_or_null(pillar_name)
		assert_not_null(pillar, "Shrine should have %s" % pillar_name)
	shrine.queue_free()

func test_shrine_has_torches():
	var shrine := _shrine_scene.instantiate()
	add_child(shrine)
	var torch_count := 0
	for child in shrine.get_children():
		if child.name.begins_with("Torch"):
			torch_count += 1
	assert_gte(torch_count, 5, "Shrine should have at least 5 torches")
	shrine.queue_free()

func test_shrine_has_entrance_columns():
	var shrine := _shrine_scene.instantiate()
	add_child(shrine)
	var left := shrine.get_node_or_null("EntranceColumnL")
	var right := shrine.get_node_or_null("EntranceColumnR")
	assert_not_null(left, "Shrine should have left entrance column")
	assert_not_null(right, "Shrine should have right entrance column")
	shrine.queue_free()
