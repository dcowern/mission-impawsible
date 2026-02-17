extends GutTest
## Integration test: verifies the full game loop structure.
## Tests that all systems are wired together correctly.

func before_each():
	GameState.reset()

func test_game_state_initialized():
	assert_eq(GameState.tuna_coins, 2)
	assert_eq(GameState.get_ability_level("fire"), 0)
	assert_false(GameState.gem_found)

func test_coin_economy_flow():
	# Simulate: explore → find coins → pick up
	GameState.add_tuna_coins(3)  # 5 total
	assert_eq(GameState.tuna_coins, 5)

	# Visit shrine → unlock ability
	var unlocked := GameState.unlock_ability("fire")
	assert_true(unlocked)
	assert_eq(GameState.get_ability_level("fire"), 1)
	assert_eq(GameState.tuna_coins, 4)

func test_quest_progression():
	var quest_mgr := QuestManager.new()
	add_child_autofree(quest_mgr)

	# Start: talk to elder
	quest_mgr.set_main_quest_stage("awakening")
	assert_eq(quest_mgr.get_main_quest_stage(), "awakening")

	# Find scroll
	quest_mgr.advance_main_quest()
	assert_eq(quest_mgr.get_main_quest_stage(), "first_steps")

	# Advance through all stages to complete
	quest_mgr.advance_main_quest()  # five_trials
	quest_mgr.advance_main_quest()  # gem_location
	quest_mgr.advance_main_quest()  # restoration
	quest_mgr.advance_main_quest()  # complete
	assert_true(GameState.gem_found)

func test_full_save_load_cycle():
	# Set up game state as if player has been playing
	GameState.add_tuna_coins(5)  # 7 total
	GameState.unlock_ability("fire")    # fire=1, coins=6
	GameState.unlock_ability("ice")     # ice=1, coins=5
	GameState.quest_flags["main_quest"] = "first_steps"
	GameState.quest_flags["fetch_barrel"] = "active"

	# Save
	GameState.write_to_save()

	# Capture saved state
	var saved := CogitoSceneManager._current_world_dict.duplicate(true)

	# Reset everything
	GameState.reset()
	assert_eq(GameState.tuna_coins, 2)
	assert_eq(GameState.get_ability_level("fire"), 0)

	# Restore
	CogitoSceneManager._current_world_dict = saved
	GameState.read_from_save()

	# Verify all state restored
	assert_eq(GameState.tuna_coins, 5)
	assert_eq(GameState.get_ability_level("fire"), 1)
	assert_eq(GameState.get_ability_level("ice"), 1)
	assert_eq(GameState.quest_flags["main_quest"], "first_steps")
	assert_eq(GameState.quest_flags["fetch_barrel"], "active")

func test_ability_system_flow():
	# Unlock and verify ability is usable
	GameState.add_tuna_coins(1)  # 3 total
	GameState.unlock_ability("fire")
	assert_eq(GameState.get_ability_level("fire"), 1)

	# Create ability and verify
	var ability := AbilityBase.new()
	ability.discipline = "fire"
	add_child_autofree(ability)
	ability._on_ability_unlocked("fire", 1)
	assert_true(ability.can_use())

	# Cooldown prevents reuse
	ability._cooldown_timer = 1.0
	assert_false(ability.can_use())

func test_npc_taming_flow():
	var dragon := DragonNPC.new()
	dragon.npc_id = "test_dragon"
	add_child_autofree(dragon)

	# Dragon starts untamed
	assert_false(dragon.tamed)

	# Tame it
	dragon.apply_taming()
	assert_true(dragon.tamed)
	assert_eq(dragon.current_state, NPCBase.State.TAMED)

	# State saves
	var state := dragon.save_state()
	assert_true(state["tamed"])

func test_world_scene_structure():
	var world_scene: PackedScene = load("res://scenes/world/world.tscn")
	assert_not_null(world_scene, "World scene should load")
	var world: Node = world_scene.instantiate()
	add_child_autofree(world)

	# Verify all critical systems present
	assert_not_null(world.get_node_or_null("CatPlayer"), "Player exists")
	assert_not_null(world.get_node_or_null("StartingVillage"), "Village exists")
	assert_not_null(world.get_node_or_null("AbilityShrine"), "Shrine exists")
	assert_not_null(world.get_node_or_null("QuestManager"), "Quest manager exists")
	assert_not_null(world.get_node_or_null("TunaCoinDisplay"), "Coin HUD exists")
	assert_not_null(world.get_node_or_null("AbilityHUD"), "Ability HUD exists")
	assert_not_null(world.get_node_or_null("DialogueBalloon"), "Dialogue balloon exists")
	assert_not_null(world.get_node_or_null("TutorialManager"), "Tutorial exists")
	assert_not_null(world.get_node_or_null("CreditsScreen"), "Credits exists")
	assert_not_null(world.get_node_or_null("TouchControls"), "Touch controls exists")
	assert_not_null(world.get_node_or_null("PlatformSettings"), "Platform settings exists")

	# NPCs
	assert_not_null(world.get_node_or_null("ElderCat"), "Elder cat exists")
	assert_not_null(world.get_node_or_null("Dragon1"), "Dragon exists")
	assert_not_null(world.get_node_or_null("Bird1"), "Bird creature exists")
