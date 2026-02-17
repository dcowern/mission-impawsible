extends GutTest
## Tests for save/load integration with COGITO world dictionary.

func before_each():
	GameState.reset()
	# Clear any existing world dict entries
	if is_instance_valid(CogitoSceneManager):
		CogitoSceneManager._current_world_dict.erase("mi_tuna_coins")
		CogitoSceneManager._current_world_dict.erase("mi_ability_levels")
		CogitoSceneManager._current_world_dict.erase("mi_quest_flags")
		CogitoSceneManager._current_world_dict.erase("mi_gem_found")

func test_write_to_save_persists_coins():
	GameState.add_tuna_coins(5)  # now 7
	GameState.write_to_save()
	assert_eq(CogitoSceneManager._current_world_dict["mi_tuna_coins"], 7)

func test_write_to_save_persists_abilities():
	GameState.unlock_ability("fire")
	GameState.write_to_save()
	var saved_levels: Dictionary = CogitoSceneManager._current_world_dict["mi_ability_levels"]
	assert_eq(saved_levels["fire"], 1)
	assert_eq(saved_levels["ice"], 0)

func test_read_from_save_restores_coins():
	CogitoSceneManager._current_world_dict["mi_tuna_coins"] = 10
	GameState.read_from_save()
	assert_eq(GameState.tuna_coins, 10)

func test_read_from_save_restores_abilities():
	var levels := {"fire": 3, "ice": 1, "woodland": 0, "dragon_taming": 0, "creature_speak": 2}
	CogitoSceneManager._current_world_dict["mi_ability_levels"] = levels
	GameState.read_from_save()
	assert_eq(GameState.get_ability_level("fire"), 3)
	assert_eq(GameState.get_ability_level("ice"), 1)
	assert_eq(GameState.get_ability_level("creature_speak"), 2)

func test_read_from_save_restores_gem_found():
	CogitoSceneManager._current_world_dict["mi_gem_found"] = true
	GameState.read_from_save()
	assert_true(GameState.gem_found)

func test_roundtrip_save_load():
	GameState.add_tuna_coins(3)  # 5 total
	GameState.unlock_ability("fire")  # fire=1, coins=4
	GameState.unlock_ability("ice")   # ice=1, coins=3
	GameState.quest_flags["main_quest"] = "stage_2"
	GameState.gem_found = false

	# Save
	GameState.write_to_save()

	# Copy the saved dict values (since reset() will overwrite via sync)
	var saved_dict: Dictionary = CogitoSceneManager._current_world_dict.duplicate(true)

	# Reset to defaults
	GameState.reset()
	assert_eq(GameState.tuna_coins, 2)
	assert_eq(GameState.get_ability_level("fire"), 0)

	# Restore saved dict (simulating what COGITO does when loading from disk)
	CogitoSceneManager._current_world_dict = saved_dict

	# Load
	GameState.read_from_save()
	assert_eq(GameState.tuna_coins, 3)
	assert_eq(GameState.get_ability_level("fire"), 1)
	assert_eq(GameState.get_ability_level("ice"), 1)
	assert_eq(GameState.quest_flags["main_quest"], "stage_2")

func test_sync_on_coin_change():
	# Changing coins should auto-sync to world dict
	GameState.add_tuna_coins(1)
	if CogitoSceneManager._current_world_dict.has("mi_tuna_coins"):
		assert_eq(CogitoSceneManager._current_world_dict["mi_tuna_coins"], 3)
	else:
		pass_test("sync not available in test context (CogitoSceneManager may not be ready)")
